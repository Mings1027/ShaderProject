using UnityEngine;

public class PlayerJump : MonoBehaviour
{
    private Rigidbody rigid;
    private bool isGrounded;
    private bool isJumping;
    private Vector3 velocity;

    [SerializeField] private ParticleSystem snowParticle;
    [SerializeField] private Transform groundCheck;
    [SerializeField] private float groundDistance = 0.4f;
    [SerializeField] private LayerMask groundMask;
    [SerializeField] private float jumpForce = 10f;
    [SerializeField] private float gravity = 20f;

    private void Awake()
    {
        rigid = GetComponent<Rigidbody>();
        rigid.useGravity = false;
    }

    private void FixedUpdate()
    {
        CheckGround();

        if (isJumping || !isGrounded)
        {
            ApplyGravity();
        }
    }

    public void TryJump()
    {
        if (isGrounded && !isJumping)
        {
            isJumping = true;
            snowParticle.Stop();
            velocity.y = Mathf.Sqrt(jumpForce * 2f * gravity);
        }
    }

    private void ApplyGravity()
    {
        velocity.y -= gravity * Time.fixedDeltaTime;
        rigid.MovePosition(rigid.position + velocity.y * Time.fixedDeltaTime * Vector3.up);

        if (isGrounded && velocity.y < 0)
        {
            isJumping = false;
            snowParticle.Play();
            velocity.y = 0f;
        }
    }

    private void CheckGround()
    {
        isGrounded = Physics.CheckSphere(groundCheck.position, groundDistance, groundMask);
    }
}