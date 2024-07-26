void ToonShader_float(in float ToonRamp,    out float ToonRampOutput)
    {
        #ifdef SHADERGRAPH_PREVIEW
            ToonRampOutput = float3(0.5, 0.5, 0);
        #else
            Light light = GetMainLight();

            ToonRamp *= light.shadowAttenuation;

            ToonRampOutput = ToonRamp;

        #endif
    }