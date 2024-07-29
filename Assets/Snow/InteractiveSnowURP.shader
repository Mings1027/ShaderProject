Shader "Custom/Snow Interactive" 
{
    Properties
    {
        [Header(Main)]
        _Noise("Snow Noise", 2D) = "gray" {} // 눈 노이즈 텍스처
        _NoiseScale("Noise Scale", Range(0,2)) = 0.1 // 노이즈 텍스처의 스케일
        _NoiseWeight("Noise Weight", Range(0,2)) = 0.1 // 노이즈의 가중치
        [HDR]_ShadowColor("Shadow Color", Color) = (0.5,0.5,0.5,1) // 그림자 색상

        [Space]
        [Header(Tesselation)]
        _MaxTessDistance("Max Tessellation Distance", Range(10,200)) = 50 // 최대 테셀레이션 거리
        _Tess("Tessellation", Range(1,64)) = 20 // 테셀레이션 수준

        [Space]
        [Header(Snow)]
        [HDR]_Color("Snow Color", Color) = (0.5,0.5,0.5,1) // 눈 색상
        [HDR]_PathColorIn("Snow Path Color In", Color) = (0.5,0.5,0.7,1) // 눈 경로 안쪽 색상
        [HDR]_PathColorOut("Snow Path Color Out", Color) = (0.5,0.5,0.7,1) // 눈 경로 바깥쪽 색상
        _PathBlending("Snow Path Blending", Range(0,3)) = 0.3 // 눈 경로 혼합 비율
        _MainTex("Snow Texture", 2D) = "white" {} // 눈 텍스처
        _SnowHeight("Snow Height", Range(0,2)) = 0.3 // 눈 높이
        _SnowDepth("Snow Path Depth", Range(0,10)) = 0.3 // 눈 경로 깊이
        _SnowTextureOpacity("Snow Texture Opacity", Range(0,2)) = 0.3 // 눈 텍스처 불투명도
        _SnowTextureScale("Snow Texture Scale", Range(0,2)) = 0.3 // 눈 텍스처 스케일

        [Space]
        [Header(Sparkles)]
        _SparkleScale("Sparkle Scale", Range(0,10)) = 10 // 반짝임 스케일
        _SparkCutoff("Sparkle Cutoff", Range(0,10)) = 0.8 // 반짝임 컷오프
        _SparkleNoise("Sparkle Noise", 2D) = "gray" {} // 반짝임 노이즈 텍스처

        [Space]
        [Header(Rim)]
        _RimPower("Rim Power", Range(0,20)) = 20 // 림 효과의 강도
        [HDR]_RimColor("Rim Color Snow", Color) = (0.5,0.5,0.5,1) // 림 색상
    }
    HLSLINCLUDE

    // Includes
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 핵심 HLSL 라이브러리 포함
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 조명 HLSL 라이브러리 포함
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" // 그림자 HLSL 라이브러리 포함
    #include "SnowTessellation.hlsl" // Snow Tessellation HLSL 파일 포함
    #pragma require tessellation tessHW // 테셀레이션 지원 요구
    #pragma vertex TessellationVertexProgram // 테셀레이션 버텍스 프로그램 지정
    #pragma hull hull // Hull 쉐이더 프로그램 지정
    #pragma domain domain // Domain 쉐이더 프로그램 지정
    // Keywords
    
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN // 다양한 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS // 추가적인 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile _ _SHADOWS_SOFT // 부드러운 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile_fog // 안개 효과에 대한 다중 컴파일 옵션

    ControlPoint TessellationVertexProgram(Attributes v)
    {
        ControlPoint p;
        p.vertex = v.vertex; // 버텍스 위치
        p.uv = v.uv; // UV 좌표
        p.normal = v.normal; // 노멀 벡터
        return p;
    }
    ENDHLSL

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"} // 불투명 렌더링 및 URP 파이프라인 태그

        Pass
        {
            Tags { "LightMode" = "UniversalForward" } // 포워드 렌더링 패스

            HLSLPROGRAM
            // vertex happens in snowtessellation.hlsl
            #pragma fragment frag // 프래그먼트 셰이더 지정
            #pragma target 4.0 // 셰이더 타겟 버전 설정
            
            sampler2D _MainTex, _SparkleNoise; // 주 텍스처 및 반짝임 노이즈 샘플러
            float4 _Color, _RimColor; // 눈 색상 및 림 색상
            float _RimPower; // 림 효과 강도
            float4 _PathColorIn, _PathColorOut; // 눈 경로 색상
            float _PathBlending; // 눈 경로 혼합 비율
            float _SparkleScale, _SparkCutoff; // 반짝임 스케일 및 컷오프
            float _SnowTextureOpacity, _SnowTextureScale; // 눈 텍스처 불투명도 및 스케일
            float4 _ShadowColor; // 그림자 색상

            half4 frag(Varyings IN) : SV_Target
            {
                // Effects RenderTexture Reading
                float3 worldPosition = mul(unity_ObjectToWorld, IN.vertex).xyz; // 월드 좌표 변환
                float2 uv = IN.worldPos.xz - _Position.xz; // UV 좌표 계산
                uv /= (_OrthographicCamSize * 2); // 카메라 크기로 UV 스케일 조정
                uv += 0.5; // UV 좌표 보정

                // effects texture				
                float4 effect = tex2D(_GlobalEffectRT, uv); // 이펙트 텍스처 샘플링

                // mask to prevent bleeding
                effect *=  smoothstep(0.99, 0.9, uv.x) * smoothstep(0.99, 0.9,1- uv.x); // UV 경계 마스크
                effect *=  smoothstep(0.99, 0.9, uv.y) * smoothstep(0.99, 0.9,1- uv.y); // UV 경계 마스크

                // worldspace Noise texture
                float3 topdownNoise = tex2D(_Noise, IN.worldPos.xz * _NoiseScale).rgb; // 월드 좌표 노이즈 텍스처 샘플링

                // worldspace Snow texture
                float3 snowtexture = tex2D(_MainTex, IN.worldPos.xz * _SnowTextureScale).rgb; // 월드 좌표 눈 텍스처 샘플링
                
                //lerp between snow color and snow texture
                float3 snowTex = lerp(_Color.rgb,snowtexture * _Color.rgb, _SnowTextureOpacity); // 눈 색상과 텍스처 혼합
                
                //lerp the colors using the RT effect path 
                float3 path = lerp(_PathColorOut.rgb * effect.g, _PathColorIn.rgb, saturate(effect.g * _PathBlending)); // 눈 경로 색상 혼합
                float3 mainColors = lerp(snowTex,path, saturate(effect.g)); // 주 색상 혼합

                // lighting and shadow information
                float shadow = 0; // 초기 그림자 값
                half4 shadowCoord = TransformWorldToShadowCoord(IN.worldPos); // 그림자 좌표 변환
                
                #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
                    Light mainLight = GetMainLight(shadowCoord); // 주 광원 그림자 포함
                    shadow = mainLight.shadowAttenuation; // 그림자 감쇠
                #else
                    Light mainLight = GetMainLight(); // 주 광원
                #endif

                // extra point lights support
                float3 extraLights; // 추가 광원
                int pixelLightCount = GetAdditionalLightsCount(); // 추가 광원 수
                for (int j = 0; j < pixelLightCount; ++j) 
                {
                    Light light = GetAdditionalLight(j, IN.worldPos, half4(1, 1, 1, 1)); // 추가 광원 정보
                    float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation); // 광원 감쇠
                    extraLights += attenuatedLightColor;			
                }

                float4 litMainColors = float4(mainColors,1); // 조명 적용 색상
                extraLights *= litMainColors.rgb; // 추가 조명 적용
                // add in the sparkles
                float sparklesStatic = tex2D(_SparkleNoise, IN.worldPos.xz * _SparkleScale).r; // 반짝임 노이즈 샘플링
                float cutoffSparkles = step(_SparkCutoff,sparklesStatic); // 반짝임 컷오프 적용
                litMainColors += cutoffSparkles  *saturate(1- (effect.g * 2)) * 4; // 반짝임 효과 추가
                
                // add rim light
                half rim = 1.0 - dot((IN.viewDir), IN.normal) * topdownNoise.r; // 림 라이트 계산
                litMainColors += _RimColor * pow(abs(rim), _RimPower); // 림 라이트 적용

                // ambient and mainlight colors added
                half4 extraColors;
                extraColors.rgb = litMainColors.rgb * mainLight.color.rgb * (shadow + unity_AmbientSky.rgb); // 주변광 및 주 광원 색상 추가
                extraColors.a = 1; // 불투명도 설정
                
                // colored shadows
                float3 coloredShadows = (shadow + (_ShadowColor.rgb * (1-shadow))); // 색상 그림자 계산
                litMainColors.rgb = litMainColors.rgb * mainLight.color * (coloredShadows); // 색상 그림자 적용
                // everything together
                float4 final = litMainColors + extraColors + float4(extraLights,0); // 최종 색상 계산
                // add in fog
                final.rgb = MixFog(final.rgb, IN.fogFactor); // 안개 효과 적용
                return final; // 최종 출력
            }
            ENDHLSL
        }
    }
}
