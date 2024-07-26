using UnityEngine;

public class ObjectPosition : MonoBehaviour
{
    [SerializeField] private Transform[] interactiveObjects;

    private void Update()
    {
        for (int i = 0; i < interactiveObjects.Length; i++)
        {
            Shader.SetGlobalVector("_InteractiveObject", new Vector3(interactiveObjects[i].position.x, interactiveObjects[i].position.y, interactiveObjects[i].position.z));
        }
    }
}
