/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

uint getByte(uint pos)
{
	uint dword = PlyFile[pos / 4];

	uint byte = pos % 4;

	return (dword >> (byte * 8)) & 0xff;
}

// like C++ code "*p"
uint starP(uint p)
{
	return getByte(p);
}

// like C++ code
void parseWhiteSpaceNoLF(inout uint p)
{
	for (;; ++p)
	{
		uint c = starP(p);

		if (c == 0)
		{
			break;
		}

		if (!(c == ' ' || c == '\t'))
		{
			break;
		}
	}
}

// like C++ code
bool parseStartsWith(inout uint p, uint a, uint b = (uint)-1, uint c = (uint)-1, uint d = (uint)-1)
{
	uint backup = p;

	if(starP(p) != a) return false;
	p++;

	if(b == (uint)-1) return true;
	if(starP(p) != b) { p = backup; return false; }
	p++;

	if(c == (uint)-1) return true;
	if(starP(p) != c) { p = backup; return false; }
	p++;

	if(d == (uint)-1) return true;
	if(starP(p) != d) { p = backup; return false; }
	p++;

	return true;
}


// like C++ code
bool parseToEndOfLine(inout uint p)
{
	while (starP(p))
	{
		if (starP(p) == 13) // CR
		{
			++p;

			if (starP(p) == 10) // CR+LF
				++p;

			return true;
		}
		if (starP(p) == 10) // LF
		{
			++p;
			return true;
		}
		++p;
	}

	return false;
}


bool parseInt64(inout uint p, out int64_t outValue)
{
	const uint backup = p;
	bool bNegate	   = false;

	if (starP(p) == '-')
	{
		bNegate = true;
		++p;
	}

	if (starP(p) < '0' || starP(p) > '9')
	{
		p = backup;
		return false;
	}

	outValue = 0;

	while (starP(p) >= '0' && starP(p) <= '9')
	{
		outValue = outValue * 10 + (starP(p) - '0');

		++p;
	}

	if (bNegate)
	{
		outValue = -outValue;
	}

	return true;
}


[numthreads(1, 1, 1)]
void main(uint2 DTid : SV_DispatchThreadID)
{
	PlyHeader[0].HeaderSize = (uint)-1;
	PlyHeader[0].FormatId = (uint)-1;

	uint stride = 0;

	bool valid = 
		getByte(0) == 'p' &&
		getByte(1) == 'l' &&
		getByte(2) == 'y' &&
		getByte(3) == '\n';

	if(!valid)
		return;

	uint p = 0;
	for(;;)
	{
		if(parseStartsWith(p, 'e', 'l', 'e', 'm'))
		if(parseStartsWith(p, 'e', 'n', 't', ' '))
		if(parseStartsWith(p, 'v', 'e', 'r', 't'))
		if(parseStartsWith(p, 'e', 'x', ' '))
		{
			if(!parseInt64(p, PlyHeader[0].VertexCount))
				valid = false;

			continue;
		}
		if(parseStartsWith(p, 'p', 'r', 'o', 'p'))
		if(parseStartsWith(p, 'e', 'r', 't', 'y'))
		if(parseStartsWith(p, ' '))
		{
			// todo, we assume all float properties
			++stride;
		}

		if(parseStartsWith(p, 'e', 'n', 'd', '_'))
		if(parseStartsWith(p, 'h', 'e', 'a', 'd'))
		if(parseStartsWith(p, 'e', 'r', '\n'))
			break;

		parseToEndOfLine(p);
	}

	if(!valid)
		return;

	// in uints
	PlyHeader[0].HeaderSize = p / 4;	// 382 seems right
	// in uints
	PlyHeader[0].Stride = stride;	// 62 seems righ
	// todo
	PlyHeader[0].FormatId = 0;
}
