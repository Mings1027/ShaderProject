Shader "Custom/TestShader"
{
    Properties
    { 
        main_tex("Texture", 2D) = "white" {}
        main_tex2("Texture2", 2D) = "white" {}
    }

    HLSLINCLUDE
    #pragma target 4.5
    #pragma vertex vert
    #pragma fragment frag
    #pragma multi_compile_instancing

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    
    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags {"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
    
            CBUFFER_START(UnityPerMaterial)
            float4 main_tex_ST;
            float4 main_tex2_ST;
            CBUFFER_END
            
            TEXTURE2D(main_tex);
            TEXTURE2D(main_tex2);
            
            SAMPLER(sampler_main_tex);
            SAMPLER(sampler_main_tex2);

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
                float4 mainTex2Color = SAMPLE_TEXTURE2D(main_tex2, sampler_main_tex2, TRANSFORM_TEX(input.uv, main_tex2));
                float4 mainTexColor = SAMPLE_TEXTURE2D(main_tex, sampler_main_tex, TRANSFORM_TEX(input.uv, main_tex) + mainTex2Color.r * 0.5f);
                return mainTex2Color;
            }
            
            ENDHLSL
        }
    }
}