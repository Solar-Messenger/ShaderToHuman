//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../include/s2h.hlsl"
#include "../include/s2h_3d.hlsl"

// 1:no Anti-Aliasing, 2:2x2, 3:3x3
#define AA 3

/*$(ShaderResources)*/

void scene(inout Context3D context)
{
    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    float3 offset = float3(0,-1,0);

    s2h_drawCheckerBoard(context, offset);

    s2h_drawSphereWS(context, float3(1, 0, 0) + offset, float4(1, 0, 0, 1), 0.1f);
    s2h_drawSphereWS(context, float3(0, 1, 0) + offset, float4(0, 1, 0, 1), 0.1f);
    s2h_drawSphereWS(context, float3(0, 0, 1) + offset, float4(0, 0, 1, 1), 0.1f);

    // axis
    s2h_drawArrowWS(context, float3(0, 0, 0) + offset, float3(1, 0, 0) + offset, float4(1, 0, 0, 1), 0.09f);
    s2h_drawArrowWS(context, float3(0, 0, 0) + offset, float3(0, 1, 0) + offset, float4(0, 1, 0, 1), 0.09f);
    s2h_drawArrowWS(context, float3(0, 0, 0) + offset, float3(0, 0, 1) + offset, float4(0, 0, 1, 1), 0.09f);

    // yellow square
    s2h_drawLineWS(context, float3(-1, 2,  1) + offset, float3(1, 2,  1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3(-1, 2, -1) + offset, float3(1, 2, -1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3(-1, 2, -1) + offset, float3(-1, 2, 1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3( 1, 2, -1) + offset, float3( 1, 2, 1) + offset, float4(1, 1, 0, 1), 0.09f);

    // todo: AABB, OBB, animation, push transform, noAA option, shadows option
}

// @param ro ray origin
// @param rd ray direction, assumed to be normalized
float3 computeSkyColor(float3 ro, float3 rd)
{
//    float PI = 3.14159265f;
//    float2 uv = float2(asin(rd.x) / PI + 0.5, asin(rd.y) / PI + 0.5) * 2 - 1;
//   float2 uv = float2(acos(rd.y) / PI, (atan2(rd.x, rd.z) + PI) / (2.0 * PI));

//    return frac(float3(uv.x, uv.y, 0));

    // use direction as color
    return normalize(rd * 0.5 + 0.5) * 0.5f;

    // horizon line
    if(abs(rd.y) < 0.001f)
        return float3(1,1,1);
    else
    {
        // brown ground 
        if(rd.y < 0.0f)
            return float3(3,2,1) * 0.1f;
    }

    return lerp(float3(0.5f, 0.5f, 1), float3(0.6f, 0.6f, 1), rd.y);
}

float4x4 lookAt(float3 eye, float3 target, float3 up)
{
    float3 zaxis = normalize(target - eye);
    float3 xaxis = normalize(cross(up, zaxis));
    float3 yaxis = cross(zaxis, xaxis);
    return transpose(float4x4(float4(xaxis, 0), float4(yaxis, 0), float4(zaxis, 0), float4(eye, 1)));
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float aspectRatio = dimensions.x / dimensions.y;
    uint2 pxPos = DTid;

    Context3D context;

    float4 tot = float4(0, 0, 0, 0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        float2 subPixel = float2(float(m), float(n)) / float(AA) - float2(0.5, 0.5);
        float2 uv = (pxPos + 0.5 + subPixel) / dimensions.xy;

        float3 worldPos;
        {
            float2 screenPos = uv * 2.0 - 1.0;

            // gigi flaw? Need to set Viewer CameraSettings the ProjMtxTexture
//            screenPos.x *= aspectRatio;

            screenPos.y = -screenPos.y;
            float4 worldPosHom = mul(float4(screenPos, /*$(Variable:depthNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
            worldPos = worldPosHom.xyz / worldPosHom.w;
        }

        s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

        // you uncomment to composite with former pass
        context.dstColor = float4(computeSkyColor(context.ro, context.rd), 1);

        sceneWithShadows(context);

//        float time = /*$(Variable:iTime)*/;
        float time = 124.4f;
        float s = sin(time) * 2.0f;
        float c = cos(time) * 2.0f;
        float4x4 mat = lookAt(float3(s, 1, c), float3(0, 1, 0), float3(0, 1, 0));
        s2h_drawBasis(context, mat, 1.0f);

        tot += context.dstColor;
    }
    tot /= float(AA*AA);

    Output[DTid] = lerp(Output[DTid], float4(tot.rgb, 1), tot.a);
}
