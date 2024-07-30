// 필요한 경우 테셀레이션 지원을 정의합니다.
#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
    #define UNITY_CAN_COMPILE_TESSELLATION 1
    #define UNITY_domain domain
    #define UNITY_partitioning partitioning
    #define UNITY_outputtopology outputtopology
    #define UNITY_patchconstantfunc patchconstantfunc
    #define UNITY_outputcontrolpoints outputcontrolpoints
#endif

float _Tess; // 테셀레이션 값
float _MaxTessDistance; // 최대 테셀레이션 거리

struct Varyings
{
    float3 worldPos : TEXCOORD1; // 월드 좌표
    float3 normal : NORMAL; // 노멀 벡터
    float4 vertex : SV_POSITION; // 버텍스 위치
    float2 uv : TEXCOORD0; // UV 좌표
    float3 viewDir : TEXCOORD3; // 뷰 방향 벡터
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

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("patchConstantFunction")]
ControlPoint hull(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id]; // 패치의 컨트롤 포인트 반환
}

TessellationFactors CalcTriEdgeTessFactors(float3 triVertexFactors)
{
    TessellationFactors tess;
    tess.edge[0] = 0.5 * (triVertexFactors.y + triVertexFactors.z); // 엣지 테셀레이션 팩터 계산
    tess.edge[1] = 0.5 * (triVertexFactors.x + triVertexFactors.z); // 엣지 테셀레이션 팩터 계산
    tess.edge[2] = 0.5 * (triVertexFactors.x + triVertexFactors.y); // 엣지 테셀레이션 팩터 계산
    tess.inside = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f; // 내부 테셀레이션 팩터 계산
    return tess; // 테셀레이션 팩터 반환
}

float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
{
    float3 worldPosition = mul(unity_ObjectToWorld, vertex).xyz; // 월드 좌표 변환
    float dist = distance(worldPosition, _WorldSpaceCameraPos); // 카메라와의 거리 계산
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0); // 거리 기반 팩터 계산
    return f * tess; // 테셀레이션 팩터 반환
}

TessellationFactors DistanceBasedTess(float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
{
    float3 f;
    f.x = CalcDistanceTessFactor(v0, minDist, maxDist, tess); // 첫 번째 버텍스의 테셀레이션 팩터 계산
    f.y = CalcDistanceTessFactor(v1, minDist, maxDist, tess); // 두 번째 버텍스의 테셀레이션 팩터 계산
    f.z = CalcDistanceTessFactor(v2, minDist, maxDist, tess); // 세 번째 버텍스의 테셀레이션 팩터 계산

    return CalcTriEdgeTessFactors(f); // 테셀레이션 팩터 반환
}

uniform float3 _Position; // 위치
uniform sampler2D _GlobalEffectRT; // 글로벌 이펙트 텍스처
uniform float _OrthographicCamSize; // 정사영 카메라 크기

sampler2D _Noise; // 노이즈 텍스처
float _NoiseScale, _SnowHeight, _NoiseWeight, _SnowDepth; // 노이즈 및 눈 관련 파라미터

TessellationFactors patchConstantFunction(InputPatch<ControlPoint, 3> patch)
{
    float minDist = 2.0; // 최소 거리
    float maxDist = _MaxTessDistance; // 최대 테셀레이션 거리
    TessellationFactors f;
    return DistanceBasedTess(patch[0].vertex, patch[1].vertex, patch[2].vertex, minDist, maxDist, _Tess); // 거리 기반 테셀레이션 팩터 계산
}

float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.vertex.xyz); // 월드 좌표 변환
    float3 normalWS = TransformObjectToWorldNormal(input.normal); // 월드 노멀 변환

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0)); // 클립 공간으로 변환

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE); // Z축 반전 처리
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE); // Z축 반전 처리
#endif
    return positionCS; // 클립 공간 좌표 반환
}

Varyings vert(Attributes input)
{
    Varyings output;
    
    float3 worldPosition = mul(unity_ObjectToWorld, input.vertex).xyz; // 월드 좌표 변환
    //create local uv
    float2 uv = worldPosition.xz - _Position.xz; // UV 좌표 계산
    uv = uv / (_OrthographicCamSize * 2); // 카메라 크기로 UV 스케일 조정
    uv += 0.5; // UV 좌표 보정
    
    // Effects RenderTexture Reading
    float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv, 0, 0)); // 이펙트 텍스처 샘플링
    // smoothstep to prevent bleeding
    RTEffect *=  smoothstep(0.99, 0.9, uv.x) * smoothstep(0.99, 0.9,1- uv.x); // UV 경계 마스크
    RTEffect *=  smoothstep(0.99, 0.9, uv.y) * smoothstep(0.99, 0.9,1- uv.y); // UV 경계 마스크
    
    // worldspace noise texture
    float SnowNoise = tex2Dlod(_Noise, float4(worldPosition.xz * _NoiseScale, 0, 0)).r; // 월드 좌표 노이즈 텍스처 샘플링
    output.viewDir = SafeNormalize(GetCameraPositionWS() - worldPosition); // 뷰 방향 벡터 계산

    // move vertices up where snow is
    input.vertex.xyz += SafeNormalize(input.normal) * saturate(( _SnowHeight) + (SnowNoise * _NoiseWeight)) * saturate(1-(RTEffect.g * _SnowDepth)); // 눈 높이에 따라 버텍스 이동

    // transform to clip space
    #ifdef SHADERPASS_SHADOWCASTER
        output.vertex = GetShadowPositionHClip(input); // 그림자 좌표 변환
    #else
        output.vertex = TransformObjectToHClip(input.vertex.xyz); // 클립 공간으로 변환
    #endif

    //outputs
    output.worldPos =  mul(unity_ObjectToWorld, input.vertex).xyz; // 월드 좌표 변환
    output.normal = input.normal; // 노멀 벡터
    output.uv = input.uv; // UV 좌표
    output.fogFactor = ComputeFogFactor(output.vertex.z); // 안개 팩터 계산
    return output; // Varyings 반환
}

[UNITY_domain("tri")]
Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    Attributes v;
    
    #define Interpolate(fieldName) v.fieldName = \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z; // 버텍스 속성 보간

    Interpolate(vertex) // 버텍스 보간
    Interpolate(uv) // UV 좌표 보간
    Interpolate(normal) // 노멀 벡터 보간
    
    return vert(v); // 보간된 속성으로 vert 함수 호출
}
