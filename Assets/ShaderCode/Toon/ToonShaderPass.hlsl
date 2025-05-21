#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half3 ToonLight(half3 normal, half3 lightDir, Light mainLight, half toonRampSmoothness, half toonRampOffset,
                half3 toonRampTinting, half ambient)
{
    half NdotL = dot(normal, lightDir) * 0.5 + 0.5;
    half toonRamp = smoothstep(toonRampOffset, toonRampOffset + toonRampSmoothness, NdotL);
    toonRamp *= mainLight.shadowAttenuation;
    half3 lighting = mainLight.color * (toonRamp + toonRampTinting) + ambient;

    return lighting;
}

half3 ToonAdditionalLight(half3 worldPos, half3 normal, half toonRampSmoothness, half toonRampOffset)
{
    uint pixelLightCount = GetAdditionalLightsCount();
    InputData inputData;

    float4 positionsCS = TransformWorldToHClip(worldPos);
    float3 ndc = positionsCS.xyz / positionsCS.w;
    float2 screenUV = half2(ndc.x, ndc.y) * 0.5 + 0.5;

    #if UNITY_UV_STARTS_AT_TOP
    screenUV.y = 1.0 - screenUV.y;
    #endif

    inputData.normalizedScreenSpaceUV = screenUV;
    inputData.positionWS = worldPos;

    half4 shadowMask = CalculateShadowMask(inputData);
    half3 diffuseColor = 0;

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, worldPos, shadowMask);

        #ifdef _LIGHT_LAYERS
    uint meshRenderingLayers = GetMeshRenderingLayer();
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
        {
            half3 color = dot(normal, light.direction);
            color = smoothstep(toonRampOffset, toonRampOffset + toonRampSmoothness, color);
            color *= light.color * light.distanceAttenuation * light.shadowAttenuation;

            diffuseColor += color;
        }
    LIGHT_LOOP_END
    return diffuseColor;
}

half FresnelEffect(float3 Normal, float3 ViewDir, float Power)
{
    return pow(1.0 - saturate(dot(normalize(Normal), normalize(ViewDir))), Power);
}

half3 ToonRimLight(half3 worldPos, half3 normal, half3 lightDir, half rimPower, half shadowAttenuation)
{
    half3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
    half rim = FresnelEffect(normal, viewDir, rimPower) * shadowAttenuation;
    half NdotL = dot(normal, lightDir);
    return step(0.5, NdotL * rim);
}
