//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 pxPos = DTid + 0.5f;

    {
        ContextGather ui;

		float panScale = pow(2, UIState[0].PanAndScale.z * 0.02f);
		pxPos += UIState[0].PanAndScale.xy;
		pxPos *= panScale;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 10));
        ui.s2h_State = UIState[0].s2h_State;
		
		s2h_printFloat(ui, UIState[0].PanAndScale.x);
		s2h_printLF(ui);
		s2h_printFloat(ui, UIState[0].PanAndScale.y);
		s2h_printLF(ui);
		s2h_printFloat(ui, UIState[0].PanAndScale.z);
		s2h_printLF(ui);

        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

		s2h_coordinateSystem(ui, float2(50, 110), float4(-30.0f, -30.0f, 250.0f, 250.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 0);
		ui.lineWidth = 1.0f;
		s2h_coordinateSystem(ui, float2(340, 120), float4(-10.0f, -100.0f, 150.0f, 10.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 3);
	
		
		// fade in pixel grid with strong magnification
		{
			const float4 gridColor = float4(1, 1, 1, 0.2f);
			float2 subPixelPos = frac(pxPos);
			float2 subPixelSideDist = min(subPixelPos, 1.0f - subPixelPos);
			// 0 at border
			float dist = min(subPixelSideDist.x, subPixelSideDist.y);
			// 0..1
			float alpha = saturate(1.0f - dist / panScale) * saturate(0.3f - panScale);
			ui.dstColor = lerp(ui.dstColor, float4(gridColor.rgb, 1), alpha * gridColor.a);
		}
		
		float4 background = float4(0.01f, 0.01f, 0.1f, 1.0f);
		float4 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
	
		Output[DTid] = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
        s2h_deinit(ui, UIState[0].s2h_State);
    }
}