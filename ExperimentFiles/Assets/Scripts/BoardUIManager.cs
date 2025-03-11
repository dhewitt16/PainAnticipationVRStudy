/*
    Created by Shuangyi Tong <shuangyi.tong@eng.ox.ac.uk> @ 2021
*/

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

using Valve.VR;
using Valve.VR.InteractionSystem;

public class BoardUIManager : MonoBehaviour
{
    public SteamVR_Action_Boolean menuButton = SteamVR_Input.GetBooleanAction("Menu");
    public SteamVR_Action_Boolean trigger = SteamVR_Input.GetBooleanAction("InteractUI");
    public string boardCommand = "";
    public string userAction = "";
    public long lastTriggerPressTime = -1;

    public GameObject canvas;
    public GameObject board_ui;
    public GameObject dialogue_title;
    public GameObject dialogue_text;
    public GameObject confirm_button;
    public GameObject confirm_button_cube;
    public GameObject mainSessionUI;
    public GameObject leftCue;
    public GameObject rightCue;
    public GameObject middleCue;
    public GameObject collectedItemsValue;
    public GameObject slider;
    public GameObject leftLabel;
    public GameObject rightLabel;
    public GameObject ratings;

    public GameObject leftHand;
    public GameObject rightHand;

    public Sprite[] CandidateCues;
    
    private string leftLastColliderName = "";
    private bool leftUICallbackReady = false;
    private Action leftUIResetCallback = () => {};

    private string rightLastColliderName = "";
    private bool rightUICallbackReady = false;
    private Action rightUIResetCallback = () => {};

    public long lastCueTime = -1;
    public long cueTime = 800; // in mS

    void Awake()
    {
        DontDestroyOnLoad(this.gameObject);
    }

    void Start()
    {
        menuButton.AddOnStateDownListener(LeftMenuButtonDown, SteamVR_Input_Sources.LeftHand);
        menuButton.AddOnStateDownListener(RightMenuButtonDown, SteamVR_Input_Sources.RightHand);

        trigger.AddOnStateDownListener(LeftTriggerDown, SteamVR_Input_Sources.LeftHand);
        trigger.AddOnStateDownListener(RightTriggerDown, SteamVR_Input_Sources.RightHand);
    }

    private void ShowControllerAndPointer()
    {
        Hand leftHandComp = leftHand.GetComponent<Hand>();
        leftHandComp.ShowController(true);
        Hand rightHandComp = rightHand.GetComponent<Hand>();
        rightHandComp.ShowController(true);
        leftHand.transform.Find("LeftPointer").gameObject.SetActive(true);
        rightHand.transform.Find("RightPointer").gameObject.SetActive(true);
    }

    private void HideControllerAndPointer()
    {
        Hand leftHandComp = leftHand.GetComponent<Hand>();
        leftHandComp.HideController(true);
        Hand rightHandComp = rightHand.GetComponent<Hand>();
        rightHandComp.HideController(true);

        leftHand.transform.Find("LeftPointer").gameObject.SetActive(false);
        rightHand.transform.Find("RightPointer").gameObject.SetActive(false);
    }

    public void SetBoardDisplay(bool active)
    {
        if (active)
        {
            ShowControllerAndPointer();
        }
        else
        {
            HideControllerAndPointer();
        }

        board_ui.SetActive(active);
    }

    // Update is called once per frame
    void Update()
    {
        long now = DateTimeOffset.Now.ToUnixTimeMilliseconds();
        if (now - lastCueTime > cueTime && lastCueTime != -1)
        {
            Debug.Log(Time.fixedTime);
            leftCue.SetActive(false);
            rightCue.SetActive(false);
            middleCue.SetActive(false);
            lastCueTime = -1;
        }
    }

    public void HandleRaycastHit(string inputSource, RaycastHit hit)
    {
        GameObject hitObj = hit.collider.gameObject;

        // Invoke reset action
        if (inputSource == "LeftPointer" && leftUICallbackReady 
            && leftLastColliderName != hitObj.name)
        {
            // No need to call if the other pointer also on the same object
            if (leftLastColliderName != rightLastColliderName)
            {
                leftUIResetCallback();
            }
            leftUICallbackReady = false;
            leftLastColliderName = hitObj.name;
        }

        if (inputSource == "RightPointer" && rightUICallbackReady 
            && rightLastColliderName != hitObj.name)
        {
            // No need to call if the other pointer also on the same object
            if (leftLastColliderName != rightLastColliderName)
            {
                rightUIResetCallback();
            }
            rightUICallbackReady = false;
            rightLastColliderName = hitObj.name;
        }


        if (hitObj.tag == "UICollider")
        {
            string UIColliderName = hitObj.name;
            switch (UIColliderName) {
                case "ConfirmButtonCube":
                    confirm_button.GetComponent<Image>().color = new Color32(208, 91, 0, 255);

                    if (inputSource == "LeftPointer")
                    {
                        leftUIResetCallback = () => { confirm_button.GetComponent<Image>().color = new Color32(129, 255, 248, 255); };
                        leftUICallbackReady = true;
                    }
                    else if (inputSource == "RightPointer")
                    {
                        rightUIResetCallback = () => { confirm_button.GetComponent<Image>().color = new Color32(129, 255, 248, 255); };
                        rightUICallbackReady = true;
                    }

                    break;
                default:
                    Debug.Log("Unknown UI collider: " + UIColliderName);
                    break;
            }
        }
    }

    public void LeftMenuButtonDown(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left menu button pressed");

        userAction = "MenuButtonPressed";
    }

    public void RightMenuButtonDown(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right menu button pressed");

        userAction = "MenuButtonPressed";
    }

    public void LeftTriggerDown(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left trigger pressed");
        lastTriggerPressTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
        if (leftUICallbackReady && leftLastColliderName == "ConfirmButtonCube" && board_ui.activeSelf)
        {
            boardCommand = "ConfirmButtonPressed";
        }
    }

    public void RightTriggerDown(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right trigger pressed");
        lastTriggerPressTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
        if (rightUICallbackReady && rightLastColliderName == "ConfirmButtonCube" && board_ui.activeSelf)
        {
            boardCommand = "ConfirmButtonPressed";
        }
    }

    public void ShowButtonHints(string actionName)
    {
        Hand leftHandComp = leftHand.GetComponent<Hand>();
        ControllerButtonHints.ShowButtonHint(leftHandComp, SteamVR_Input.GetBooleanAction(actionName));

        Hand rightHandComp = rightHand.GetComponent<Hand>();
        ControllerButtonHints.ShowButtonHint(rightHandComp, SteamVR_Input.GetBooleanAction(actionName));
    }

    public void HideButtonHints(string actionName)
    {
        Hand leftHandComp = leftHand.GetComponent<Hand>();
        ControllerButtonHints.HideButtonHint(leftHandComp, SteamVR_Input.GetBooleanAction(actionName));

        Hand rightHandComp = rightHand.GetComponent<Hand>();
        ControllerButtonHints.HideButtonHint(rightHandComp, SteamVR_Input.GetBooleanAction(actionName));
    }

    public void SetTitleText(string title)
    {
        dialogue_title.GetComponent<Text>().text = title;
    }

    public void SetMainText(string mainText)
    {
        dialogue_text.GetComponent<Text>().text = mainText;
    }

    public void SetConfirmButtonText(string buttonText)
    {
        Text confirm_button_text = confirm_button.transform.GetChild(0).gameObject.GetComponent<Text>();
        confirm_button_text.text = buttonText;
    }

    public void ActivateConfirmButton(bool active)
    {
        confirm_button.SetActive(active);
        confirm_button_cube.SetActive(active);
    }

    public void SetMainSessionUIDisplay(bool active)
    {
        Debug.Log("main session ui active: " + active.ToString());
        mainSessionUI.SetActive(active);
    }

    public void SetCollectedCount(double count)
    {
        collectedItemsValue.GetComponent<Text>().text = count.ToString("0.00");
    }

    public void SetSliderDisplay(bool active)
    {
        slider.SetActive(active);
    }

    public float GetSliderValue()
    {
        return slider.GetComponent<Slider>().value;
    }

    public void SetSliderValue(float v)
    {
        slider.GetComponent<Slider>().value = v;
    }

    public void SetLeftLabel(string l)
    {
        leftLabel.GetComponent<Text>().text = l;
    }

    public void SetRightLabel(string r)
    {
        rightLabel.GetComponent<Text>().text = r;
    }

    public void SetRatingsVal(int r, bool updateHidden=true)
    {
        Debug.Log(r);
        if (r == 999)
        {
            Debug.Log("Hiding");
            ratings.SetActive(false);
            SetSliderDisplay(false);
        }
        else
        {   
            ratings.SetActive(true);
            SetSliderDisplay(true);
            ratings.GetComponent<Text>().text = r.ToString();
            SetSliderValue((float)r / 10f);
            if (updateHidden)
            {
                slider.GetComponent<SliderControl>().hiddenValue = (float)r / 10f;
            }
        }
    }

    public void SetCueActive(string cue, int sprite_id = -1)
    {
        if (cue == "Left")
        {
            if (sprite_id > 0)
            {
                leftCue.GetComponent<SpriteRenderer>().sprite = CandidateCues[sprite_id];
            }
            leftCue.SetActive(true);
        }
        else if (cue == "Right")
        {            
            if (sprite_id > 0)
            {
                rightCue.GetComponent<SpriteRenderer>().sprite = CandidateCues[sprite_id];
            }
            rightCue.SetActive(true);
        }
        else if (cue == "Middle" || cue == "MiddleCondition")
        {
            if (sprite_id > 0)
            {
                middleCue.GetComponent<SpriteRenderer>().sprite = CandidateCues[sprite_id];
            }
            middleCue.SetActive(true);
        }
        lastCueTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    }
}
