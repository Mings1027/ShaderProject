Shader "Custom/FakeLightTest"
{
    Properties
    {
        [NoScaleOffset][SingleLineTexture]_GradientTexture("Gradient Texture", 2D) = "white" {}
        [HDR]_LightTint("Light Tint", Color) = (1,1,1,1)
        [Space(5)]_LightSoftness("Light Softness", Range( 0 , 1)) = 1
        [IntRange]_LightPosterize("Light Posterize", Range( 0 , 128)) = 1
        [Space(5)]_ShadingBlend("Shading Blend", Range( 0 , 1)) = 0.5
        _ShadingSoftness("Shading Softness", Range( 0.01 , 1)) = 0.5

        [Toggle(_Halo_ON)] _Halo("Halo", Float) = 1
        [HDR]_HaloTint("Halo Tint", Color) = (1,1,1,1)
        _HaloSize("Halo Size", Range( 0 , 5)) = 0
        [IntRange]_HaloPosterize("Halo Posterize", Range( 0 , 128)) = 0
        _HaloDepthFade("Halo Depth Fade", Range( 0.1 , 2)) = 0.5

        [Space(25)][Toggle(_DISTANCE_ON)]_DistanceFade("Distance Fade", Float) = 0
        [Tooltip(Starts fading away at this distance from the camera)]_FarFade("Far Fade", Range( 0 , 400)) = 200
        _FarTransition("Far Transition", Range(0 , 100)) = 50
        _CloseFade("Close Fade", Range( 0 , 50)) = 0
        _CloseTransition("Close Transition", Range( 0 , 50)) = 0

        [Space(25)][Toggle(___FLICKERING____ON)] ___Flickering___("___Flickering___", Float) = 0
        _FlickerIntensity("Flicker Intensity", Range( 0 , 1)) = 0.5
        _FlickerHue("Flicker Hue", Color) = (1,1,1)
        _FlickerSpeed("Flicker Speed", Range( 0.01 , 5)) = 1
        _FlickerSoftness("Flicker Softness", Range( 0 , 1)) = 0.5
        _SizeFlickering("Size Flickering", Range( 0 , 0.5)) = 0.1

        [Space(25)][Toggle(___NOISE____ON)] ___Noise___("___Noise___", Float) = 0
        [NoScaleOffset][SingleLineTexture]_NoiseTexture("Noise Texture", 2D) = "white" {}
        [KeywordEnum(Red,RedxGreen,Alpha)] _TexturePacking("Texture Packing", Float) = 0
        _Noisiness("Noisiness", Range( 0 , 2)) = 1
        _NoiseScale("Noise Scale", Range( 0.1 , 5)) = 0.1
        _NoiseMovement("Noise Movement", Range( 0 , 1)) = 0

        [Space(20)][Toggle(_SPECULARHIGHLIGHT_ON)] _SpecularHighlight("Specular Highlight", Float) = 0
        _SpecIntensity("Spec Intensity", Range( 0 , 1)) = 0.5

        [Space(20)][Toggle(_DITHERINGPATTERN_ON)] _DitheringPattern("Dithering Pattern", Float) = 0
        _DitherIntensity("Dither Intensity", Range( 0.01 , 1)) = 0.5

        [Space(20)][KeywordEnum(OFF,Low,Medium,High,Insane)] _ScreenShadows("Screen Shadows (HEAVY)", Float) = 0
        _ShadowThreshold("Shadow Threshold", Range( 0.05 , 1)) = 0.5

        [Toggle(_PARTICLEMODE_ON)] _ParticleMode("Particle Mode", Float) = 0
        [Space(15)][Toggle(_ACCURATECOLORS_ON)] _AccurateColors("Accurate Colors", Float) = 0
        [Space(15)][Toggle(_DAYFADING_ON)] _DayFading("Day Fading", Float) = 0

        [Space(15)][KeywordEnum(Additive,Contrast,Negative)] _BlendMode("Blend Mode", Float) = 0
        [Enum(Default,0,Off,1,On,2)][Space(5)]_DepthWrite("Depth Write", Float) = 0
        [HideInInspector][IntRange]_SrcBlend("SrcBlend", Range( 0 , 12)) = 1
        [HideInInspector][IntRange]_DstBlend("DstBlend", Range( 0 , 12)) = 1
        _RandomOffset("RandomOffset", Range( 0 , 1000)) = 0

        [HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
    }

    SubShader
    {
        LOD 0



        Tags
        {
            "RenderPipeline"="UniversalPipeline" "RenderType"="Overlay" "Queue"="Overlay" "UniversalMaterialType"="Unlit"
        }

        Cull Front
        AlphaToMask Off

        HLSLINCLUDE
        #pragma target 4.5
        #pragma prefer_hlslcc gles
        // ensure rendering platforms toggle list is visible

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
        ENDHLSL


        Pass
        {

            Name "Forward"
            Tags
            {
                "LightMode"="UniversalForwardOnly"
            }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_DepthWrite]
            ZTest Always
            Offset 0 , 0
            ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ASE_VERSION 19801
            #define ASE_SRP_VERSION 100400
            #define REQUIRE_DEPTH_TEXTURE 1
            #define REQUIRE_OPAQUE_TEXTURE 1
            #define ASE_USING_SAMPLING_MACROS 1

            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            #define ASE_NEEDS_FRAG_SCREEN_POSITION
            #define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
            #define ASE_NEEDS_FRAG_WORLD_POSITION
            #define ASE_NEEDS_FRAG_COLOR
            #pragma shader_feature_local _BLENDMODE_ADDITIVE _BLENDMODE_CONTRAST _BLENDMODE_NEGATIVE
            #pragma shader_feature_local _DITHERINGPATTERN_ON
            #pragma shader_feature_local _ACCURATECOLORS_ON
            #pragma shader_feature_local _PARTICLEMODE_ON
            #pragma shader_feature_local ___FLICKERING____ON
            #pragma shader_feature_local ___NOISE____ON
            #pragma shader_feature_local _TEXTUREPACKING_RED _TEXTUREPACKING_REDXGREEN _TEXTUREPACKING_ALPHA
            #pragma shader_feature_local _SCREENSHADOWS_OFF _SCREENSHADOWS_LOW _SCREENSHADOWS_MEDIUM _SCREENSHADOWS_HIGH _SCREENSHADOWS_INSANE
            #pragma shader_feature_local _DAYFADING_ON
            #pragma shader_feature_local _SPECULARHIGHLIGHT_ON
            #pragma shader_feature_local _Halo_ON
            #pragma shader_feature_local _DISTANCE_ON
            #ifdef STEREO_INSTANCING_ON
			TEXTURE2D_ARRAY(_CameraNormalsTexture); SAMPLER(sampler_CameraNormalsTexture);
            #else
            TEXTURE2D(_CameraNormalsTexture);
            SAMPLER(sampler_CameraNormalsTexture);
            #endif


            #if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
            #else
            #define ASE_SV_DEPTH SV_Depth
            #define ASE_SV_POSITION_QUALIFIERS
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 texcoord : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 ase_color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct PackedVaryings
            {
                ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
                float4 clipPosV : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                #ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
                #endif
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD3;
                #endif
                #if defined(LIGHTMAP_ON)
					float4 lightmapUVOrVertexSH : TEXCOORD4;
                #endif

                float4 ase_texcoord5 : TEXCOORD5;
                float4 ase_texcoord6 : TEXCOORD6;
                float4 ase_color : COLOR;
                float4 ase_texcoord7 : TEXCOORD7;
                float4 ase_texcoord8 : TEXCOORD8;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _LightTint;
                float _LightSoftness;
                float _LightPosterize;
                float _ShadingBlend;
                float _ShadingSoftness;

                float4 _HaloTint;
                float _HaloSize;
                float _HaloPosterize;
                float _HaloDepthFade;

                float _FarFade;
                float _FarTransition;
                float _CloseTransition;
                float _CloseFade;

                float _FlickerIntensity;
                float3 _FlickerHue;
                float _FlickerSpeed;
                float _FlickerSoftness;
                float _SizeFlickering;

                float _Noisiness;
                float _NoiseScale;
                float _NoiseMovement;

                float _SpecIntensity;

                float _DitherIntensity;

                float _ShadowThreshold;

                float _DepthWrite;
                float _SrcBlend;
                float _DstBlend;
                float _RandomOffset;

            CBUFFER_END

            TEXTURE2D(_GradientTexture);
            SAMPLER(sampler_GradientTexture);
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);


            float noise58_g1436(float x)
            {
                float n = sin(2 * x) + sin(3.14159265 * x);
                return n;
            }

            float4 NormalTexURP2275(float2 uvs)
            {
                #ifdef STEREO_INSTANCING_ON
				return SAMPLE_TEXTURE2D_ARRAY(_CameraNormalsTexture,sampler_CameraNormalsTexture,uvs,unity_StereoEyeIndex);
                #else
                return SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uvs);
                #endif
            }

            float4 ASEScreenPositionNormalizedToPixel(float4 screenPosNorm)
            {
                float4 screenPosPixel = screenPosNorm * float4(_ScreenParams.xy, 1, 1);
                #if UNITY_UV_STARTS_AT_TOP
                screenPosPixel.xy = float2(screenPosPixel.x,
                           _ProjectionParams.x < 0
                               ? _ScreenParams.y - screenPosPixel.y
                               : screenPosPixel.y);
                #else
					screenPosPixel.xy = float2( screenPosPixel.x, ( _ProjectionParams.x > 0 ) ? _ScreenParams.y - screenPosPixel.y : screenPosPixel.y );
                #endif
                return screenPosPixel;
            }

            float ExperimentalScreenShadowsURP(float2 lightDirScreen, float threshold, float stepsSpace, float stepsNum,
                                     float radius, float mask, float3 wPos, float3 lightPos, float3 camPos,
                                     float2 screenPos, float3 offsetDir)
            {
                if (mask <= 0) return 1;
                float depth = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(screenPos), _ZBufferParams);

                //offset light position by its max radius:
                float3 lightRadiusOffsetPos = lightPos + offsetDir * radius;
                //convert position to real depth distance:
                float MaxDist = -mul(UNITY_MATRIX_V, float4(lightRadiusOffsetPos, 1)).z;
                //Early Return if greater than max radius:
                if (depth > MaxDist) return 1;
                //initialization:
                float shadow = 0;
                float op = 2 / stepsNum;
                float spacing = stepsSpace / stepsNum * clamp(distance(lightPos, camPos), radius, 1);
                //float spacing =((stepsSpace/stepsNum)) ;
                float t = spacing;
                float realLightDist = -mul(UNITY_MATRIX_V, float4(lightPos, 1)).z;
                [unroll] for (int i = 1; i <= stepsNum; i++)
                {
                    float2 uvs = screenPos + lightDirScreen.xy * t; //offset uv
                    t = clamp(spacing * i, -1, 1); //ray march
                    float d = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uvs); //sample depth
                    float l = LinearEyeDepth(d, _ZBufferParams);
                    if (MaxDist < l) return 1;
                    float3 world = ComputeWorldSpacePosition(uvs, d, UNITY_MATRIX_I_VP);
                    if (distance(wPos, lightPos) > radius) return 1; //remove out of range artifacts
                    if (shadow >= 1) break;
                    if (world.y - wPos.y > threshold * MaxDist && abs(world.y - wPos.y) < radius) shadow += op;
                }
                //return smoothstep(.9,1,shadow);
                shadow = step(0.01, shadow) * mask;
                return 1 - shadow;
            }

            float2 WorldToScreen(float3 pos)
            {
                float4 wts = ComputeScreenPos(TransformWorldToHClip(pos));
                float3 wts_NDC = wts.xyz / wts.w;
                return wts_NDC.xy;
            }

            inline float Dither4x4Bayer(int x, int y)
            {
                const float dither[16] = {
                    1, 9, 3, 11,
                    13, 5, 15, 7,
                    4, 12, 2, 10,
                    16, 8, 14, 6
                };
                int r = y * 4 + x;
                return dither[r] / 16; // same # of instructions as pre-dividing due to compiler magic
            }

            inline float Dither8x8Bayer(int x, int y)
            {
                const float dither[64] = {
                    1, 49, 13, 61, 4, 52, 16, 64,
                    33, 17, 45, 29, 36, 20, 48, 32,
                    9, 57, 5, 53, 12, 60, 8, 56,
                    41, 25, 37, 21, 44, 28, 40, 24,
                    3, 51, 15, 63, 2, 50, 14, 62,
                    35, 19, 47, 31, 34, 18, 46, 30,
                    11, 59, 7, 55, 10, 58, 6, 54,
                    43, 27, 39, 23, 42, 26, 38, 22
                };
                int r = y * 8 + x;
                return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
            }

            PackedVaryings VertexFunction(Attributes input)
            {
                PackedVaryings output = (PackedVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);

                #ifdef _PARTICLEMODE_ON
                float3 particlePosition = input.texcoord.xyz;
                #else
                float3 particlePosition = objectPosition;
                #endif

                #ifdef _DISTANCE_ON
                float3 axisMul = float3(1, 0, 1);
                float disFromCam = distance(particlePosition * axisMul, axisMul * _WorldSpaceCameraPos);
                output.ase_texcoord6.w = saturate(1.0 - (disFromCam - _FarFade) / _FarTransition) * saturate(
                    (disFromCam - _CloseFade) / _CloseTransition);
                #endif

                #ifdef _PARTICLEMODE_ON
                float randomOffset = input.texcoord.w;
                #else
                float randomOffset = _RandomOffset;
                #endif

                #ifdef ___FLICKERING____ON
                float flickerTime = _TimeParameters.x * ((_FlickerSpeed + randomOffset * 0.1) * 4);
                float flickerNoise = noise58_g1436(flickerTime + randomOffset * PI);
                float flickerSoftness = (1.0 - _FlickerSoftness) * 0.5;
				float flickerAlpha = saturate( 1.0 - _FlickerIntensity + ((flickerNoise + 2.0) / 4.0 - ( 1.0 - flickerSoftness )) * (1.0 - ( 1.0 - _FlickerIntensity )) / (flickerSoftness - ( 1.0 - flickerSoftness )) );
                #else
                float flickerAlpha = 1.0;
                #endif

                float flickerSize = 1.0 - _SizeFlickering + flickerAlpha * (1.0 - (1.0 - _SizeFlickering));
                float3 objScale = float3(length(GetObjectToWorldMatrix()[0].xyz),
                                              length(GetObjectToWorldMatrix()[1].xyz),
                                              length(GetObjectToWorldMatrix()[2].xyz));

                #ifdef _PARTICLEMODE_ON
                float3 particleScale = (objScale * input.texcoord1.xyz);
                #else
                float3 particleScale = objScale;
                #endif

                float maxScale = max(max(particleScale.x, particleScale.y), particleScale.z);

                #ifdef _PARTICLEMODE_ON
                float particleSize = (maxScale * 0.1);
                #else
                float particleSize = 1.0;
                #endif

                float lightDirY = dot(-_MainLightPosition.xyz, float3(0, 1, 0));
                output.ase_texcoord7.x = saturate(lightDirY * 4.0);

                output.ase_texcoord7.y = _HaloSize * flickerSize * particleSize * 0.5;
                float depthScale = unity_OrthoParams.w == 0.0
       ? distance(_WorldSpaceCameraPos, particlePosition) / -UNITY_MATRIX_P[1][1]
       : unity_OrthoParams.y;
                output.ase_texcoord7.z = depthScale;
                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                float3 viewVector = _WorldSpaceCameraPos.xyz - worldPos;
                float3 safeViewDir = SafeNormalize(viewVector);

                output.ase_texcoord7.w = step(0.0, dot(safeViewDir, _WorldSpaceCameraPos - particlePosition));

                output.ase_texcoord8.x = distance(_WorldSpaceCameraPos, particlePosition);
                output.ase_texcoord8.yzw = lerp(_FlickerHue, float3(1, 1, 1), flickerAlpha * flickerAlpha);

                output.ase_texcoord5 = input.texcoord;
                output.ase_texcoord6.xyz = input.texcoord1.xyz;
                output.ase_color = input.ase_color;

                #ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexPos = input.positionOS.xyz;
                #else
                float3 defaultVertexPos = float3(0, 0, 0);
                #endif

                float3 vertexPos = defaultVertexPos;

                #ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexPos;
                #else
                input.positionOS.xyz += vertexPos;
                #endif

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                #if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(input.texcoord1, unity_LightmapST, output.lightmapUVOrVertexSH.xy);
                #endif

                #ifdef ASE_FOG
					output.fogFactor = ComputeFogFactor( vertexInput.positionCS.z );
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					output.shadowCoord = GetShadowCoord( vertexInput );
                #endif

                output.positionCS = vertexInput.positionCS;
                output.clipPosV = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                return output;
            }

            PackedVaryings vert(Attributes input)
            {
                return VertexFunction(input);
            }

            half4 frag(PackedVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(LOD_FADE_CROSSFADE)
					LODDitheringTransition( input.positionCS.xyz, unity_LODFade.x );
                #endif

                float3 worldPosition = input.positionWS;
                float3 viewDirection = GetWorldSpaceNormalizeViewDir(worldPosition);
                float4 screenPos = ComputeScreenPos(input.clipPosV);

                // float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

                #if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						float4 shadowCoordinates = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						float4 shadowCoordinates = TransformWorldToShadowCoord( worldPosition );
                #endif
                #endif

                float4 clipToScreenPos = screenPos / screenPos.w;
                clipToScreenPos.z = UNITY_NEAR_CLIP_VALUE >= 0
          ? clipToScreenPos.z
          : clipToScreenPos.z * 0.5 + 0.5;
                float linearDepth = LinearEyeDepth(
                    SHADERGRAPH_SAMPLE_SCENE_DEPTH(clipToScreenPos.xy), _ZBufferParams);
                float3 objToWorldDir
                    = mul(GetObjectToWorldMatrix(), float4(transpose(mul(GetWorldToObjectMatrix(),
                              UNITY_MATRIX_I_V))[2].xyz, 0.0)).xyz;
                float viewObjDot = dot(viewDirection, -objToWorldDir);
                float3 worldToViewPos = mul(UNITY_MATRIX_V, float4(worldPosition, 1)).xyz;
                float sceneDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(clipToScreenPos.xy);

                #ifdef UNITY_REVERSED_Z
                float normalizedDepth = 1.0 - sceneDepth;
                #else
				float normalizedDepth = sceneDepth;
                #endif

                float interpolatedDepth = lerp(_ProjectionParams.y, _ProjectionParams.z, normalizedDepth);

                float3 reconstructedViewPos = float3(worldToViewPos.x, worldToViewPos.y, -interpolatedDepth);
                float3 viewToWorld = mul(UNITY_MATRIX_I_V, float4(reconstructedViewPos, 1.0)).xyz;
                float3 reconstructedWorldPos = (unity_OrthoParams.w < 1.0
                                                                       ? linearDepth * (viewDirection / viewObjDot) +
                                                                       _WorldSpaceCameraPos
                                                                       : viewToWorld).xyz;

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);

                #ifdef _PARTICLEMODE_ON
                float3 particlePosition = input.ase_texcoord5.xyz;
                #else
                float3 particlePosition = objectPosition;
                #endif

                float3 localPos = reconstructedWorldPos - particlePosition;
                float3 objScale = float3(length(GetObjectToWorldMatrix()[0].xyz),
   length(GetObjectToWorldMatrix()[1].xyz),
   length(GetObjectToWorldMatrix()[2].xyz));

                #ifdef _PARTICLEMODE_ON
                float3 scaledParticlePos = objScale * input.ase_texcoord6.xyz;
                #else
                float3 scaledParticlePos = objScale;
                #endif
                float maxScale = max(max(scaledParticlePos.x, scaledParticlePos.y), scaledParticlePos.z);

                #ifdef _PARTICLEMODE_ON
                float randomOffset = input.ase_texcoord5.w;
                #else
                float randomOffset = _RandomOffset;
                #endif

                #ifdef ___FLICKERING____ON
                float flickerTime = _TimeParameters.x * ((_FlickerSpeed + randomOffset * 0.1) * 4);
                float flickerNoise = noise58_g1436(flickerTime + randomOffset * PI);
                float flickerSoftness = (1.0 - _FlickerSoftness) * 0.5;
                float flickerAlpha = saturate(1.0 - _FlickerIntensity + ((flickerNoise + 2.0) / 4.0 - ( 1.0 - flickerSoftness )) * (1.0 - ( 1.0 - _FlickerIntensity )) / (flickerSoftness - ( 1.0 - flickerSoftness )) );
                #else
                float flickerAlpha = 1.0;
                #endif

                float4 normalSample = NormalTexURP2275(clipToScreenPos.xy);
                float3 worldNormal = normalSample.xyz;

                #ifdef ___NOISE____ON
                float3 worldNormalPow3 = pow(abs(worldNormal), (3.0).xxx);
                float dotNormalSum = dot(worldNormalPow3, (1.0).xxx);
                
                float4 noisePixelScreenPos = ASEScreenPositionNormalizedToPixel(clipToScreenPos);
                float ditherValue =
                    Dither8x8Bayer(fmod(noisePixelScreenPos.x, 8), fmod(noisePixelScreenPos.y, 8));

                float3 normalizedWorldNormal = saturate(worldNormalPow3) / dotNormalSum;

                float3 noiseUV = reconstructedWorldPos * 0.1 * _NoiseScale;

                float2 lerpUV1 = lerp(noiseUV.xz, noiseUV.yz * 0.9,
                                round((1.0 - normalizedWorldNormal.x) * normalizedWorldNormal.x *
                                    ditherValue + normalizedWorldNormal.x));

                float2 lerpUV2 = lerp(lerpUV1, noiseUV.xy * 0.94,
                            round(normalizedWorldNormal.z + ditherValue * (
                            normalizedWorldNormal.z * (1.0 - normalizedWorldNormal.z))));
                
                float noiseTime = _TimeParameters.x * ((_NoiseMovement + randomOffset * 0.1) * 0.2);
                float noisePhase = noiseTime + randomOffset * PI;
                
                float4 noiseSample1 = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,
                     ( lerpUV2 + ( noisePhase * float2( 1.02,0.87 ) ) ));
              
                float4 noiseSample2 = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,
                   ( lerpUV2 * 0.7 + (noisePhase * float2(-0.72,-0.67))));

                #if defined( _TEXTUREPACKING_RED )
                float staticSwitch212_g2191 = noiseSample2.r;
                float noiseValue1 = noiseSample1.r;
                #elif defined( _TEXTUREPACKING_REDXGREEN )
                float staticSwitch212_g2191 = noiseSample2.r;
                float noiseValue1 = noiseSample1.g;
                #elif defined( _TEXTUREPACKING_ALPHA )
                float staticSwitch212_g2191 = noiseSample2.a;
                float noiseValue1 = noiseSample1.a;
                #else
                float staticSwitch212_g2191 = noiseSample2.r;
                float noiseValue1 = noiseSample1.r;
                #endif

                float noiseFactor = 1.0 + (noiseValue1 * staticSwitch212_g2191 * _Noisiness - _Noisiness * 0.2);
                #else
                float noiseFactor = 1.0;
                #endif

                float flickerMagnitude = 1.0 - _SizeFlickering + flickerAlpha * (1.0 - (1.0 - _SizeFlickering));

                float localSilhouette = saturate(1.0 - length(localPos) / (maxScale * (flickerMagnitude * 0.45)));
                float lightSoftness = (1.0 - _LightSoftness * 1.1) * 0.5;

                float smoothStepValue = smoothstep(lightSoftness, 1.0 - lightSoftness,
                   localSilhouette * (localSilhouette + noiseFactor));

                float brightnessBoost = saturate(pow(localSilhouette, 30.0));
                float brightnessSum = smoothStepValue + brightnessBoost;
                float lightPosterize = 256.0 / _LightPosterize;
                float gradientMask = smoothStepValue * (_LightPosterize <= 0.0
                           ? brightnessSum
                           : saturate(floor(brightnessSum * lightPosterize) / lightPosterize));

                #if defined( _SCREENSHADOWS_OFF )
                float screenSpaceShadowsQuality = -1.0;
                #elif defined( _SCREENSHADOWS_LOW )
				float screenSpaceShadowsQuality = 16.0;
                #elif defined( _SCREENSHADOWS_MEDIUM )
				float screenSpaceShadowsQuality = 32.0;
                #elif defined( _SCREENSHADOWS_HIGH )
				float screenSpaceShadowsQuality = 64.0;
                #elif defined( _SCREENSHADOWS_INSANE )
				float screenSpaceShadowsQuality = 128.0;
                #else
				float screenSpaceShadowsQuality = -1.0;
                #endif

                #ifdef _DAYFADING_ON
                float mainLightFactor = input.ase_texcoord7.x;
				float dayFadingFactor = mainLightFactor;
                #else
                float dayFadingFactor = 1.0;
                #endif

                float distanceFade;

                #ifdef _DISTANCE_ON
                float flickerControl = input.ase_texcoord6.w;
                distanceFade = flickerControl * dayFadingFactor;
                #else
                distanceFade = dayFadingFactor;
                #endif

                float screenSpaceShadowIntensity;

                #if defined(_SCREENSHADOWS_OFF)
                screenSpaceShadowIntensity = 1.0;
                #else
                float sphereRadius = maxScale * 0.5;
                float fadeOffFactor = 1.0 - abs(particlePosition.y) / sphereRadius;
                float3 normalizedViewFromObj = normalize(particlePosition - _WorldSpaceCameraPos);

                float viewDotObj = dot(normalizedViewFromObj, -objToWorldDir);
                float4 worldToScreenPos = ComputeScreenPos(
                    TransformWorldToHClip(particlePosition * float3(1, 0.1, 1)));
                float3 worldToScreenNDC = worldToScreenPos.xyz / worldToScreenPos.w;
                float2 screenPosDiff = (float4(worldToScreenNDC, 0.0) - clipToScreenPos).xy;
                
                float3 offsetForShadow = viewDotObj * normalizedViewFromObj;
                float2 screenLightDir = fadeOffFactor * viewDotObj * screenPosDiff;
                float shadowThresholdEffect = _ShadowThreshold * 0.01;
                float screenSpaceSteps = 1.0;

                float localScreenShadows = ExperimentalScreenShadowsURP(
                screenLightDir, shadowThresholdEffect, screenSpaceSteps, screenSpaceShadowsQuality,
                sphereRadius, distanceFade, reconstructedWorldPos, particlePosition, _WorldSpaceCameraPos,
                clipToScreenPos.xy, offsetForShadow);

                #if defined(_SCREENSHADOWS_LOW) || defined(_SCREENSHADOWS_MEDIUM) || defined(_SCREENSHADOWS_HIGH) || defined(_SCREENSHADOWS_INSANE)
                screenSpaceShadowIntensity = localScreenShadows;
                #else
                screenSpaceShadowIntensity = 1.0;
                #endif
                #endif

                float3 lightDir = normalize(-localPos);
                float lightDotNormal = dot(lightDir, worldNormal);
                float smoothLight = smoothstep(0.0, _ShadingSoftness, saturate(lightDotNormal * 1 * screenSpaceShadowIntensity));
                float2 inverseUVGradient = (1.0 - gradientMask).xx;
                float shadingPosterization = 256.0 / inverseUVGradient;
                float lightMask = saturate((inverseUVGradient <= 0.0
                ? smoothLight
                : saturate(floor(smoothLight * shadingPosterization) / shadingPosterization)) + _ShadingBlend);
                float surfaceMask = step(0.01, localSilhouette);
                float lightIntensity = gradientMask * lightMask * surfaceMask;

                #ifdef _SPECULARHIGHLIGHT_ON
                float dotLightNormal = dot(normalize(viewDirection + lightDir), worldNormal * float3(1, 0.99, 1));
				float specIntensity = _SpecIntensity * 2 * pow(saturate(dotLightNormal) , (0.5 * 0.5 + 0.5) * 200) * lightIntensity;
                #else
                float specIntensity = 0.0;
                #endif

                float4 gradientSample = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture,
                    inverseUVGradient) * _LightTint * input.ase_color;
                float3 lightColor = gradientSample.rgb * (gradientSample.a * lightIntensity * 0.1) + specIntensity;

                #ifdef _ACCURATECOLORS_ON
                float4 pixelScreenColor = float4(SHADERGRAPH_SAMPLE_SCENE_COLOR(clipToScreenPos.xy), 1.0);
				float3 accuratePower = abs(pixelScreenColor.rgb);
                float3 accurateColor = lightColor * 4 * pow(accuratePower , saturate(0.8 - 0.4 * gradientMask).xxx);
                #else
                float3 accurateColor = lightColor;
                #endif

                #ifdef _Halo_ON
                float haloSize = input.ase_texcoord7.y;
                float2 objWorldToScreenUV = WorldToScreen(particlePosition);
                float2 screenAspectRatio = float2(_ScreenParams.x / _ScreenParams.y, 1.0);
                float2 screenPosDelta = objWorldToScreenUV.xy - clipToScreenPos.xy;
                float screenDistance = length(screenPosDelta * screenAspectRatio * input.ase_texcoord7.z);
                float haloMask = (1.0 - smoothstep(0.0, haloSize, screenDistance)) * input.ase_texcoord7.w;
                float haloPosterization = 256.0 / _HaloPosterize;
                float haloIntensity = haloMask * (_HaloPosterize <= 0.0
                                    ? haloMask
                                    : saturate(floor(haloMask * haloPosterization) / haloPosterization));
                float2 inverseHaloUV = (1.0 - haloIntensity).xx;
                float haloPenetrationMask = saturate(pow(
                    saturate(distance(reconstructedWorldPos, _WorldSpaceCameraPos) - input.ase_texcoord8.x),
                    _HaloDepthFade));
                float4 haloColorSample = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, inverseHaloUV)
                    * _HaloTint * input.ase_color;
                float3 haloColor = haloColorSample.rgb * (haloColorSample.a * haloMask *
                    haloPenetrationMask * haloIntensity);
                #else
                float3 haloColor = 0;
                #endif

                float3 finalLightColor = (accurateColor + haloColor) * input.ase_texcoord8.yzw * (
                    distanceFade * flickerAlpha);

                #ifdef _DITHERINGPATTERN_ON
                float4 ditherPixelScreenPos = ASEScreenPositionNormalizedToPixel(clipToScreenPos);
                float ditherEffect = Dither4x4Bayer(fmod(ditherPixelScreenPos.x, 4), fmod(ditherPixelScreenPos.y, 4));
                float combinedFinalColorEffect = smoothstep(0.0, _DitherIntensity,
                  0.333 * (finalLightColor.x + finalLightColor.y + finalLightColor.z) * (_DitherIntensity + 1.0));
                float ditherAppliedColor = step(ditherEffect, saturate(combinedFinalColorEffect * 1.00001));
				float3 dithering = ( finalLightColor * ditherAppliedColor );
                #else
                float3 dithering = finalLightColor;
                #endif

                float3 combinedColor = dithering;

                #if defined( _BLENDMODE_ADDITIVE )
                float3 blendModeValue = combinedColor;
                #elif defined( _BLENDMODE_CONTRAST )
				float3 blendModeValue = combinedColor;
                #elif defined( _BLENDMODE_NEGATIVE )
				float3 blendModeValue = ( 1.0 - saturate( combinedColor ) );
                #else
				float3 blendModeValue = combinedColor;
                #endif

                float3 finalColor = blendModeValue;

                float3 bakedAlbedo = 0;
                float3 bakedEmission = 0;
                float3 outputColor = finalColor;
                float alpha = 1;
                float AlphaClipThreshold = 0.5;
                float AlphaClipThresholdShadow = 0.5;

                #ifdef _ALPHATEST_ON
					clip(alpha - AlphaClipThreshold);
                #endif

                #ifdef ASE_FOG
					outputColor = MixFog(outputColor, input.fogFactor);
                #endif

                return half4(outputColor, alpha);
            }
            ENDHLSL
        }


    }

    CustomEditor "ShaderCode.FPL.FakeLightEditor"
    Fallback "Hidden/InternalErrorShader"

}