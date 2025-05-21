Shader "Custom/SimpleMatrixExample"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;

                // 로컬 위치 → 월드 위치 변환
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 월드 위치 → 클립 공간 위치 변환
                o.pos = mul(unity_MatrixVP, worldPos);

                // 노멀을 월드 공간으로 변환 (역전치 모델뷰 행렬 사용)
                float3 normalWS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                o.normalWS = normalize(normalWS);

                // 카메라 위치 (월드 공간)
                float3 camPos = _WorldSpaceCameraPos;

                // 뷰 방향 (월드 공간)
                o.viewDirWS = normalize(camPos - worldPos.xyz);

                o.uv = v.uv;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 간단한 디퓨즈 조명: 노멀과 뷰 방향 내적 (라이트 방향 대신 뷰 방향 사용)
                float ndotl = saturate(dot(i.normalWS, i.viewDirWS));

                fixed4 col = tex2D(_MainTex, i.uv) * ndotl;

                return col;
            }
            ENDCG
        }
    }
}
