//========= Copyright 2018, HTC Corporation. All rights reserved. ===========

// Modified by Shuangyi Tong <shuangyi.tong@eng.ox.ac.uk> Jan. 09, 2022
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Assertions;

using ViveSR;
using ViveSR.anipal;
using ViveSR.anipal.Eye;

public class SRanipal_GazeObject : MonoBehaviour
{
    private static EyeData eyeData = new EyeData();
    private bool eye_callback_registered = false;

    public string hitObjectName = "";
    public Vector3 gazeLocalDirection = Vector3.zero;
    public float left_pupil_diameter_mm = -1;
    public float left_eye_openness = -1;
    public Vector2 left_pupil_position = Vector2.zero;
    public float right_pupil_diameter_mm = -1;
    public float right_eye_openness = -1;
    public Vector2 right_pupil_position = Vector2.zero;

    void Awake()
    {
        DontDestroyOnLoad(this.gameObject);
        gazeLocalDirection = new Vector3(0, 0, 0);
    }

    private void Start()
    {
        if (!SRanipal_Eye_Framework.Instance.EnableEye)
        {
            Debug.Log("SRanipal_Eye_Framework not enabled");
            enabled = false;
            return;
        }
    }

    private void Update()
    {
        if (SRanipal_Eye_Framework.Status != SRanipal_Eye_Framework.FrameworkStatus.WORKING &&
            SRanipal_Eye_Framework.Status != SRanipal_Eye_Framework.FrameworkStatus.NOT_SUPPORT) 
            
        {
            Debug.Log("Ranipal_Eye_Framework not working");
            return;
        }

        if (SRanipal_Eye_Framework.Instance.EnableEyeDataCallback == true && eye_callback_registered == false)
        {
            SRanipal_Eye.WrapperRegisterEyeDataCallback(Marshal.GetFunctionPointerForDelegate((SRanipal_Eye.CallbackBasic)EyeCallback));
            eye_callback_registered = true;
        }
        else if (SRanipal_Eye_Framework.Instance.EnableEyeDataCallback == false && eye_callback_registered == true)
        {
            SRanipal_Eye.WrapperUnRegisterEyeDataCallback(Marshal.GetFunctionPointerForDelegate((SRanipal_Eye.CallbackBasic)EyeCallback));
            eye_callback_registered = false;
        }

        Vector3 GazeOriginCombinedLocal, GazeDirectionCombinedLocal;

        if (eye_callback_registered)
        {
            if (SRanipal_Eye.GetGazeRay(GazeIndex.COMBINE, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal, eyeData)) { }
            else if (SRanipal_Eye.GetGazeRay(GazeIndex.LEFT, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal, eyeData)) { }
            else if (SRanipal_Eye.GetGazeRay(GazeIndex.RIGHT, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal, eyeData)) { }
            else return;

            SingleEyeData leftEyeData = eyeData.verbose_data.left;
            SingleEyeData rightEyeData = eyeData.verbose_data.right;

            bool valid = false;

            valid = leftEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_PUPIL_DIAMETER_VALIDITY);
            left_pupil_diameter_mm = valid ? leftEyeData.pupil_diameter_mm : -1;

            valid = rightEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_PUPIL_DIAMETER_VALIDITY);
            right_pupil_diameter_mm = valid ? rightEyeData.pupil_diameter_mm : -1;

            valid = leftEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_EYE_OPENNESS_VALIDITY);
            left_eye_openness = valid ? leftEyeData.eye_openness : -1;

            valid = rightEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_EYE_OPENNESS_VALIDITY);
            right_eye_openness = valid ? rightEyeData.eye_openness : -1;

            valid = leftEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_PUPIL_POSITION_IN_SENSOR_AREA_VALIDITY);
            left_pupil_position = valid ? leftEyeData.pupil_position_in_sensor_area : Vector2.zero;

            valid = rightEyeData.GetValidity(SingleEyeDataValidity.SINGLE_EYE_DATA_PUPIL_POSITION_IN_SENSOR_AREA_VALIDITY);
            right_pupil_position = valid ? rightEyeData.pupil_position_in_sensor_area : Vector2.zero;
        }
        else
        {
            if (SRanipal_Eye.GetGazeRay(GazeIndex.COMBINE, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal)) { }
            else if (SRanipal_Eye.GetGazeRay(GazeIndex.LEFT, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal)) { }
            else if (SRanipal_Eye.GetGazeRay(GazeIndex.RIGHT, out GazeOriginCombinedLocal, out GazeDirectionCombinedLocal)) { }
            else return;
        }

        gazeLocalDirection = GazeDirectionCombinedLocal;
        Vector3 GazeDirectionCombined = Camera.main.transform.TransformDirection(GazeDirectionCombinedLocal);

        RaycastHit hit;
        if (Physics.Raycast(Camera.main.transform.position, GazeDirectionCombined, out hit, Mathf.Infinity)) {
            GameObject hitObj = hit.collider.gameObject;
            hitObjectName = hitObj.name;
        }
    }
    private void Release()
    {
        if (eye_callback_registered == true)
        {
            SRanipal_Eye.WrapperUnRegisterEyeDataCallback(Marshal.GetFunctionPointerForDelegate((SRanipal_Eye.CallbackBasic)EyeCallback));
            eye_callback_registered = false;
        }
    }

    internal class MonoPInvokeCallbackAttribute : System.Attribute
    {
        public MonoPInvokeCallbackAttribute() { }
    }

    [MonoPInvokeCallback]
    private static void EyeCallback(ref EyeData eye_data)
    {
        eyeData = eye_data;
    }
}