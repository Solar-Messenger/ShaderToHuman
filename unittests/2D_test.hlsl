/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../include/s2h.hlsl"

/*$(ShaderResources)*/

#define PI 3.14159265

float3 accurateLinearToSRGB(float3 linearCol)
{
	float3 sRGBLo = linearCol * 12.92;
	float3 sRGBHi = (pow(abs(linearCol), float3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
	float3 sRGB;
	sRGB.r = linearCol.r <= 0.0031308 ? sRGBLo.r : sRGBHi.r;
	sRGB.g = linearCol.g <= 0.0031308 ? sRGBLo.g : sRGBHi.g;
	sRGB.b = linearCol.b <= 0.0031308 ? sRGBLo.b : sRGBHi.b;
	return sRGB;
}

float3 accurateSRGBToLinear(in float3 sRGBCol)
{
	float3 linearRGBLo = sRGBCol / 12.92;
	float3 linearRGBHi = pow((sRGBCol + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
	float3 linearRGB;
	linearRGB.r = sRGBCol.r <= 0.04045 ? linearRGBLo.r : linearRGBHi.r;
	linearRGB.g = sRGBCol.g <= 0.04045 ? linearRGBLo.g : linearRGBHi.g;
	linearRGB.b = sRGBCol.b <= 0.04045 ? linearRGBLo.b : linearRGBHi.b;
	return linearRGB;
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    {
        ContextGather ui;

        s2h_init(ui, pxPos + 0.5f);

		// should be in left top of screen
//        s2h_printTxt(ui, 'A');

        s2h_setCursor(ui, float2(10, 10));
        ui.textColor.rgb = float3(1,1,1);

		// 1 pixel wide border
//		s2h_drawRectangle(ui, 1, /*$(Variable:iFrameBufferSize)*/ - 1, float4(0.3f,0.1f,0.1f,1));
		// verify no shift, we expect a one pixel border
//		s2h_drawRectangleAA(ui, 0, /*$(Variable:iFrameBufferSize)*/, 1,0,4);

        s2h_setScale(ui, 3);
        s2h_printTxt(ui, '2', 'D', 'T', 'e', 's', 't');
        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0,0);
        s2h_setScale(ui, 2);
        s2h_printTxt(ui, 'w','i', 't', 'h', ' ');
        s2h_printTxt(ui, 'A', 'A');

        float4 red = float4(1, 0, 0, 1);
        float4 green = float4(0, 1, 0, 1);
        float4 blue = float4(0, 0, 1, 1);
        float4 white = float4(1, 1, 1, 1);
        s2h_drawCircle(ui, float2(190 - 140, 40 + 80), 20, red, 2.0f);
        s2h_drawCircle(ui, float2(190 - 140, 40 + 80), 30, green, 4.0f);

        for(int i = 0; i < 13; ++i )
        {
            float2 center = float2(390 - 140 - 30, 80 + 40);
            float f = i / 13.0f * 2 * 3.14159265;
            float2 d = float2(sin(f), cos(f)); 
            s2h_drawLine(ui, center + d * 20.0f, center + d * 50.0f, blue, 6.0f);
        }

        // s2h_drawRectangle()
        {
            s2h_drawRectangle(ui, float2(20,190 + 20), float2(80,260 + 20), blue);
            s2h_drawRectangle(ui, float2(50,220 + 20), float2(150,280 + 20), blue * 0.5f);
        }

        // s2h_drawRectangleAA()
        {
            s2h_drawRectangleAA(ui, float2(220,190 + 20), float2(280,260 + 20), blue, white, 10.0f);
            s2h_drawRectangleAA(ui, float2(250,220 + 20), float2(350,280 + 20), blue * 0.5f, white * 0.5f, 10.0f);
        }

        // s2h_drawCrosshair()
        {
            s2h_drawCrosshair(ui, float2(190 - 140, 40 + 80), 10, blue, 3.0f);

            // single pixel wide sharp white cross hair with black outline
            s2h_drawCrosshair(ui, float2(100, 90 + 30) + 0.5f, 10, float4(0, 0, 0, 1), 3);
            s2h_drawCrosshair(ui, float2(100, 90 + 30) + 0.5f, 10, float4(1, 1, 1, 1), 1);

            // 2 pixel sharp white sharp white cross hair with black outline
            s2h_drawCrosshair(ui, float2(130, 90 + 30), 10, float4(0, 0, 0, 1), 4);
            s2h_drawCrosshair(ui, float2(130, 90 + 30), 10, float4(1, 1, 1, 1), 2);
        }

        // s2h_drawDisc()
        {
            s2h_drawDisc(ui, float2(590 - 140, 140 + 80), 30, red);
            s2h_drawDisc(ui, float2(590 - 140, 140 + 80), 20, white);
            s2h_drawDisc(ui, float2(590 - 140, 140 + 80), 10, red);
        }

        // s2h_drawHalfSpace()
        for(int i = 0; i < 8; ++i)
        {
            float w = PI * 2 * i / 8;
            float2 center = float2(100, 400);
            float3 halfSpace = float3(sin(w), cos(w), 0);
            halfSpace.z -= dot(halfSpace, float3(center, 1));
            halfSpace.z += 80.0f;
            // the multiplicative factor is not shown in this visualization
            halfSpace *= i + 1;
            s2h_drawHalfSpace(ui, halfSpace, center, float4(1,1,1,1), 20, 30);
        }

        // opaque pink background
        float4 background = float4(accurateSRGBToLinear(float3(0.7f, 0.5f, 0.5f)), 1.0f);

        float4 linearColor = float4(background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb, 1);

        // accurateLinearToSRGB is needed if you want to get correct blending
        Output[DTid] = float4(accurateLinearToSRGB(linearColor.rgb), linearColor.a);
    }
}