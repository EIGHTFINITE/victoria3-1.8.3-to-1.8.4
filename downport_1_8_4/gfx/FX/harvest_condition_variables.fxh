Code
[[
		//#define DEBUG_INCIDENT_MASK 					// Enable to debug mask
		//#define DEBUG_INCIDENT_MASK_Drought
		#define DROUGHT_INDEX 1
		#define FLOOD_INDEX 2
		#define FROST_INDEX 3
		#define WILDFIRE_INDEX 4
		#define TORRENTIAL_RAINS_INDEX 5
		#define HAIL_INDEX 6
		#define EXTREME_WINDS_INDEX 7


		// General
		#define OpacityLowImpactValue				1.5
		#define OpacityHighImpactValue				7.5
		#define HarvestConditionOverlayAlpha 		1.0 	// Strength of the whole overlay

		// Fade transition states
		#define HarvestConditionFadeStateNone		0	// Normal color
		#define HarvestConditionFadeStateFaded 		1	// Transparent
		#define HarvestConditionFadeStateFadingIn 	2	// Becomes opaque
		#define HarvestConditionFadeStateFadingOut 	3	// Becomes transparent


		// Drought
		#define DroughtSlopeMin						0.2
		#define DroughtPreSaturation 				0.15
		#define DroughtPreValue 					0.8
		#define DroughtFinalSaturation 				0.7
		#define DroughtOverlayColor 				float3( 0.855, 0.470, 0.167 )
		#define DroughtDryOverlayColor 				float3( 0.587, 0.535, 0.337 )
		#define DroughtCracksOverlayColor 			float3( 0.742, 0.461, 0.203 )

		#define DroughtColorMaskPositionFrom 		1.0
		#define DroughtColorMaskContrastFrom 		0.1
		#define DroughtColorMaskPositionTo 			0.0
		#define DroughtColorMaskContrastTo 			0.0

		#define DroughtDryTexureIndex				5
		#define DroughtDryMaskUvTiling				9

		#define DroughtDryMaskPositionFrom 			1.05
		#define DroughtDryMaskContrastFrom 			0.455
		#define DroughtDryMaskPositionTo 			0.85
		#define DroughtDryMaskContrastTo 			1.205

		#define DroughtCracksTexureIndex			13
		#define DroughtCrackedTextureUvTiling		2
		#define DroughtCracksAreaMaskTiling 		20.0

		#define DroughtCracksAreaMaskPositionFrom 	0.761
		#define DroughtCracksAreaMaskContrastFrom 	0.101
		#define DroughtCracksAreaMaskPositionTo 	0.441
		#define DroughtCracksAreaMaskContrastTo 	0.101

		#define DroughtCracksTextureBlendWeight		0.42
		#define DroughtCracksTextureBlendContrast	1.5

		#define DroughtOverlayTree 					float3( 0.646, 0.287, 0.067 )

		#define DroughtDecalPreSaturation 			0.0
		#define DroughtDecalPreValue 				0.8
		#define DroughtDecalFinalSaturation 		0.4
		#define DroughtOverlayDecal 				float3( 1.000, 0.402, 0.0 )


		// Flooding & Torrential Rains
		#define FloodSlopeMin					0.98

		#define FloodNoiseTiling				30
		#define FloodDetailTiling				0.5
		#define FloodTextureIndex				1
		#define FloodWaterOpacity 				0.92
		#define FloodWaterPropertiesBlend		0.995
		#define FloodNormalDirection			float3( 0.0, 0.0, 1.0 )
		#define FloodPropertiesSettings 		float4( 0.0, 0.125, 0.0, 0.08 )

		#define FloodDiffuseWetMultiplier		0.5
		#define FloodPropertiesWetMultiplier	0.65

		#define FloodNoisePositionFrom			0.75
		#define FloodNoisePositionTo			0.5
		#define FloodNoiseContrastFrom			0.1
		#define FloodNoiseContrastTo			0.25

		#define FloodWaterInnerColor			float3( 0.053, 0.055, 0.074 )
		#define FloodWaterEdgeColor				float3( 0.088, 0.073, 0.052 )

		#define TorrFloodWaterInnerColor		float3( 0.126, 0.186, 0.232 )
		#define TorrFloodWaterEdgeColor			float3( 0.022, 0.029, 0.056 )
		#define TorrFloodLowImpactValue			2.0
		#define TorrFloodHighImpactValue		4.0
		#define TorrFloodNoiseTiling			15
		#define TorrFloodDetailTiling			0.25
		#define TorrFloodTextureIndex			2
		#define TorrFloodNoisePositionFrom		0.7
		#define TorrFloodNoisePositionTo		0.6
		#define TorrFloodNoiseContrastFrom		0.4
		#define TorrFloodNoiseContrastTo		0.3


		// Frost & Hail
		#define FrostLowImpactValue				1.5
		#define FrostHighImpactValue			3.0
		#define FrostOverlayColor 				float3( 0.471, 0.556, 0.667 )
		#define FrostTextureTiling				0.02
		#define FrostTextureWeight				0.75

		#define HailLowImpactValue				1.0
		#define HailHighImpactValue				3.0
		#define HailTextureTiling				0.2
		#define HailTextureWeight				0.85

		// Wildfire
		#define WildfireLowImpactValue						1.5
		#define WildfireHighImpactValue						7.5

		#define WildfireBurntMaskUvTiling					14.0
		#define WildfireBurntMaskContrast					0.05
		#define WildfireBurntMaskMultiplier					0.5

		#define WildfireFireInnerMaskSize					0.04
		#define WildfireFireTerrainBlendContrast			4.0

		// Extreme Winds
		#define ExtremeWindsLowImpactValue		0.5
		#define ExtremeWindsHighImpactValue		3.5
		#define ExtremeWindSwaySpeed			4.0
		#define ExtremeWindSwayScale			2.5
]]