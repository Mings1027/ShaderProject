using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerInput : MonoBehaviour
{
    private Vector3 moveDir;
    private WallCollisionDetector wallDetector;
    [SerializeField] private float moveSpeed;
    [SerializeField] private float detectDistance;
    [SerializeField] private float radius;

    private void Awake()
    {
        wallDetector = GetComponent<WallCollisionDetector>();
    }

    private void Update()
    {
        if (moveDir != Vector3.zero)
        {
            transform.rotation = Quaternion.LookRotation(moveDir);
            if (!wallDetector.IsWallInDirection(moveDir))
            {
                transform.Translate(moveSpeed * Time.deltaTime * moveDir, Space.World);
            }
        }
    }

    private void OnMove(InputValue value)
    {
        var input = value.Get<Vector2>();
        moveDir = new Vector3(input.x, 0, input.y);
    }

}
