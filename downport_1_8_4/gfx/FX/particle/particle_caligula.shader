Includes = {
	"cw/particle2.fxh"
	"distance_fog.fxh"
	"coloroverlay.fxh"
	"fog_of_war.fxh"
	"ssao_struct.fxh"
	"harvest_condition.fxh"

	"particle/particle_caligula.fxh"

	"cw/debug_constants.fxh"
}

PixelShader =
{
	TextureSampler WavyNoiseParticle
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/wavy_noise.dds"
	}
	TextureSampler CommonNoiseParticle
	{
		Index = 2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/common_noise.dds"
	}
	TextureSampler RainMaskParticle
	{
		Index = 3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/rain_mask.dds"
	}
	TextureSampler HailMaskParticle
	{
		Index = 6
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/hail_mask.dds"
	}

	MainCode PixelShaderPollinatorSurge
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;
				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 ) * Input.Color;
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;

				// Settings
				float GlobalAlpha = lerp( 0.45, 1.0, _DayValue );

				float DistanceFade = 200.0;
				float SunAngleDistance = 150.0;

				float CameraHeightValue = RemapClamped( CameraPosition.y, 50.0, 150.0, 0.0, 1.0 );
				float CameraDistance = length( CameraPosition - Input.WorldSpacePos );
				DistanceFade = lerp( 200.0, 300.0, CameraHeightValue );
				DistanceFade *= smoothstep( 0.0, 1.0, RemapClamped( CameraDistance, 0.0, 100.0, 0.0, 1.0 ) );
				SunAngleDistance = lerp( 100.0, 250.0, CameraHeightValue );

				float RainUvTiling = 1.5;
				float RainSpeed = 0.05;

				float WavyNoiseTiling = 0.001;
				float WavyNoiseSpeed = 0.5;
				float NoisePosition = 1.0;
				float NoiseContrast = 0.95;

				float SunAnglePosition = 0.80;
				float SunAngleContrast = 0.1;

				float Distance = length( CameraPosition - Input.WorldSpacePos );
				Distance = RemapClamped( Distance, 0.0, DistanceFade, 1.0, 0.0 );

				float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
				float3 H = normalize( ToCam + ToSunDir );
				float NdotH = saturate( dot( float3( 0.0, 1.0, 0.0 ), H ) );
				float AngleMultiplier = NdotH;
				float AngleMultiplierIntense = saturate( LevelsScan( AngleMultiplier, 1.0, 0.1 ) );
				AngleMultiplier = saturate( AngleMultiplier );
				AngleMultiplier = LevelsScan( AngleMultiplier, SunAnglePosition, SunAngleContrast );
				AngleMultiplier = 1.0 - AngleMultiplier;

				float2 CommonNoiseUvPan = ( float2( 0.0, -0.1 ) ) * GlobalTime * 0.1 * 1.5;
				float2 CommonNoiseUv = ( Input.UV0 + CommonNoiseUvPan ) * 0.02;
				CommonNoiseUv += 5.0 * Input.Color.r;
				float CommonNoise = PdxTex2D( CommonNoiseParticle, CommonNoiseUv ).r;
				CommonNoise *= 0.2;

				float2 WavyNoiseUvPan = ( float2( 0.1, -80.0 )  ) * GlobalTime * 0.1 * WavyNoiseSpeed;
				float2 WavyNoiseUv = ( Input.UV0 + WavyNoiseUvPan ) * WavyNoiseTiling;
				WavyNoiseUv.x *= 100.0;
				WavyNoiseUv += 10.0 * Input.Color.r;
				WavyNoiseUv += CommonNoise;

				float WavyNoise = PdxTex2D( WavyNoiseParticle, WavyNoiseUv ).r;
				WavyNoise = LevelsScan( WavyNoise, NoisePosition, NoiseContrast );
				WavyNoise *= Color.a;
				WavyNoise *= 0.15;

				Input.UV0 += ProvinceCoords;

				// UV Coords
				float2 Coord1 = Input.UV0 * Input.Color.g;
				Coord1.x = Coord1.x * 1.0;

				float2 UvPan = float2( 0.0, -2.0 ) * GlobalTime * 0.3 * RainSpeed * Input.Color.r;
				float2 RainUv = ( Coord1 + UvPan ) * RainUvTiling;
				float RainNoise = PdxTex2D( RainMaskParticle, RainUv ).r;

				RainNoise *= Color.a;
				RainNoise = lerp( RainNoise * 0.5, RainNoise * 20.0, WavyNoise );

				float3 RainColor = lerp( float3( 0.871, 0.937, 1.000 ), float3( 1.000, 0.953, 0.779), _DayValue );
				Color = float4( Overlay( RainColor, RainNoise ), RainNoise );
				Color += float4( Overlay( RainColor, RainNoise ), RainNoise ) * AngleMultiplierIntense * _DayValue;
				Color += float4( Overlay( RainColor, WavyNoise ), WavyNoise );
				Color.a = lerp( Color.a, Color.a * 0.9, AngleMultiplier );
				Color.a = saturate( lerp( 0.0, Color.a, Distance ) );

				Color.a = saturate( Color.a * GlobalAlpha );

				#if defined( MAP_PARTICLE ) && !defined( GUI_SHADER )
					// Paralax offset to keep overlays at terrain level
					float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
					float ParalaxDist = ( 0.0 - Input.WorldSpacePos.y ) / ToCam.y;
					float3 ParallaxCoord = Input.WorldSpacePos + ToCam * ParalaxDist;
					ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

					float3 ColorOverlay;
					float PreLightingBlend;
					float PostLightingBlend;
					GameProvinceOverlayAndBlend( ParallaxCoord.xz, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
					Color.rgb = ApplyColorOverlay( Color.rgb, ColorOverlay, saturate( PreLightingBlend + PostLightingBlend ) );

					float3 PostEffectsColor = Color.rgb;
					PostEffectsColor = ApplyFogOfWar( PostEffectsColor, Input.WorldSpacePos );
					PostEffectsColor = GameApplyDistanceFog( PostEffectsColor, Input.WorldSpacePos );
					Color.rgb = lerp( Color.rgb, PostEffectsColor, 1.0 - _FlatmapLerp );
				#endif

				// Output
				Out.Color = Color;

				return Out;
			}
		]]
	}

	MainCode PixelShaderOptimalSunlight
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;
				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 );
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;

				// Settings
				float GlobalAlpha = lerp( 0.65, 1.0, _DayValue );

				float DistanceFade = 200.0;
				float SunAngleDistance = 150.0;

				float CameraHeightValue = RemapClamped( CameraPosition.y, 50.0, 150.0, 0.0, 1.0 );
				float CameraDistance = length( CameraPosition - Input.WorldSpacePos );
				DistanceFade = lerp( 200.0, 300.0, CameraHeightValue );
				DistanceFade *= smoothstep( 0.0, 1.0, RemapClamped( CameraDistance, 0.0, 100.0, 0.0, 1.0 ) );

				SunAngleDistance = lerp( 100.0, 250.0, CameraHeightValue );

				float RainUvTiling = 1.5;
				float RainSpeed = 0.05;

				float WavyNoiseTiling = 0.001;
				float WavyNoiseSpeed = 0.5;
				float NoisePosition = 1.0;
				float NoiseContrast = 0.95;

				float SunAnglePosition = 0.80;
				float SunAngleContrast = 0.1;

				float Distance = length( CameraPosition - Input.WorldSpacePos );
				Distance = RemapClamped( Distance, 0.0, DistanceFade, 1.0, 0.0 );

				float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
				float3 H = normalize( ToCam + ToSunDir );
				float NdotH = saturate( dot( float3( 0.0, 1.0, 0.0 ), H ) );
				float AngleMultiplier = NdotH;
				float AngleMultiplierIntense = saturate( LevelsScan( AngleMultiplier, 1.0, 0.1 ) );
				AngleMultiplier = saturate( AngleMultiplier );
				AngleMultiplier = LevelsScan( AngleMultiplier, SunAnglePosition, SunAngleContrast );
				AngleMultiplier = 1.0 - AngleMultiplier;

				float2 CommonNoiseUvPan = ( float2( 0.0, -0.1 ) ) * GlobalTime * 0.1 * 1.5;
				float2 CommonNoiseUv = ( Input.UV0 + CommonNoiseUvPan ) * 0.02;
				CommonNoiseUv += 5.0 * Input.Color.r;
				float CommonNoise = PdxTex2D( CommonNoiseParticle, CommonNoiseUv ).r;
				CommonNoise *= 0.05;

				float2 WavyNoiseUvPan = ( float2( 0.1, -80.0 )  ) * GlobalTime * 0.1 * WavyNoiseSpeed;
				float2 WavyNoiseUv = ( Input.UV0 + WavyNoiseUvPan ) * WavyNoiseTiling;
				WavyNoiseUv.x *= 100.0;
				WavyNoiseUv += 10.0 * Input.Color.r;
				WavyNoiseUv += CommonNoise;

				float WavyNoise = PdxTex2D( WavyNoiseParticle, WavyNoiseUv ).r;
				WavyNoise = LevelsScan( WavyNoise, NoisePosition, NoiseContrast );
				WavyNoise *= 1.2;

				float3 RainColor = lerp( float3( 0.566, 0.778, 1.000 ), float3( 1.000, 0.953, 0.679), _DayValue ); //
				Color.rgb = RainColor;
				Color.a *= WavyNoise;
				Color.a = lerp( Color.a, Color.a * 0.75, AngleMultiplier );
				Color.a = lerp( 0.0, Color.a, Distance );
				Color.a = saturate( Color.a * GlobalAlpha );

				#if defined( MAP_PARTICLE ) && !defined( GUI_SHADER )
					// Paralax offset to keep overlays at terrain level
					float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
					float ParalaxDist = ( 0.0 - Input.WorldSpacePos.y ) / ToCam.y;
					float3 ParallaxCoord = Input.WorldSpacePos + ToCam * ParalaxDist;
					ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

					float3 ColorOverlay;
					float PreLightingBlend;
					float PostLightingBlend;
					GameProvinceOverlayAndBlend( ParallaxCoord.xz, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
					Color.rgb = ApplyColorOverlay( Color.rgb, ColorOverlay, saturate( PreLightingBlend + PostLightingBlend ) );

					float3 PostEffectsColor = Color.rgb;
					PostEffectsColor = ApplyFogOfWar( PostEffectsColor, Input.WorldSpacePos );
					PostEffectsColor = GameApplyDistanceFog( PostEffectsColor, Input.WorldSpacePos );
					Color.rgb = lerp( Color.rgb, PostEffectsColor, 1.0 - _FlatmapLerp );
				#endif

				// Output
				Out.Color = Color;

				return Out;
			}
		]]
	}

	MainCode PixelShaderTorrentialRain
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;
				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 ) * Input.Color;
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;

				// HarvestCondition mask
				HarvestConditionData ConditionData;
				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				SampleHarvestConditionMask( MapCoords, ConditionData );

				// Settings
				float GlobalAlpha = lerp( 1.5, 5.0, ConditionData._TorrentialRains );
				float RainUvTiling = 1.0;
				float RainSpeed = Input.Color.r;

				float CameraHeightValue = RemapClamped( CameraPosition.y, 50.0, 400.0, 0.0, 1.0 );
				float Distance = lerp( 150.0, 500.0, CameraHeightValue );
				float CameraDistance = length( CameraPosition - Input.WorldSpacePos );
				float DistanceFade = RemapClamped( CameraDistance, 0.0, Distance, 1.0, 0.0 );
				DistanceFade *= smoothstep( 0.0, 1.0, RemapClamped( CameraDistance, 0.0, 50.0, 0.0, 1.0 ) );

				Input.UV0 += ProvinceCoords;

				// UV Coords
				float2 Coord1 = Input.UV0 * Input.Color.g;
				Coord1.x = Coord1.x * 3.0;

				float2 UvPan = float2( 0.0, -2.0 ) * GlobalTime * RainSpeed;
				float2 RainUv = ( Coord1 + UvPan ) * RainUvTiling;
				float RainNoise = PdxTex2D( RainMaskParticle, RainUv ).r;

				RainNoise *= Color.a;

				float3 RainColor = float3( 0.389, 0.467, 0.645 );
				Color = float4( RainColor, RainNoise );

				Color.a = saturate( lerp( 0.0, Color.a, DistanceFade ) );
				Color.a *= GlobalAlpha;

				#if defined( MAP_PARTICLE ) && !defined( GUI_SHADER )
					// Paralax offset to keep overlays at terrain level
					float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
					float ParalaxDist = ( 0.0 - Input.WorldSpacePos.y ) / ToCam.y;
					float3 ParallaxCoord = Input.WorldSpacePos + ToCam * ParalaxDist;
					ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

					float3 ColorOverlay;
					float PreLightingBlend;
					float PostLightingBlend;
					GameProvinceOverlayAndBlend( ParallaxCoord.xz, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
					Color.rgb = ApplyColorOverlay( Color.rgb, ColorOverlay, saturate( PreLightingBlend + PostLightingBlend ) );

					float3 PostEffectsColor = Color.rgb;
					PostEffectsColor = ApplyFogOfWar( PostEffectsColor, Input.WorldSpacePos );
					PostEffectsColor = GameApplyDistanceFog( PostEffectsColor, Input.WorldSpacePos );
					Color.rgb = lerp( Color.rgb, PostEffectsColor, 1.0 - _FlatmapLerp );
				#endif

				// Output
				Out.Color = Color;

				return Out;
			}
		]]
	}

	MainCode PixelShaderHailstorm
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;
				float4 Color = PdxTex2D( DiffuseMap, Input.UV0 ) * Input.Color;
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;

				// HarvestCondition mask
				HarvestConditionData ConditionData;
				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				SampleHarvestConditionMask( MapCoords, ConditionData );

				// Settings
				float GlobalAlpha = lerp( 0.1, 0.4, ConditionData._Hail );
				float RainUvTiling = 1.0;
				float RainSpeed = Input.Color.r * 0.5;

				float CameraHeightValue = RemapClamped( CameraPosition.y, 50.0, 400.0, 0.0, 1.0 );
				float Distance = lerp( 150.0, 450.0, CameraHeightValue );
				float CameraDistance = length( CameraPosition - Input.WorldSpacePos );
				float DistanceFade = RemapClamped( CameraDistance, 0.0, Distance, 1.0, 0.0 );
				DistanceFade *= smoothstep( 0.0, 1.0, RemapClamped( CameraDistance, 0.0, 50.0, 0.0, 1.0 ) );

				Input.UV0 += ProvinceCoords;

				// UV Coords
				float2 UvPan = float2( Input.Color.b * -0.005, -2.0 ) * GlobalTime * RainSpeed;
				float2 Coord1 = UvPan + Input.UV0 * RainUvTiling * Input.Color.g;

				float2 RainUv = Coord1 + UvPan;
				float RainNoise = PdxTex2D( HailMaskParticle, RainUv ).r;

				Color.a = LevelsScan( Color.a, 0.4, 0.5 );
				RainNoise *= Color.a;

				float3 RainColor = float3( 1.0, 1.0, 1.0 );
				Color = float4( RainColor, RainNoise );

				Color.a = saturate( lerp( 0.0, Color.a, DistanceFade ) );
				Color.a *= GlobalAlpha;

				#if defined( MAP_PARTICLE ) && !defined( GUI_SHADER )
					// Paralax offset to keep overlays at terrain level
					float3 ToCam = normalize( CameraPosition - Input.WorldSpacePos );
					float ParalaxDist = ( 0.0 - Input.WorldSpacePos.y ) / ToCam.y;
					float3 ParallaxCoord = Input.WorldSpacePos + ToCam * ParalaxDist;
					ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

					float3 ColorOverlay;
					float PreLightingBlend;
					float PostLightingBlend;
					GameProvinceOverlayAndBlend( ParallaxCoord.xz, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
					Color.rgb = ApplyColorOverlay( Color.rgb, ColorOverlay, saturate( PreLightingBlend + PostLightingBlend ) );

					float3 PostEffectsColor = Color.rgb;
					PostEffectsColor = ApplyFogOfWar( PostEffectsColor, Input.WorldSpacePos );
					PostEffectsColor = GameApplyDistanceFog( PostEffectsColor, Input.WorldSpacePos );
					Color.rgb = lerp( Color.rgb, PostEffectsColor, 1.0 - _FlatmapLerp );
				#endif

				// Output
				Out.Color = Color;

				return Out;
			}
		]]
	}
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}

RasterizerState RasterizerStateNoCulling
{
	CullMode = "none"
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE|ALPHA"
	BlendOpAlpha = "max"
}

Effect ParticlePollinatorSurge
{
	VertexShader = "VertexParticleCaligula"
	PixelShader = "PixelShaderPollinatorSurge"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleOptimalSunlight
{
	VertexShader = "VertexParticleCaligula"
	PixelShader = "PixelShaderOptimalSunlight"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleTorrentialRain
{
	VertexShader = "VertexParticleCaligula"
	PixelShader = "PixelShaderTorrentialRain"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}

Effect ParticleHailstorm
{
	VertexShader = "VertexParticleCaligula"
	PixelShader = "PixelShaderHailstorm"
	Defines = { "BILLBOARD" }
	RasterizerState = "RasterizerStateNoCulling"
}