Shader "Custom/ToonShader"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _ToonRampSmoothness ("Toon Ramp Smoothness", Range(0, 0.5)) = 0.25
        _MainToonOffset ("Main Toon Offset", Range(0, 1)) = 0.5
        _ToonRampTinting ("Toon Ramp Tinting", Color) = (1, 1, 1, 1)
        _Ambient ("Ambient", Range(-1, 1)) = 0.3

        [Header(Rim)]
        _RimPower ("Rim Power", Range(0, 10)) = 2
        _RimBrightness ("Rim Brightness", Range(0, 5)) = 3
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)

        [Header(Additional Light)]
        _AdditionalToonOffset ("Additional Toon Offset", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "LightMode"="UniversalForward"
        }

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _Color;
                half _ToonRampSmoothness;
                half _MainToonOffset;
                half3 _ToonRampTinting;
                half _Ambient;

                half _RimPower;
                half _RimBrightness;
                half4 _RimColor;

                half _AdditionalToonOffset;
            CBUFFER_END

            #include "ToonShaderPass.hlsl"

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                output.worldPos = TransformObjectToWorld(input.positionOS.xyz);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half2 baseMapUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseMapUV) * _Color;

                half4 shadowCoord = TransformWorldToShadowCoord(input.worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                half3 lightDir = normalize(mainLight.direction);

                half3 toonLighting = ToonLight(input.normalWS, lightDir, mainLight, _ToonRampSmoothness,
                                   _MainToonOffset, _ToonRampTinting, _Ambient);
                half3 additionalLight = ToonAdditionalLight(input.worldPos, input.normalWS, _ToonRampSmoothness,
                                    _AdditionalToonOffset);
                half3 toonRim = ToonRimLight(input.worldPos, input.normalWS, lightDir, _RimPower,
                    mainLight.shadowAttenuation) * _RimColor;
                toonRim *= _RimBrightness;

                half3 lightResult = toonLighting + additionalLight;
                half3 finalColor = (baseColor + toonRim) * lightResult;
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
        // Shadow Caster Pass
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                // Shadow Map에 반영하기 위해 LightMode를 ShadowCaster로 해주어야함 
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _ShadowBias;

            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;

                // normal bias is negative since we want to apply an inset normal offset
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));

                #if UNITY_REVERSED_Z
                output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/Unlit"
}