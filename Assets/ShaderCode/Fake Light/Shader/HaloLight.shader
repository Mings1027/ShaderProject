Shader "Custom/HaloLight"
{
    Properties
    {
        [NoScaleOffset][SingleLineTexture]_GradientTexture("Gradient Texture", 2D) = "white" {}
        [HDR]_HaloTint("Halo Tint", Color) = (1, 1, 1, 1)
        _HaloSize("Halo Size", Range(0 ,5)) = 0
        [IntRange]_HaloPosterize("Halo Posterize", Range(0 ,128)) = 0
        _HaloDepthFade("Halo Depth Fade", Range(0.1 ,2)) = 0.5

        [Enum(Default,0 ,Off,1 ,On,2)][Space(5)]_DepthWrite("Depth Write", Float) = 0
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
            #define REQUIRE_DEPTH_TEXTURE 1

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                float4 clipPosV : TEXCOORD0;
                float3 positionWS : TEXCOORD1;

                float4 texcoord2 : TEXCOORD2;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _HaloTint;
                float _HaloSize;
                float _HaloPosterize;
                float _HaloDepthFade;

                float _DepthWrite;
                float _SrcBlend;
                float _DstBlend;
            CBUFFER_END

            TEXTURE2D(_GradientTexture);
            SAMPLER(sampler_GradientTexture);

            float2 WorldToScreen(float3 pos)
            {
                float4 wts = ComputeScreenPos(TransformWorldToHClip(pos));
                float3 wts_NDC = wts.xyz / wts.w;
                return wts_NDC.xy;
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
                PackedVaryings output = (PackedVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);
                output.texcoord2.x = distance(_WorldSpaceCameraPos, objectPosition);
                output.texcoord2.y = _HaloSize * 0.5;
                output.texcoord2.z = CalculateDepthScale(objectPosition);
                
                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                float3 viewVector = _WorldSpaceCameraPos.xyz - worldPos;
                float3 safeViewDir = SafeNormalize(viewVector);

                output.texcoord2.w = step(0.0, dot(safeViewDir, _WorldSpaceCameraPos - objectPosition));

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.clipPosV = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                return output;
            }

            PackedVaryings vert(Attributes input)
            {
                return VertexFunction(input);
            }

            float4 NormalizeScreenPosition(float4 clipPos)
            {
                float4 screenPos = ComputeScreenPos(clipPos);
                float4 normalizedScreenPos = screenPos / screenPos.w;
                normalizedScreenPos.z = UNITY_NEAR_CLIP_VALUE >= 0
                                            ? normalizedScreenPos.z
                                            : normalizedScreenPos.z * 0.5 + 0.5;
                return normalizedScreenPos;
            }

            float3 ReconstructWorldPosition(float3 worldPos, float4 normalizedScreenPos)
            {
                if (unity_OrthoParams.w == 1)
                {
                    float sceneDepth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(normalizedScreenPos.xy);

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
                        = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(normalizedScreenPos.xy), _ZBufferParams);

                    float4x4 worldToObjMatrix = GetWorldToObjectMatrix();

                    // (world->obj) x (view->world) = (view->obj)
                    float4x4 viewToObjMatrix = mul(worldToObjMatrix, UNITY_MATRIX_I_V);

                    float4x4 objToWorldMatrix = GetObjectToWorldMatrix();
                    float3 zAxisDirection = transpose(viewToObjMatrix)[2].xyz;

                    float3 viewDirection = GetWorldSpaceNormalizeViewDir(worldPos);
                    float3 objToWorldDir = mul(objToWorldMatrix, float4(zAxisDirection, 0.0)).xyz;
                    float viewObjDot = dot(viewDirection, -objToWorldDir);

                    return linearDepth * (viewDirection / viewObjDot) + _WorldSpaceCameraPos;
                }
            }

            float ComputeHaloMask(PackedVaryings input, float4 normalizedScreenPos)
            {
                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);
                float haloSize = input.texcoord2.y;
                float2 objWorldToScreenUV = WorldToScreen(objectPosition);
                float2 screenAspectRatio = float2(_ScreenParams.x / _ScreenParams.y, 1.0);
                float2 screenPosDelta = objWorldToScreenUV.xy - normalizedScreenPos.xy;
                float screenDistance = length(screenPosDelta * screenAspectRatio * input.texcoord2.z);
                float haloMask = (1.0 - smoothstep(0.0, haloSize, screenDistance)) * input.texcoord2.w;
                return haloMask;
            }

            float3 ComputeHaloColor(PackedVaryings input, float3 worldPos, float mask)
            {
                float scaleFactor = 256.0 / _HaloPosterize;
                float intensity = mask * (_HaloPosterize <= 0.0
                                              ? mask
                                              : saturate(floor(mask * scaleFactor) / scaleFactor));
                float2 inverseUV = (1.0 - intensity).xx;

                float distanceToCamera = distance(worldPos, _WorldSpaceCameraPos);
                float depthFadeFactor = saturate(distanceToCamera - input.texcoord2.x);
                float penetrationMask = saturate(pow(depthFadeFactor, _HaloDepthFade));

                float4 colorSample = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, inverseUV) * _HaloTint;
                return colorSample.rgb * (colorSample.a * mask * penetrationMask * intensity);
            }

            half4 frag(PackedVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float4 normalizedScreenPos = NormalizeScreenPosition(input.clipPosV);

                float3 reconstructedWorldPos
                    = ReconstructWorldPosition(input.positionWS, normalizedScreenPos);

                float haloMask = ComputeHaloMask(input, normalizedScreenPos);

                float3 haloColor = ComputeHaloColor(input, reconstructedWorldPos, haloMask);

                return half4(haloColor, 1);
            }
            ENDHLSL
        }


    }
    Fallback "Hidden/InternalErrorShader"

}