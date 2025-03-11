using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateObject : MonoBehaviour
{
    public GameObject[] objectToGenerate;
    public int distanceBetweenObjects = 1;
    public int repetitions = 10;
    public int objectsPerCircle = 12;
    public float scale = 0.5f;
    // Start is called before the first frame update
    void Start()
    {
        for (int i = 0; i < objectToGenerate.Length * repetitions; i++)
        {
            for (int j = 0; j < objectsPerCircle; j++)
            {
                GameObject instantiateObj = UnityEngine.Object.Instantiate(objectToGenerate[i % objectToGenerate.Length], 
                    new Vector3((float)(distanceBetweenObjects * i * Math.Cos((2 * Math.PI * j) / objectsPerCircle)), 0,
                                (float)(distanceBetweenObjects * i * Math.Sin((2 * Math.PI * j) / objectsPerCircle))), Quaternion.identity);
                instantiateObj.transform.parent = transform;
                instantiateObj.transform.localScale = new Vector3(scale, scale, scale);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
