using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public enum ViewType
    {
        FirstPerson,
        ThirdPerson
    }

    public ViewType View
    {
        get => viewType;
        set
        {
            viewType = value;
            UpdateCamPosition();
        }
    }

    private Transform followTarget;

    [SerializeField] private ViewType viewType;
    [SerializeField] private float speed;
    [SerializeField] private Transform firstPersonTarget;
    [SerializeField] private Transform thirdPersonTarget;

    [SerializeField] private float smoothSpeed;
    [SerializeField, Range(1, 10)] private float offset;

    private void Start()
    {
        UpdateCamPosition();
    }

    private void FixedUpdate()
    {
        var desiredPos = followTarget.position + new Vector3(0, offset, -offset);
        var smoothedPos = Vector3.Lerp(transform.position, desiredPos, smoothSpeed * Time.deltaTime);
        transform.position = smoothedPos;
    }

    private void UpdateCamPosition()
    {
        followTarget = viewType == ViewType.FirstPerson ? firstPersonTarget : thirdPersonTarget;

    }

}
