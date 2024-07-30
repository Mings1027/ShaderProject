Shader "Custom/TestShader"
{
    Properties
    {

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings vertex(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 fragment() : SV_Target
            {
                half4 customColor = half4(0.4, 0.2, 0.1, 1);
                half2 rg = customColor.rg;
                half2 br = customColor.br;

                half4 final = half4(rg,br);
                return final;
            }

            ENDHLSL

        }
    }
}