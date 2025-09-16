/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "SplatCommon.hlsl"

/*$(ShaderResources)*/

struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};

/*
// @param xy x:-1 / 1, y:-1 / 1
float2 computeCorner(float2 xy, float3 csConic, float2 resolution)
{
	float a = csConic.x;
	float b = 0.5f * csConic.y;
	float c = csConic.z;

	// see ShaderToy https://www.shadertoy.com/view/msGcDh
	float baseHalf = (a + c) * 0.5f;
	float rootHalf = 0.5f * sqrt((a - c) * (a - c) + 4.0f * b * b);
	float rx	   = rsqrt(baseHalf + rootHalf);
	float ry	   = rsqrt(baseHalf - rootHalf);

	float2 k = float2(a - c, 2.0f * b);

	// if splat gets thinner than a pixel, keep it pixel size for antialiasing, this works with aspectRatio
//	rx = max(rx, 1.0f / resolution.y);
//	ry = max(ry, 1.0f / resolution.x);

	// half vector, should be faster than atan()
	float2 axis0 = normalize(k + float2(length(k), 0));

	float2 axis1 = float2(axis0.y, -axis0.x);

	return (axis0 * (rx * xy.x) - axis1 * (ry * xy.y)) * float2(resolution.y / resolution.x, 1.0f);
}
*/

// @param xy to identify corner x:-1 / 1, y:-1 / 1
// @return relative pixel pos
float2 computeCornerPs(float2 xy, float3 psConic)
{
//	return float2(10,0) * xy.x - float2(0,10) * xy.y;

	float a = psConic.x;
	float b = 0.5f * psConic.y;
	float c = psConic.z;

	// see ShaderToy https://www.shadertoy.com/view/msGcDh
	float baseHalf = (a + c) * 0.5f;
	float rootHalf = 0.5f * sqrt((a - c) * (a - c) + 4.0f * b * b);
	float rx	   = rsqrt(baseHalf + rootHalf);
	float ry	   = rsqrt(baseHalf - rootHalf);

	float2 k = float2(a - c, 2.0f * b);

	// if splat gets thinner than a pixel, keep it pixel size for antialiasing, this works with aspectRatio
//	rx = max(rx, 1.0f / resolution.y);
//	ry = max(ry, 1.0f / resolution.x);

	// half vector, should be faster than atan()
	float2 axis0 = normalize(k + float2(length(k), 0));

	float2 axis1 = float2(axis0.y, -axis0.x);

	return (axis0 * (rx * xy.x) + axis1 * (ry * xy.y));
}


// @param projection also called viewToClip
float deviceDepthFromViewLinearDepth(float viewSpaceZ, float4x4 projection)
{
	// can be optimized
	float deviceDepth = (projection._34 / viewSpaceZ - projection._33) / projection._43;

	return deviceDepth;
}

// inverse of ScreenFromClip()
// for debugging
// @param deviceDepth see deviceDepthFromViewLinearDepth() and viewLinearDepthFromDeviceDepth()
// @return clipPos
float4 ClipFromScreen(float2 pixelPos, float deviceDepth)
{
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

	// float2(0..1, 0..1)
	float2 uv = pixelPos / dimensions;

	return float4(uv * float2(2, -2) - float2(1, -1), deviceDepth, 1.0f);
}

float getFloat(inout uint p)
{
	return asfloat(PlyFile[p++]);
}

float3 getFloat3(inout uint p)
{
	return float3(getFloat(p), getFloat(p), getFloat(p));
}

float4 getFloat4(inout uint p)
{
	return float4(getFloat(p), getFloat(p), getFloat(p), getFloat(p));
}

// @return linearScale
float3 unpackScale(float3 scale)
{
	return exp(scale);
}

// see unpackScale()
float3 packScale(float3 scale)
{
	return log(scale);
}

// @return 0..1, roughly around x=-4 it's 0.0f, around x=+4 it's 1.0f
float sigmoid(float x)
{
	// CUDA Gaussian Splatting implementation
	// https://github.com/graphdeco-inria/diff-gaussian-rasterization/blob/8064f52ca233942bdec2d1a1451c026deedd320b/cuda_rasterizer/auxiliary.h
	return 1.0f / (1.0f + exp(-x));

/* // no visual difference
	if (x >= 0.0f)
	{
		return 1.0f / (1.0f + exp(-x));
	}
	else
	{
		float z = exp(x);
		return z / (1.0f + z);
	}
*/
}

// see sigmoid()
float unsigmoid(float x)
{
	return -log(1.0f / x - 1.0f);
}

SplatParams getSplatParamsFromPly(uint splatId, float3 SplatOffset)
{
	SplatParams ret = (SplatParams)0;

	uint p = plyHeader[0].HeaderSize + splatId * plyHeader[0].Stride;

	ret.pos = getFloat3(p);

	float3 normal = getFloat3(p);

	float3 colorSH = getFloat3(p);
	ret.colorAndAlpha.rgb = colorSH * 0.2820948f + 0.5f;

	p += 45;	// SH bands besides 0

	ret.colorAndAlpha.a = sigmoid(getFloat(p));
	ret.linearScale = unpackScale(getFloat3(p));
	ret.rot = getFloat4(p);

	return ret;
}

VSOutput_Splat mainVS(VSInput input)
{
	VSOutput_Splat output = (VSOutput_Splat)0;

	uint id = input.vertexId % 6;

	float2 uv = float2(0, 0);
	if(id == 1) uv = float2(1, 0);
	if(id == 2 || id == 3) uv = float2(1, 1);
	if(id == 4) uv = float2(0, 1);


	// x:-1 / 1, y:-1 / 1
	float2 xy = uv * 2.0f - 1.0f;

	uint splatId = input.instanceId;

    float2 resolution = /*$(Variable:iFrameBufferSize)*/.xy;

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

//	SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);

	SplatParams splatParams = getSplatParamsFromPly(splatId, /*$(Variable:SplatOffset)*/);

    SplatRasterizeParams params;
    bool visible = computeSplatRasterizeParams(splatParams, params, dimensions, worldToClip, viewToClip, worldToView);

	// why - ?
	output.position = ClipFromScreen(params.psCenter, deviceDepthFromViewLinearDepth(-params.splatZ.x, viewToClip));	// todo depth
 
	float aspectRatio = resolution.x / resolution.y;
	// ps from cs scale
	float2 s = float2(2, -2) / resolution.xy;
	float invAspectRatio = viewToClip._m11 / viewToClip._m00;

	float3 psConicMul1 = params.psConicMul / log2((float)_E);
	float3 psConic = psConicMul1 / -0.5f;

	float2 cornerPos = computeCornerPs(xy, psConic) / resolution * float2(2, -2);

	output.position.xy += cornerPos * output.position.w * GAUSSIAN_CUTOFF_SCALE; 

	params.toInterpolator(output.a, output.b, output.c);

	output.uv = uv;
	output.splatId = splatId;

	return output;
}
