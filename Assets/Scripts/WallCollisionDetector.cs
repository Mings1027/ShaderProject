using UnityEngine;

public class WallCollisionDetector : MonoBehaviour
{
    [SerializeField] private LayerMask wallLayer;
    [SerializeField, Range(1, 100)] private int rayCount = 5;
    [SerializeField, Range(0, 90)] private float rayAngle = 30f;
    [SerializeField, Range(0, 10)] private float rayDistance = 1f;
    [SerializeField] private bool drawGizmos;

    public bool IsWallInDirection(Vector3 direction)
    {
        float halfAngle = rayAngle / 2;
        float angleStep = rayCount > 1 ? rayAngle / (rayCount - 1) : 0; // rayCount가 1일 때 angleStep이 0이 되지 않도록

        for (int i = 0; i < rayCount; i++)
        {
            float currentAngle = -halfAngle + (i * angleStep);
            Vector3 rayDirection = Quaternion.Euler(0, currentAngle, 0) * direction;

            // Raycast를 사용하여 특정 방향으로 벽이 있는지 체크
            if (Physics.Raycast(transform.position, rayDirection, rayDistance, wallLayer))
            {
                return true; // 벽이 있으면 true 반환
            }
        }

        return false; // 벽이 없으면 false 반환
    }

    private void OnDrawGizmos()
    {
        // 디버깅을 위한 Ray 표시
        if (!drawGizmos) return;

        float halfAngle = rayAngle / 2;
        float angleStep = rayCount > 1 ? rayAngle / (rayCount - 1) : 0; // rayCount가 1일 때 angleStep이 0이 되지 않도록
        Vector3 forward = transform.forward;

        for (int i = 0; i < rayCount; i++)
        {
            float currentAngle = -halfAngle + (i * angleStep);
            Vector3 rayDirection = Quaternion.Euler(0, currentAngle, 0) * forward;

            // 벽과 충돌 여부를 확인
            bool isHit = Physics.Raycast(transform.position, rayDirection, rayDistance, wallLayer);
            Gizmos.color = isHit ? Color.green : Color.red;

            Gizmos.DrawRay(transform.position, rayDirection * rayDistance);
        }
    }
}
