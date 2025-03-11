using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class NumericalColor : MonoBehaviour
{
    private Text text = null;
    // Start is called before the first frame update
    void Start()
    {
        text = GetComponent<Text>();
    }

    // Update is called once per frame
    void Update()
    {
        string t = text.text;
        float numVal = 0;

        try
        {
            numVal = float.Parse(t);

            if (numVal < 0 || numVal > 10)
            {
                throw new FormatException("Out of range");
            }
        }
        catch (FormatException e)
        {
            Debug.Log("Unable to parse string to int");
            numVal = 0;
        }

        Color c = new Color((float)(numVal / 10f), 1 - (float)(numVal / 10f), 0.9451f * (1 - (float)(numVal / 10f)));
        text.color = c;
    }
}
