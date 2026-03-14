//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#ifdef S2H_GLSL
    // shadertoy
	#define S2S_FRAMEBUFFERSIZE() iResolution.xy
	#define S2S_TIME() iTime
	#define S2S_MOUSE() iMouse
	#define S2S_NEAR() 0.1f
	#define S2S_INV_VIEW_PROJECTION() u_worldFromClip
	// todo
	#define S2S_CAMERA_POS() vec3(0,0,0)
#else
    // gigi
	#define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
	#define S2S_TIME() /*$(Variable:iTime)*/
	#define S2S_MOUSE() /*$(Variable:MouseState)*/
	#define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
	#define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
	#define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/

/*$(ShaderResources)*/
#endif


// from https://bgolus.medium.com/the-best-darn-grid-shader-yet-727f9278b9d8
float gridTextureGradBox(float2 p, float2 ddx, float2 ddy, float N = 10.0f)
{
	float2 w = max(abs(ddx), abs(ddy)) + 0.01f;
	float2 a = p + 0.5f * w;
	float2 b = p - 0.5f * w;
	float2 i = (floor(a) + min(frac(a) * N, 1.0f) -
              floor(b) - min(frac(b) * N, 1.0f)) / (N * w);
	return (1.0f - i.x) * (1.0f - i.y);
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 pxPos = DTid + 0.5f;

	float4 background = float4(0.01f, 0.01f, 0.1f, 1.0f);
	float4 linearColor = background;

	// pixel perfect UI without pan and scale
	ContextGather ui;
	
	// snap pxPos
	float2 snappedPxPos = floor(pxPos) + 0.5f;
		
	s2h_init(ui, snappedPxPos);
	s2h_setScale(ui, 2);
	s2h_setCursor(ui, float2(10, 10));

	s2h_coordinateSystem(ui, float2(50, 130), float4(-30.0f, -30.0f, 250.0f, 250.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 0);
	ui.lineWidth = 1.0f;
	s2h_coordinateSystem(ui, float2(440, 150), float4(-10.0f, -120.0f, 150.0f, 10.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 3);
	
	s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
	s2h_printTxt(ui, _c, _o, _o, _r, _d, _i);
	s2h_printTxt(ui, _n, _a, _t, _e, _S, _y);
	s2h_printTxt(ui, _s, _t, _e, _m);
		
	linearColor = linearColor * (1.0f - ui.dstColor.a) + ui.dstColor;
		
	Output[DTid] = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
}