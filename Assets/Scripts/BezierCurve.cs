using System;
using DG.Tweening;
using UnityEngine;

public class BezierCurve : MonoBehaviour
{
    [SerializeField] private Transform first, second, third, fourth, fifth;
    [SerializeField] private Transform target;
    private float lerpTime;
    private Sequence curveSequence;

    private void Start()
    {
        curveSequence = DOTween.Sequence();
        curveSequence.Append(target.DOJump(first.position, 5, 1, 1).SetEase(Ease.Linear))
            .Append(target.DOJump(second.position, -4, 1, 1).SetEase(Ease.Linear))
            .Append(target.DOJump(third.position, 3, 1, 1).SetEase(Ease.Linear))
            .Append(target.DOJump(fourth.position, -2, 1, 1).SetEase(Ease.Linear))
            .Append(target.DOJump(fifth.position, 1, 1, 1).SetEase(Ease.Linear)).SetAutoKill(false);
    }

    // void Update()
    // {
    //     if (Input.GetKeyDown(KeyCode.Space))
    //     {
    //         lerpTime = 0;
    //     }
    //
    //     var lerp = lerpTime += Time.deltaTime;
    //     target.position = Vector3.Slerp(startPoint.position, endPoint.position, lerp);
    // }
}