// This shader adds tessellation in URP
Shader "Example/Basic Tessellation"
{

	// The properties block of the Unity shader. In this example this block is empty
	// because the output color is predefined in the fragment shader code.
	Properties
	{
		_Tess("Tessellation", Range(1, 64)) = 20
		_MaxTessDistance("Max Tess Distance", Range(1, 32)) = 20
		_Noise("Noise", 2D) = "gray" {}
	    _Weight("Displacement Amount", Range(0, 10)) = 0
	}

	// The SubShader block containing the Shader code. 
    SubShader
    {
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

    	Pass
	    {
		    Tags{ "LightMode" = "UniversalForward" }

	        HLSLPROGRAM
    
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"    
            #include "CustomTessellation.hlsl"

            #pragma require tessellation
            #pragma vertex TessellationVertexProgram
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain   

	        sampler2D _Noise;
	        float _Weight;

    	    ControlPoint TessellationVertexProgram(Attributes v)
	        {
		        ControlPoint p;

    		    p.vertex = v.vertex;
    	    	p.uv = v.uv;
	        	p.normal = v.normal;
    	    	p.color = v.color;

		        return p;
	        }

	        // after tesselation
	        Varyings vert(Attributes input)
    	    {
		        Varyings output;
        		float Noise = tex2Dlod(_Noise, float4(input.uv, 0, 0)).r;
                // float NoiseSmaller = tex2Dlod(_Noise, float4(input.uv * 0.5, 0, 0)).r;
                // float combinedNoise = NoiseSmaller * 0.5 + Noise * 0.5;

        		input.vertex.xyz += (input.normal) *  Noise * _Weight;
	        	output.vertex = TransformObjectToHClip(input.vertex.xyz);
        		output.color = input.color;
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
         		DomainPos(color)
    	    	DomainPos(normal)

		        return vert(v);
	        }

	        // The fragment shader definition.            
    	    half4 frag(Varyings IN) : SV_Target
            {
	    	    half4 tex = tex2D(_Noise, IN.uv);
            
                // float Noise = tex2Dlod(_Noise, float4(IN.uv + _Time.x, 0, 0)).r;
                // float NoiseSmaller = tex2Dlod(_Noise, float4(IN.uv * 0.5, 0, 0)).r;
                // float combinedNoise = NoiseSmaller * 0.5 + Noise * 0.5;

    	    	return tex;
	        }
            
		    ENDHLSL
    	}
	}
}