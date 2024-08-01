#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
    #define UNITY_CAN_COMPILE_TESSELLATION 1
    #define UNITY_domain domain
    #define UNITY_partitioning partitioning
    #define UNITY_outputtopology outputtopology
    #define UNITY_patchconstantfunc patchconstantfunc
    #define UNITY_outputcontrolpoints outputcontrolpoints
#endif

		
CBUFFER_START(UnityPerMaterial)
float _Tess;
float _MaxTessDistance;
sampler2D _Noise;
float _Weight;
CBUFFER_END

struct Varyings
{
	float4 color : COLOR;
	float3 normal : NORMAL;
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
};

struct TessellationFactors
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct ControlPoint
{
	float4 vertex : INTERNALTESSPOS;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
};

struct Attributes
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("patchConstantFunction")]
ControlPoint hull(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
{
	return patch[id];
}

float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
{
    float3 worldPosition = TransformObjectToWorld(vertex.xyz);
    float dist = distance(worldPosition, _WorldSpaceCameraPos);
	float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
	return (f);
}

TessellationFactors patchConstantFunction(InputPatch<ControlPoint, 3> patch)
{
	float minDist = 5.0;
	float maxDist = _MaxTessDistance;

	TessellationFactors f;

	float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess);
	float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess);
	float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess);

	f.edge[0] = (edge1 + edge2) / 2;
	f.edge[1] = (edge2 + edge0) / 2;
	f.edge[2] = (edge0 + edge1) / 2;
	f.inside = (edge0 + edge1 + edge2) / 3;
	return f;
}