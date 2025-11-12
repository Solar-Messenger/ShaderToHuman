#if COPYRIGHT == 1
//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////
#endif

#ifdef GIGI
#include "../include/s2h.hlsl"
#include "../include/s2h_3d.hlsl"
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

#define PI 3.14159265f

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();

#if SUB_CATEGORY == 0 // init
    s2h_setCursor(ui, float2(10, 10));
    s2h_setScale(ui, 2.0f);
    s2h_printTxt(ui, _i, _n, _i, _t);
#endif

#if SUB_CATEGORY == 1 // disc
    s2h_drawDisc(ui, float2(100, 50), 40.0f, float4(1,0,0,1));
    s2h_drawDisc(ui, float2(200, 50), 20.0f, float4(0,1,0,1));
    s2h_drawDisc(ui, float2(150, 50), 30.0f, float4(0,0,0,0.5f));
#endif

#if SUB_CATEGORY == 2   // circle
    s2h_drawCircle(ui, float2(100, 50), 40.0f, float4(1,0,0,1), 1.0f);
    s2h_drawCircle(ui, float2(200, 50), 20.0f, float4(0,1,0,1), 5.0f);
    s2h_drawCircle(ui, float2(150, 50), 30.0f, float4(0,0,0,0.5f), 8.0f);
#endif

#if SUB_CATEGORY == 3   // halfSpace
    s2h_drawCrosshair(ui, ui.mouseInput.xy + 0.5f, 10.0f, float4(1,1,1,1), 2.0f);
    int edgeCount = 3;
    bool inside = true;
    float insideAA = 1.0f;
    for(int i = 0; i < edgeCount; ++i)
    {
        float2 center = float2(150, 50);

        float w = float(i) * PI * 2.0f / float(edgeCount) + 0.2f;
        float3 halfSpace = float3(sin(w), cos(w), -20);
        halfSpace.z -= dot(halfSpace, float3(center, 0));

        s2h_drawHalfSpace(ui, halfSpace, ui.mouseInput.xy + 0.5f, float4(s2h_indexToColor(uint(i + 1)),1), 10.0f, 20.0f);

        if(dot(halfSpace, float3(ui.pxPos, 1)) > 0.0f)
            inside = false;
 
        insideAA *= saturate(0.5f - dot(halfSpace, float3(ui.pxPos - float2(200, 0), 1)));
    }

    if(inside) ui.dstColor = float4(1, 1, 1, 1);
    ui.dstColor = lerp(ui.dstColor, float4(1,1,1,1), insideAA);

    s2h_setScale(ui, 2.0f);
    s2h_setCursor(ui, float2(166, 10));
    s2h_printTxt(ui, _n, _o, _A, _A);
    s2h_setCursor(ui, float2(366, 10));
    s2h_printTxt(ui, _A, _A);

#endif

#if SUB_CATEGORY == 4   // rectangle
    s2h_drawRectangle(ui, float2(100, 10), float2(300, 90), float4(1,0,0,1));
    s2h_drawRectangle(ui, float2(200, 50), float2(400, 65), float4(0,1,0,1));
    s2h_drawRectangle(ui, float2(150, 25), float2(350, 75), float4(0,0,0,0.5f));
#endif

#if SUB_CATEGORY == 5  // rectangleAA
    s2h_drawRectangleAA(ui, float2(100, 10), float2(300, 90), float4(1,0,0,1), float4(1,1,0,1), 5.0f);
    s2h_drawRectangleAA(ui, float2(200, 50), float2(400, 65), float4(0,0,1,1), float4(0,1,1,1), 3.0f);
    s2h_drawRectangleAA(ui, float2(150, 25), float2(350, 75), float4(1,1,1,1), float4(0,0,0,0.5f), 2.0f);
#endif

#if SUB_CATEGORY == 6  // crosshair
    s2h_drawCrosshair(ui, float2(190 - 140, 50) + 0.5f, 10.0f, float4(0,0,1,1), 1.0f);

    // single pixel wide sharp white cross hair with black outline
    s2h_drawCrosshair(ui, float2(200, 50) + 0.5f, 20.0f, float4(0, 0, 0, 1), 3.0f);
    s2h_drawCrosshair(ui, float2(200, 50) + 0.5f, 20.0f, float4(1, 1, 1, 1), 1.0f);

    // 2 pixel sharp white sharp white cross hair with black outline
    s2h_drawCrosshair(ui, float2(360, 50), 30.0f, float4(0, 0, 0, 1), 4.0f);
    s2h_drawCrosshair(ui, float2(360, 50), 30.0f, float4(1, 1, 1, 1), 2.0f);

#endif

#if SUB_CATEGORY == 7  // line
    for(int i = 0; i < 5; ++i)
    {
        float w = float(i) * 1.1f + 1.0f;
        float2 center = float2(50, 50) + float2(90 * i, 0);
        float2 sc = float2(sin(w), cos(w)) * 20.0f;
        s2h_drawLine(ui, center + sc, center - sc, float4(s2h_indexToColor(uint(i)), 1), 1.0f + float(i) * 4.0f);
    }
#endif

#if SUB_CATEGORY == 8 // sRGBRamp
    // sRGB gradient
    float value = (pxPos.x - S2S_FRAMEBUFFERSIZE().x * 0.5f) / 256.0f + 0.5f;
    ui.dstColor = float4(value, value, value, 1);

    s2h_drawSRGBRamp(ui, float2(S2S_FRAMEBUFFERSIZE().x * 0.5f - 128.0f, 75 - 16));
#endif

#if SUB_CATEGORY == 9   // arrow
    // todo
#endif

#if SUB_CATEGORY == 10  // triangle
    // todo
#endif

    float3 background = float3(0.7f, 0.4f, 0.4f);
    float3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = float4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}

#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}
#endif