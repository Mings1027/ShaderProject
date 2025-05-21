using System;
using UnityEngine;

namespace ShaderCode.Fake_Light
{
    public class GpuFakeLight : MonoBehaviour
    {
        [SerializeField] private Material material;
        [SerializeField] private Mesh mesh;

        private void Start()
        {
            Camera.main.depthTextureMode |= DepthTextureMode.Depth;
        }

        private void Update()
        {
            material.SetPass(0);
            Matrix4x4 matrix = Matrix4x4.TRS(transform.position, transform.rotation, Vector3.one);
            Graphics.DrawMesh(mesh, matrix, material, gameObject.layer);
        }
    }
}