using System.Collections.Generic;
using UnityEngine;

namespace FPL
{
    public enum FPL_Properties
    {
        _LightTint,
        _LightSoftness,
        _LightPosterize,
        _ShadingBlend,
        _ShadingSoftness,

        _HaloTint,
        _HaloSize,
        _HaloPosterize,
        _HaloDepthFade,

        _FarFade,
        _FarTransition,
        _CloseFade,
        _CloseTransition,

        _RandomOffset,
        _FlickerIntensity,
        _FlickerSpeed,
        _FlickerHue,
        _FlickerSoftness,
        _SizeFlickering,

        _Noisiness,
        _NoiseScale,
        _NoiseMovement,
        _SpecIntensity,
        _SpecPower,
    }

    [RequireComponent(typeof(MeshRenderer))]
    public class FPL_Controller : MonoBehaviour
    {
        #region Variables

        //Shader Variables Dictionnary Constructor:
        static FPL_Controller()
        {
            LightPropertiesDictionary = new Dictionary<FPL_Properties, int>()
            {
                { FPL_Properties._LightTint, Shader.PropertyToID(nameof(FPL_Properties._LightTint)) },
                { FPL_Properties._LightSoftness, Shader.PropertyToID(nameof(FPL_Properties._LightSoftness)) },
                { FPL_Properties._LightPosterize, Shader.PropertyToID(nameof(FPL_Properties._LightPosterize)) },
                { FPL_Properties._ShadingBlend, Shader.PropertyToID(nameof(FPL_Properties._ShadingBlend)) },
                { FPL_Properties._ShadingSoftness, Shader.PropertyToID(nameof(FPL_Properties._ShadingSoftness)) },

                { FPL_Properties._HaloTint, Shader.PropertyToID(nameof(FPL_Properties._HaloTint)) },
                { FPL_Properties._HaloSize, Shader.PropertyToID(nameof(FPL_Properties._HaloSize)) },
                { FPL_Properties._HaloPosterize, Shader.PropertyToID(nameof(FPL_Properties._HaloPosterize)) },
                { FPL_Properties._HaloDepthFade, Shader.PropertyToID(nameof(FPL_Properties._HaloDepthFade)) },

                { FPL_Properties._FarFade, Shader.PropertyToID(nameof(FPL_Properties._FarFade)) },
                { FPL_Properties._FarTransition, Shader.PropertyToID(nameof(FPL_Properties._FarTransition)) },
                { FPL_Properties._CloseFade, Shader.PropertyToID(nameof(FPL_Properties._CloseFade)) },
                { FPL_Properties._CloseTransition, Shader.PropertyToID(nameof(FPL_Properties._CloseTransition)) },

                { FPL_Properties._RandomOffset, Shader.PropertyToID(nameof(FPL_Properties._RandomOffset)) },
                { FPL_Properties._FlickerIntensity, Shader.PropertyToID(nameof(FPL_Properties._FlickerIntensity)) },
                { FPL_Properties._FlickerSpeed, Shader.PropertyToID(nameof(FPL_Properties._FlickerSpeed)) },
                { FPL_Properties._FlickerHue, Shader.PropertyToID(nameof(FPL_Properties._FlickerHue)) },
                { FPL_Properties._FlickerSoftness, Shader.PropertyToID(nameof(FPL_Properties._FlickerSoftness)) },
                { FPL_Properties._SizeFlickering, Shader.PropertyToID(nameof(FPL_Properties._SizeFlickering)) },

                { FPL_Properties._Noisiness, Shader.PropertyToID(nameof(FPL_Properties._Noisiness)) },
                { FPL_Properties._NoiseScale, Shader.PropertyToID(nameof(FPL_Properties._NoiseScale)) },
                { FPL_Properties._NoiseMovement, Shader.PropertyToID(nameof(FPL_Properties._NoiseMovement)) },

                { FPL_Properties._SpecIntensity, Shader.PropertyToID(nameof(FPL_Properties._SpecIntensity)) },
                { FPL_Properties._SpecPower, Shader.PropertyToID(nameof(FPL_Properties._SpecPower)) },
            };
        }

        [SerializeField] private MeshRenderer _mesh;
        private MaterialPropertyBlock _propertyBlock;
        private static readonly Dictionary<FPL_Properties, int> LightPropertiesDictionary;

        private void InitializeVariables()
        {
            if (_mesh == null) _mesh = GetComponent<MeshRenderer>();
            if (_propertyBlock == null) _propertyBlock = new MaterialPropertyBlock();
        }

        private bool MeshCheck()
        {
            if (_mesh == null)
            {
                Debug.LogWarning("Warning: FPL_Controller is missing its mesh renderer component");
                return true;
            }

            return false;
        }

        private void Awake()
        {
            InitializeVariables();
        }
#if UNITY_EDITOR
        private void OnValidate()
        {
            InitializeVariables();
        }
#endif

        #endregion

        #region Public Methods

        /// <summary>
        /// Set a float property on the current the FakePointLight.
        /// </summary>
        public void SetProperty(FPL_Properties lightProperty, float value)
        {
            if (MeshCheck()) return;
            _propertyBlock.SetFloat(LightPropertiesDictionary[lightProperty], value);
            _mesh.SetPropertyBlock(_propertyBlock);
        }

        /// <summary>
        /// Set a color property on the current FakePointLight.
        /// </summary>
        public void SetProperty(FPL_Properties lightProperty, Color value)
        {
            if (MeshCheck()) return;
            _propertyBlock.SetColor(LightPropertiesDictionary[lightProperty], value);
            _mesh.SetPropertyBlock(_propertyBlock);
        }

        /// <summary>
        /// Access the MaterialPropertyBlock of the current FakePointLight. (for advanced custom adjustments)
        /// </summary>
        public MaterialPropertyBlock GetPropertyBlock()
        {
            return _propertyBlock;
        }

        /// <summary>
        /// Set the MaterialPropertyBlock of the current FakePointLight. (for advanced custom adjustments)
        /// </summary>
        public void SetPropertyBlock(MaterialPropertyBlock propertyBlock)
        {
            _propertyBlock = propertyBlock;
            if (MeshCheck()) return;
            _mesh.SetPropertyBlock(_propertyBlock);
        }

        #endregion

        #region DEBUGGING

#if ODIN_INSPECTOR
        [Space (15)]
        [SerializeField] FPL_Properties _property;
        [SerializeField] float _value;
        [Sirenix.OdinInspector.Button]
        private void ApplyPropertyDebug()
        {
            SetProperty (_property, _value);
        }
#endif

        #endregion
    }
}