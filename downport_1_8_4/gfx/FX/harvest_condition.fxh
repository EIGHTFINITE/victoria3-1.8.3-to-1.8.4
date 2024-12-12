Includes = {
	"cw/camera.fxh"
	"jomini/jomini_province_overlays.fxh"
	"coloroverlay_powerbloc.fxh"
	"sharedconstants.fxh"
	"dynamic_masks.fxh"
	"utility_game.fxh"

	"harvest_condition_variables.fxh"
}

struct HarvestConditionData
{
	float _Drought;
	float _Flood;
	float _Frost;
	float _Wildfire;
	float _TorrentialRains;
	float _Hail;
	float _ExtremeWinds;
	float _LocustSwarm;
	float _Heatwave;
	float _DiseaseOutbreak;
};

BufferTexture HarvestConditionProvinceBuffer
{
	Ref = HarvestConditionProvinceMiscData
	type = float4
}

Code
[[
	float4 SampleHarvestCondition( float2 MapCoords )
	{
		float2 ColorIndex = PdxTex2DLod0( ProvinceColorIndirectionTexture, MapCoords ).rg;
		int Index = ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
		return PdxReadBuffer4( HarvestConditionProvinceBuffer, Index );
	}

	void SampleHarvestConditionMask( float2 MapCoords, inout HarvestConditionData ConditionData )
	{
		// HarvestCondition mask
		float2 Pixel = MapCoords * IndirectionMapSize + 0.5;
		float2 FracCoord = frac( Pixel );
		Pixel = floor( Pixel ) / IndirectionMapSize - InvIndirectionMapSize / 2.0;
		float4 C11 = SampleHarvestCondition( Pixel );
		float4 C21 = SampleHarvestCondition( Pixel + float2( InvIndirectionMapSize.x, 0.0 ) * ( 1.0 ) );
		float4 C12 = SampleHarvestCondition( Pixel + float2( 0.0, InvIndirectionMapSize.y ) * ( 1.0 ) );
		float4 C22 = SampleHarvestCondition( Pixel + InvIndirectionMapSize * ( 1.0  ) );
		float x1 = lerp( C11.g, C21.g, FracCoord.x );
		float x2 = lerp( C12.g, C22.g, FracCoord.x );

		// Opacity
		float Impact = lerp( x1, x2, FracCoord.y );
		Impact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, OpacityLowImpactValue, 0.0, 0.6 );
		Impact += RemapClamped( lerp( x1, x2, FracCoord.y ), OpacityLowImpactValue, OpacityHighImpactValue, 0.0, 0.4 );

		// Harvest condition filtering
		float Dro1 = lerp( C11.r == DROUGHT_INDEX, C21.r == DROUGHT_INDEX, FracCoord.x );
		float Dro2 = lerp( C12.r == DROUGHT_INDEX, C22.r == DROUGHT_INDEX, FracCoord.x );
		ConditionData._Drought = lerp( Dro1, Dro2, FracCoord.y ) * Impact;

		float Flo1 = lerp( C11.r == FLOOD_INDEX, C21.r == FLOOD_INDEX, FracCoord.x );
		float Flo2 = lerp( C12.r == FLOOD_INDEX, C22.r == FLOOD_INDEX, FracCoord.x );
		ConditionData._Flood = lerp( Flo1, Flo2, FracCoord.y ) * Impact;

		float FrostImapact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, FrostLowImpactValue, 0.0, 0.5 );
		FrostImapact += RemapClamped( lerp( x1, x2, FracCoord.y ), FrostLowImpactValue, FrostHighImpactValue, 0.0, 0.5 );
		float Fro1 = lerp( C11.r == FROST_INDEX, C21.r == FROST_INDEX, FracCoord.x );
		float Fro2 = lerp( C12.r == FROST_INDEX, C22.r == FROST_INDEX, FracCoord.x );
		ConditionData._Frost = lerp( Fro1, Fro2, FracCoord.y ) * FrostImapact;

		float WildfireImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, WildfireLowImpactValue, 0.0, 0.5 );
		WildfireImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), WildfireLowImpactValue, WildfireHighImpactValue, 0.0, 0.5 );
		float Wil1 = lerp( C11.r == WILDFIRE_INDEX, C21.r == WILDFIRE_INDEX, FracCoord.x );
		float Wil2 = lerp( C12.r == WILDFIRE_INDEX, C22.r == WILDFIRE_INDEX, FracCoord.x );
		ConditionData._Wildfire = lerp( Wil1, Wil2, FracCoord.y ) * WildfireImpact;

		float TorrentialRainsImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, TorrFloodLowImpactValue, 0.0, 0.5 );
		TorrentialRainsImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), TorrFloodLowImpactValue, TorrFloodHighImpactValue, 0.0, 0.5 );
		float Tor1 = lerp( C11.r == TORRENTIAL_RAINS_INDEX, C21.r == TORRENTIAL_RAINS_INDEX, FracCoord.x );
		float Tor2 = lerp( C12.r == TORRENTIAL_RAINS_INDEX, C22.r == TORRENTIAL_RAINS_INDEX, FracCoord.x );
		ConditionData._TorrentialRains = lerp( Tor1, Tor2, FracCoord.y ) * TorrentialRainsImpact;

		float HailImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, HailLowImpactValue, 0.0, 0.5 );
		HailImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), HailLowImpactValue, HailHighImpactValue, 0.0, 0.5 );
		float Hail1 = lerp( C11.r == HAIL_INDEX, C21.r == HAIL_INDEX, FracCoord.x );
		float Hail2 = lerp( C12.r == HAIL_INDEX, C22.r == HAIL_INDEX, FracCoord.x );
		ConditionData._Hail = lerp( Hail1, Hail2, FracCoord.y ) * HailImpact;

		float ExtremeWindsImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, ExtremeWindsLowImpactValue, 0.0, 0.5 );
		ExtremeWindsImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), ExtremeWindsLowImpactValue, ExtremeWindsHighImpactValue, 0.0, 0.5 );
		float Extw1 = lerp( C11.r == EXTREME_WINDS_INDEX, C21.r == EXTREME_WINDS_INDEX, FracCoord.x );
		float Extw2 = lerp( C12.r == EXTREME_WINDS_INDEX, C22.r == EXTREME_WINDS_INDEX, FracCoord.x );
		ConditionData._ExtremeWinds = lerp( Extw1, Extw2, FracCoord.y ) * ExtremeWindsImpact;

		float LocustSwarmImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, LocustSwarmLowImpactValue, 0.0, 0.5 );
		LocustSwarmImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), LocustSwarmLowImpactValue, LocustSwarmHighImpactValue, 0.0, 0.5 );
		float Locu1 = lerp( C11.r == LOCUST_SWARM_INDEX, C21.r == LOCUST_SWARM_INDEX, FracCoord.x );
		float Locu2 = lerp( C12.r == LOCUST_SWARM_INDEX, C22.r == LOCUST_SWARM_INDEX, FracCoord.x );
		ConditionData._LocustSwarm = lerp( Locu1, Locu2, FracCoord.y ) * LocustSwarmImpact;

		float HeatwaveImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, HeatwaveLowImpactValue, 0.0, 0.6 );
		HeatwaveImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), HeatwaveLowImpactValue, HeatwaveHighImpactValue, 0.0, 0.4 );
		float Heat1 = lerp( C11.r == HEATWAVE_INDEX, C21.r == HEATWAVE_INDEX, FracCoord.x );
		float Heat2 = lerp( C12.r == HEATWAVE_INDEX, C22.r == HEATWAVE_INDEX, FracCoord.x );
		ConditionData._Heatwave = lerp( Heat1, Heat2, FracCoord.y ) * HeatwaveImpact;

		float DiseaseOutbreakImpact = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.0, DiseaseOutbreakLowImpactValue, 0.0, 0.6 );
		DiseaseOutbreakImpact += RemapClamped( lerp( x1, x2, FracCoord.y ), DiseaseOutbreakLowImpactValue, DiseaseOutbreakHighImpactValue, 0.0, 0.4 );
		float Dis1 = lerp( C11.r == DISEASE_OUTBREAK_INDEX, C21.r == DISEASE_OUTBREAK_INDEX, FracCoord.x );
		float Dis2 = lerp( C12.r == DISEASE_OUTBREAK_INDEX, C22.r == DISEASE_OUTBREAK_INDEX, FracCoord.x );
		ConditionData._DiseaseOutbreak = lerp( Dis1, Dis2, FracCoord.y ) * DiseaseOutbreakImpact;
	}
]]

VertexShader =
{
	TextureSampler ProvinceColorIndirectionTexture
	{
		Ref = JominiProvinceColorIndirection
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Wrap"
		SampleModeV = "Border"
		Border_Color = { 0 0 0 0 }
	}
}

PixelShader =
{
	TextureSampler WavyNoise
	{
		Index = 14
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/wavy_noise.dds"
	}
	TextureSampler CommonNoise
	{
		Index = 15
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/common_noise.dds"
	}
	TextureSampler HailMask
	{
		Index = 17
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/hail_ground_mask.dds"
	}

	Code
	[[
		void DebugCondition( inout float3 Diffuse, HarvestConditionData ConditionData )
		{
			#if defined( DEBUG_INCIDENT_MASK_ALL )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 1.0, 0.0, 0.0 ), ConditionOpacity );
			#endif

			#if defined( DEBUG_INCIDENT_MASK_Drought )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 1.0, 0.0, 0.0 ), ConditionData._Drought );
			#endif
		}





		/////////////////////////////////////////////
		//////// Harvest condition functions ////////
		/////////////////////////////////////////////
		void ApplyDryTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float HarvestConditionValue, float3 OverlayColor )
		{
			float LowerValueAdjust = smoothstep( 0.0, 0.1, HarvestConditionValue );

			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 DroughtDiffuse = Diffuse;
			float3 DroughtNormal = Normal;
			float4 DroughtProperties = Properties;

			// Angle Adjustment
			float3 TerrainNormal = CalculateNormal( WorldSpacePosXz );
			float SlopeMultiplier = dot( TerrainNormal, float3( 0.0, 1.0, 0.0 ) );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DroughtSlopeMin, 1.0, 0.0, 1.0 );
			HarvestConditionValue *= SlopeMultiplier;

			// Drought Mask
			float ColorPositionValue = lerp( DroughtColorMaskPositionFrom, DroughtColorMaskPositionTo, HarvestConditionValue );
			float ColorContrastValue = lerp( DroughtColorMaskContrastFrom, DroughtColorMaskContrastTo, HarvestConditionValue );
			float DryPositionValue = lerp( DroughtDryMaskPositionFrom, DroughtDryMaskPositionTo, HarvestConditionValue );
			float DryContrastValue = lerp( DroughtDryMaskContrastFrom, DroughtDryMaskContrastTo, HarvestConditionValue );
			float CracksPositionValue = lerp( DroughtCracksAreaMaskPositionFrom, DroughtCracksAreaMaskPositionTo, HarvestConditionValue );
			float CracksContrastValue = lerp( DroughtCracksAreaMaskContrastFrom, DroughtCracksAreaMaskContrastTo, HarvestConditionValue );

			// Dry patches
			float4 DryTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, DroughtDryTexureIndex ) );
			DryTexDiffuse.a = 1.0 - DryTexDiffuse;
			float4 DryTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, DroughtDryTexureIndex ) );
			float3 DryTexNormal = UnpackRRxGNormal( DryTexNormalRRxG ).xyz;
			float4 DryTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, DroughtDryTexureIndex ) );

			float2 DryMaskUv = float2( MapCoords.x * 2.0, MapCoords.y ) * DroughtDryMaskUvTiling;
			float DryNoiseMask = PdxTex2D( WavyNoise, DryMaskUv ).r;

			float DryMask = LevelsScan( DryNoiseMask, DryPositionValue, DryContrastValue );
			float2 DryBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, DryTexDiffuse.a ), float2( 1.0 - DryMask, DryMask ), _DetailBlendRange );

			// Base terrain color change
			float ColorNoise = LevelsScan( DryNoiseMask, ColorPositionValue, ColorContrastValue );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, AdjustHsv( DroughtDiffuse.rgb, 0.0, DroughtPreSaturation, DroughtPreValue ), ColorNoise );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, Overlay( DroughtDiffuse.rgb, OverlayColor ), ColorNoise );

			DryTexDiffuse.rgb = Overlay( DryTexDiffuse.rgb, DroughtDryOverlayColor );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, DryTexDiffuse.rgb, DryBlendFactors.y );
			DroughtNormal = lerp( DroughtNormal, DryTexNormal, DryBlendFactors.y );
			DroughtProperties = lerp( DroughtProperties, DryTexProperties, DryBlendFactors.y );

			// Cracks Area Mask
			float2 CrackedMaskUv = float2( MapCoords.x * 2.0, MapCoords.y ) * DroughtCracksAreaMaskTiling;
			float CrackedMask = PdxTex2D( WavyNoise, CrackedMaskUv ).r;
			CrackedMask = LevelsScan( CrackedMask, CracksPositionValue, CracksContrastValue );

			// Cracked areas
			float2 CrackedTextureUv = CalcDetailUV( WorldSpacePosXz ) * DroughtCrackedTextureUvTiling;
			float4 CrackedTexDiffuse = PdxTex2D( DetailTextures, float3( CrackedTextureUv, DroughtCracksTexureIndex ) );
			CrackedTexDiffuse.rgb = Overlay( CrackedTexDiffuse.rgb, DroughtCracksOverlayColor );
			CrackedTexDiffuse.a = 1.0 - CrackedTexDiffuse.a;
			float4 CrackedTexNormalRRxG = PdxTex2D( NormalTextures, float3( CrackedTextureUv, DroughtCracksTexureIndex ) );
			float3 CrackedTexNormal = UnpackRRxGNormal( CrackedTexNormalRRxG ).xyz;
			float4 CrackedTexProperties = PdxTex2D( MaterialTextures, float3( CrackedTextureUv, DroughtCracksTexureIndex ) );
			float2 BlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, CrackedTexDiffuse.a), float2( 1.0 - DroughtCracksTextureBlendWeight, DroughtCracksTextureBlendWeight ), _DetailBlendRange * DroughtCracksTextureBlendContrast );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, CrackedTexDiffuse.rgb, BlendFactors.y * CrackedMask );
			DroughtNormal = lerp( DroughtNormal, CrackedTexNormal, BlendFactors.y * CrackedMask );
			DroughtProperties = lerp( DroughtProperties, CrackedTexProperties, BlendFactors.y * CrackedMask );

			// Color adjustment
			DroughtDiffuse.rgb = AdjustHsv( DroughtDiffuse.rgb, 0.0, DroughtFinalSaturation, 1.0 );

			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse.rgb, LowerValueAdjust );
			Normal = lerp( Normal, DroughtNormal, LowerValueAdjust );
			Properties = lerp( Properties, DroughtProperties, LowerValueAdjust );
		}

		//// Draught ////
		void ApplyDroughtTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			ApplyDryTerrain( Diffuse, Normal, Properties, WorldSpacePosXz, ConditionData._Drought, DroughtOverlayColor );
		}

		//// Disease Outbreak ////
		void ApplyDiseaseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			ApplyDryTerrain( Diffuse, Normal, Properties, WorldSpacePosXz, ConditionData._DiseaseOutbreak, DiseaseOverlayColor );
		}

		//// Heatwave ////
		void ApplyHeatwaveTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			ApplyDryTerrain( Diffuse, Normal, Properties, WorldSpacePosXz, ConditionData._Heatwave, HeatwaveOverlayColor );
		}


		//// Flooding ////
		void ApplyFloodingDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData, inout float WaterNormalLerp )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz ) * FloodDetailTiling;

			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Flood );
			float AdjustedPositionValue = lerp(	FloodNoisePositionFrom, FloodNoisePositionTo, ConditionData._Flood );
			float AdjustedContrastValue = lerp( FloodNoiseContrastFrom, FloodNoiseContrastTo, ConditionData._Flood );

			// Water adjustments
			float3 TerrainNormal = CalculateNormal( WorldSpacePosXz );
			float SlopeMultiplier = dot( TerrainNormal, float3( 0.0, 1.0, 0.0 ) );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, FloodSlopeMin, 1.0, 0.0, 1.0 );

			float4 FloodTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, FloodTextureIndex ) );

			float2 FloodNoiseUv = TextureUv * FloodNoiseTiling;
			float FloodNoise = PdxTex2D( WavyNoise, FloodNoiseUv ).r;
			FloodNoise = LevelsScan( FloodNoise, AdjustedPositionValue, AdjustedContrastValue ) * SlopeMultiplier;
			float2 FloodBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, FloodTexDiffuse.a ), float2( 1.0 - FloodNoise, FloodNoise ), _DetailBlendRange * 2.0 );

			// Watercolor
			float FloodNoiseFill = PdxTex2D( WavyNoise, FloodNoiseUv ).r;
			FloodNoiseFill = LevelsScan( FloodNoiseFill, AdjustedPositionValue, AdjustedContrastValue );
			float4 FloodWaterColor = lerp( float4( FloodWaterInnerColor, 1.0 ), float4( FloodWaterEdgeColor, 1.0 ), FloodBlendFactors.y * FloodNoiseFill );

			// Apply Water Color
			float4 FloodDiffuse = lerp( Diffuse, FloodWaterColor, FloodBlendFactors.y * FloodWaterOpacity );
			float3 FloodNormal = lerp( Normal, FloodNormalDirection, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			float4 FloodProperties = lerp( Properties, FloodPropertiesSettings, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			WaterNormalLerp = FloodBlendFactors.y;
			WaterNormalLerp = smoothstep( 0.8, 1.0, WaterNormalLerp );

			// Apply Flood
			FloodDiffuse.rgb = lerp( FloodDiffuse.rgb, FloodDiffuse.rgb * FloodDiffuseWetMultiplier, ConditionData._Flood );
			FloodProperties.a = lerp( FloodProperties.a, FloodProperties.a * FloodPropertiesWetMultiplier, ConditionData._Flood );

			Diffuse = lerp( Diffuse, FloodDiffuse, LowerValueAdjust );
			Normal = lerp( Normal, FloodNormal, LowerValueAdjust );
			Properties = lerp( Properties, FloodProperties, LowerValueAdjust );
		}





		//// Frost ////
		void ApplyFrostDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float2 FrostDetailUV = CalcDetailUV( WorldSpacePosXz ) * FrostTextureTiling;

			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Frost );
			float Frost = RemapClamped( ConditionData._Frost, 0.0, 1.0, 0.2, 0.3 ) * LowerValueAdjust;

			float4 FrostTexDiffuse = PdxTex2D( DetailTextures, float3( FrostDetailUV, 21 ) );
			FrostTexDiffuse.rgb = Overlay( FrostTexDiffuse.rgb, FrostOverlayColor );
			float4 FrostTexNormalRRxG = PdxTex2D( NormalTextures, float3( FrostDetailUV, 21 ) );
			float3 FrostTexNormal = UnpackRRxGNormal( FrostTexNormalRRxG ).xyz;
			float4 FrostTexProperties = PdxTex2D( MaterialTextures, float3( FrostDetailUV, 21 ) );

			float FrostBlendMask = lerp( 0.0, Diffuse.a, 1.0 - FrostTextureWeight );
			FrostTexDiffuse.a = lerp( 1.0, FrostTexDiffuse.a, FrostTextureWeight );
			float2 FrostBlendFactors = CalcHeightBlendFactors( float2( FrostBlendMask, FrostTexDiffuse.a ), float2( 1.0 - Frost, Frost ), _DetailBlendRange );

			// Apply
			Diffuse = lerp( Diffuse, FrostTexDiffuse, FrostBlendFactors.y );
			Normal = lerp( Normal, FrostTexNormal, FrostBlendFactors.y );
			Properties = lerp( Properties, FrostTexProperties, FrostBlendFactors.y );
		}





		//// Wildfire ////
		void ApplyWildfireDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );
			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Wildfire );

			float4 WildfireDiffuse = Diffuse;
			float3 WildfireNormal = Normal;
			float4 WildfireProperties = Properties;

			// Color adjustment
			float3 WhiteBurntGroundDiffuse = AdjustHsv( Diffuse.rgb, 0.0, 0.0, 0.8 );
			float3 CharredDiffuse = AdjustHsv( Diffuse.rgb, 0.0, 0.2, 0.4 );

			// Base Masks
			float BurnValue = 1.0 - ConditionData._Wildfire * WildfireBurntMaskMultiplier;
			float BaseBurnMask = PdxTex2D( CommonNoise, TextureUv * WildfireBurntMaskUvTiling ).r;
			float BurntMask = LevelsScan( BaseBurnMask, BurnValue, WildfireBurntMaskContrast );

			// White
			float WhiteBurntGroundMask = PdxTex2D( CommonNoise, TextureUv * 18 ).r;
			WhiteBurntGroundMask = LevelsScan( WhiteBurntGroundMask, 0.69, 1.6 );
			float WhiteMaskBlendFactor = CalcHeightBlendFactors( float2( Diffuse.a, WhiteBurntGroundMask ), float2( 1.0 - WhiteBurntGroundMask, WhiteBurntGroundMask ), _DetailBlendRange * 2.5 ).y;

			// Wildfire diffuse
			WildfireDiffuse.rgb = lerp( WildfireDiffuse.rgb, CharredDiffuse, BurntMask );
			WildfireDiffuse.rgb = lerp( WildfireDiffuse.rgb, WhiteBurntGroundDiffuse, WhiteMaskBlendFactor );

			// Apply
			Diffuse = lerp( Diffuse, WildfireDiffuse, BurntMask );
			Normal = lerp( Normal, WildfireNormal, BurntMask );
			Properties = lerp( Properties, WildfireProperties, BurntMask );
		}

		void ApplyWildfireTerrainPostLight( inout float3 Color, float MaterialHeight, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Wildfire );

			// BaseMasks
			float BurnValue = 1.0 - ConditionData._Wildfire * WildfireBurntMaskMultiplier;
			float BaseBurnMask = PdxTex2D( CommonNoise, TextureUv * WildfireBurntMaskUvTiling ).r;
			float BurntMask = LevelsScan( BaseBurnMask, BurnValue, WildfireBurntMaskContrast );

			// Smoke testing
			float AdjustedTime = GlobalTime * 0.001;
			float2 DisplaceUvAnim = float2( 0.2, 1.0 ) * AdjustedTime * 15;
			float2 SmokeUvAnim = float2( -1.0, 0.1 ) * AdjustedTime * 5;
			float2 SmokeUvAnim2 = float2( -1.0, 0.3 ) * AdjustedTime * 15;

			float2 DisplaceNoiseUv = TextureUv * 30 + DisplaceUvAnim;
			float DisplaceNoise = PdxTex2D( WavyNoise, DisplaceNoiseUv ).r;
			DisplaceNoise *= 0.045;

			float2 SmokeNoiseUv = TextureUv * 60 + SmokeUvAnim;
			SmokeNoiseUv += DisplaceNoise;
			float SmokeNoise = PdxTex2D( CommonNoise, SmokeNoiseUv ).r;
			SmokeNoise = LevelsScan( SmokeNoise, 0.15, 1.0 );

			float2 SmokeNoiseUv2 = TextureUv * 80 + SmokeUvAnim2;
			SmokeNoiseUv2 += DisplaceNoise;
			float SmokeNoise2 = PdxTex2D( CommonNoise, SmokeNoiseUv2 ).r;
			SmokeNoise2 = LevelsScan( SmokeNoise2, 0.15, 1.0 );

			SmokeNoise = SmokeNoise * SmokeNoise2;

			// Effect Properties
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );
			float FireUVDistortionStrength = 1.0f;
			float2 PanSpeedA = float2( 0.005, 0.001 ) * 1.5;
			float2 PanSpeedB = float2( 0.010, 0.005 ) * 1.5;
			float2 UVPan02 = float2( -frac( GlobalTime * PanSpeedA.x ), frac( GlobalTime * PanSpeedA.y ) );
			float2 UVPan01 = float2( frac( GlobalTime * PanSpeedB.x ),  frac( GlobalTime * PanSpeedB.y ) );
			float2 UV02 = ( DetailUV + 0.5 ) * 0.1;
			float2 UV01 = DetailUV * 0.2;
			UV02 += UVPan02;
			float Noise02 = PdxTex2D( CommonNoise, UV02 ).r;
			UV01 += UVPan01;
			UV01 += Noise02 * FireUVDistortionStrength;
			float FlameColorMask = PdxTex2D( CommonNoise, UV01 ).r;

			float FlameMaskInner = LevelsScan( BaseBurnMask, BurnValue + WildfireFireInnerMaskSize, WildfireBurntMaskContrast );
			float FlameMask = BurntMask - FlameMaskInner;
			FlameColorMask = LevelsScan( FlameColorMask * FlameMask, 0.25, 2.2 );
			float2 FireBlendFactors = CalcHeightBlendFactors( float2( 1.0 - MaterialHeight, FlameColorMask ), float2( 1.0 - FlameColorMask, FlameColorMask ), _DetailBlendRange * WildfireFireTerrainBlendContrast );

			float3 BurnColour = PdxTex2D( FlameVfxLut, saturate( float2( FireBlendFactors.y, FireBlendFactors.y ) ) ).rgb;

			Color = lerp( Color, vec3( 0.025 ), SmokeNoise * ( 1.0 - BurntMask ) * ConditionData._Wildfire );
			Color = lerp( Color, BurnColour * 2.0, FlameMask );
			Color = lerp( Color, BurnColour * 2.0, FireBlendFactors.y * BurntMask );
		}

		void ApplyWildFireTrees( inout float4 Diffuse, float2 Uv, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Wildfire );

			// Base Masks
			float BurnValue = 1.0 - ConditionData._Wildfire * WildfireBurntMaskMultiplier;
			float BaseBurnMask = PdxTex2D( CommonNoise, TextureUv * WildfireBurntMaskUvTiling ).r;
			float BurntMask = LevelsScan( BaseBurnMask, BurnValue, WildfireBurntMaskContrast );
			float FlameMaskInner = LevelsScan( BaseBurnMask, BurnValue + WildfireFireInnerMaskSize, WildfireBurntMaskContrast );
			float FlameMask = BurntMask - FlameMaskInner;

			// Colors
			float3 CharredDiffuse = AdjustHsv( Diffuse.rgb, 0.0, 0.5, 0.5 );
			float3 WhiteBurntGroundDiffuse = AdjustHsv( Diffuse.rgb, 0.0, 0.5, 0.9 );

			// White
			float WhiteBurntGroundMask = PdxTex2D( CommonNoise, TextureUv * 18 ).r;
			WhiteBurntGroundMask = LevelsScan( WhiteBurntGroundMask, 0.7, 1.6 );

			// Effect Properties
			Uv += WorldSpacePosXz;
			Uv *= 0.5;
			float FireUVDistortionStrength = 0.5f;
			float2 PanSpeedA = float2( 0.005, 0.01 ) * 0.3;
			float2 PanSpeedB = float2( 0.010, 0.2 ) * 0.3;
			float2 UVPan02 = float2( -frac( GlobalTime * PanSpeedA.x ), frac( GlobalTime * PanSpeedA.y ) );
			float2 UVPan01 = float2( frac( GlobalTime * PanSpeedB.x ),  frac( GlobalTime * PanSpeedB.y ) );
			float2 UV02 = ( Uv + 0.5 ) * 0.1;
			float2 UV01 = Uv * 0.2;
			UV02 += UVPan02;
			float Noise02 = PdxTex2D( CommonNoise, UV02 ).r;
			UV01 += UVPan01;
			UV01 += Noise02 * FireUVDistortionStrength;
			float FlameColorMask = PdxTex2D( CommonNoise, UV01 ).r;
			FlameColorMask = LevelsScan( FlameColorMask, 0.5, 0.6 );

			float3 BurnColour = PdxTex2D( FlameVfxLut, saturate( float2( FlameColorMask, FlameColorMask ) ) ).rgb;

			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.0, 2.1, Diffuse.a ), FlameMaskInner );
			Diffuse.rgb = lerp( Diffuse.rgb, CharredDiffuse, FlameMaskInner );
			Diffuse.rgb = lerp( Diffuse.rgb, WhiteBurntGroundDiffuse, WhiteBurntGroundMask );
			Diffuse.rgb = lerp( Diffuse.rgb, BurnColour, FlameColorMask * FlameMask );
		}





		//// Torrential Rain ////
		float2 GetRainDropWater( float2 Position )
		{
			float GridSize = 0.2;
			float RainAmount = 3.5;
			float RippleSpeed = 1.2;
			float2 Normal2D = float2( 0.0, 0.0 );

			for( float i = 0.0; i < RainAmount; i++ )
			{
				float2 Coord = Rotate( Position * 10.0 , 0.25 * i ) + float2( 5.0, 5.0 ) * i;
				float2 GridPos = round( Coord / float2( GridSize, GridSize ) ) * float2( GridSize, GridSize );
				float Offset = Hash1D( GridPos + float2( 153.0 * i, 127.0 * i ) );
				float2 Delta = GridPos - Coord;
				float Dist = length( Delta );
				Delta /= Dist;
				Dist /= GridSize;
				float Mask = 1.0 - clamp( ( Dist) * 4.0 - 1.0, 0.0, 1.0 );

				Offset = mod( RippleSpeed * GlobalTime + Offset * 3.0, 3.0 ) - 1.0;
				float Ripple = sin( ( Dist - Offset ) * 60.0 );
				float RippleD = cos( ( Dist - Offset ) * 60.0 );
				float RippleMask = clamp( abs( Dist - Offset ) * 10.0, 0.0, 1.0 );
				float Height = ( 1.0 - RippleMask ) * Mask;
				Normal2D += RippleD * Height;
			}

			return Normal2D;
		}
		float2 GetRainDropWaterNormal( float2 Uv )
		{
			float2 e = float2( 0.001, 0.0 );
			float2 RainNormal2D = GetRainDropWater( Uv );
			float2 RainNormal2Dx = GetRainDropWater( Uv + e );
			float2 RainNormal2Dy = GetRainDropWater( Uv + e.yx );

			//// Normal
			float2 Normal = float2( RainNormal2Dx.x - RainNormal2D.x, RainNormal2Dy.x - RainNormal2D.x );

			return Normal;
		}

		void ApplyTorrentialDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData, inout float WaterNormalLerp )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz ) * TorrFloodDetailTiling;

			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._TorrentialRains );
			float AdjustedPositionValue = lerp(	TorrFloodNoisePositionFrom, TorrFloodNoisePositionTo, ConditionData._TorrentialRains );
			float AdjustedContrastValue = lerp( TorrFloodNoiseContrastFrom, TorrFloodNoiseContrastTo, ConditionData._TorrentialRains );

			// Water adjustments
			float3 TerrainNormal = CalculateNormal( WorldSpacePosXz );
			float SlopeMultiplier = dot( TerrainNormal, float3( 0.0, 1.0, 0.0 ) );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, FloodSlopeMin, 1.0, 0.0, 1.0 );

			float4 FloodTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, TorrFloodTextureIndex ) );

			float2 FloodNoiseUv = TextureUv * TorrFloodNoiseTiling;
			float FloodNoise = PdxTex2D( WavyNoise, FloodNoiseUv ).r;
			FloodNoise = LevelsScan( FloodNoise, AdjustedPositionValue, AdjustedContrastValue ) * SlopeMultiplier;
			float2 FloodBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, FloodTexDiffuse.a ), float2( 1.0 - FloodNoise, FloodNoise ), _DetailBlendRange * 2.0 );

			// Watercolor
			float FloodNoiseFill = PdxTex2D( WavyNoise, FloodNoiseUv ).r;
			FloodNoiseFill = LevelsScan( FloodNoiseFill, AdjustedPositionValue, AdjustedContrastValue );
			float4 FloodWaterColor = lerp( float4( TorrFloodWaterInnerColor, 1.0 ), float4( TorrFloodWaterEdgeColor, 1.0 ), FloodBlendFactors.y * FloodNoiseFill );

			// Apply Water Color
			float4 FloodDiffuse = lerp( Diffuse, FloodWaterColor, FloodBlendFactors.y * FloodWaterOpacity );
			float3 FloodNormal = lerp( Normal, FloodNormalDirection, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			float4 FloodProperties = lerp( Properties, FloodPropertiesSettings, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			WaterNormalLerp = FloodBlendFactors.y;
			WaterNormalLerp = smoothstep( 0.8, 1.0, WaterNormalLerp );

			// Apply Flood
			FloodDiffuse.rgb = lerp( FloodDiffuse.rgb, FloodDiffuse.rgb * FloodDiffuseWetMultiplier, ConditionData._TorrentialRains );
			FloodProperties.a = lerp( FloodProperties.a, FloodProperties.a * FloodPropertiesWetMultiplier, ConditionData._TorrentialRains );

			// Raindrops
			float RainDropMask = LevelsScan( FloodBlendFactors.y, 1.1, 0.5 );
			float2 RainDropUv = MapCoords * float2( 2.0, 1.0 ) * 250.0;
			float2 RainDropNormal = GetRainDropWaterNormal( RainDropUv ) * RainDropMask;
			FloodDiffuse.rgb = Overlay( FloodDiffuse.rgb, vec3( 1.0 ), length( RainDropNormal ) * 0.8 );
			FloodNormal.xy = FloodNormal.xy + RainDropNormal * 1.0;
			FloodNormal = normalize( FloodNormal );

			Diffuse = lerp( Diffuse, FloodDiffuse, LowerValueAdjust );
			Normal = lerp( Normal, FloodNormal, LowerValueAdjust );
			Properties = lerp( Properties, FloodProperties, LowerValueAdjust );
		}





		//// Hail ////
		void ApplyHailDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, HarvestConditionData ConditionData )
		{
			float2 MapCoords = WorldSpacePosXz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );
			float2 FrostDetailUV = CalcDetailUV( WorldSpacePosXz ) * HailTextureTiling;

			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._Hail );
			float Frost = RemapClamped( ConditionData._Hail, 0.0, 1.0, 0.17, 0.24 ) * LowerValueAdjust;

			float4 FrostTexDiffuse = PdxTex2D( DetailTextures, float3( FrostDetailUV, 21 ) );
			FrostTexDiffuse.rgb = Overlay( FrostTexDiffuse.rgb, FrostOverlayColor );
			float4 FrostTexNormalRRxG = PdxTex2D( NormalTextures, float3( FrostDetailUV, 21 ) );
			float3 FrostTexNormal = UnpackRRxGNormal( FrostTexNormalRRxG ).xyz;
			float4 FrostTexProperties = PdxTex2D( MaterialTextures, float3( FrostDetailUV, 21 ) );

			float FrostBlendMask = lerp( 0.0, Diffuse.a, 1.0 - HailTextureWeight );
			FrostTexDiffuse.a = lerp( 1.0, FrostTexDiffuse.a, HailTextureWeight );
			float2 FrostBlendFactors = CalcHeightBlendFactors( float2( FrostBlendMask, FrostTexDiffuse.a ), float2( 1.0 - Frost, Frost ), _DetailBlendRange );

			// Apply
			Diffuse = lerp( Diffuse, FrostTexDiffuse, FrostBlendFactors.y );
			Normal = lerp( Normal, FrostTexNormal, FrostBlendFactors.y );
			Properties = lerp( Properties, FrostTexProperties, FrostBlendFactors.y );

			float HailNoise = PdxTex2D( HailMask, FrostDetailUV * 20.0 ).r;
			Diffuse.rgb = lerp( Diffuse.rgb, FrostOverlayColor, HailNoise * 0.5 * ConditionData._Hail );
		}





		//// Locust Swarm ////
		void ApplyLocustDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, HarvestConditionData ConditionData )
		{
			ApplyDryTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._LocustSwarm, LocustSwarmOverlayColor );

			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._LocustSwarm );

			// Paralax offset
			float3 ToCam = normalize( CameraPosition - WorldSpacePos );
			float ParalaxDist = ( 4.0 - WorldSpacePos.y ) / ToCam.y;
			float3 ParallaxCoord = WorldSpacePos + ToCam * ParalaxDist;
			ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );

			float2 Uv = ParallaxCoord.xz * float2( 2.0, 1.0 );

			ParalaxDist = ( 10.0 - WorldSpacePos.y ) / ToCam.y;
			ParallaxCoord = WorldSpacePos + ToCam * ParalaxDist;
			ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;
			float2 Uv2 = ParallaxCoord.xz * float2( 2.0, 1.0 );

			float Time = GlobalTime * 0.01;
			float Noise1 = saturate( fbm( float3( Uv * 70, Time * 5.0 ) ) );
			float Noise2 = saturate( fbm( float3( Uv * 90, Time * 8.0 ) ) );

			float AreaLow = lerp( 0.3, 0.05, ConditionData._LocustSwarm );
			float AreaHigh = lerp( 0.5, 0.4, ConditionData._LocustSwarm );
			Noise1 = smoothstep( AreaLow, AreaHigh, Noise1 );
			Noise2 = smoothstep( 0.0, 0.25, Noise2 );

			float NoiseLocusts = saturate( fbm( float3( Uv * 30000, Time * 150.0 ) ) );
			float NoiseLocusts2 = saturate( fbm( float3( Uv2 * 50000, Time * 170.0 ) ) );
			NoiseLocusts = NoiseLocusts * 0.5 + NoiseLocusts2 * 0.5;
			NoiseLocusts = LevelsScan( NoiseLocusts - Noise2 * 0.1, 0.04, 0.01 );
			NoiseLocusts *= Noise1;
			NoiseLocusts *= LowerValueAdjust;
			NoiseLocusts = saturate( NoiseLocusts );


			// Apply
			Diffuse.rgb = lerp( Diffuse.rgb, float3( 0.0, 0.0, 0.0 ), Noise1 * 0.2 );
			Diffuse.rgb = lerp( Diffuse.rgb, float3( 0.056, 0.016, 0.000 ), NoiseLocusts );
			Properties = lerp( Properties, float4( 0.0, 0.1, 0.0, 0.9 ), NoiseLocusts );
			Normal = lerp( Normal, float3( 0.0, 0.0, 1.0 ), NoiseLocusts );
		}

		void ApplyLocustTrees( inout float4 Diffuse, float3 WorldSpacePos, HarvestConditionData ConditionData )
		{
			float LowerValueAdjust = smoothstep( 0.0, 0.1, ConditionData._LocustSwarm );

			// Paralax offset
			float3 ToCam = normalize( CameraPosition - WorldSpacePos );
			float ParalaxDist = ( 4.0 - WorldSpacePos.y ) / ToCam.y;
			float3 ParallaxCoord = WorldSpacePos + ToCam * ParalaxDist;
			ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;

			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			float2 TextureUv = MapCoords * float2( 2.0, 1.0 );

			float2 Uv = ParallaxCoord.xz * float2( 2.0, 1.0 );

			ParalaxDist = ( 10.0 - WorldSpacePos.y ) / ToCam.y;
			ParallaxCoord = WorldSpacePos + ToCam * ParalaxDist;
			ParallaxCoord.xz = ParallaxCoord.xz / _ProvinceMapSize;
			float2 Uv2 = ParallaxCoord.xz * float2( 2.0, 1.0 );

			float Time = GlobalTime * 0.01;
			float Noise1 = saturate( fbm( float3( Uv * 50, Time * 4.0 ) ) );
			float Noise2 = saturate( fbm( float3( Uv * 7, Time * 5.0 ) ) );

			Noise1 = smoothstep( 0.05, 0.40, Noise1 );
			Noise2 = smoothstep( 0.0, 0.25, Noise2 );

			float NoiseLocusts = saturate( fbm( float3( Uv * 30000, Time * 100.0 ) ) );
			float NoiseLocusts2 = saturate( fbm( float3( Uv2 * 50000, Time * 110.0 ) ) );
			NoiseLocusts = NoiseLocusts * 0.5 + NoiseLocusts2 * 0.5;
			NoiseLocusts = LevelsScan( NoiseLocusts - Noise2 * 0.1, 0.04, 0.01 );
			NoiseLocusts *= Noise1;
			NoiseLocusts *= LowerValueAdjust;
			NoiseLocusts = saturate( NoiseLocusts );


			// Apply
			Diffuse.rgb = lerp( Diffuse.rgb, float3( 0.034, 0.01, 0.0 ), NoiseLocusts );
		}




		////////////////////////////////////////
		//////// Apply Harvest conditons ////////
		////////////////////////////////////////

		//// Terrain ////
		void ApplyHarvestConditionTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, inout float WaterNormalLerp )
		{
			HarvestConditionData ConditionData;

			// HarvestCondition mask
			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( MapCoords, ConditionData );

			// Apply drought
			if ( ConditionData._Drought > 0.0 )
			{
				ApplyDroughtTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._DiseaseOutbreak > 0.0)
			{
				ApplyDiseaseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._Heatwave > 0.0)
			{
				ApplyHeatwaveTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._Flood > 0.0)
			{
				ApplyFloodingDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData, WaterNormalLerp );
			}
			if ( ConditionData._Wildfire > 0.0)
			{
				ApplyWildfireDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._Frost > 0.0)
			{
				ApplyFrostDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._TorrentialRains > 0.0)
			{
				ApplyTorrentialDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData, WaterNormalLerp );
			}
			if ( ConditionData._Hail > 0.0)
			{
				ApplyHailDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData );
			}
			if ( ConditionData._LocustSwarm > 0.0)
			{
				ApplyLocustDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos, ConditionData );
			}

			DebugCondition( Diffuse.rgb, ConditionData );
		}
		void ApplyHarvestConditionTerrainPostLight( inout float3 Diffuse, float MaterialHeight, float3 WorldSpacePos )
		{
			HarvestConditionData ConditionData;

			// HarvestCondition mask
			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( MapCoords, ConditionData );

			ApplyWildfireTerrainPostLight( Diffuse, MaterialHeight, WorldSpacePos.xz, ConditionData );
		}


		//// Tree ////
		void ApplyHarvestConditionTree( inout float4 Diffuse, float2 Uv, float2 MapCoords, float3 WorldSpacePos )
		{
			HarvestConditionData ConditionData;

			// HarvestCondition mask
			SampleHarvestConditionMask( MapCoords, ConditionData );

			// Angle Adjustment
			float3 TerrainNormal = CalculateNormal( WorldSpacePos.xz );
			float SlopeMultiplier = dot( TerrainNormal, float3( 0.0, 1.0, 0.0 ) );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DroughtSlopeMin, 1.0, 0.0, 1.0 );
			float DryValue = saturate( ConditionData._Drought + ConditionData._Heatwave + ConditionData._LocustSwarm ) * SlopeMultiplier;

			// Drought
			float3  DroughtDiffuse = AdjustHsv( Diffuse, 0.0, DroughtPreSaturation, DroughtPreValue );
			DroughtDiffuse = Overlay( DroughtDiffuse, DroughtOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse, DryValue );
			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.0, 2.0, Diffuse.a ), DryValue );

			// Disease
			float3 DiseaseDiffuse = AdjustHsv( Diffuse, 0.0, DroughtPreSaturation, DroughtPreValue );
			DiseaseDiffuse = Overlay( DiseaseDiffuse, DiseaseOverlayColor );
			Diffuse.rgb = lerp( Diffuse.rgb, DiseaseDiffuse, ConditionData._DiseaseOutbreak * SlopeMultiplier );
			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.0, 2.0, Diffuse.a ), ConditionData._DiseaseOutbreak * SlopeMultiplier );

			// Frost
			float2 FrostDetailUV = CalcDetailUV( WorldSpacePos.xz ) * FrostTextureTiling;
			float4 FrostTexDiffuse = PdxTex2D( DetailTextures, float3( FrostDetailUV, 21 ) );
			FrostTexDiffuse.rgb = Overlay( FrostTexDiffuse.rgb, FrostOverlayColor );
			Diffuse.rgb = lerp( Diffuse.rgb, FrostTexDiffuse, ConditionData._Frost * FrostTexDiffuse.a );

			// Wildfire
			ApplyWildFireTrees( Diffuse, Uv, WorldSpacePos.xz, ConditionData );

			// Locust
			ApplyLocustTrees( Diffuse, WorldSpacePos, ConditionData );

			DebugCondition( Diffuse.rgb, ConditionData );
		}


		//// Decal ////
		void ApplyHarvestConditionDecal( inout float4 Diffuse, float2 MapCoords, float2 WorldSpacePosXz )
		{
			HarvestConditionData ConditionData;

			// HarvestCondition mask
			SampleHarvestConditionMask( MapCoords, ConditionData );
			float DryValue = saturate( ConditionData._Drought + ConditionData._Heatwave + ConditionData._LocustSwarm + ConditionData._DiseaseOutbreak );

			// Drought
			float3 DroughtDiffuse = Diffuse;
			DroughtDiffuse = AdjustHsv( DroughtDiffuse, 0.0, DroughtDecalPreSaturation, DroughtDecalPreValue );
			DroughtDiffuse = Overlay( DroughtDiffuse, DroughtOverlayDecal );
			DroughtDiffuse = AdjustHsv( DroughtDiffuse, 0.0, DroughtDecalFinalSaturation, 1.0 );
			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse, DryValue );

			// Frost
			float Frost = ConditionData._Frost * 0.25;
			float2 FrostDetailUV = CalcDetailUV( WorldSpacePosXz ) * FrostTextureTiling;
			float4 FrostTexDiffuse = PdxTex2D( DetailTextures, float3( FrostDetailUV, 21 ) );
			FrostTexDiffuse.rgb = Overlay( FrostTexDiffuse.rgb, FrostOverlayColor );
			Diffuse = lerp( Diffuse, FrostTexDiffuse, Frost );

			DebugCondition( Diffuse.rgb, ConditionData );
		}
	]]
}