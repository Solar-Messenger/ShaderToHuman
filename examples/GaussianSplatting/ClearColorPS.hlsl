//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_3d.hlsl"
#include "SplatCommon.hlsl"

#ifdef S2H_GLSL
    // shadertoy
    #define S2S_FRAMEBUFFERSIZE() iResolution.xy
    #define S2S_TIME() iTime
    #define S2S_MOUSE() iMouse
    #define S2S_NEAR() 0.1f
    #define S2S_INV_VIEW_PROJECTION() transpose(u_worldFromClip)
    #define S2S_CAMERA_POS() ((u_worldFromView * vec4(0, 0, 0, 1)).xyz)
#else
    // gigi
    #define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
    #define S2S_TIME() /*$(Variable:iTime)*/
    #define S2S_MOUSE() /*$(Variable:iMouse)*/
    #define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
    #define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
    #define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
#endif

/*$(ShaderResources)*/

struct VSOutput // AKA PSInput
{
	// for xbox needs this to be last
	float4 position : SV_POSITION;
};

struct PSOutput
{
	// linear color, not sRGB
	float4 colorTarget : SV_Target0;
};

/*
// works well, assumes no normalize
float s2h_floatLookupFloat(uint functionId, float x)
{
	float steps = floor(x * 8) / 8.0f;
//	float steps = floor(x * 8 + 1) / 8.0f;	// can we do this ?
	float halfFixup = x / steps * 0.5f;
	float end = steps * halfFixup * 2.0f;

	if(functionId == 1)
		return steps;
	if(functionId == 2)
		return halfFixup;
	if(functionId == 3)
		return end;

	return x;
}
*/

float sqr(float x)
{
	return x * x;
}

// with normalize
float s2h_floatLookupFloat(uint functionId, float x)
{
	float4 gpt = /*$(Variable:GeneralPurposeTweak)*/;

	float colorA = 0.1f, colorAAlpha = 1.0f;
	float colorB = 0.9f;
//	float colorA = 0.0f, colorAAlpha = 1.0f;
//	float colorB = 1.0f;

	// 0..1
	float steps = floor(x * 8) / 8.0f;
//	float steps = floor(x * 8 + 1) / 8.0f;	// can we do this ?
	float fixup = x / steps;

	// at least smooth
	fixup = fixup * (1 - steps);
	// remap to be linear
	fixup = fixup / (1 - x);

	float sumColor = colorA * (1 - steps) * colorAAlpha + colorB * steps * fixup;
	float sumAlpha = (colorAAlpha) * (1 - steps) + (fixup) * steps;
	float color = sumColor / sumAlpha;

	if(functionId == 1)
		return steps;
	if(functionId == 2)
		return fixup * FIXUP_MUL;
	if(functionId == 3)
		return color;

	return lerp(colorA, colorB, x);
}

PSOutput main(VSOutput input)
{
	uint2 pxPos = (int2)input.position.xy;

    float3 background = float3(0.1f, 0.2f, 0.3f) * 0.7f;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float3 color;

    // some faint 2D color grid  to not confuse with Gigi or Photoshop grid
    // and to make grey shadow look about right
    {
        float3 darkColor = float3(0.27f, 0.27f, 0.27f * 1.2f);
        float3 lightColor = float3(0.29f, 0.29f, 0.29f * 1.2f);
        uint2 gridPos = pxPos / 16;
        bool checker = (gridPos.x % 2) == (gridPos.y % 2);
        color = checker ? lightColor : darkColor;
    }

	float3 linearOutput =  background;		// hack

    {
        ContextGather ui;

        s2h_init(ui, pxPos);

		s2h_drawSRGBRamp(ui, float2(2, 2));

#if WEIGHT_EXPERIMENT == 1
		s2h_setCursor(ui, float2(10, 50));
		// uses s2h_floatLookupFloat()
		s2h_function(ui, 0, float4(0,0,0,0.5f), int2(50,16), float2(0,1), float2(0,1));
		s2h_printLF(ui);
		s2h_function(ui, 1, float4(0,0,0,0.5f), int2(50,16), float2(0,1), float2(0,1));
		s2h_printLF(ui);
		s2h_function(ui, 2, float4(0,0,0,0.5f), int2(50,16), float2(0,1), float2(0,1));
		s2h_printLF(ui);
		s2h_function(ui, 3, float4(0,0,0,0.5f), int2(50,16), float2(0,1), float2(0,1));
#endif

        linearOutput = lerp(linearOutput, ui.dstColor.rgb, ui.dstColor.a);
    }

    Context3D context;
    float3 worldPos;
    {
        float2 uv = pxPos / dimensions.xy;
        float2 screenPos = uv * 2.0f - 1.0f;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, S2S_NEAR(), 1), S2S_INV_VIEW_PROJECTION());
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }
    s2h_init(context, S2S_CAMERA_POS(), normalize(worldPos - S2S_CAMERA_POS()));

    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    float3 offset = float3(0,-1,0);

	context.dstColor.rgb = linearOutput;

    s2h_drawCheckerBoard(context, offset);

    uint splatId = 0;
	SplatParams splatParams = getSplatParams(splatId, /*$(Variable:SplatOffset)*/);
	float4x4 splatBase = computeSplatBase(splatParams);
    // splat basis
    s2h_drawBasis(context, splatBase, GAUSSIAN_CUTOFF_SCALE);

	color = context.dstColor.rgb;

//	float3 color = float3(1,1,1);

	PSOutput ret;

    ret.colorTarget = float4(s2h_accurateLinearToSRGB(color), 0.5f);
//   ret.colorTarget = float4(s2h_accurateLinearToSRGB(color), 0.01f);
	// hack
//    ret.colorTarget = float4(0,0,0, 0.5f);

	return ret;
}