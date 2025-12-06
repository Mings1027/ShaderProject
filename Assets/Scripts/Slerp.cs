using System;
using Cysharp.Threading.Tasks;
using UnityEngine;

[Serializable]
public class CurveData
{
    public float lerp;
    public Vector3 startPoint;
    public Vector3 endPoint;
}

public class Slerp : MonoBehaviour
{
    [SerializeField] private CurveData[] curveDataList;
    [SerializeField] private Transform target;

    private void Start()
    {
        Curve().Forget();
    }

    private async UniTaskVoid Curve()
    {
        var first = curveDataList[0];
        while (first.lerp <= 1)
        {
            first.lerp += Time.deltaTime;
            target.position = Vector3.Slerp(first.startPoint, first.endPoint, first.lerp);
            await UniTask.Yield();
        }
        
        var second = curveDataList[1];
        while (second.lerp <= 1)
        {
            second.lerp += Time.deltaTime;
            target.position = Vector3.Slerp(second.startPoint, second.endPoint, second.lerp);
            await UniTask.Yield();
        }
        
        var  third = curveDataList[2];
        while (third.lerp <= 1)
        {
            third.lerp += Time.deltaTime;
            target.position = Vector3.Slerp(third.startPoint, third.endPoint, third.lerp);
            await UniTask.Yield();
        }
        
        var  fourth = curveDataList[3];
        while (fourth.lerp <= 1)
        {
            fourth.lerp += Time.deltaTime;
            target.position = Vector3.Slerp(fourth.startPoint, fourth.endPoint, fourth.lerp);
            await UniTask.Yield();
        }
        
        var fifth = curveDataList[4];
        while (fifth.lerp <= 1)
        {
            fifth.lerp += Time.deltaTime;
            target.position = Vector3.Slerp(fifth.startPoint, fifth.endPoint, fifth.lerp);
            await UniTask.Yield();
        }
    }
}