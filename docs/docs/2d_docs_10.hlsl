




































//!KEEP #include "include/s2h.hlsl"



/*$(ShaderResources)*/




void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = S2S_MOUSE();



































































































    s2h_Triangle triA;
    triA.A = float2(50,1);
    triA.B = float2(150,100);
    triA.C = float2(250,1);
    s2h_drawTriangle(ui, triA, float4(0,0,1,0.5));
    s2h_Triangle triB;
    triB.A = float2(230,10);
    triB.B = float2(160,80);
    triB.C = float2(300,80);
    s2h_drawTriangle(ui, triB, float4(0,1,1,0.5));
    s2h_Triangle triC;
    triC.A = float2(240,30);
    triC.B = float2(280,70);
    triC.C = float2(320,30);
    s2h_drawTriangle(ui, triC, float4(1,1,1,0.5));

    float3 background = float3(0.7f, 0.4f, 0.4f);
    float3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = float4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}

