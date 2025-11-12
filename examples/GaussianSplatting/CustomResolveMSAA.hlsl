//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "SplatCommon.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint3 DTid : SV_DispatchThreadID)
{
	uint2 pxPos = DTid.xy;

	// hard coded sampleCount MSAA
	const uint sampleCount = 8;

#if 0
	uint sampleId = (pxPos.x%2) + 2 * (pxPos.y%2);
	float4 ret = TextureIn.Load(pxPos / uint2(2,2), sampleId);
#else
	float4 ret = float4(0, 0, 0, 0.0001f);
	for(uint i = 0; i < sampleCount; ++i)
	{
		float4 value = TextureIn.Load(pxPos, i);
		value.a /= FIXUP_MUL;// *2 as we use alpha=0.5 as base

#if WEIGHT_EXPERIMENT == 0
	value.a = 1;
#endif

//		value.a=0.5f;
		value.rgb = s2h_accurateSRGBToLinear(value.rgb);

		
		ret += float4(value.rgb, 1) * value.a;
	}
//	ret /= sampleCount;
	ret.rgb /= ret.a;
	ret.a = 1;
#endif

	ret.rgb = s2h_accurateLinearToSRGB(ret.rgb);

	// uncomment to visualize alpha
//	ret.rgb = TextureIn.Load(pxPos, 0).a;

	TextureOut[pxPos] = ret;
}
