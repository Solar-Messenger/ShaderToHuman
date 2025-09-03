/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../include/s2h.hlsl"
#include "../include/s2h_3d.hlsl"

/*$(ShaderResources)*/

static const float columnWidthInChars = 33.0f;

void separator(inout ContextGather ui)
{
    ui.textColor = float4(1, 1, 1, 1);
    s2h_setScale(ui, 1);
    s2h_printLF(ui);
    s2h_printSpace(ui, columnWidthInChars - 3);
    s2h_frame(ui, columnWidthInChars - 3);
    s2h_printLF(ui);
    s2h_printLF(ui);
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = float2(pxPos) / float2(dimensions); 

    float4 ret = float4(0,0,0,0);

    {
        ContextGather ui;

        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, float2(10, 10));
        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

        // s2h_printTxt()
        {
            ui.textColor.rgb = float3(1,1,1);
            s2h_setScale(ui, 2.0f);
            s2h_printTxt(ui, _G, _a, _t, _h, _e, _r);
            s2h_printTxt(ui, _T, _e, _s, _t);
            s2h_printLF(ui);
            separator(ui);
        }

        // print characters in different size using s2h_setScale(), s2h_printTxt(), s2h_printLF(), s2h_printSpace()
        {
            ui.textColor.rgb = float3(1,1,0);
            for(uint i = 1u; i <= 3u; ++i)
            {
                s2h_setScale(ui, float(i));
                s2h_printTxt(ui, _A, _B, _C);
                s2h_printTxt(ui, _a, _b, _c);
                s2h_printSpace(ui, 2.0f);
                s2h_printTxt(ui, _x);
                s2h_printLF(ui);
            }
            separator(ui);
        }

        // printInt()
        for(uint i = 1u; i <= 2u; ++i)
        {
            s2h_setScale(ui, float(i));
            s2h_printInt(ui, 0); s2h_printLF(ui);
            s2h_printInt(ui, -12345); s2h_printLF(ui);
            s2h_printInt(ui, int(s2h_fontSize())); s2h_printLF(ui);
            s2h_printInt(ui, 0x7ffffff); s2h_printLF(ui); // 134217727
            s2h_printInt(ui, -0x7ffffff); s2h_printLF(ui); // -134217727
        }
        separator(ui);

        // s2h_printHex()
        for(uint i = 1u; i <= 2u; ++i)
        {
            s2h_setScale(ui, float(i));
            s2h_printHex(ui, 0u); s2h_printLF(ui);
            s2h_printHex(ui, 0xfffffffu); s2h_printLF(ui);
            s2h_printHex(ui, 0x87654321u); s2h_printLF(ui);
            s2h_printHex(ui, 0x09abcdefu); s2h_printLF(ui);
        }
        separator(ui);

        // printFloat()
        for(uint i = 1u; i <= 2u; ++i)
        {
            s2h_setScale(ui, float(i));
            s2h_printFloat(ui, 0.0f); s2h_printLF(ui);
            s2h_printFloat(ui, -0.1f); s2h_printLF(ui);
            s2h_printFloat(ui, -12.34f); s2h_printLF(ui);
            s2h_printFloat(ui, 12.34f); s2h_printLF(ui);
            s2h_printFloat(ui, -12345.0f); s2h_printLF(ui);
            s2h_printFloat(ui, 100.0f); s2h_printLF(ui);
            s2h_printFloat(ui, float(0x7ffffff)); s2h_printLF(ui); // 134217727
            s2h_printFloat(ui, float(-0x7ffffff)); s2h_printLF(ui); // -134217727
        }
        separator(ui);

        // next column
        ui.pxCursor = float2(5.0f + columnWidthInChars * 8.0f, 5.0f);
        ui.pxLeftX = ui.pxCursor.x; 

        // colorize text using ui.textColor.rgb, darker (sRGB / linear has effect), and larger than 1
        {
            s2h_setScale(ui, 2.0f);
            ui.textColor.rgb = float3(1,0,0) * 0.5f;
            s2h_printTxt(ui, _R);
            ui.textColor.rgb = float3(0,1,0) * 0.5f;
            s2h_printTxt(ui, _G);
            ui.textColor.rgb = float3(0,0,1) * 0.5f;
            s2h_printTxt(ui, _B);
            s2h_printTxt(ui, _SPACE);
            ui.textColor.rgb = float3(1,0,0);
            s2h_printTxt(ui, _R);
            ui.textColor.rgb = float3(0,1,0);
            s2h_printTxt(ui, _G);
            ui.textColor.rgb = float3(0,0,1);
            s2h_printTxt(ui, _B);
            s2h_printTxt(ui, _SPACE);
            ui.textColor.rgb = float3(1,0,0) * 10.0f;
            s2h_printTxt(ui, _R);
            ui.textColor.rgb = float3(0,1,0) * 10.0f;
            s2h_printTxt(ui, _G);
            ui.textColor.rgb = float3(0,0,1) * 10.0f;
            s2h_printTxt(ui, _B);
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_printBox(), s2h_printDisc()
        for(uint i = 1u; i <= 3u; ++i)
        {
            s2h_setScale(ui, float(i));
            s2h_printBox(ui, float4(1, 0.7, 0.3f, 1));
            s2h_printBox(ui, float4(1, 0, 0, 1));
            s2h_printDisc(ui, float4(0, 1, 0, 1));
            s2h_printDisc(ui, float4(1, 1, 0, 1));
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_radioButton(), s2h_button()
        s2h_setScale(ui, 1);
        s2h_printTxt(ui, 'R', 'a', 'd', 'i', 'o');
        s2h_printTxt(ui, ' ', '=', ' ');
        s2h_printInt(ui, UIState[0].UIRadioState);
        s2h_printLF(ui);
        s2h_printLF(ui);
        for(uint i = 1; i <= 2; ++i)
        {
            s2h_setScale(ui, i);
            s2h_printTxt(ui, 'X');
            ui.buttonColor = float4(1,0,0,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 1) && leftMouse) UIState[0].UIRadioState = 1;
            ui.buttonColor = float4(0,1,0,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 2) && leftMouse) UIState[0].UIRadioState = 2;
            ui.buttonColor = float4(0,0,1,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 3) && leftMouse) UIState[0].UIRadioState = 3;
            ui.buttonColor = float4(0.5f,0.5f,0.5f,1);
            s2h_printTxt(ui, ' ', 'C', 'l', 'e', 'a', 'r');
            if(s2h_button(ui, 5) && leftMouse) UIState[0].UIRadioState = 0;
            s2h_printTxt(ui, 'X');
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_checkBox
        for(uint i = 1; i <= 3; ++i)
        {
            s2h_setScale(ui, i);
            s2h_printInt(ui, UIState[0].UICheckboxState);
            s2h_printTxt(ui, '=', 'X');
            ui.buttonColor = float4(0.5f,0.5f,0.5f,1);
            if(s2h_checkBox(ui, UIState[0].UICheckboxState) && leftMouseClicked) UIState[0].UICheckboxState = !UIState[0].UICheckboxState;
            s2h_printTxt(ui, 'C', 'h', 'e', 'c', 'k');
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_progress()
        s2h_printTxt(ui, 'P', 'r', 'o', 'g', 'r');
        s2h_printTxt(ui, 'e', 's', 's');
        s2h_printLF(ui);
        for(uint i = 1; i <= 3; ++i)
        {
            s2h_setScale(ui, i);
            s2h_progress(ui, 3, -10.0f);
            s2h_printTxt(ui, 'X');
            s2h_progress(ui, 5, 0.0f);
            s2h_printLF(ui);
            s2h_progress(ui, 3, 0.2f);
            s2h_printTxt(ui, 'X');
            s2h_progress(ui, 5, 0.7f);
            s2h_printLF(ui);
            s2h_progress(ui, 3, 1.0f);
            s2h_printTxt(ui, 'X');
            s2h_progress(ui, 5, 2.0f);
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_sliderFloat()
        {
            s2h_printTxt(ui, 'F', 'l', 'o', 'a', 't');
            s2h_sliderFloat(ui, 8, UIState[0].colorSlider0.a, 0.0f, 1.0f);
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_sliderRGB()
        for(uint i = 1; i <= 2; ++i)
        {
            s2h_setScale(ui, i);
            s2h_sliderRGB(ui, 10, UIState[0].colorSlider0.rgb);
            s2h_printTxt(ui, 'R', 'G', 'B'); // text right behind the UI element
            s2h_printLF(ui);
            s2h_printLF(ui);    // multiple s2h_printLF are needed
            s2h_printLF(ui);
        }
        separator(ui);

        // for debugging:
        s2h_printTxt(ui, 's', '2', 'h', '_');
        s2h_printTxt(ui, 'S', 't', 'a', 't', 'e', ' ');
        s2h_printInt(ui, UIState[0].s2h_State.x);
        s2h_printTxt(ui, ',');
        s2h_printInt(ui, UIState[0].s2h_State.y);
        s2h_printTxt(ui, ',');
        s2h_printInt(ui, UIState[0].s2h_State.z);
        s2h_printTxt(ui, ',');
        s2h_printInt(ui, UIState[0].s2h_State.w);
        s2h_printLF(ui);
        s2h_printLF(ui);

        // next column
        ui.pxCursor = float2(5 + 2 * columnWidthInChars * 8, 5);
        ui.pxLeftX = ui.pxCursor.x; 

        // s2h_drawCircle()
        {
            // todo: dark edges around looks wrong, sRGB ?
            s2h_drawCircle(ui, ui.pxCursor + 10, 10, float4(1,0,0,1), 0);
            s2h_drawCircle(ui, ui.pxCursor + int2(20, 0) + 10, 10, float4(0,1,0,1), 4);
            s2h_drawCircle(ui, ui.pxCursor + int2(40, 0) + 10, 10, float4(0,0,1,1), 10);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
        separator(ui);

        // s2h_frame()
        {
            ui.scale = 3;
            ui.textColor = float4(0, 0 ,0, 1);
            s2h_printSpace(ui, 1);
            s2h_printTxt(ui, 'F', 'r', 'a', 'm', 'e');
            s2h_frame(ui, 5);
            s2h_printLF(ui);
            s2h_printSpace(ui, 1);
            ui.textColor = float4(1, 1, 0, 1);
            ui.frameFillColor = float4(1, 0 ,0, 1);
            ui.frameBorderColor = float4(0.5f, 0 ,0, 1);
            s2h_printTxt(ui, 'F', 'r', 'a', 'm', 'e');
            s2h_frame(ui, 5);
        }

        // more unit tests to come




        // opaque green background
        float4 background = float4(0.2f, 0.5f, 0.2f, 1.0f);

        Output[DTid] = lerp(background, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
        s2h_deinit(ui, UIState[0].s2h_State);
    }
}