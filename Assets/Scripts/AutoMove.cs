using System.Collections;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class AutoMove : MonoBehaviour
{
    private Vector3 moveDir;

    [SerializeField] private int moveCount;
    [SerializeField] private float moveSpeed;

    private void Start()
    {
        MovePath().Forget();
    }

    private void Update()
    {
        transform.Translate(moveSpeed * Time.deltaTime * moveDir);
    }

    private async UniTaskVoid MovePath()
    {
        var count = 0;
        while (count < moveCount)
        {
            await UniTask.Delay(1000, cancellationToken: this.GetCancellationTokenOnDestroy());
            moveDir = new Vector3(1, 0, 0);

            await UniTask.Delay(1000, cancellationToken: this.GetCancellationTokenOnDestroy());
            moveDir = new Vector3(0, 0, 1);

            await UniTask.Delay(1000, cancellationToken: this.GetCancellationTokenOnDestroy());
            moveDir = new Vector3(-1, 0, 0);

            await UniTask.Delay(1000, cancellationToken: this.GetCancellationTokenOnDestroy());
            moveDir = new Vector3(0, 0, -1);

            count++;
        }

        moveDir = new Vector3(0, 0, 0);
    }
}
