// 필요한 경우 테셀레이션 지원을 정의합니다.
#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
    #define UNITY_CAN_COMPILE_TESSELLATION 1
    #define UNITY_domain domain
    #define UNITY_partitioning partitioning
    #define UNITY_outputtopology outputtopology
    #define UNITY_patchconstantfunc patchconstantfunc
    #define UNITY_outputcontrolpoints outputcontrolpoints
#endif

struct Varyings
{
    float3 world_pos : TEXCOORD1; // 월드 좌표
    float3 normal : NORMAL; // 노멀 벡터
    float4 vertex : SV_POSITION; // 버텍스 위치
    float2 uv : TEXCOORD0; // UV 좌표
    float3 view_dir : TEXCOORD3; // 뷰 방향 벡터
    float fogFactor : TEXCOORD4; // 안개 팩터
};

struct TessellationFactors
{
    float edge[3] : SV_TessFactor; // 엣지 테셀레이션 팩터
    float inside : SV_InsideTessFactor; // 내부 테셀레이션 팩터
};

struct Attributes
{
    float4 vertex : POSITION; // 버텍스 위치
    float3 normal : NORMAL; // 노멀 벡터
    float2 uv : TEXCOORD0; // UV 좌표
};

struct ControlPoint
{
    float4 vertex : INTERNALTESSPOS; // 내부 테셀레이션 위치
    float2 uv : TEXCOORD0; // UV 좌표
    float3 normal : NORMAL; // 노멀 벡터
};

uniform float3 _Position; // 위치
uniform Texture2D _GlobalEffectRT; // 글로벌 이펙트 텍스처
uniform SamplerState sampler_GlobalEffectRT;
uniform float _OrthographicCamSize; // 정사영 카메라 크기

Texture2D _Noise; // 노이즈 텍스처
SamplerState sampler_Noise;
Texture2D _SnowTexture;
SamplerState sampler_SnowTexture;
Texture2D _SparkleNoise; // 주 텍스처 및 반짝임 노이즈 샘플러
SamplerState sampler_SparkleNoise;

CBUFFER_START(UnityPerMaterial)

float _NoiseScale, _NoiseWeight; // 노이즈 스케일 값
float4 _ShadowColor; // 그림자 색상

float _MaxTessDistance; // 최대 테셀레이션 거리
float _Tess; // 테셀레이션 값

float4 _SnowColor, _PathColorIn, _PathColorOut;
float _PathBlending; // 눈 경로 혼합 비율
float _SnowHeight, _SnowDepth; // 노이즈 및 눈 관련 파라미터
float _SnowTextureOpacity, _SnowTextureScale; // 눈 텍스처 불투명도 및 스케일

float _SparkleScale, _SparkCutoff; // 반짝임 스케일 및 컷오프

float _RimPower; // 림 효과 강도
float4 _RimColor; // 눈 색상 및 림 색상

CBUFFER_END

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("patch_constant_function")]
ControlPoint hull(const InputPatch<ControlPoint, 3> patch, const uint id : SV_OutputControlPointID)
{
    return patch[id]; // 패치의 컨트롤 포인트 반환
}

TessellationFactors calc_tri_edge_tess_factors(float3 triVertexFactors)
{
    TessellationFactors tess;
    tess.edge[0] = 0.5 * (triVertexFactors.y + triVertexFactors.z); // 엣지 테셀레이션 팩터 계산
    tess.edge[1] = 0.5 * (triVertexFactors.x + triVertexFactors.z); // 엣지 테셀레이션 팩터 계산
    tess.edge[2] = 0.5 * (triVertexFactors.x + triVertexFactors.y); // 엣지 테셀레이션 팩터 계산
    tess.inside = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f; // 내부 테셀레이션 팩터 계산
    return tess; // 테셀레이션 팩터 반환
}

float calc_distance_tess_factor(const float4 vertex, const float minDist, const float maxDist, const float tess)
{
    float3 worldPosition = mul(unity_ObjectToWorld, vertex).xyz; // 월드 좌표 변환
    float dist = distance(worldPosition, _WorldSpaceCameraPos); // 카메라와의 거리 계산
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0); // 거리 기반 팩터 계산
    return f * tess; // 테셀레이션 팩터 반환
}

TessellationFactors distance_based_tess(const float4 v0, const float4 v1, const float4 v2, const float minDist, const float maxDist, const float tess)
{
    float3 f;
    f.x = calc_distance_tess_factor(v0, minDist, maxDist, tess); // 첫 번째 버텍스의 테셀레이션 팩터 계산
    f.y = calc_distance_tess_factor(v1, minDist, maxDist, tess); // 두 번째 버텍스의 테셀레이션 팩터 계산
    f.z = calc_distance_tess_factor(v2, minDist, maxDist, tess); // 세 번째 버텍스의 테셀레이션 팩터 계산

    return calc_tri_edge_tess_factors(f); // 테셀레이션 팩터 반환
}


TessellationFactors patch_constant_function(const InputPatch<ControlPoint, 3> patch)
{
    float minDist = 2.0; // 최소 거리
    float maxDist = _MaxTessDistance; // 최대 테셀레이션 거리
    return distance_based_tess(patch[0].vertex, patch[1].vertex, patch[2].vertex, minDist, maxDist, _Tess); // 거리 기반 테셀레이션 팩터 계산
}

float4 get_shadow_position_h_clip(Attributes input)
{
    const float3 position_ws = TransformObjectToWorld(input.vertex.xyz); // 월드 좌표 변환
    const float3 normal_ws = TransformObjectToWorldNormal(input.normal); // 월드 노멀 변환

    float4 position_cs = TransformWorldToHClip(ApplyShadowBias(position_ws, normal_ws, 0)); // 클립 공간으로 변환

#if UNITY_REVERSED_Z
    position_cs.z = min(position_cs.z, position_cs.w * UNITY_NEAR_CLIP_VALUE); // Z축 반전 처리
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE); // Z축 반전 처리
#endif
    return position_cs; // 클립 공간 좌표 반환
}

float2 CalculateUV(float3 world_position)
{
    float2 uv = world_position.xz - _Position.xz;
    uv = uv / (_OrthographicCamSize * 2);
    uv += 0.5;
    return uv;
}

float4 SampleEffectTexture(float2 uv)
{
    float4 rt_effect = _GlobalEffectRT.SampleLevel(sampler_GlobalEffectRT, uv, 0);
    rt_effect *= smoothstep(0.99, 0.9, uv.x) * smoothstep(0.99, 0.9, 1 - uv.x);
    rt_effect *= smoothstep(0.99, 0.9, uv.y) * smoothstep(0.99, 0.9, 1 - uv.y);
    return rt_effect;
}

float4 TransformVertexToClipSpace(Attributes input)
{
    #ifdef SHADERPASS_SHADOWCASTER
    return GetShadowPositionHClip(input);
    #else
    return TransformObjectToHClip(input.vertex.xyz);
    #endif
}

Varyings vert(Attributes input)
{
    Varyings output;
    
    float3 world_position = mul(unity_ObjectToWorld, input.vertex).xyz; // 월드 좌표 계산
    
    float2 uv = CalculateUV(world_position); // UV 좌표 계산 
    
    float4 rt_effect = SampleEffectTexture(uv); // 이펙트 텍스처 샘플링 및 경계 마스크

    // Sample Noise Texture
    const float snow_noise = _Noise.SampleLevel(sampler_Noise, world_position.xz * _NoiseScale, 0).r;  

    // Calculate View Direction
    output.view_dir = SafeNormalize(GetCameraPositionWS() - world_position); 
    
    input.vertex.xyz += SafeNormalize(input.normal) * (_SnowHeight + snow_noise * _NoiseWeight) * saturate(1-rt_effect.g * _SnowDepth); // 눈 높이에 따라 버텍스 이동

    output.vertex = TransformVertexToClipSpace(input);

    //outputs
    output.world_pos =  mul(unity_ObjectToWorld, input.vertex).xyz; // 월드 좌표 변환
    output.normal = input.normal; // 노멀 벡터
    output.uv = input.uv; // UV 좌표
    output.fogFactor = ComputeFogFactor(output.vertex.z); // 안개 팩터 계산
    return output;
}

[UNITY_domain("tri")]
Varyings domain(TessellationFactors factors, const OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    Attributes v;
    
    #define INTERPOLATE(fieldName) v.fieldName = \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z; // 버텍스 속성 보간

    INTERPOLATE(vertex) // 버텍스 보간
    INTERPOLATE(uv) // UV 좌표 보간
    INTERPOLATE(normal) // 노멀 벡터 보간
    
    return vert(v); // 보간된 속성으로 vert 함수 호출
}
