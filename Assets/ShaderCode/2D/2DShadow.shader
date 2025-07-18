Shader "Unlit/Simple2DShadow"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _ShadowColor ("Shadow Color", Color) = (0,0,0,0.5)
        _ShadowOffset ("Shadow Offset", Vector) = (-0.1, -0.1, 0, 0)
        _PixelSnap ("Pixel Snap", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        LOD 100

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile _ PIXELSNAP_ON

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _ShadowColor;
            float4 _ShadowOffset;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                // 그림자 버텍스 계산
                v2f shadowOUT;
                shadowOUT.vertex = UnityObjectToClipPos(IN.vertex + _ShadowOffset);
                shadowOUT.texcoord = IN.texcoord;
                shadowOUT.color = IN.color * _ShadowColor;

                // 원본 버텍스 계산
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color * _Color;

                #ifdef PIXELSNAP_ON
                OUT.vertex = UnityPixelSnap (OUT.vertex);
                shadowOUT.vertex = UnityPixelSnap (shadowOUT.vertex);
                #endif

                // 이 셰이더는 두 개의 패스를 하나로 합친 방식입니다.
                // 먼저 그림자를 그리고, 그 위에 원본을 그립니다.
                // 하지만 CG/HLSL에서는 한 번에 하나의 v2f만 반환할 수 있으므로,
                // 이 방식 대신 두 개의 Pass를 사용하는 것이 더 일반적입니다.
                // 여기서는 설명을 위해 하나의 Pass로 개념을 보여드립니다.
                // 실제로는 아래 frag 함수에서 두 색상을 혼합하는 방식으로 처리합니다.
                
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_TARGET
            {
                // 그림자 텍스처 샘플링
                fixed4 shadowColor = tex2D(_MainTex, IN.texcoord - _ShadowOffset.xy) * _ShadowColor;
                shadowColor.a *= _Color.a; // 원본의 알파값을 그림자에도 반영

                // 원본 텍스처 샘플링
                fixed4 originalColor = tex2D(_MainTex, IN.texcoord) * _Color;

                // 원본 이미지가 그려질 픽셀에서는 원본 색상을, 그 외 그림자 영역에서는 그림자 색상을 출력
                // 알파 블렌딩을 통해 두 색상을 합칩니다.
                fixed4 finalColor = originalColor;
                // 원본의 알파가 거의 없는(투명한) 부분에만 그림자를 더합니다.
                finalColor = lerp(shadowColor, finalColor, originalColor.a);
                
                // 더 간단한 방법: 두 색상을 그냥 더하기 (결과가 다를 수 있음)
                // finalColor = originalColor + shadowColor * (1.0 - originalColor.a);

                finalColor.rgb *= finalColor.a;

                return finalColor;
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}