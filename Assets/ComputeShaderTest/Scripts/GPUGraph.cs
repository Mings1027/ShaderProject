using System;
using UnityEngine;
using UnityEngine.Rendering;

public class GPUGraph : MonoBehaviour
{
    const int maxResolution = 1000;

    static readonly int
        positionsId = Shader.PropertyToID("_Positions"),
        argsId = Shader.PropertyToID("_Args"),
        resolutionId = Shader.PropertyToID("_Resolution"),
        stepId = Shader.PropertyToID("_Step"),
        timeId = Shader.PropertyToID("_Time"),
        transitionProgressId = Shader.PropertyToID("_TransitionProgress");

    [SerializeField] ComputeShader computeShader;

    [SerializeField] Material material;

    [SerializeField] Mesh mesh;

    [SerializeField, Range(10, maxResolution)]
    int resolution = 10;

    [SerializeField] FunctionLibrary.FunctionName function;

    public enum TransitionMode
    {
        Cycle,
        Random
    }

    [SerializeField] TransitionMode transitionMode;

    [SerializeField, Min(0f)] float functionDuration = 1f, transitionDuration = 1f;

    float duration;

    bool transitioning;

    FunctionLibrary.FunctionName transitionFunction;

    ComputeBuffer positionsBuffer;
    
    private void OnValidate()
    {
        float step = 2f / resolution;
        computeShader.SetInt(resolutionId, resolution);
        computeShader.SetFloat(stepId, step);

        material.SetFloat(stepId, step);
    }

    void OnEnable()
    {
        positionsBuffer = new ComputeBuffer(maxResolution * maxResolution, 3 * 4);
    }

    void OnDisable()
    {
        positionsBuffer.Release();
        positionsBuffer = null;
    }

    void Update()
    {
        duration += Time.deltaTime;
        if (transitioning)
        {
            if (duration >= transitionDuration)
            {
                duration -= transitionDuration;
                transitioning = false;
            }
        }
        else if (duration >= functionDuration)
        {
            duration -= functionDuration;
            transitioning = true;
            transitionFunction = function;
            PickNextFunction();
        }

        UpdateFunctionOnGPU();
    }

    void PickNextFunction()
    {
        function = transitionMode == TransitionMode.Cycle
            ? FunctionLibrary.GetNextFunctionName(function)
            : FunctionLibrary.GetRandomFunctionNameOtherThan(function);
    }

    void UpdateFunctionOnGPU()
    {
        computeShader.SetFloat(timeId, Time.time);
        if (transitioning)
        {
            computeShader.SetFloat(
                transitionProgressId,
                Mathf.SmoothStep(0f, 1f, duration / transitionDuration)
            );
        }

        var kernelIndex =
            (int)function +
            (int)(transitioning ? transitionFunction : function) *
            FunctionLibrary.FunctionCount;
        computeShader.SetBuffer(kernelIndex, positionsId, positionsBuffer);

        int groups = Mathf.CeilToInt(resolution / 8f);
        computeShader.Dispatch(kernelIndex, groups, groups, 1);

        material.SetBuffer(positionsId, positionsBuffer);
        var bounds = new Bounds(Vector3.zero, Vector3.one * (2f + 2f / resolution));
        var renderParams = new RenderParams(material)
        {
            worldBounds = bounds,
            shadowCastingMode = ShadowCastingMode.On,
            receiveShadows = true
        };
        
        Graphics.RenderMeshPrimitives(renderParams, mesh, 0, resolution * resolution);

        // Graphics.DrawMeshInstancedProcedural(
        //     mesh, 0, material, bounds, resolution * resolution
        // );
    }
}