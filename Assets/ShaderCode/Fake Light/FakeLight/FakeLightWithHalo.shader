Shader "Custom/FakeLightWithHalo"
{
    Properties
    {
        [NoScaleOffset][SingleLineTexture]_GradientTexture("Gradient Texture", 2D) = "white" {}
        [HDR]_LightTint("Light Tint", Color) = (1, 1, 1, 1)
        _LightSoftness("Light Softness", Range(0 ,1)) = 1
        [IntRange]_LightPosterize("Light Posterize", Range(0 ,128)) = 1
        _ShadingBlend("Shading Blend", Range(0 ,1)) = 0.5
        _ShadingSoftness("Shading Softness", Range(0.01 ,1)) = 0.5

        [Space(25)][Toggle(_Halo_ON)] _Halo("Halo", Float) = 1
        [HDR]_HaloTint("Halo Tint", Color) = (1, 1, 1, 1)
        _HaloSize("Halo Size", Range(0 ,5)) = 0
        [IntRange]_HaloPosterize("Halo Posterize", Range(0 ,128)) = 0
        _HaloDepthFade("Halo Depth Fade", Range(0.1 ,2)) = 0.5

        [Space(25)][Toggle(_DISTANCE_ON)]_DistanceFade("Distance Fade", Float) = 0
        [Tooltip(Starts fading away at this distance from the camera)]_FarFade("Far Fade", Range( 0 , 400)) = 200
        _FarTransition("Far Transition", Range(0 , 100)) = 50
        _CloseFade("Close Fade", Range( 0 , 50)) = 0
        _CloseTransition("Close Transition", Range( 0 , 50)) = 0

        [Space(25)][Toggle(_FLICKERING_ON)] _Flickering("Flickering", Float) = 0
        _FlickerTint("Flicker Tint", Color) = (1,1,1)
        _FlickerIntensity("Flicker Intensity", Range( 0 , 1)) = 0.5
        _FlickerSpeed("Flicker Speed", Range( 0.01 , 5)) = 1
        _FlickerSoftness("Flicker Softness", Range( 0 , 1)) = 0.5
        _SizeFlickering("Size Flickering", Range( 0 , 0.5)) = 0.1

        [Space(25)][Toggle(_NOISE_ON)] _Noise("Noise", Float) = 0
        [NoScaleOffset][SingleLineTexture]_NoiseTexture("Noise Texture", 2D) = "white" {}
        [KeywordEnum(Red,RedxGreen,Alpha)] _TexturePacking("Texture Packing", Float) = 0
        _Noisiness("Noisiness", Range( 0 , 2)) = 1
        _NoiseScale("Noise Scale", Range( 0.1 , 5)) = 0.1
        _NoiseMovement("Noise Movement", Range( 0 , 1)) = 0

        [Space(20)][Toggle(_SPECULARHIGHLIGHT_ON)] _SpecularHighlight("Specular Highlight", Float) = 0
        [HDR]_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
        _SpecIntensity("Spec Intensity", Range( 0 , 1)) = 0.5
        [IntRange]_SpecPower("Spec Power", Range(0, 200)) = 100

        [Space(15)][Toggle(_ACCURATECOLORS_ON)] _AccurateColors("Accurate Colors", Float) = 0

        [Space(25)]_RandomOffset("RandomOffset", Range( 0 , 1000)) = 0

        [Enum(Default,0, Off,1, On,2)][Space(5)]_DepthWrite("Depth Write", Float) = 0
        [HideInInspector][IntRange]_SrcBlend("SrcBlend", Range(0 ,12)) = 1
        [HideInInspector][IntRange]_DstBlend("DstBlend", Range(0 ,12)) = 1
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
            // #define _SURFACE_TYPE_TRANSPARENT 1
            // #define ASE_VERSION 19801
            // #define ASE_SRP_VERSION 100400
            #define REQUIRE_DEPTH_TEXTURE 1
            #define REQUIRE_OPAQUE_TEXTURE 1
            // #define ASE_USING_SAMPLING_MACROS 1

            #pragma shader_feature_local _Halo_ON
            #pragma shader_feature_local _DISTANCE_ON
            #pragma shader_feature_local _FLICKERING_ON
            #pragma shader_feature_local _NOISE_ON
            #pragma shader_feature_local _SPECULARHIGHLIGHT_ON
            #pragma shader_feature_local _ACCURATECOLORS_ON

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float4 clipPosV : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 texcoord3 : TEXCOORD3;

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
                float _CloseFade;
                float _CloseTransition;

                float3 _FlickerTint;
                float _FlickerIntensity;
                float _FlickerSpeed;
                float _FlickerSoftness;
                float _SizeFlickering;

                float _Noisiness;
                float _NoiseScale;
                float _NoiseMovement;

                float4 _SpecularColor;
                float _SpecIntensity;
                float _SpecPower;
                float _RandomOffset;

                float _DepthWrite;
                float _SrcBlend;
                float _DstBlend;
            CBUFFER_END

            TEXTURE2D(_GradientTexture);
            SAMPLER(sampler_GradientTexture);
            TEXTURE2D(_CameraNormalsTexture);
            SAMPLER(sampler_CameraNormalsTexture);
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            float4 NormalTex(float2 uvs)
            {
                #ifdef STEREO_INSTANCING_ON
				return SAMPLE_TEXTURE2D_ARRAY(_CameraNormalsTexture,sampler_CameraNormalsTexture,uvs,unity_StereoEyeIndex);
                #else
                return SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uvs);
                #endif
            }

            float Noise(float x)
            {
                float n = sin(2 * x) + sin(3.14159265 * x);
                return n;
            }

            float CalculateFlickerAlpha()
            {
                #ifdef _FLICKERING_ON
                float flickerTime = _TimeParameters.x * ((_FlickerSpeed + _RandomOffset * 0.1) * 4);
                float flickerNoise = Noise(flickerTime + _RandomOffset * PI);
                float flickerSoftness = (1.0 - _FlickerSoftness) * 0.5;
                float normalizedNoise = (flickerNoise + 2.0) / 4.0;
                float baseIntensity = 1.0 - _FlickerIntensity;
                float adjustedNoise = normalizedNoise - (1.0 - flickerSoftness);
                float flickerRange = flickerSoftness - (1.0 - flickerSoftness);
                float intensityFactor = adjustedNoise * (1.0 - baseIntensity) / flickerRange;
                float flickerAlpha = saturate(baseIntensity + intensityFactor);
                #else
                float flickerAlpha = 1.0;
                #endif

                return flickerAlpha;
            }
            
            float CalculateDistanceFade(float3 objectPos)
            {
                #ifdef _DISTANCE_ON
                float3 axisMul = float3(1, 0, 1);
                float disFromCam = distance(objectPos * axisMul, axisMul * _WorldSpaceCameraPos);
                float farFade = saturate(1.0 - (disFromCam - _FarFade) / _FarTransition);
                float closeFade = saturate((disFromCam - _CloseFade) / _CloseTransition);
                return farFade * closeFade;
                #else
                return 1.0;
                #endif
            }

            float CalculateDepthScale(float3 objectPos)
            {
                if (unity_OrthoParams.w == 1)
                {
                    return unity_OrthoParams.y;
                }
                else
                {
                    float distanceToCam = distance(_WorldSpaceCameraPos, objectPos);
                    return distanceToCam / -UNITY_MATRIX_P[1][1];
                }
            }

            PackedVaryings VertexFunction(Attributes input)
            {
                PackedVaryings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.color = input.color;
                output.clipPosV = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);

                output.texcoord2.x = distance(_WorldSpaceCameraPos, objectPosition);
                output.texcoord2.y = CalculateDistanceFade(objectPosition);
                output.texcoord2.z = CalculateDepthScale(objectPosition);

                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                float3 viewVector = _WorldSpaceCameraPos.xyz - worldPos;
                float3 safeViewDir = SafeNormalize(viewVector);

                output.texcoord2.w = step(0.0, dot(safeViewDir, _WorldSpaceCameraPos - objectPosition));

                float flickerAlpha = CalculateFlickerAlpha();
                float flickerSize = 1.0 - _SizeFlickering + flickerAlpha * (1.0 - (1.0 - _SizeFlickering));
                output.texcoord3.xyz = lerp(_FlickerTint, float3(1, 1, 1), flickerAlpha * flickerAlpha);
                output.texcoord3.w = _HaloSize * flickerSize * 0.5;

                return output;
            }

            PackedVaryings vert(Attributes input)
            {
                return VertexFunction(input);
            }

            float4 ClipToScreenPosition(float4 clipPos)
            {
                float4 screenPos = ComputeScreenPos(clipPos);
                float4 clipToScreenPos = screenPos / screenPos.w;
                clipToScreenPos.z = UNITY_NEAR_CLIP_VALUE >= 0
                                        ? clipToScreenPos.z
                                        : clipToScreenPos.z * 0.5 + 0.5;
                return clipToScreenPos;
            }

            float3 ScreenWorldPosition(float3 worldPos, float4 clipToScreenPos, float3 viewDirection)
            {
                if (unity_OrthoParams.w == 1)
                {
                    float sceneDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(clipToScreenPos.xy);

                    #ifdef UNITY_REVERSED_Z
                    float normalizedDepth = 1.0 - sceneDepth;
                    #else
                    float normalizedDepth = sceneDepth;
                    #endif

                    float interpolatedDepth = lerp(_ProjectionParams.y, _ProjectionParams.z, normalizedDepth);
                    float3 worldToViewPos = mul(UNITY_MATRIX_V, float4(worldPos, 1)).xyz;
                    float3 reconstructedViewPos = float3(worldToViewPos.x, worldToViewPos.y, -interpolatedDepth);
                    return mul(UNITY_MATRIX_I_V, float4(reconstructedViewPos, 1.0)).xyz;
                }
                else
                {
                    float linearDepth
                        = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(clipToScreenPos.xy), _ZBufferParams);

                    float4x4 worldToObjMatrix = GetWorldToObjectMatrix();

                    // (world->obj) x (view->world) = (view->obj)
                    float4x4 viewToObjMatrix = mul(worldToObjMatrix, UNITY_MATRIX_I_V);

                    float4x4 objToWorldMatrix = GetObjectToWorldMatrix();
                    float3 zAxisDirection = transpose(viewToObjMatrix)[2].xyz;


                    float3 objToWorldDir = mul(objToWorldMatrix, float4(zAxisDirection, 0.0)).xyz;
                    float viewObjDot = dot(viewDirection, -objToWorldDir);

                    return linearDepth * (viewDirection / viewObjDot) + _WorldSpaceCameraPos;
                }
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

            float2 WorldToScreen(float3 pos)
            {
                float4 wts = ComputeScreenPos(TransformWorldToHClip(pos));
                float3 wts_NDC = wts.xyz / wts.w;
                return wts_NDC.xy;
            }

            float GetMaxScale()
            {
                float4x4 objToWorldMatrix = GetObjectToWorldMatrix();
                float3 objScale = float3(
                    length(objToWorldMatrix[0].xyz),
                    length(objToWorldMatrix[1].xyz),
                    length(objToWorldMatrix[2].xyz)
                );
                return max(max(objScale.x, objScale.y), objScale.z);
            }

            float CalculateNoise(float3 worldNormal, float3 worldPos)
            {
                #ifdef _NOISE_ON

                float3 normalPow = pow(abs(worldNormal), 3);
                float normalSum = normalPow.x + normalPow.y + normalPow.z;
                float3 saturateNorm = saturate(normalPow) / normalSum;

                float3 noiseUV = worldPos * 0.1 * _NoiseScale;

                float2 uv1 = lerp(noiseUV.xz, noiseUV.yz * 0.9,
                                      round((1.0 - saturateNorm.x) * saturateNorm.x * saturateNorm.x));

                float2 uv2 = lerp(uv1, noiseUV.xy * 0.94,
                                      round(saturateNorm.z  * (saturateNorm.z * (1.0 - saturateNorm.z))));

                float noiseTime = _TimeParameters.x * ((_NoiseMovement + _RandomOffset * 0.1) * 0.2);
                float noisePhase = noiseTime + _RandomOffset * PI;

                float4 noiseSampleA = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,
                    (uv2 + (noisePhase * float2(1.02,0.87))));

                float4 noiseSampleB = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,
                    (uv2 * 0.7 + (noisePhase * float2(-0.72 ,-0.67))));

                #if defined( _TEXTUREPACKING_RED )
                float noiseSampleValue = noiseSample2.r;
                float noiseValue1 = noiseSample1.r;
                #elif defined( _TEXTUREPACKING_REDXGREEN )
                float noiseSampleValue = noiseSample2.r;
                float noiseValue1 = noiseSample1.g;
                #elif defined( _TEXTUREPACKING_ALPHA )
                float noiseSampleValue = noiseSample2.a;
                float noiseValue1 = noiseSample1.a;
                #else
                float noiseSampleValue = noiseSampleB.r;
                float noiseValue1 = noiseSampleA.r;
                #endif

                return 1.0 + (noiseValue1 * noiseSampleValue * _Noisiness - _Noisiness * 0.2);
                #else
                return 1.0;
                #endif
            }

            float ComputeLocalSilhouette(float3 localPos, float maxScale, float3 flickerAlpha)
            {
                float flickerMagnitude = 1.0 - _SizeFlickering + flickerAlpha * (1.0 - (1.0 - _SizeFlickering));
                return saturate(1.0 - length(localPos) / (maxScale * flickerMagnitude * 0.45));
            }

            float CalculateGradientMask(float localSilhouette, float noiseFactor)
            {
                float lightSoftness = (1.0 - _LightSoftness * 1.1) * 0.5;
                float smoothStepValue
                    = smoothstep(lightSoftness, 1.0 - lightSoftness, localSilhouette * (localSilhouette + noiseFactor));
                float brightnessBoost = saturate(pow(localSilhouette, 30.0));
                float brightnessSum = smoothStepValue + brightnessBoost;
                float lightPosterize = 256.0 / _LightPosterize;
                float posterizedBrightness = saturate(floor(brightnessSum * lightPosterize) / lightPosterize);
                return smoothStepValue * (_LightPosterize <= 0.0 ? brightnessSum : posterizedBrightness);
            }

            float CalculateLightMask(float gradientMask, float3 lightDir, float3 worldNormal, float noiseFactor)
            {
                float inverseGradient = 1.0 - gradientMask;
                float posterization = 256.0 / inverseGradient;
                float lightDotNormal = dot(lightDir, worldNormal);
                float smoothLight = smoothstep(0.0, _ShadingSoftness, saturate(lightDotNormal * noiseFactor));
                float posterizedLight = saturate(floor(smoothLight * posterization) / posterization);
                return saturate((inverseGradient <= 0.0 ? smoothLight : posterizedLight) + _ShadingBlend);
            }

            half CalculateLightIntensity(float disFromCenter, float noiseFactor, float3 lightDir, float3 worldNormal)
            {
                float lightSoftness = (1.0 - _LightSoftness * 1.1) * 0.5;
                float smoothStepValue
                    = smoothstep(lightSoftness, 1.0 - lightSoftness, disFromCenter * (disFromCenter + noiseFactor));
                float brightnessBoost = saturate(pow(disFromCenter, 30.0));
                float brightnessSum = smoothStepValue + brightnessBoost;
                float lightPosterize = 256.0 / _LightPosterize;
                float posterizedBrightness = saturate(floor(brightnessSum * lightPosterize) / lightPosterize);
                float gradientMask = smoothStepValue * (_LightPosterize <= 0.0 ? brightnessSum : posterizedBrightness);
                float inverseGradient = 1.0 - gradientMask;
                float posterization = 256.0 / inverseGradient;
                float lightDotNormal = dot(lightDir, worldNormal);
                float smoothLight = smoothstep(0.0, _ShadingSoftness, saturate(lightDotNormal * noiseFactor));
                float posterizedLight = saturate(floor(smoothLight * posterization) / posterization);
                float lightMask = saturate((inverseGradient <= 0.0 ? smoothLight : posterizedLight) + _ShadingBlend);
                float surfaceMask = step(0.01, disFromCenter);

                return gradientMask * lightMask * surfaceMask;
            }

            float3 CalculateSpecLight(float3 viewDirection, float3 lightDir, float3 worldNormal, float lightIntensity)
            {
                #ifdef _SPECULARHIGHLIGHT_ON
                float LdotN = dot(normalize(viewDirection + lightDir), worldNormal * float3(1, 0.99, 1));
                float specFactor = pow(saturate(LdotN) , _SpecPower) * _SpecIntensity * lightIntensity;
                return _SpecularColor.rgb * specFactor;
                #else
                return 0.0;
                #endif
            }

            float3 ComputeHaloColor(PackedVaryings input, float3 objectPos, float4 clipToScreenPos, float3 worldPos,
                float noiseFactor)
            {
                #ifdef _Halo_ON
                float haloSize = input.texcoord3.w;
                float2 objWorldToScreenUV = WorldToScreen(objectPos);
                float2 screenAspectRatio = float2(_ScreenParams.x / _ScreenParams.y, 1.0);
                float2 screenPosDelta = objWorldToScreenUV.xy - clipToScreenPos.xy;
                float screenDistance = length(screenPosDelta * screenAspectRatio * input.texcoord2.z);
                float haloMask = (1.0 - smoothstep(0.0, haloSize, screenDistance)) * input.texcoord2.w;
                float scaleFactor = 256.0 / _HaloPosterize;

                float posterizedHalo = saturate(floor(haloMask * scaleFactor) / scaleFactor);

                float intensity = lerp(posterizedHalo, haloMask, step(_HaloPosterize, 0.0));
                float2 inverseUV = (1.0 - intensity).xx;

                float distanceToCamera = distance(worldPos, _WorldSpaceCameraPos);
                float depthFadeFactor = saturate(distanceToCamera - input.texcoord2.x);
                float penetrationMask = saturate(pow(depthFadeFactor, _HaloDepthFade));

                float4 colorSample = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, inverseUV) * _HaloTint;
                return colorSample.rgb * colorSample.a * haloMask * penetrationMask * intensity * noiseFactor;
                #else
                return float3(0, 0, 0);
                #endif
            }

            half3 CalculateAccurateColor(float3 lightColor, half4 clipToScreenPos, half gradientMask)
            {
                #ifdef _ACCURATECOLORS_ON
                float4 pixelScreenColor = float4(SHADERGRAPH_SAMPLE_SCENE_COLOR(clipToScreenPos.xy), 1.0);
                float3 accuratePower = abs(pixelScreenColor.rgb);
                return lightColor * 4 * pow(accuratePower, saturate(0.8 - 0.4 * gradientMask));
                #else
                return lightColor;
                #endif
            }

            half4 frag(PackedVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float4 clipToScreenPos = ClipToScreenPosition(input.clipPosV);

                float3 viewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);

                float3 screenToWorldPos = ScreenWorldPosition(input.positionWS, clipToScreenPos, viewDirection);

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);

                float3 localPos = screenToWorldPos - objectPosition;

                float4 normalSample = NormalTex(clipToScreenPos.xy);
                float3 worldNormal = normalSample.xyz;

                float noiseFactor = CalculateNoise(worldNormal, screenToWorldPos);

                float maxScale = GetMaxScale();

                float3 flickerAlpha = CalculateFlickerAlpha();

                float localSilhouette = ComputeLocalSilhouette(localPos, maxScale, flickerAlpha);

                float3 lightDir = normalize(-localPos);

                float gradientMask = CalculateGradientMask(localSilhouette, noiseFactor);

                float lightMask = CalculateLightMask(gradientMask, lightDir, worldNormal, noiseFactor);
                
                float surfaceMask = step(0.01, localSilhouette);

                half lightIntensity = gradientMask * lightMask * surfaceMask;

                float3 specColor = CalculateSpecLight(viewDirection, lightDir, worldNormal, lightIntensity);

                float4 sample = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, 1 - lightIntensity)
                    * _LightTint * input.color;

                float3 lightColor = sample.rgb * (sample.a * lightIntensity * 0.1) + specColor;

                float3 accurateColor = CalculateAccurateColor(lightColor, clipToScreenPos, gradientMask);

                float3 haloColor = ComputeHaloColor(input, objectPosition, clipToScreenPos, screenToWorldPos,
                    noiseFactor);

                float distanceFade = input.texcoord2.y;

                float3 finalColor = (accurateColor + haloColor) * input.texcoord3.xyz * distanceFade * flickerAlpha;
                
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/InternalErrorShader"

}