Shader "Custom/SimpleFakeLight"
{
    Properties
    {
        [NoScaleOffset][SingleLineTexture]_GradientTexture("Gradient Texture", 2D) = "white" {}
        [HDR]_LightTint("Light Tint", Color) = (1, 1, 1, 1)
        _LightSoftness("Light Softness", Range(0 ,1)) = 1
        [IntRange]_LightPosterize("Light Posterize", Range(0 ,128)) = 1
        _ShadingBlend("Shading Blend", Range(0 ,1)) = 0.5
        _ShadingSoftness("Shading Softness", Range(0.01 ,1)) = 0.5
        
        [Toggle(_IS_ORTHOGRAPHIC)] _IsOrthographic("Is Orthographic", Float) = 0
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

        Pass
        {

            Name "Forward"
            Tags
            {
                "LightMode"="UniversalForwardOnly"
            }

            Blend One One
            ZTest Always
            Offset 0 , 0
            ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile_instancing

            #pragma shader_feature_local _ACCURATECOLORS_ON
            #pragma shader_feature_local _IS_ORTHOGRAPHIC

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

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

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _LightTint;
                float _LightSoftness;
                float _LightPosterize;
                float _ShadingBlend;
                float _ShadingSoftness;
            CBUFFER_END

            TEXTURE2D(_GradientTexture);
            SAMPLER(sampler_GradientTexture);
            
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
                return clipToScreenPos;
            }

            float3 ScreenToWorldPosition(float3 positionWS, float4 clipToScreenPos)
            {
                #ifdef _IS_ORTHOGRAPHIC
                float sceneDepth = SampleSceneDepth(clipToScreenPos.xy);

                #ifdef UNITY_REVERSED_Z
                float normalizedDepth = 1.0 - sceneDepth;
                #else
                    float normalizedDepth = sceneDepth;
                #endif

                float interpolatedDepth = lerp(_ProjectionParams.y, _ProjectionParams.z, normalizedDepth);
                float3 worldToViewPos = mul(UNITY_MATRIX_V, float4(positionWS, 1)).xyz;
                float3 reconstructedViewPos = float3(worldToViewPos.x, worldToViewPos.y, -interpolatedDepth);
                return mul(UNITY_MATRIX_I_V, float4(reconstructedViewPos, 1.0)).xyz;
                #else
                float linearDepth
                    = LinearEyeDepth(SampleSceneDepth(clipToScreenPos.xy), _ZBufferParams);

                float4x4 worldToObjMatrix = GetWorldToObjectMatrix();

                // (world->obj) x (view->world) = (view->obj)
                float4x4 viewToObjMatrix = mul(worldToObjMatrix, UNITY_MATRIX_I_V);

                float4x4 objToWorldMatrix = GetObjectToWorldMatrix();
                float3 zAxisDirection = transpose(viewToObjMatrix)[2].xyz;

                float3 objToWorldDir = mul(objToWorldMatrix, float4(zAxisDirection, 0.0)).xyz;

                float3 viewDirection = GetWorldSpaceNormalizeViewDir(positionWS);
                float viewObjDot = dot(viewDirection, -objToWorldDir);

                return linearDepth * (viewDirection / viewObjDot) + _WorldSpaceCameraPos;
                #endif
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

            float CalculateGradientMask(float3 localPos, float maxScale)
            {
                float localSilhouette = saturate(1.0 - length(localPos) / (maxScale * 0.45));
                float lightSoftness = (1.0 - _LightSoftness * 1.1) * 0.5;
                float smoothStepValue
                    = smoothstep(lightSoftness, 1.0 - lightSoftness,  localSilhouette);
                float brightnessBoost = saturate(pow(localSilhouette, 30.0));
                float brightnessSum = smoothStepValue + brightnessBoost;
                float lightPosterize = 256.0 / _LightPosterize;
                float posterizedBrightness = saturate(floor(brightnessSum * lightPosterize) / lightPosterize);
                return smoothStepValue * lerp(brightnessSum, posterizedBrightness, step(1.0, _LightPosterize));
            }

            half4 frag(PackedVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float4 clipToScreenPos = ClipToScreenPosition(input.clipPosV);
                
                float3 screenToWorldPos = ScreenToWorldPosition(input.positionWS, clipToScreenPos);

                float3 objectPosition = GetAbsolutePositionWS(UNITY_MATRIX_M._m03_m13_m23);

                float3 localPos = screenToWorldPos - objectPosition;

                float maxScale = GetMaxScale();
               
                float gradientMask = CalculateGradientMask(localPos, maxScale);

                half lightIntensity = gradientMask;
                
                float4 sampleTexture = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, 1 - lightIntensity)
                    * _LightTint * input.color;

                float3 lightColor = sampleTexture.rgb * sampleTexture.a * lightIntensity * 0.1;

                float3 finalColor = lightColor;

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/InternalErrorShader"

}