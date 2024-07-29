using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    public Vector3 GetMoveDir => moveDir;

    private Vector3 moveDir;
    private WallCollisionDetector wallDetector;
    private Rigidbody rigid;

    [SerializeField] private float moveSpeed;
    [SerializeField] private float rotationSpeed = 700f; // 회전 속도

    private void Awake()
    {
        wallDetector = GetComponent<WallCollisionDetector>();
        rigid = GetComponent<Rigidbody>();
        rigid.freezeRotation = true;
    }
    // private void Update()
    // {
    //     MovementTransform();
    // }
    private void FixedUpdate()
    {
        MovementRigidbody();
    }

    private void OnMove(InputValue value)
    {
        var input = value.Get<Vector2>();
        moveDir = new Vector3(input.x, 0, input.y).normalized;
    }

    // private void MovementTransform()
    // {
    //     if (moveDir != Vector3.zero)
    //     {
    //         if (!wallDetector.IsWallInDirection(moveDir))
    //         {
    //             var movement = new Vector3(moveDir.x, 0, moveDir.z).normalized;
    //             var newPosition = transform.position + moveSpeed * Time.deltaTime * movement;

    //             if (movement != Vector3.zero)
    //             {
    //                 var targetRotation = Quaternion.LookRotation(movement, Vector3.up);
    //                 transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
    //             }

    //             transform.SetPositionAndRotation(newPosition, transform.rotation);
    //         }
    //     }
    // }

    private void MovementRigidbody()
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
