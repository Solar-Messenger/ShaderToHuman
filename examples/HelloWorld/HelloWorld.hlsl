//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    ContextGather ui;
    s2h_init(ui, pxPos + 0.5f);
    s2h_setCursor(ui, float2(10, 10));

    s2h_setScale(ui, 3.0f);
    s2h_printTxt(ui, _H, _e, _l, _l, _o);
    s2h_printLF(ui);
    s2h_printTxt(ui, _W, _o, _r, _l, _d);

    float4 background = float4(uv.x, uv.y, 0, 1.0f);
    Output[DTid] = lerp(background, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
}
