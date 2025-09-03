/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float aspectRatio = dimensions.x / dimensions.y;
    uint2 pxPos = DTid;

    float3 color;

    // some faint 2D color grid  to not confuse with Gigi or Photoshop grid
    // and to make grey shadow look about right
    {
        float3 darkColor = float3(0.27f, 0.27f, 0.27f * 1.2f);
        float3 lightColor = float3(0.29f, 0.29f, 0.29f * 1.2f);
        uint2 gridPos = DTid / 16;
        bool checker = (gridPos.x % 2) == (gridPos.y % 2);
        color = checker ? lightColor : darkColor;
    }

#ifdef COLOR
    Output[DTid] = float4(0, 0, 0, 1.0f);
#else
    Output[DTid] = float4(color, 1.0f);
#endif
}