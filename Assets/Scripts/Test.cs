using System;
using System.Collections;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

public class Test : MonoBehaviour
{
    [SerializeField] private GameObject scannerPrefab;
    [SerializeField] private float duration;
    [SerializeField] private float size;

    private void Update()
    {
        for (int i = 0; i < 100000; i++)
        {
            var v = new Vector3(Random.Range(-10f, 10f), Random.Range(-10f, 10f), Random.Range(-10f, 10f));
        }
    }

    private async UniTaskVoid SpawnScanner()
    {
        var scanner = Instantiate(scannerPrefab, transform.position, Quaternion.identity);
        if (scanner.TryGetComponent(out ParticleSystem particle))
        {
            var main = particle.main;
            main.duration = duration;
            main.startSize = size;
            particle.Play();
        }
        await UniTask.Delay(TimeSpan.FromSeconds(duration));
        Destroy(scanner);
    }
}
