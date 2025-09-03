/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../include/s2h.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = DTid / dimensions * 2.0f;
    float2 subUV = frac(uv);

    float4 value;

    if(uv.x < 1)
    {
        if(uv.y < 1)
            value = Input0.SampleLevel(Bilinear, subUV, 0);
        else
            value = Input1.SampleLevel(Bilinear, subUV, 0);
    }
    else
    {
        if(uv.y < 1)
            value = Input2.SampleLevel(Bilinear, subUV, 0);
        else
            value = Input3.SampleLevel(Bilinear, subUV, 0);
    }

    Output[DTid] = value;

    // UI2D
    {
        ContextGather ui;

        s2h_init(ui, DTid);
        // light blue
        ui.textColor.rgb = float3(0.5f, 0.5f, 1);

        s2h_setScale(ui, 5);

        ui.pxCursor = dimensions * float2(0.5f, 0) + float2(-ui.scale * 8, 10);
        s2h_printTxt(ui, 'A');
        ui.pxCursor = dimensions * float2(1, 0) + float2(-ui.scale * 8, 10);
        s2h_printTxt(ui, 'B');
        ui.pxCursor = dimensions * float2(0.5f, 0.5f) + float2(-ui.scale * 8, 10);
        s2h_printTxt(ui, 'C');
        ui.pxCursor = dimensions * float2(1, 0.5f) + float2(-ui.scale * 8, 10);
        s2h_printTxt(ui, 'D');

        Output[DTid] = lerp(Output[DTid], float4(ui.dstColor.rgb, 1), ui.dstColor.a);
    }
}