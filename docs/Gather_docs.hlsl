#if COPYRIGHT == 1
/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////
#endif

#ifdef GIGI
#include "../include/s2h.hlsl"
#include "common.hlsl"
#define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
#define S2S_TIME() /*$(Variable:iTime)*/
#define S2S_MOUSE() /*$(Variable:iMouse)*/
#define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
#define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
#define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
#endif

#if S2H_GLSL == 1
//!KEEP #include "include/s2h.glsl"
#else
//!KEEP #include "include/s2h.hlsl"
#endif

#if S2H_GLSL == 0
/*$(ShaderResources)*/
#endif

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y));
 
    s2h_setCursor(ui, float2(10, 10));
    s2h_setScale(ui, 2.0f);
    ui.textColor.rgb = float3(1,1,1);

#if SUB_CATEGORY == 0   // init
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _i, _n, _i, _t);
#endif

#if SUB_CATEGORY == 1   // printTxt
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _T, _x, _t);
    s2h_printLF(ui);

    ui.textColor.rgb = float3(0,0,0);
    s2h_printLF(ui);

    s2h_setScale(ui, 6.0f);

    ui.textColor.rgb = float3(1,0,0);
    s2h_printTxt(ui, _R);
    ui.textColor.rgb = float3(0,1,0);
    s2h_printTxt(ui, _G);
    ui.textColor.rgb = float3(0,0,1);
    s2h_printTxt(ui, _B);
    s2h_printTxt(ui, _SPACE);
#endif

#if SUB_CATEGORY == 2  // printInt
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _I, _n, _t);
    s2h_printLF(ui);
    s2h_printLF(ui);

    ui.textColor = float4(0, 0, 0, 1);
    s2h_printInt(ui, 12345);
    s2h_printLF(ui);
    s2h_printInt(ui, -12345);
    s2h_printLF(ui);
    s2h_printLF(ui);
#endif

#if SUB_CATEGORY == 3  // printHex
    ui.textColor = float4(1, 1, 1, 1);
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _H, _e, _x);
    s2h_printLF(ui);
    s2h_printLF(ui);

    ui.textColor = float4(0, 0, 0, 1);
    s2h_printHex(ui, 0x1297ABu);
    s2h_printLF(ui);
    s2h_printLF(ui);
#endif

#if SUB_CATEGORY == 4  // printFloat
    ui.textColor = float4(1, 1, 1, 1);
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _F, _l, _o, _a, _t);
    s2h_printLF(ui);
    s2h_printLF(ui);

    ui.textColor = float4(0, 0, 0, 1);
    s2h_printFloat(ui, -12.34);
    s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, 0.34);
#endif

#if SUB_CATEGORY == 5   // shapes
    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _i, _n, _t);
    s2h_printTxt(ui, _B, _o, _x);
    s2h_printTxt(ui, _SLASH);
    s2h_printTxt(ui, _D, _i, _s, _c);
    s2h_printLF(ui);
    s2h_printLF(ui);
    s2h_setScale(ui, 3.0f);
    s2h_printBox(ui, float4(1, 0.7, 0.3f, 1));
    s2h_printBox(ui, float4(1, 0, 0, 1));
    s2h_printDisc(ui, float4(0, 1, 0, 1));
    s2h_printDisc(ui, float4(1, 1, 0, 1));
    s2h_printLF(ui);
    s2h_setScale(ui, 1.0f);
    s2h_printLF(ui);
    s2h_printBox(ui, float4(1, 0.7, 0.3f, 1));
    s2h_printBox(ui, float4(1, 0, 0, 1));
    s2h_printDisc(ui, float4(0, 1, 0, 1));
    s2h_printDisc(ui, float4(1, 1, 0, 1));
#endif

#if SUB_CATEGORY == 6   // progress
    // 0..1
    float fraction = 0.25f;

    s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
    s2h_printTxt(ui, _p, _r, _o, _g, _r);
    s2h_printTxt(ui, _e, _s, _s);
    s2h_printLF(ui);
    s2h_printLF(ui);

    ui.textColor = float4(0,0,0,1);
    s2h_progress(ui, 10u, fraction);
    s2h_printLF(ui);
    s2h_progress(ui, 5u, fraction);
    s2h_printLF(ui);

    s2h_setScale(ui, 3.0f);
    ui.textColor = float4(1,0,0,1);
    ui.buttonColor = float4(0,1,0,1);
    s2h_progress(ui, 15u, fraction);
    s2h_printTxt(ui, _SPACE);
#endif        
    float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);
    fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
}

#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor;
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}
#endif