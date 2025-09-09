/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../include/s2h.hlsl"
#include "../include/s2h_scatter.hlsl"
#include "../include/s2h_3d.hlsl"
#include "SplatCommon.hlsl"

/*$(ShaderResources)*/

float3 getSplatPos()
{
    return float3(4, -1, 4);
}

// @return visible
bool getSplat(uint splatId, out SplatRasterizeParams params)
{
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float3 wsPos = getSplatPos();
    float4 inColorAndAlpha = float4(1.0f, 0.7f, 0.2f, 1.0f);
    float3x3 osRot = matrixFromQuaternion(float4(0, 0, 0, 1));
    float3 osScale = float3(1,2,3) * 0.4f;
    float3x3 osRotMulScale = mul(osRot, float3x3(float3(osScale.x, 0, 0), float3(0, osScale.y, 0), float3(0, 0, osScale.z)));
    float3x3 wsRotMulScale = osRotMulScale;
    float widthZ = length(osScale[0]);

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

    params.setup(wsRotMulScale, wsPos, widthZ, inColorAndAlpha,
        viewToClip, worldToClip, worldToView, float4(dimensions, 1.0f / dimensions));

    // if not behind camera
    bool visible = params.splatZ.x < 0.0f; 

    return visible;
}

void scene(inout Context3D context)
{
    float3 offset = getSplatPos();

    // todo: check for sRGB correct blending, a=0.5 seems too faint
//    drawSphereWS(context, float3(1, 0, 0) + offset, float4(1, 0, 0, 0.5f), 1.0f);
//    drawSphereWS(context, float3(0, 1, 0) + offset, float4(0, 1, 0, 0.5f), 1.0f);
//    drawSphereWS(context, float3(0, 0, 1) + offset, float4(0, 0, 1, 0.5f), 1.0f);

    // center
    s2h_drawSphereWS(context, offset, float4(1, 0, 0, 0.5f), 0.2f);
    // axis
    s2h_drawArrowWS(context, offset, offset + float3(1, 0, 0), float4(1, 0, 0, 1));
    s2h_drawArrowWS(context, offset, offset + float3(0, 2, 0), float4(0, 1, 0, 1));
    s2h_drawArrowWS(context, offset, offset + float3(0, 0, 3), float4(0, 0, 1, 1));
}

// affects instancing number (can be a limit) and performance (if too small the GPU will not utilized efficiently, likely around warp size)
// need to be the same in C++
#define INSTANCE_SIZE 128


struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};


struct VSOutput // AKA PSInput
{
	// one splat, see struct SplatRasterizeParams
	nointerpolation float4 a : TEXCOORD0;
	nointerpolation float4 b : TEXCOORD1;
	nointerpolation float3 c : TEXCOORD2;

	// for xbox needs this to be last
	float4 position : SV_POSITION;
};

struct PSOutput
{
	float4 colorTarget : SV_Target0;
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

VSOutput mainVS(VSInput input)
{
	VSOutput output = (VSOutput)0;

	uint globalVertexId = INSTANCE_SIZE * 4 * input.instanceId + input.vertexId;

	// x:0/1, y:0/1
	//
	// 0--1
	// |  |
	// |  |
	// 3--2
	float2 uv = float2(((input.vertexId + 1) >> 1) & 1, (input.vertexId >> 1) & 1);
	// x:-1 / 1, y:-1 / 1
	float2 xy = uv * 2.0f - 1.0f;

	uint splatId = globalVertexId / 4;

//	// we use instancing so the last instance might not be fully filled
//	if (quadIndex >= g_constants.getTotalSplatCount())
//		return output;

//	uint splatId = g_SortedSplatsIndices[quadIndex];
    float2 resolution = /*$(Variable:iFrameBufferSize)*/.xy;

//	SplatRasterizeParams params = getSplatElementCsToVs(g_SplatBufferRaw, SETUP_FLOAT4_COUNT, splatId).params;
    SplatRasterizeParams params;
    bool visible = getSplat(splatId, params);

    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);

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

//	ret.position = mul(float4(input.position, 1.0f), /*$(Variable:ViewProjMtx)*/);
//	output.UV = uv;
	return output;
}

PSOutput mainPS(VSOutput input)
{
	PSOutput ret = (PSOutput)0;
	ret.colorTarget = float4(1, 0, 1, 1);
	return ret;
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;
    float2 pxPosFloat = pxPos + 0.5f;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float aspectRatio = dimensions.x / dimensions.y;

    float2 uv = (pxPos + 0.5f) / dimensions.xy;

    float3 worldPos;
    {
        float2 screenPos = uv * 2.0 - 1.0;

        // gigi flaw? Need to set Viewer CamerSettings the ProjMtxTexture
//        screenPos.x *= aspectRatio;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, /*$(Variable:depthNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }

    Context3D context;

    s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

    scene(context);


    SplatRasterizeParams params;

    bool visible = getSplat(0, params);

    if(visible)
    {
        float4 value = params.evaluate(pxPos + 0.5f);

        Output[DTid] = lerp(Output[DTid], float4(value.rgb, 1), value.a);

        // visualize bounding ellipse
        if(1)
        {
            float a = params.computeOriginalConicPs().x;
            float b = params.computeOriginalConicPs().y;
            float c = params.computeOriginalConicPs().z;

            float x = pxPosFloat.x - params.psCenter.x;
            float y = pxPosFloat.y - params.psCenter.y;

            float gaussianCutoffScale = GAUSSIAN_CUTOFF_SCALE;

            float error = a * x * x + 2.0 * b * x * y + c * y * y - gaussianCutoffScale * gaussianCutoffScale;
            if(abs(error) < 0.1)
                Output[DTid] = lerp(Output[DTid], float4(0, 1, 0, 1), 0.5f);
        }
    }

    Output[DTid] = lerp(Output[DTid], float4(context.dstColor.rgb, 1), context.dstColor.a);

    // UI2D
    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 10));

        if(visible)
        {
            // DirectX to OpenGL style math
            float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
            float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
            float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);
            float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

            float3 wsPos = getSplatPos();
//            float3 wsPos = float3(0,-1,0);
            float4 csPos = mul(worldToClip, float4(wsPos, 1));
            // left..right: -1..1, bottom..top:-1..1
            float2 uvPos = csPos.xy / csPos.w * float2(0.5f, -0.5f) + 0.5f;
            float2 pxPos = uvPos * dimensions;
            

//            s2h_drawCrosshair(ui, pxPos, 20, float4(1, 1, 1, 1), 4);

            float4 aabb2 = params.computeAABB();

//            drawRectangle(ui, aabb2.xy, aabb2.zw, float4(0, 1, 0, 0.5f));
            s2h_drawRectangleAA(ui, aabb2.xy, aabb2.zw, float4(0, 1, 1, 0.5f), float4(0,0,0,0), 5);

            Output[ui.pxPos] = float4(Output[ui.pxPos].rgb * (1 - ui.dstColor.a) + ui.dstColor.rgb, Output[ui.pxPos].a);
            return;
        }
    }
}
