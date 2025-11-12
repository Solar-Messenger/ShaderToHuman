//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

struct VSInput
{
	// within the instance (not the globalVertexId)
	uint vertexId : SV_VertexID;
	// to compute the globalVertexId
	uint instanceId : SV_InstanceID;
};

struct VSOutput // AKA PSInput
{
	// for xbox needs this to be last
	float4 position : SV_POSITION;
};

VSOutput main(VSInput input)
{
	VSOutput output = (VSOutput)0;

	uint id = input.vertexId % 6;

	float2 uv = float2(0, 0);
	if(id == 1) uv = float2(1, 0);
	if(id == 2 || id == 3) uv = float2(1, 1);
	if(id == 4) uv = float2(0, 1);

	// x:-1 / 1, y:-1 / 1
	float2 xy = uv * 2.0f - 1.0f;

	output.position = float4(xy, 0.5f, 1.0f);

	return output;
}