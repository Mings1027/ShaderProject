using System;
using System.Collections;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.InputSystem;

public class Test : MonoBehaviour
{
    [SerializeField] private GameObject scanerPrefab;
    [SerializeField] private float duration;
    [SerializeField] private float size;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {

            SpawnScanner().Forget();
        }
    }

    private async UniTaskVoid SpawnScanner()
    {
        var scanner = Instantiate(scanerPrefab, transform.position, Quaternion.identity);
        if (scanner.TryGetComponent(out ParticleSystem particleSystem))
        {
            var main = particleSystem.main;
            main.duration = duration;
            main.startSize = size;
            particleSystem.Play();
        }
        await UniTask.Delay(TimeSpan.FromSeconds(duration));
        Destroy(scanner);
    }
}
