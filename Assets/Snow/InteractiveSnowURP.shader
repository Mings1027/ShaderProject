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
        [HDR]_SnowColor("Snow Color", Color) = (0.5, 0.5, 0.5, 1) // 눈 색상
        [HDR]_PathColorIn("Snow Path Color In", Color) = (0.5, 0.5, 0.7, 1) // 눈 경로 안쪽 색상
        [HDR]_PathColorOut("Snow Path Color Out", Color) = (0.5, 0.5, 0.7, 1) // 눈 경로 바깥쪽 색상
        _PathBlending("Snow Path Blending", Range(0,3)) = 0.3 // 눈 경로 혼합 비율
        _SnowTexture("Snow Texture", 2D) = "white" {} // 눈 텍스처
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

    #pragma vertex TessellationVertexProgram // 테셀레이션 버텍스 프로그램 지정
    #pragma hull hull // Hull 쉐이더 프로그램 지정
    #pragma domain domain // Domain 쉐이더 프로그램 지정
    #pragma fragment fragment // 프래그먼트 셰이더 지정
    #pragma target 2.0 // 셰이더 타겟 버전 설정
    
    // Keywords
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN // 다양한 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS // 추가적인 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile _ _SHADOWS_SOFT // 부드러운 그림자 모드에 대한 다중 컴파일 옵션
    #pragma multi_compile_fog // 안개 효과에 대한 다중 컴파일 옵션
    #pragma multi_compile_instancing

    #pragma require tessellation  // 테셀레이션 지원 요구

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

            half4 sample_effect_texture(float2 uv)
            {
                float4 effect = _GlobalEffectRT.Sample(sampler_GlobalEffectRT, uv);
                effect *= smoothstep(0.99, 0.9, uv.x) * smoothstep(0.99, 0.9, 1 - uv.x);
                effect *= smoothstep(0.99, 0.9, uv.y) * smoothstep(0.99, 0.9, 1 - uv.y);
                return effect;
            }
            
            float get_shadow_value(Varyings IN)
            {
                float shadow = 0;
                half4 shadowCoord = TransformWorldToShadowCoord(IN.world_pos);
                #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
                    Light mainLight = GetMainLight(shadowCoord);
                    shadow = mainLight.shadowAttenuation;
                #else
                    Light mainLight = GetMainLight();
                #endif
                return shadow;
            }
            
            float3 get_extra_lights(Varyings IN)
            {
                float3 extra_lights = float3(0, 0, 0);
                const int pixel_light_count = GetAdditionalLightsCount();
                for (int j = 0; j < pixel_light_count; ++j)
                {
                    const Light light = GetAdditionalLight(j, IN.world_pos, half4(1, 1, 1, 1));
                    const float3 attenuated_light_color = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                    extra_lights += attenuated_light_color;
                }
                return extra_lights;
            }
            
            float apply_sparkles(Varyings IN, float4 effect)
            {
                const float sparkles = _SparkleNoise.Sample(sampler_SparkleNoise, IN.world_pos.xz * _SparkleScale).r;
                const float cutoff_sparkles = step(_SparkCutoff, sparkles);
                return cutoff_sparkles * saturate(1 - effect.g * 2) * 4;
            }

            half4 apply_rim_light(Varyings IN, float3 topdown_noise)
            {
                const half rim = 1.0 - dot(IN.view_dir, IN.normal) * topdown_noise.r;
                return _RimColor * pow(abs(rim), _RimPower);
            }

            half4 compute_extra_colors(half4 litMainColors, Light mainLight, float shadow)
            {
                half4 extra_colors;
                extra_colors.rgb = litMainColors.rgb * mainLight.color.rgb * (shadow + unity_AmbientSky.rgb);
                extra_colors.a = 1;
                return extra_colors;
            }
            
            half4 fragment(Varyings IN) : SV_Target
            {
                const float2 uv = (IN.world_pos.xz - _Position.xz) / (_OrthographicCamSize * 2) + 0.5;
                float4 effect = sample_effect_texture(uv);
                const float3 topdown_noise = _Noise.Sample(sampler_Noise, IN.world_pos.xz * _NoiseScale).rgb;
                const float3 snowtexture = _SnowTexture.Sample(sampler_SnowTexture, IN.world_pos.xz * _SnowTextureScale).rgb;
                const float3 snow_tex = lerp(_SnowColor.rgb,snowtexture * _SnowColor.rgb, _SnowTextureOpacity);
                const float3 path = lerp(_PathColorOut.rgb * effect.g, _PathColorIn.rgb, saturate(effect.g * _PathBlending));
                float3 main_colors = lerp(snow_tex,path, saturate(effect.g));

                const float shadow = get_shadow_value(IN);
                const Light main_light = GetMainLight();
                
                float3 extra_lights = get_extra_lights(IN);
                float4 lit_main_colors = float4(main_colors,1);
                extra_lights *= lit_main_colors.rgb;
                lit_main_colors += apply_sparkles(IN, effect);
                lit_main_colors += apply_rim_light(IN, topdown_noise);
                const half4 extra_colors = compute_extra_colors(lit_main_colors, main_light, shadow);
                const float3 colored_shadows = shadow + _ShadowColor.rgb * (1 - shadow);
                lit_main_colors.rgb *= main_light.color * colored_shadows;
                float4 final = lit_main_colors + extra_colors + float4(extra_lights, 0);
                final.rgb = MixFog(final, IN.fogFactor);
                return final;
            }
            ENDHLSL
        }
    }
}
