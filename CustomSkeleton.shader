Shader "Spine/Skeleton"
{
    Properties
    {
        _Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
        [NoScaleOffset] _MainTex ("Main Texture", 2D) = "black" {}
        [Toggle(_STRAIGHT_ALPHA_INPUT)] _StraightAlphaInput("Straight Alpha Texture", Int) = 0
        [HideInInspector] _StencilRef("Stencil Reference", Float) = 1.0
        [HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Float) = 8 // Set to Always as default

        // Outline properties are drawn via custom editor.
        [HideInInspector] _OutlineWidth("Outline Width", Range(0,8)) = 3.0
        [HideInInspector] _OutlineColor("Outline Color", Color) = (1,1,0,1)
        [HideInInspector] _OutlineReferenceTexWidth("Reference Texture Width", Int) = 1024
        [HideInInspector] _ThresholdEnd("Outline Threshold", Range(0,1)) = 0.25
        [HideInInspector] _OutlineSmoothness("Outline Smoothness", Range(0,1)) = 1.0
        [HideInInspector][MaterialToggle(_USE8NEIGHBOURHOOD_ON)] _Use8Neighbourhood("Sample 8 Neighbours", Float) = 1
        [HideInInspector] _OutlineOpaqueAlpha("Opaque Alpha", Range(0,1)) = 1.0
        [HideInInspector] _OutlineMipLevel("Outline Mip Level", Range(0,3)) = 0

        _OutlineThreshold("Outline Threshold", Range(0, 1)) = 0.5
        _OutlineSmoothFactor ("Outline Smooth Factor", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }

        Fog
        {
            Mode Off
        }
        Cull Off
        ZWrite Off
        Blend One OneMinusSrcAlpha
        Lighting Off

        Stencil
        {
            Ref[_StencilRef]
            Comp[_StencilComp]
            Pass Keep
        }

        Pass
        {
            Name "Normal"

            HLSLPROGRAM
            #pragma shader_feature _ _STRAIGHT_ALPHA_INPUT
            #pragma vertex vert
            #pragma fragment frag
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            sampler2D _MainTex;

            float _OutlineThreshold;
            float _OutlineSmoothFactor;

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD1;
            };

            inline half3 GammaToLinearSpace(half3 sRGB)
            {
                return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);
            }

            inline half4 PMAGammaToTargetSpace(half4 gammaPMAColor)
            {
                #if UNITY_COLORSPACE_GAMMA
	return gammaPMAColor;
                #else
                return gammaPMAColor.a == 0
                           ? half4(GammaToLinearSpace(gammaPMAColor.rgb), gammaPMAColor.a)
                           : half4(GammaToLinearSpace(gammaPMAColor.rgb / gammaPMAColor.a) * gammaPMAColor.a,
                                   gammaPMAColor.a);
                #endif
            }

            VertexOutput vert(VertexInput input)
            {
                VertexOutput output;
                output.pos = TransformObjectToHClip(input.vertex.xyz);
                output.uv = input.uv;
                output.vertexColor = PMAGammaToTargetSpace(input.vertexColor);
                output.normal = TransformObjectToWorldNormal(input.normal);
                output.worldPos = TransformObjectToWorld(input.vertex.xyz);
                return output;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, i.uv);
                
                #if defined(_STRAIGHT_ALPHA_INPUT)
                texColor.rgb *= texColor.a;
                #endif
                
                float3 normalWS = normalize(i.normal);
                Light mainLight = GetMainLight();
                
                // Directional Light 조명 계산
                float ndl = max(0, dot(normalWS, mainLight.direction));
                float3 diffuseColor = mainLight.color * ndl;
                
                // 추가적인 라이트 조명 계산
                int lightCount = GetAdditionalLightsCount();
                for (int j = 0; j < lightCount; j++)
                {
                    Light additionalLight = GetAdditionalLight(j, i.worldPos);
                    float ndlAdd = max(0, dot(normalWS, additionalLight.direction));
                    diffuseColor += additionalLight.color * ndlAdd * additionalLight.distanceAttenuation *
                        additionalLight.shadowAttenuation;
                }
                
                float lightIntensity = mainLight.shadowAttenuation + dot(normalWS, mainLight.direction) * 0.5 + 0.5;
                // 메인 라이트 강도
                for (int j = 0; j < lightCount; j++)
                {
                    Light additionalLight = GetAdditionalLight(j, i.worldPos);
                    lightIntensity += additionalLight.shadowAttenuation * (dot(normalWS, additionalLight.direction) *
                        0.5 + 0.5) * additionalLight.distanceAttenuation; // 추가 라이트 강도
                }
                lightIntensity = saturate(lightIntensity);

                float alphaFactor = 1.0;
                if (texColor.a < _OutlineThreshold)
                {
                    alphaFactor = saturate(texColor.a / _OutlineThreshold + lightIntensity * _OutlineSmoothFactor);
                }

                float3 finalColor = (mainLight.color * mainLight.shadowAttenuation + diffuseColor) * (texColor.rgb * i.
                                                         vertexColor.rgb);
                
                return float4(finalColor, texColor.a * i.vertexColor.a * alphaFactor);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Caster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            ZWrite On
            ZTest LEqual

            Fog
            {
                Mode Off
            }
            Cull Off
            Lighting Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            fixed _Cutoff;

            struct VertexOutput
            {
                V2F_SHADOW_CASTER;
                float4 uvAndAlpha : TEXCOORD1;
            };

            VertexOutput vert(appdata_base v, float4 vertexColor : COLOR)
            {
                VertexOutput o;
                o.uvAndAlpha = v.texcoord;
                o.uvAndAlpha.a = vertexColor.a;
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                fixed4 texcol = tex2D(_MainTex, i.uvAndAlpha.xy);
                clip(texcol.a * i.uvAndAlpha.a - _Cutoff);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDHLSL
        }
    }
    CustomEditor "SpineShaderWithOutlineGUI"
}
