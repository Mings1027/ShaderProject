Shader "Custom/Refraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _IOR ("IOR", Range(-1, 1)) = 0
        _RefractionStrength ("Refraction Strength", Range(0, 0.5)) = 0.1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" "LightMode"="UniversalForward"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float3 tangentWS : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)
                float _IOR;
                float _RefractionStrength;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * input.tangentOS.w;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // === View Direction Node ===
                // Space: World, Normalize: checked
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                
                // === Normal Vector Node ===  
                // Space: World, Normalize: checked
                float3 worldNormal = normalize(input.normalWS);
                
                // === Refract (Custom Function) Node ===
                // View(3) -> viewDirection
                // Normal(3) -> worldNormal  
                // IOR(1) -> _IOR
                float3 refractionResult = refract(-viewDirection, worldNormal, _IOR);
                
                // === Transform Node ===
                // From: World, To: Tangent, Type: Direction
                // In(3) -> refractionResult
                
                // Tangent space transformation matrix 구성
                float3x3 tangentTransform_World = float3x3(
                    normalize(input.tangentWS),
                    normalize(input.bitangentWS), 
                    normalize(input.normalWS)
                );
                
                // World to Tangent 변환
                float3 transformOut = mul(tangentTransform_World, refractionResult);
                
                // === Screen Position Node ===
                // Mode: Default
                float4 screenPosNDC = input.screenPos / input.screenPos.w;
                float4 screenPosOut = float4(screenPosNDC.xy, 0, 0);
                
                // === Add Node ===
                // A(3) -> transformOut (only xy used)
                // B(3) -> screenPosOut (only xy used)
                float4 addResult = screenPosOut + float4(transformOut.xy, 0, 0);
                
                // === Scene Color Node ===
                // UV(4) -> addResult
                float3 sceneColor = SHADERGRAPH_SAMPLE_SCENE_COLOR(addResult);
                
                // === Output ===
                // Base Color(3) -> sceneColor
                return half4(sceneColor, 1.0);
            }
            ENDHLSL
        }
    }
}