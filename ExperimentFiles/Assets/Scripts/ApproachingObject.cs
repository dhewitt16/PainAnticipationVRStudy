using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApproachingObject : MonoBehaviour
{
    public float spawnDistanceFactor = 10.0f;
    public float totalTimeToCollisionTime = 0.5f;
    public float disappearTime = 0f;
    public float fixedHeight = 2f;
    public string target = "Right";
    public GameObject leftTarget;
    public GameObject rightTarget;
    public GameObject head;
    public bool alwaysTrackHandPosition = true;
    public long startTimeUnixTS;
    public string objectInformation = "";

    private float forwardSpeed;
    private Vector3 forwardDirection;
    private float startTime;
    private MeshRenderer renderer;
    private AudioSource audio;
    private bool alreadyCollided = false;
    // Start is called before the first frame update
    void Start() 
    {
        renderer = GetComponent<MeshRenderer>();
        audio = GetComponent<AudioSource>();
        
        renderer.enabled = false;
    }

    private void CalculateSpeedAndDirection(Vector3 startLocation, float remainingTime)
    {
        if (remainingTime <= 0)
        {
            return;
        }
        
        if (target == "Right") 
        {
            forwardDirection = Vector3.Normalize(rightTarget.transform.position - startLocation);
            forwardSpeed = Vector3.Distance(rightTarget.transform.position, startLocation) / remainingTime; 
        }
        else if (target == "Left")
        {
            forwardDirection = Vector3.Normalize(leftTarget.transform.position - startLocation);
            forwardSpeed = Vector3.Distance(leftTarget.transform.position, startLocation) / remainingTime; 
        }
        else if (target == "Middle")
        {
            forwardDirection = Vector3.Normalize((leftTarget.transform.position + rightTarget.transform.position) / 2 - startLocation);
            forwardSpeed = Vector3.Distance((leftTarget.transform.position + rightTarget.transform.position) / 2, startLocation) / remainingTime; 
        }
        else if (target == "MiddleCondition")
        {
            Vector3 targetPosition = new Vector3(((leftTarget.transform.position + rightTarget.transform.position) / 2).x, 0, ((leftTarget.transform.position + rightTarget.transform.position) / 2).z);
            forwardDirection = Vector3.Normalize(targetPosition - startLocation);
            forwardSpeed = Vector3.Distance(targetPosition, startLocation) / remainingTime; 
        }
    }

    public void Instantiate(long delays=0)
    {
        leftTarget = GameObject.Find("LeftHand");
        rightTarget = GameObject.Find("RightHand");
        head = Camera.main.transform.gameObject;

        Vector3 headDirection = head.transform.rotation * Vector3.forward;
        Vector3 startLocation = new Vector3(head.transform.position.x, 0, head.transform.position.z)
             + spawnDistanceFactor * new Vector3(headDirection.x, fixedHeight / spawnDistanceFactor, headDirection.z);
        transform.position = startLocation;

        CalculateSpeedAndDirection(startLocation, totalTimeToCollisionTime);

        startTime = Time.fixedTime + (float)(delays / 1000.0f);
        startTimeUnixTS = DateTimeOffset.Now.ToUnixTimeMilliseconds() + delays;
    }

    void FixedUpdate()
    {
        if (Time.fixedTime < startTime) return;
        else if (audio && !audio.enabled)
        {
            audio.enabled = true;
            if (target == "Left")
            {
                audio.panStereo = -0.9f;
            }
            else if (target == "Right")
            {
                audio.panStereo = 0.9f;
            }
        }

        if (alwaysTrackHandPosition)
        {
            CalculateSpeedAndDirection(transform.position, -Time.fixedTime + startTime + totalTimeToCollisionTime);
        }

        transform.position += forwardDirection * forwardSpeed * Time.deltaTime;
        if (Time.fixedTime - startTime > totalTimeToCollisionTime - disappearTime && disappearTime > 0)
        {
            if (renderer.enabled)
            {
                Debug.Log("Hide object now");
                renderer.enabled = false;
                objectInformation = "object_disappear";
            }
        }
        else
        {
            // When the objet start, it disables renderer, we need to reenable it if before disappear time
            if (!renderer.enabled)
            {
                Debug.Log(Time.fixedTime);
                renderer.enabled = true;
                objectInformation = "object_appear";
            }
        }

        if (Time.fixedTime - startTime > totalTimeToCollisionTime)
        {
            if (!alreadyCollided)
            {
                objectInformation = "object_collision";
                alreadyCollided = true;
            }
        }
        
        if (Time.fixedTime - startTime > totalTimeToCollisionTime + 0.1)
        {
            Destroy(gameObject);
        }
    }
}
