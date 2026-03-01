//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#define PI 3.14159265f

/*$(ShaderResources)*/

void test_drawArrow(inout ContextGather ui, float2 pxStart, float2 pxEnd, float arrowHeadLength, float arrowHeadWidth)
{
	s2h_drawArrow(ui,
		pxStart, pxEnd,
		float4(0.0f, 0.0f, 0.0f, 1.0f),
		ui.lineWidth * arrowHeadLength, ui.lineWidth * arrowHeadWidth);

	float backup = ui.lineWidth;
	ui.lineWidth = 1.0f;
	s2h_drawCrosshair(ui, pxStart, 5.0f, float4(1.0f, 0.0f, 0.0f, 0.5f));
	ui.lineWidth = 1.0f;
	s2h_drawCrosshair(ui, pxEnd, 5.0f, float4(0.0f, 1.0f, 0.0f, 0.5f));
	ui.lineWidth = backup;
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    float4 red =   float4(1, 0, 0, 1);
    float4 green = float4(0, 1, 0, 1);
	float4 blue =  float4(0, 1, 0, 1);
    float4 white = float4(1, 1, 1, 1);

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 10));
        ui.s2h_State = UIState[0].s2h_State;

        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

		for (float r = 0; r < 8; ++r)
		{
			ui.lineWidth = r;
			
			test_drawArrow(ui,
				float2(20.0f, 50.0f + r * 20.0f),
				float2(60.0f, 50.0f + r * 20.0f),
				0.0f, 0.0f);

			test_drawArrow(ui,
				float2(100.0f + 20.0f, 50.0f + r * 20.0f),
				float2(100.0f + 60.0f, 50.0f + r * 20.0f),
				4.0f, 1.5f);

			test_drawArrow(ui,
				float2(200.0f + 20.0f, 50.0f + r * 20.0f),
				float2(200.0f + 60.0f, 50.0f + r * 20.0f),
				8.0f, 1.5f);

			test_drawArrow(ui,
				float2(300.0f + 20.0f, 50.0f + r * 20.0f),
				float2(300.0f + 60.0f, 50.0f + r * 20.0f),
				8.0f, 0.5f);

			test_drawArrow(ui,
				float2(400.0f + 20.0f, 50.0f + r * 20.0f),
				float2(400.0f + 160.0f, 50.0f + r * 20.0f),
				8.0f, 1.5f);
		}
		
		ui.lineWidth = 5.0f;
		uint count = 12;
		for (uint i = 0; i < count; ++i)
		{
			float w = i / float(count) * PI * 2.0f;
			float2 center = float2(700.0f, 50.0f + 3.5f * 20.0f);
			float2 sc = float2(sin(w), cos(w)) * 80.0f;
			test_drawArrow(ui,
				center + sc * 0.3f,
				center + sc,
				8.0f, 1.5f);
		}
		
		s2h_setCursor(ui, float2(20.0f, 20.0f));
		s2h_printTxt(ui, _0, _COMMA, _SPACE, _0);
		s2h_setCursor(ui, float2(100.0f + 20.0f, 20.0f));
		s2h_printTxt(ui, _4, _COMMA, _SPACE, _1, _PERIOD, _5);
		s2h_setCursor(ui, float2(200.0f + 20.0f, 20.0f));
		s2h_printTxt(ui, _8, _COMMA, _SPACE, _1, _PERIOD, _5);
		s2h_setCursor(ui, float2(300.0f + 20.0f, 20.0f));
		s2h_printTxt(ui, _8, _COMMA, _SPACE, _0, _PERIOD, _5);
		s2h_setCursor(ui, float2(450.0f + 20.0f, 20.0f));
		s2h_printTxt(ui, _8, _COMMA, _SPACE, _1, _PERIOD, _5);
		s2h_setCursor(ui, float2(650.0f + 20.0f, 20.0f));
		s2h_printTxt(ui, _8, _COMMA, _SPACE, _1, _PERIOD, _5);

		s2h_setCursor(ui, float2(0.0f, 0.0f));
        
		ui.lineWidth = 10.0f;

        float2 center = dimensions / 2.0f;
        float lineLength = length(ui.mouseInput.xy - center);
        float arrowHeadLength = 0.25f * lineLength;
        arrowHeadLength = max(arrowHeadLength, 40.f);
        float arrowHeadWidth = 0.5f * arrowHeadLength;
        arrowHeadWidth = max(arrowHeadWidth, 20.0f);
        s2h_drawArrow(ui, center, ui.mouseInput.xy, blue, arrowHeadLength, arrowHeadWidth);

        float2 lineDirOpposite = normalize(center - ui.mouseInput.xy); 
        float2 lineEndOpposite = center + lineDirOpposite * lineLength;
        s2h_drawArrow(ui, center, lineEndOpposite, red, arrowHeadLength, arrowHeadWidth);

        float4 background = float4(0.5f, 0.5f, 0.5f, 1.0f);
        float4 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;

        Output[pxPos] = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
        s2h_deinit(ui, UIState[0].s2h_State);
    }
}