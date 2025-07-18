Shader "Custom/CenterToEdgeLight"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Multiplier ("Intensity Multiplier", Range(0.1, 2.0)) = 1.0
        _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionsOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Multiplier;
            float4 _TintColor;

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionsOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv_center = float2(0.5, 0.5);
                float2 direction_from_center = input.uv - uv_center;
                float distance_from_center = length(direction_from_center);

                // 광선의 강도를 거리와 색상으로 조절
                float intensity = saturate(1.0 - distance_from_center * _Multiplier);

                // 텍스처 색상 샘플링 및 광선 효과 추가
                half4 texColor = tex2D(_MainTex, input.uv);
                texColor.rgb *= _TintColor.rgb * intensity;

                return texColor;
            }
            ENDHLSL
        }
    }
}
