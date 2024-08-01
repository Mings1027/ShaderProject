Shader "Custom/TestShader"
{
    Properties
    { 
         _MainTex("Texture", 2D) = "white" {}
         _MainTex2("Texture2", 2D) = "white" {}
         _LerpControlTex("LerpTex", 2D) = "white" {}
         _ZeroToOne("ZeroToOne", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name  "URPUnlit"
            Tags {"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            #pragma target 4.5
            // #pragma exclude_renderers gles d3d9
            #pragma multi_compile_instancing
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainTex2_ST;
                float4 _LerpControlTex_ST;
                float _ZeroToOne;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            TEXTURE2D(_MainTex2);
            TEXTURE2D(_LerpControlTex);
            
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_MainTex2);
            SAMPLER(sampler_LerpControlTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            }; 
            

            Varyings vert(Attributes input)
            {
                Varyings output;

                float4 positionOS = input.positionOS;
                float3 positionWS = TransformObjectToWorld(positionOS.xyz);
                float4 positionCS = TransformWorldToHClip(positionWS);

                output.positionCS = positionCS;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex2Color = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, TRANSFORM_TEX(input.uv, _MainTex2));
                float4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(input.uv, _MainTex) + mainTex2Color.r * 0.5f);
                return mainTex2Color;
            }
            
            ENDHLSL
        }
    }
}