Shader "Custom/SimpleFakeLight2D"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [NoScaleOffset][SingleLineTexture]_GradientTexture("Gradient Texture", 2D) = "white" {}
        [HDR]_LightTint("Light Tint", Color) = (1, 1, 1, 1)
        _LightSoftness("Light Softness", Range(0 ,1)) = 1
        [IntRange]_LightPosterize("Light Posterize", Range(0 ,128)) = 1

        _RadiusFactor("Radius Factor", Range(0.01, 1.0)) = 0.5

        [Enum(Default,0, Off,1, On,2)][Space(5)]_DepthWrite("Depth Write", Float) = 0

        [Space(15)][KeywordEnum(Additive,Contrast,Negative)] _BlendMode("Blend Mode", Float) = 0
        [HideInInspector][IntRange]_SrcBlend("SrcBlend", Range(0 ,12)) = 1
        [HideInInspector][IntRange]_DstBlend("DstBlend", Range(0 ,12)) = 1

    }

    SubShader
    {
        LOD 0

        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "UniversalMaterialType"="Unlit"
        }

        AlphaToMask Off

        Pass
        {
            Name "Forward"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            Blend [_SrcBlend] [_DstBlend]
            Offset 0 , 0
            ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile_instancing

            #pragma shader_feature_local _BLENDMODE_ADDITIVE _BLENDMODE_CONTRAST _BLENDMODE_NEGATIVE

            #pragma vertex SpriteVert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _LightTint;
                float _LightSoftness;
                float _LightPosterize;
                float _RadiusFactor;

                float _DepthWrite;
                float _SrcBlend;
                float _DstBlend;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_GradientTexture);
            SAMPLER(sampler_GradientTexture);

            Varyings SpriteVert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.color = input.color;
                output.uv = input.uv;

                return output;
            }

            float CalculateGradientMask(float uvDistanceNormalized)
            {
                float spriteCenterInfluence = saturate(1.0 - uvDistanceNormalized);
                float localSilhouette = spriteCenterInfluence;

                float lightSoftness = (1.0 - _LightSoftness * 1.1) * 0.5;
                float smoothStepValue
                    = smoothstep(lightSoftness, 1.0 - lightSoftness, localSilhouette);

                float brightnessBoost = saturate(pow(localSilhouette, 30.0));

                float brightnessSum = smoothStepValue + brightnessBoost;

                float lightPosterize = _LightPosterize > 0.1 ? 256.0 / _LightPosterize : 256.0;

                float posterizedBrightness = saturate(floor(brightnessSum * lightPosterize) / lightPosterize);

                float finalGradientMask = smoothStepValue * lerp(brightnessSum, posterizedBrightness,
                                                                 step(1.0, _LightPosterize));

                return finalGradientMask;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv_center_vec = input.uv - float2(0.5, 0.5);
                float uv_distance = length(uv_center_vec);

                float uv_distance_normalized = uv_distance / _RadiusFactor;

                float lightIntensity = CalculateGradientMask(uv_distance_normalized);

                float4 sampleTexture = SAMPLE_TEXTURE2D(_GradientTexture, sampler_GradientTexture, 1 - lightIntensity);

                float3 lightColor = sampleTexture.rgb * sampleTexture.a * _LightTint.rgb * input.color.rgb *
                    lightIntensity;

                half3 finalColor = lightColor;
                #if defined(_BLENDMODE_ADDITIVE)

                #elif defined(_BLENDMODE_CONTRAST)

                #elif defined(_BLENDMODE_NEGATIVE)
                finalColor = 1.0 - saturate(finalColor);
                #endif

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
    CustomEditor "ShaderCode.FPL.FakeLight2DEditor"

    Fallback "Hidden/InternalErrorShader"
}