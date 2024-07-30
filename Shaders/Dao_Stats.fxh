/*******************************************************
	ReShade Header: Dao_Stats
	https://github.com/Daodan317081/reshade-shaders
	License: BSD 3-Clause

	BSD 3-Clause License

	Copyright (c) 2018-2019, Alexander Federwisch
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this
	list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.

	* Neither the name of the copyright holder nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************/

#include "ReShade.fxh"

#ifndef STATS_MIPLEVEL
    #define STATS_MIPLEVEL 7.0
#endif

namespace Stats {
	texture2D shared_texStats { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels =  STATS_MIPLEVEL; };
	sampler2D shared_SamplerStats { Texture = shared_texStats; };
	float3 OriginalBackBuffer(float2 texcoord) { return tex2D(shared_SamplerStats, texcoord).rgb; }

	texture2D shared_texStatsAvgColor { Format = RGBA8; };
	sampler2D shared_SamplerStatsAvgColor { Texture = shared_texStatsAvgColor; };
	float3 AverageColor() { return tex2Dfetch(shared_SamplerStatsAvgColor, int2(0, 0), 0).rgb; }

	texture2D shared_texStatsAvgLuma { Format = R16F; };
	sampler2D shared_SamplerStatsAvgLuma { Texture = shared_texStatsAvgLuma; };
	float AverageLuma() { return tex2Dfetch(shared_SamplerStatsAvgLuma, int2(0, 0), 0).r; }

	texture2D shared_texStatsAvgColorTemp { Format = R16F; };
	sampler2D shared_SamplerStatsAvgColorTemp { Texture = shared_texStatsAvgColorTemp; };
	float AverageColorTemp() { return tex2Dfetch(shared_SamplerStatsAvgColorTemp, int2(0, 0), 0).r; }
}