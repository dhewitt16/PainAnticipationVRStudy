using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

using Valve.VR;
using Valve.VR.InteractionSystem;

public class SliderControl : MonoBehaviour
{
    public SteamVR_Action_Boolean increaseSliderAction = SteamVR_Input.GetBooleanAction("SliderIncrease");
    public SteamVR_Action_Boolean decreaseSliderAction = SteamVR_Input.GetBooleanAction("SliderDecrease");
    private bool increaseSlider = false;
    private bool decreaseSlider = false;
    public float hiddenValue = 0;
    public BoardUIManager boardUI;

    // Start is called before the first frame update
    void Start()
    {
        boardUI = GameObject.Find("Board").GetComponent<BoardUIManager>();
    }

    // Update is called once per frame
    void Update()
    {
        if (increaseSliderAction != null)
        {
            if (increaseSlider)
            {
                bool increaseLeftHandStop = increaseSliderAction.GetStateUp(SteamVR_Input_Sources.LeftHand);
                bool increaseRightHandStop = increaseSliderAction.GetStateUp(SteamVR_Input_Sources.RightHand);
                increaseSlider = !(increaseLeftHandStop || increaseRightHandStop);
            }
            else
            {
                bool increaseLeftHand = increaseSliderAction.GetStateDown(SteamVR_Input_Sources.LeftHand);
                bool increaseRightHand = increaseSliderAction.GetStateDown(SteamVR_Input_Sources.RightHand);
                increaseSlider = increaseLeftHand || increaseRightHand;
            }
        }

        if (decreaseSliderAction != null)
        {
            if (decreaseSlider)
            {
                bool decreaseLeftHandStop = decreaseSliderAction.GetStateUp(SteamVR_Input_Sources.LeftHand);
                bool decreaseRightHandStop = decreaseSliderAction.GetStateUp(SteamVR_Input_Sources.RightHand);
                decreaseSlider = !(decreaseLeftHandStop || decreaseRightHandStop);
            }
            else
            {
                bool decreaseLeftHand = decreaseSliderAction.GetStateDown(SteamVR_Input_Sources.LeftHand);
                bool decreaseRightHand = decreaseSliderAction.GetStateDown(SteamVR_Input_Sources.RightHand);
                decreaseSlider = decreaseLeftHand || decreaseRightHand;
            }
        }

        if (increaseSlider && !decreaseSlider)
        {
            hiddenValue += 0.01f;
            if (hiddenValue > 1)
            {
                hiddenValue = 1;
            }
        }

        if (!increaseSlider && decreaseSlider)
        {
            hiddenValue -= 0.01f;
            if (hiddenValue < 0)
            {
                hiddenValue = 0;
            }
        }

        if (Math.Abs(hiddenValue - GetComponent<Slider>().value) > 0.1)
        {
            boardUI.SetRatingsVal((int)(Math.Round(hiddenValue, 1) * 10), false);
        }
    }
}
