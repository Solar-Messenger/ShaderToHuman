//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

void ScaleAroundCenter(inout float2 pxPan, float2 pxCenter, float oldScale, float newScale)
{
	float2 localPos = (pxPan + pxCenter) * oldScale;

	pxPan.xy -= localPos / oldScale;
	pxPan.xy += localPos / newScale;
}

[numthreads(1, 1, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

	float2 pxPosFloat = pxPos + 0.5f;
	int4 mouseInput = int4( /*$(Variable:MouseState)*/);
	int4 mouseInputLastFrame = int4( /*$(Variable:MouseStateLastFrame)*/);

	// default on startup or after recompile
	if (all(UIState[0].PanAndScale == 0.0f))
	{
		UIState[0].PanAndScale.xyz = float3(0, 0, 0);
//		UIState[0].PanAndScale.xyz = float3(-500, -300, -200);
	}

	{
		float3 panAndScale = UIState[0].PanAndScale.xyz;

		float oldPanScale = pow(2, panAndScale.z * 0.02f);

		// update UI, once per frame

		if (mouseInputLastFrame.z == 1 && mouseInput.z == 1)	// LMB drag
		{
			panAndScale.xy -= (mouseInput.xy - mouseInputLastFrame.xy);
		}
		if (mouseInputLastFrame.w && mouseInput.w)	// RMB drag
		{
			panAndScale.z -= (mouseInput.y - mouseInputLastFrame.y);
			float newPanScale = pow(2, panAndScale.z * 0.02f);

//			ScaleAroundCenter(panAndScale.xy, mouseInput.xy, oldPanScale, newPanScale);
//			ScaleAroundCenter(panAndScale.xy, /*$(Variable:iMouse)*/.xy, oldPanScale, newPanScale);
			ScaleAroundCenter(panAndScale.xy, UIState[0].MouseDragStart.zw, oldPanScale, newPanScale);
		}

		UIState[0].PanAndScale.xyz = panAndScale;

		if (mouseInputLastFrame.z == 0 && mouseInput.z == 1)	// LMB drag start
			UIState[0].MouseDragStart.xy = mouseInput.xy;
		if (mouseInputLastFrame.w == 0 && mouseInput.w == 1)	// RMB drag start
			UIState[0].MouseDragStart.zw = mouseInput.xy;
	}
}