#include "../../include/s2h.hlsl"

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
	float4 ret = 0;
	for(uint i = 0; i < sampleCount; ++i)
	{
		float4 value = TextureIn.Load(pxPos, i);
		value.rgb = s2h_accurateSRGBToLinear(value.rgb);
//		value.rgb = s2h_accurateLinearToSRGB(value.rgb);
		ret += value;
	}
	ret /= sampleCount;
	ret.a = 1;
#endif

	ret.rgb = s2h_accurateLinearToSRGB(ret.rgb);

	TextureOut[pxPos] = ret;
}
