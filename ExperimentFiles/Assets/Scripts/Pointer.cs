/* Special thanks to VR tutorial videos made by "VR with Andrew" https://www.youtube.com/@VRwithAndrew
 */

using UnityEngine;

public class Pointer : MonoBehaviour
{
    public float defaultLength = 5.0f;
    public GameObject dot = null;
    public BoardUIManager boardUI = null;

    private LineRenderer lineRenderer = null;
    private void Awake()
    {
        lineRenderer = GetComponent<LineRenderer>();
    }
     
    private void Update()
    {
        UpdateLine();
    }

    private void UpdateLine()
    {
        RaycastHit hit = CreateRaycast();
        float colliderDistance = hit.distance == 0 ? defaultLength : hit.distance;
        float targetLength = colliderDistance;
        Vector3 endPosition = transform.position + (transform.forward * targetLength);
        dot.transform.position = endPosition;
        lineRenderer.SetPosition(0, transform.position);
        lineRenderer.SetPosition(1, endPosition);

        // Interact with UI
        if (hit.distance > 0) 
        {
            if (!boardUI)
            {
                boardUI = GameObject.Find("Board").GetComponent<BoardUIManager>();
            }
            boardUI.HandleRaycastHit(this.name, hit);
        }
    }

    private RaycastHit CreateRaycast()
    {
        RaycastHit hit;
        Ray ray = new Ray(transform.position, transform.forward);
        Physics.Raycast(ray, out hit, defaultLength);

        return hit;
    }
}