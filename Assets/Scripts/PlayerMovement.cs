using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    private Vector3 moveDir;
    private WallCollisionDetector wallDetector;
    private Rigidbody rigid;
    private PlayerJump playerJump; // PlayerJump 클래스를 참조

    [SerializeField] private float moveSpeed;
    [SerializeField] private float rotationSpeed = 700f; // 회전 속도

    private void Awake()
    {
        wallDetector = GetComponent<WallCollisionDetector>();
        rigid = GetComponent<Rigidbody>();
        rigid.freezeRotation = true;

        playerJump = GetComponent<PlayerJump>(); // PlayerJump 클래스 초기화
    }
    
    private void FixedUpdate()
    {
        Movement();
    }

    private void OnMove(InputValue value)
    {
        var input = value.Get<Vector2>();
        moveDir = new Vector3(input.x, 0, input.y).normalized;
    }

    private void OnJump(InputValue value)
    {
        var input = value.Get<float>();
        if (Mathf.Approximately(input, 1))
        {
            playerJump.TryJump(); // 점프 시도
        }
    }

    private void Movement()
    {
        if (moveDir != Vector3.zero)
        {
            // 이동 방향에 따라 벽 충돌 여부를 체크
            if (!wallDetector.IsWallInDirection(moveDir))
            {
                // 이동 방향에 힘을 추가
                Vector3 movement = moveSpeed * Time.fixedDeltaTime * moveDir;
                rigid.MovePosition(rigid.position + movement);

                // 이동 방향에 따라 회전
                Quaternion targetRotation = Quaternion.LookRotation(moveDir);
                rigid.MoveRotation(Quaternion.RotateTowards(rigid.rotation, targetRotation, rotationSpeed * Time.fixedDeltaTime));
            }
        }
    }
}