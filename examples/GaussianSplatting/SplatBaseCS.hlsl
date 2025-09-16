/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_scatter.hlsl"
#include "../../include/s2h_3d.hlsl"
#include "SplatCommon.hlsl"

// 1: low quality
// 16: high quality
// 64: very high quality
#define SAMPLE_COUNT 8

// RWStructuredBuffer<Struct_UIState> UIState : register(u1);  // need to be transient to maintain state

/*$(ShaderResources)*/

// clear to black and render base of the splat together with World Space basis
[numthreads(8, 8, 1)]
void baseCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;
    float2 pxPosFloat = pxPos + 0.5f;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;

    float2 uv = pxPosFloat / dimensions.xy;

    // clear screen
    float3 background = float3(0.1f, 0.2f, 0.3f) * 0.7f;
    float4 linearOutput = float4(background,1);

    float3 worldPos;
    {
        float2 screenPos = uv * 2.0 - 1.0;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, /*$(Variable:CameraNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }

    Context3D context;

    s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 40));
        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;

        ui.textColor.rgb = float3(1,1,1);

        s2h_setScale(ui, 2);
        s2h_printLF(ui);

#if TESTID == 0 // CS Raster
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 's', 't', 'e', 'r');
        s2h_printLF(ui);
#elif TESTID == 1 // CS Ray
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 'y');
        s2h_printLF(ui);
        s2h_printTxt(ui, 'P', 'e', 'r', 's', 'p');
        s2h_printTxt(ui, 'e', 'c', 't', 'i', 'v');
        s2h_printTxt(ui, 'e', 'C', 'o', 'r', 'r');
        s2h_printTxt(ui, 'e', 'c', 't');
        s2h_printLF(ui);
#elif TESTID == 2 // VSPS Raster
        s2h_printTxt(ui, 'V', 'S', 'P', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 's', 't', 'e', 'r');
        s2h_printLF(ui);
#elif TESTID == 3 // CS Ray many splats
        s2h_printTxt(ui, 'C', 'S', ' ');
        s2h_printTxt(ui, 'R', 'a', 'y');
        s2h_printLF(ui);
        s2h_printTxt(ui, 'M', 'a', 'n', 'y', 'S');
        s2h_printTxt(ui, 'p', 'l', 'a', 't', 's');
        s2h_printLF(ui);
#endif

		s2h_drawSRGBRamp(ui, float2(2, 2));

/*
        s2h_printLF(ui);
        s2h_printInt(ui, PlyHeader[0].HeaderSize);
        s2h_printLF(ui);
        s2h_printInt(ui, PlyHeader[0].Stride);	// *4 to get bytes, should be 58*4=232, see https://blog.playcanvas.com/compressing-gaussian-splats/
        s2h_printLF(ui);
        s2h_printInt(ui, PlyHeader[0].FormatId);
        s2h_printLF(ui);
        s2h_printInt(ui, PlyHeader[0].VertexCount);
        s2h_printLF(ui);
*/


        linearOutput = lerp(linearOutput, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
    }

    float4 sRGBOutput = float4(s2h_accurateLinearToSRGB(linearOutput.rgb), linearOutput.a);

    Output[DTid] = sRGBOutput;
}
