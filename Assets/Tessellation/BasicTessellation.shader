Shader "Custom/Basic Tessellation"
{
	Properties
	{
		_Tess("Tessellation", Range(1, 64)) = 20
		_MaxTessDistance("Max Tess Distance", Range(1, 32)) = 20
		_Noise("Noise Texture", 2D) = "white" {}
	    _Weight("Displacement Amount", Range(0, 10)) = 0
	}

	HLSLINCLUDE

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"    
	#include "CustomTessellation.hlsl"

	#pragma require tessellation
	#pragma fragment frag
	#pragma target 4.5
	#pragma vertex TessellationVertexProgram
	#pragma hull hull
	#pragma domain domain   

	ControlPoint TessellationVertexProgram(Attributes v)
	{
		ControlPoint p;

		p.vertex = v.vertex;
		p.uv = v.uv;
		p.normal = v.normal;

		return p;
	}

	ENDHLSL
 
    SubShader
    {
		Tags{ "RenderType" = "Opaque" "Queue"="Geometry" "RenderPipeline" = "UniversalPipeline" }

    	Pass
	    {
		    Tags{ "LightMode" = "UniversalForward" }

	        HLSLPROGRAM

	        // after tesselation
	        Varyings vert(Attributes input)
    	    {
		        Varyings output;
        		float Noise = tex2Dlod(_Noise, float4(input.uv, 0, 0)).r;
                float NoiseSmaller = tex2Dlod(_Noise, float4(input.uv * 0.5, 0, 0)).r;
                float combinedNoise = (NoiseSmaller + Noise) * 0.5;

        		input.vertex.xyz += (input.normal) * combinedNoise * _Weight;
	        	output.vertex = TransformObjectToHClip(input.vertex.xyz);
    	    	output.normal = input.normal;
    		    output.uv = input.uv;
	        	return output;
	        }

        	[UNITY_domain("tri")]
	        Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
	        {
	    	    Attributes v;

                #define DomainPos(fieldName) v.fieldName = \
	    			patch[0].fieldName * barycentricCoordinates.x + \
		    		patch[1].fieldName * barycentricCoordinates.y + \
			    	patch[2].fieldName * barycentricCoordinates.z;

          		DomainPos(vertex)
    	    	DomainPos(uv)
    	    	DomainPos(normal)

		        return vert(v);
	        }

    	    float4 frag(Varyings IN) : SV_Target
            {
	    	    // half4 tex = tex2D(_Noise, IN.uv);
            
                float Noise = tex2Dlod(_Noise, float4(IN.uv + _Time.x, 0, 0)).r;
                float NoiseSmaller = tex2Dlod(_Noise, float4(IN.uv * 0.5, 0, 0)).r;
                float4 combinedNoise = (NoiseSmaller + Noise) * 0.5;

    	    	return combinedNoise;
	        }
            
		    ENDHLSL
    	}
	}
}