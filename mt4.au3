#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
;#include <GUIListViewEx.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>
#include <HTTP.au3>
#include <JSON.au3>
;~ #include 'scriptingdic.au3'
;~ #include <Array.au3> ; Needed only for _ArrayDisplay, and not required by the lib

;~ Global $priceObj = _InitDictionary()

Func ComboBox_SelectString($winTitle, $winText, $control, $option)
 Local $hWnd = ControlGetHandle($winTitle, $winText, $control)
 Local $index = _GUICtrlComboBox_FindString($hWnd, $option)
 If $index = -1 Then
  SetError(1)
  Return False
 EndIf
 ;_GUICtrlComboBox_ShowDropDown($hWnd, True)
 ;_GUICtrlComboBox_SetCurSel($hWnd, $index)
 ;_GUICtrlComboBox_ShowDropDown($hWnd)

 If $index = 0 Then
  ; If the item is the first in the list, use hotkeys to navigate to it
  _GUICtrlComboBox_ShowDropDown($hWnd, True)
  ControlSend($winTitle, $winText, $hWnd, "{PGUP}")
  _GUICtrlComboBox_ShowDropDown($hWnd)
 Else
  ; Select the item right before the target index, then send down
  _GUICtrlComboBox_ShowDropDown($hWnd, True)
  _GUICtrlComboBox_SetCurSel($hWnd, $index - 1)
  ControlSend($winTitle, $winText, $hWnd, "{DOWN}")
  _GUICtrlComboBox_ShowDropDown($hWnd)
 EndIf
 Return True
EndFunc   ;==>ComboBox_SelectString

Func Example($verbose)
   ; Retrieve the position as well as height and width of the active window.
   Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:ToolbarWindow32; INSTANCE:4]")

;   WinActivate($hWin)
;~    Send("{down}")    ;;;select a random item

;~    ConsoleWrite("Window handle: " & $hWin & @LF)
;~    ConsoleWrite("Control handle: " & $hwnd & @LF)



   Local $tradeData = _HTTP_Get("http://localhost/data")
   local $tradeObj = Json_Decode($tradeData)

;~ 	; test
;~ 	$priceObj.Add("1.10756", True)


   Local $i = 0
   While 1
	   Local $id = '[' & $i & '].'
	   Local $symbol = Json_Get($tradeObj, $id & 'symbol')
	   If @error Then ExitLoop

	  Local $price = Json_Get($tradeObj, $id & 'price')


	   Local $type = Json_Get($tradeObj, $id & 'type')
	   Local $volume = Json_Get($tradeObj, $id & 'size')

	   Local $orderType = "Buy Limit"
	   If $type == "sell" Then
		  $orderType = "Buy Limit"
	   Else
		  $orderType = "Sell Limit"
	   Endif



	   ControlClick($hwnd, "", "","left", 1, 280, 10)

	  Local $hOrderWin = WinWait("Order", "", 10)
	  Local $hVolume = ControlGetHandle($hOrderWin, "", "[CLASS:Edit; INSTANCE:1]")

;~ 	  ConsoleWrite("Order handle: " & $hOrderWin & @LF)

	  ControlSetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:1]", $volume)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:1]", $symbol)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:3]", "Pending Order")
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:5]", $orderType)
	  ControlSetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:6]", $price)

	  ;~    click place then done
	  Local $hPlace = ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:16]")
;~ 	  ConsoleWrite("Place handle: " & $hPlace & @LF)
	  ControlClick($hPlace, "", "","left", 1, 5, 5)



;~ 	   update command
      _HTTP_Post("http://localhost/data", "price=" & URLEncode($price))
	   ConsoleWrite("symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price)

	   Sleep(1000)

	   $i += 1
	WEnd


   Sleep(2000)
   Example($verbose)


EndFunc   ;==>Example



;~ While 1
;~         Sleep(2000)
;~         Example(17, 0, 0)
;~ 		Example(1, 1, 0)
;~ WEnd

Example(0)