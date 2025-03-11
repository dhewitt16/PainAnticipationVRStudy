/*
    Created by Shuangyi Tong <shuangyi.tong@eng.ox.ac.uk> @ 2021
*/

using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Text;

using UnityEngine;
using UnityEngine.SceneManagement;

using Valve.VR.InteractionSystem;

public class FrameInfo
{
    protected void CopyArraySized3ToPosition(GameObject obj, double[] arr)
    {
        obj.transform.position = new Vector3((float)arr[0], (float)arr[1], (float)arr[2]);
    }

    protected void CopyArraySized3ToScale(GameObject obj, double[] arr)
    {
        obj.transform.localScale = new Vector3((float)arr[0], (float)arr[1], (float)arr[2]);
    }

    protected void CopyPositionToArraySized3(GameObject obj, double[] arr)
    {
        Vector3 pos = obj.transform.position;
        arr[0] = pos.x;
        arr[1] = pos.y;
        arr[2] = pos.z;
    }

    protected void CopyRotationToArraySized4(GameObject obj, double[] arr)
    {
        Quaternion rot = obj.transform.localRotation;
        arr[0] = rot.w;
        arr[1] = rot.x;
        arr[2] = rot.y;
        arr[3] = rot.z;
    }

    protected void CopyVector3ToArray(Vector3 v3, double[] arr)
    {
        arr[0] = v3[0];
        arr[1] = v3[1];
        arr[2] = v3[2];
    }

    protected void CopyVector2ToArray(Vector2 v2, double[] arr)
    {
        arr[0] = v2[0];
        arr[1] = v2[1];
    }
}

[Serializable]
public class TaskDataFrame : FrameInfo
{
    public double[] left_hand_position;
    public double[] left_hand_rotation;
    public double[] right_hand_position;
    public double[] right_hand_rotation;
    public double[] head_position;
    public double[] head_rotation;
    public string object_info = "";
    public string pickable_object_attached = "";
    public string board_command;
    public string user_action;
    public double slider_bar_value = 0;
    public long last_trigger_press_time = -1;
    public long last_cue_time = -1;
 
    public TaskDataFrame(DataContext ctx)
    {
        left_hand_position = new double[3];
        left_hand_rotation = new double[4];
        right_hand_position = new double[3];
        right_hand_rotation = new double[4];
        head_position = new double[3];
        head_rotation = new double[4];

        if (ctx.leftHand)
        {
            CopyPositionToArraySized3(ctx.leftHand, left_hand_position);
            CopyRotationToArraySized4(ctx.leftHand, left_hand_rotation);
        }

        if (ctx.rightHand)
        {
            CopyPositionToArraySized3(ctx.rightHand, right_hand_position);
            CopyRotationToArraySized4(ctx.rightHand, right_hand_rotation);
        }

        CopyPositionToArraySized3(ctx.mainCamera, head_position);
        CopyRotationToArraySized4(ctx.mainCamera, head_rotation);

        Player player = Player.instance;
        if (player)
        {
            foreach (Hand hand in player.hands)
            {
                GameObject attachedObject = hand.currentAttachedObject;
                if (attachedObject != null)
                {
                    pickable_object_attached = attachedObject.name;
                }
            }
        }

        GameObject[] collidingObject = GameObject.FindGameObjectsWithTag("CollidingObject");
        if (collidingObject.Length > 0)
        {
            object_info = collidingObject[0].GetComponent<ApproachingObject>().objectInformation;
            collidingObject[0].GetComponent<ApproachingObject>().objectInformation = "";
        }

        if (ctx.UIManager)
        {
            board_command = ctx.UIManager.boardCommand;
            user_action = ctx.UIManager.userAction;
            last_trigger_press_time = ctx.UIManager.lastTriggerPressTime;
            last_cue_time = ctx.UIManager.lastCueTime;
            ctx.UIManager.boardCommand = ""; // Reset it
            ctx.UIManager.userAction = ""; // Reset it
            // no need to reset trigger press time and cue time
        }

        slider_bar_value = ctx.UIManager.GetSliderValue();
    }
}

[Serializable]
public class TaskControlFrame : FrameInfo
{
    public string switch_scene = "";
    public double[] set_player_position;
    public double[] set_player_scale;
    public string show_button_hints = "";
    public string hide_button_hints = "";
    public int show_ui_board = -1;
    public string set_board_title_text = "";
    public string set_board_main_text = "";
    public string set_board_confirm_button_text = "";
    public int activate_confirm_button = -1;
    public int show_ui_main_session = -1;
    public int show_slider_bar = -1;
    public string set_hand_active;
    public string set_left_label = "";
    public string set_right_label = "";
    public int set_ratings = -1;
    public string start_new_trial_ttc = "";
    public string start_new_trial_condition = "";
    public double[] set_speed_condition;
    public int set_using_cue = -1;

    public void ApplyControlData(DataContext ctx)
    {
        if (switch_scene != "")
        {
            SceneManager.LoadScene(switch_scene, LoadSceneMode.Single);
        }

        if (set_player_position != null)
        {
            CopyArraySized3ToPosition(ctx.player, set_player_position);
        }

        if (set_player_scale != null)
        {
            CopyArraySized3ToScale(ctx.player, set_player_scale);
            CopyArraySized3ToScale(ctx.UIManager.canvas, set_player_scale);
        }

        if (show_button_hints != "")
        {
            ctx.UIManager.ShowButtonHints(show_button_hints);
        }

        if (hide_button_hints != "")
        {
            ctx.UIManager.HideButtonHints(hide_button_hints);
        }

        if (show_ui_board != -1)
        {
            ctx.UIManager.SetBoardDisplay(Convert.ToBoolean(show_ui_board));
        }

        if (set_board_title_text != "")
        {
            ctx.UIManager.SetTitleText(set_board_title_text);
        }

        if (set_board_main_text != "")
        {
            ctx.UIManager.SetMainText(set_board_main_text);
        }

        if (set_board_confirm_button_text != "")
        {
            ctx.UIManager.SetConfirmButtonText(set_board_confirm_button_text);
        }

        if (activate_confirm_button != -1)
        {
            ctx.UIManager.ActivateConfirmButton(Convert.ToBoolean(activate_confirm_button));
        }

        if (show_ui_main_session != -1)
        {
            ctx.UIManager.SetMainSessionUIDisplay(Convert.ToBoolean(show_ui_main_session));
        }

        if (show_slider_bar != -1)
        {
            ctx.UIManager.SetSliderValue(0.5f); // Reset slider
            ctx.UIManager.SetSliderDisplay(Convert.ToBoolean(show_slider_bar));
        }

        if (set_hand_active != null)
        {
            if (set_hand_active == "Left")
            {
                ctx.leftHand.SetActive(true);
                ctx.rightHand.SetActive(false);
                Debug.Log("Set Left Active Only");
            }
            else if (set_hand_active == "Right")
            {
                ctx.leftHand.SetActive(false);
                ctx.rightHand.SetActive(true);
                Debug.Log("Set Right Active Only");
            }
            else if (set_hand_active == "Both")
            {
                ctx.leftHand.SetActive(true);
                ctx.rightHand.SetActive(true);
                Debug.Log("Set Both Active");
            }
            else
            {
                Debug.Log("Unknown hand: " + set_hand_active);
            }
        }

        if (set_left_label != "")
        {
            ctx.UIManager.SetLeftLabel(set_left_label);
        }

        if (set_right_label != "")
        {
            ctx.UIManager.SetRightLabel(set_right_label);
        }

        if (set_ratings != -1)
        {
            ctx.UIManager.SetRatingsVal(set_ratings);
        }

        float distanceFactor = -1.0f;
        float totalTime = -1.0f;
        float disappearTime = -1.0f;
        int baselineTime = 1000;
        if (set_speed_condition != null)
        {
            distanceFactor = (float)set_speed_condition[0];
            totalTime = (float)set_speed_condition[1];
            disappearTime = (float)set_speed_condition[2];
            baselineTime = (int)(set_speed_condition[3] * 1000);
        }

        if (start_new_trial_ttc != "")
        {
            GameObject ballPrefab = (GameObject)Resources.Load("Prefabs/Sphere");

            GameObject instantiateBall = UnityEngine.Object.Instantiate(ballPrefab, 
                new Vector3(0, 0, 0), Quaternion.identity);
            ApproachingObject ballControl = instantiateBall.GetComponent<ApproachingObject>();
            ballControl.target = start_new_trial_ttc;
            if (distanceFactor > 0)
            {
                ballControl.spawnDistanceFactor = distanceFactor;
            }
            if (totalTime > 0)
            {
                ballControl.totalTimeToCollisionTime = totalTime;
            }
            if (disappearTime > 0)
            {
                ballControl.disappearTime = disappearTime;
            }
            ballControl.Instantiate(baselineTime);
            Debug.Log("Object generated");
            ctx.lastStartTime = ballControl.startTimeUnixTS;
        }

        if (start_new_trial_condition != "")
        {
            ctx.UIManager.SetCueActive(start_new_trial_condition, set_using_cue);

            GameObject cubePrefab = (GameObject)Resources.Load("Prefabs/Cube");

            GameObject instantiateCube = UnityEngine.Object.Instantiate(cubePrefab, 
                new Vector3(0, 0, 0), Quaternion.identity);
            
            ApproachingObject cubeControl = instantiateCube.GetComponent<ApproachingObject>();
            cubeControl.target = start_new_trial_condition;
            if (distanceFactor > 0)
            {
                cubeControl.spawnDistanceFactor = distanceFactor;
            }
            if (totalTime > 0)
            {
                cubeControl.totalTimeToCollisionTime = totalTime;
            }
            if (disappearTime > 0)
            {
                cubeControl.disappearTime = disappearTime;
            }
            cubeControl.Instantiate(2800);
            ctx.lastStartTime = cubeControl.startTimeUnixTS;
        }
    }
}

public class DataContext
{
    public BoardUIManager UIManager;
    public GameObject player;
    public GameObject leftHand;
    public GameObject rightHand;
    public PainlabTask taskMgr;
    public GameObject mainCamera;
    public long lastStartTime;
}


public class PainlabTaskProtocol : PainlabProtocol
{
    public string descriptorString;
    public DataContext ctx = null;

    protected override void RegisterWithDescriptor()
    {
        SendString(descriptorString);

        return;
    }

    protected override byte[] GetFrameBytes()
    {
        TaskDataFrame dataFrame = new TaskDataFrame(ctx);

        byte[] byteData = StringToBytes(JsonUtility.ToJson(dataFrame));

        return byteData;
    }

    protected override void ApplyControlData()
    {
        TaskControlFrame controlFrame 
            = JsonUtility.FromJson<TaskControlFrame>
                (Encoding.UTF8.GetString(_controlBuffer, 0, (int)_numControlBytes));

        controlFrame.ApplyControlData(ctx);
    }

    protected override void DebugOutput(string msg)
    {
        Debug.Log(msg);
    }
}

public class PainlabTask : MonoBehaviour
{
    static string descriptorPath = "device-descriptor";
    static string networkConfigPath = "network-config";
    protected PainlabTaskProtocol _protocol;    
    
    void Awake()
    {
        DontDestroyOnLoad(this.gameObject);
    }

    void Start()
    {
        // Init context data
        DataContext ctx = new DataContext();
        GameObject board = GameObject.Find("Board");
        ctx.UIManager = board.GetComponent<BoardUIManager>();
        ctx.player = GameObject.Find("Player");
        ctx.leftHand = GameObject.Find("LeftHand");
        ctx.rightHand = GameObject.Find("RightHand");
        ctx.mainCamera = GameObject.Find("VRCamera");
        ctx.taskMgr = this;

        _protocol = new PainlabTaskProtocol();
        _protocol.ctx = ctx;

        TextAsset networkConfig = (TextAsset)Resources.Load(networkConfigPath);
        string networkJsonString = networkConfig.text;
        NetworkConfig netConf = JsonUtility.FromJson<NetworkConfig>(networkJsonString);

        TextAsset descriptor = (TextAsset)Resources.Load(descriptorPath);
        string descriptorString = descriptor.text;
        _protocol.descriptorString = descriptorString;

        _protocol.Init(netConf);
    }

    void Update()
    {
        _protocol.UpdateFrameData();
        _protocol.HandlingControlData();
    }

    void OnApplicationQuit()
    {
        _protocol.Close();
    }

    public GameObject InstantiateHelper(GameObject prefab, Vector3 newPos, Quaternion newRot)
    {
        return Instantiate(prefab, newPos, newRot);
    }

    public void DestroyHelper(GameObject objRef)
    {
        Destroy(objRef);
    }
}