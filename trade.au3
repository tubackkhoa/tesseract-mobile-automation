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


Func ClosePrice($list, $historyURL)
   Local $historyData = _HTTP_Get($historyURL)
   local $historyObj = Json_Decode($historyData)
   Local $count = _GUICtrlListView_GetItemCount($list)
;~    ConsoleWrite("Total " & $count & @LF)
   For $ind = 0 To $count - 1 Step 1

	  WinClose("Order")
	  _GUICtrlListView_ClickItem($list, $ind, "left", False, 2)
	  Local $hOrderWin = WinWait("Order", "", 1)
	  Local $sText = WinGetTitle($hOrderWin)

;~ 	  If Not $sText Then ContinueLoop
;~ 	  ConsoleWrite($ind & ") " & $sText & @LF)
	  Local $aArray = StringRegExp($sText, 'at ([^\s]+)', $STR_REGEXPARRAYFULLMATCH)
	  If UBound($aArray) == 2 And HasPrice($historyObj, $aArray[1]) Then
		 Local $aPos = WinGetPos($hOrderWin)
		 MouseClick("left", $aPos[0] + 630, $aPos[1] + 293, 1)
		 ;~ 	   update command
         _HTTP_Post($historyURL, "price=" & URLEncode($price))
	     ConsoleWrite("close price: " & $price & @LF)
		 Sleep(500)
;~ 		 ExitLoop
	  EndIf

   Next
EndFunc

Func HasPrice($historyObj, $price)
   Local $i = 0
   While 1
	   Local $id = '[' & $i & '].'
 	   Local $currentPrice = Json_Get($historyObj, $id & 'price')
	   If @error Then ExitLoop

	  If $currentPrice == $price Then
		 return True
	  EndIf

	   $i += 1
	WEnd

	return False
EndFunc

Func Close($historyURL, $verbose)
   ; Retrieve the position as well as height and width of the active window.
   Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:SysListView32; INSTANCE:1]")

   WinActivate($hWin)
   ClosePrice($hwnd, $historyURL)

EndFunc   ;==>Example

Func Trade($tradeURL, $verbose)
   ; Retrieve the position as well as height and width of the active window.
   Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:ToolbarWindow32; INSTANCE:4]")

;   WinActivate($hWin)
;~    Send("{down}")    ;;;select a random item

;~    ConsoleWrite("Window handle: " & $hWin & @LF)
;~    ConsoleWrite("Control handle: " & $hwnd & @LF)



   Local $tradeData = _HTTP_Get($tradeURL)
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

	   Local $orderType = ""
	   If $type == "sell" Then
		  $orderType = "Sell Limit"
	   Else
		  $orderType = "Buy Limit"
	   Endif



	   ControlClick($hwnd, "", "","left", 1, 280, 10)

	  Local $hOrderWin = WinWait("Order", "", 10)
	  Local $hVolume = ControlGetHandle($hOrderWin, "", "[CLASS:Edit; INSTANCE:1]")

;~ 	  ConsoleWrite("Order handle: " & $hOrderWin & @LF)

;~ 	  ControlSetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:1]", $volume)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:2]", $volume)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:1]", $symbol)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:3]", "Pending Order")
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:5]", $orderType)
	  ControlSetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:6]", $price)
	  $mPrice = ControlGetHandle($hOrderWin, "", "[CLASS:Edit; INSTANCE:6]")
	  ControlClick($mPrice, "", "","left", 2, 60, 10)
	  ControlSend($hOrderWin, "", "[CLASS:Edit; INSTANCE:6]", $price)
;~ 	  Send($price)

;~ 	  trigger increase then decrease to change data of price
;~ 	  $udPrice = ControlGetHandle($hOrderWin, "", "[CLASS:msctls_updown32; INSTANCE:3]");
;~ 	  ControlClick($udPrice, "", "","left", 1, 9, 2)
;~ 	  ControlClick($udPrice, "", "","left", 1, 9, 14)

	  Sleep(1000)
	  ;~    click place then done
	  Local $hPlace = ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:16]")
;~ 	  ConsoleWrite("Place handle: " & $hPlace & @LF)
	  ControlClick($hPlace, "", "","left", 1, 5, 5)



;~ 	   update command
      _HTTP_Post($tradeURL, "price=" & URLEncode($price))
	   ConsoleWrite("symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price & @LF)

;~ 	   close button ok if there is
	  Local $hOK = ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:22]")
	  ControlClick($hOK, "", "","left", 1, 5, 5)

	  Sleep(500)



	   $i += 1
	WEnd
 EndFunc


Func Run($tradeURL, $historyURL, $verbose)
   Trade($tradeURL, $verbose)
   Sleep(1000)
   Close($historyURL, $verbose)
   Sleep(1000)
EndFunc   ;==>Example



While 1
   Run("http://localhost/data?type=trade", "http://localhost/data?type=history", 0)
WEnd
