using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerJump : MonoBehaviour
{
    private bool isGround;
    private bool isJumping;
    private Vector3 jumpVelocity;
    private PlayerMovement playerMovement;

    [SerializeField] private float jumpForce;
    [SerializeField] private float gravity = -9.8f;
    [SerializeField] private Transform groundCheck;
    [SerializeField] private LayerMask groundLayer;
    [SerializeField, Range(0, 1f)] private float groundCheckRadius = 0.2f;
    [SerializeField] private ParticleSystem particle;

    private void Awake()
    {
        playerMovement = GetComponent<PlayerMovement>();
    }

    private void Update()
    {
        isGround = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);
        if (!isGround && !isJumping)
        {
            ApplyGravity().Forget();
        }
    }

    private void OnJump(InputValue value)
    {
        var input = value.Get<float>();
        if (input == 1 && isGround && !isJumping)
        {
            Jump().Forget();
        }
    }

    private async UniTaskVoid Jump()
    {
        particle.Stop();
        isJumping = true;

        var jumpDirection = playerMovement.GetMoveDir;
        jumpDirection.y = 1;
        jumpVelocity = jumpDirection.normalized * jumpForce;

        while (true)
        {
            jumpVelocity.y += gravity * Time.deltaTime;
            transform.position += jumpVelocity * Time.deltaTime;
            if (jumpVelocity.y <= 0 && Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer))
            {
                particle.Play();
                isGround = true;
                isJumping = false;
                break;
            }

            await UniTask.Yield(PlayerLoopTiming.FixedUpdate, cancellationToken: this.GetCancellationTokenOnDestroy());
        }
    }

    private async UniTaskVoid ApplyGravity()
    {
        isJumping = true;
        jumpVelocity = Vector3.zero;

        var jumpDirection = playerMovement.GetMoveDir;
        // jumpDirection.y = 1;
        jumpVelocity = jumpDirection.normalized;

        while (!isGround)
        {
            jumpVelocity.y += gravity * Time.deltaTime;
            transform.position += jumpVelocity * Time.deltaTime;

            isGround = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);

            await UniTask.Yield(PlayerLoopTiming.FixedUpdate, cancellationToken: this.GetCancellationTokenOnDestroy());
        }

        isJumping = false;
        particle.Play();
    }
    private void OnDrawGizmos()
    {
        if (groundCheck == null) return;

        Gizmos.color = isGround ? Color.green : Color.red;
        Gizmos.DrawWireSphere(groundCheck.position, groundCheckRadius);
    }

}
