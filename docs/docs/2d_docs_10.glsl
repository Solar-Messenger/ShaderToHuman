







































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"










void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = iMouse;


































































































    s2h_Triangle triA;
    triA.A = vec2(50,1);
    triA.B = vec2(150,100);
    triA.C = vec2(250,1);
    s2h_drawTriangle(ui, triA, vec4(0,0,1,0.5));
    s2h_Triangle triB;
    triB.A = vec2(230,10);
    triB.B = vec2(160,80);
    triB.C = vec2(300,80);
    s2h_drawTriangle(ui, triB, vec4(0,1,1,0.5));
    s2h_Triangle triC;
    triC.A = vec2(240,30);
    triC.B = vec2(280,70);
    triC.C = vec2(320,30);
    s2h_drawTriangle(ui, triC, vec4(1,1,1,0.5));

    vec3 background = vec3(0.7f, 0.4f, 0.4f);
    vec3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = vec4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}











