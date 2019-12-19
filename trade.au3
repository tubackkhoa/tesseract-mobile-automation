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


Func NumberControl_SetText($winTitle, $winText, $control, $value)
   ControlSetText($winTitle, $winText, $control, $value)
   $hControl = ControlGetHandle($winTitle, $winText, $control)
   ControlClick($hControl, "", "","left", 2, 10, 10)
   ControlSend($winTitle, $winText, $control, $value)
EndFunc

 Func GetOrderID($list, $ind)
   Local $count = _GUICtrlListView_GetItemCount($list)
   WinClose("Order")
   _GUICtrlListView_ClickItem($list, $ind, "left", False, 2)
   Local $hOrderWin = WinWait("Order", "", 1)
   Local $sText = WinGetTitle($hOrderWin)
   Local $aArray = StringRegExp($sText, '#(\d+)', $STR_REGEXPARRAYFULLMATCH)
   If UBound($aArray) == 2 Then
	  Local $copyOrderID = $aArray[1]
	  return $copyOrderID
   EndIf

   return ""
EndFunc

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
	  Local $aArray = StringRegExp($sText, '#(\d+)', $STR_REGEXPARRAYFULLMATCH)
	  If UBound($aArray) == 2 Then
		 Local $copyOrderID = $aArray[1]
		 Local $orderID = HasCopyOrder($historyObj, $copyOrderID)
		 If Not $orderID = "" Then
			Local $aPos = WinGetPos($hOrderWin)
;~ 			Delete or Close button here
			MouseClick("left", $aPos[0] + 630, $aPos[1] + 293, 1)
			;~ 	   update command
			_HTTP_Post($historyURL, "orderID=" & URLEncode($orderID) & "&copyOrderID=" & $copyOrderID)
			ConsoleWrite("close price: " & $aArray[1] & @LF)
			Sleep(200)
		 EndIf
;~ 		 ExitLoop
	  EndIf

   Next
EndFunc

Func HasCopyOrder($historyObj, $copyOrderID)
   Local $i = 0
   While 1
	   Local $id = '[' & $i & '].'
 	   Local $currentCopyOrderID = Json_Get($historyObj, $id & 'copyOrderID')
	   If @error Then ExitLoop

	  If $currentCopyOrderID == $copyOrderID Then
		 return Json_Get($historyObj, $id & 'orderID')
	  EndIf

	   $i += 1
	WEnd

	return ""
EndFunc

Func ReverseCommand($orderType)

   If StringLeft($orderType, 1) = "S" Then
	   $orderType = StringReplace($orderType, "Sell", "Buy")
	Else
	   $orderType = StringReplace($orderType, "Buy", "Sell")
	EndIf
   return $orderType
EndFunc

Func ReversePrice(ByRef $price, ByRef $sl, ByRef $tp, $orderType, $mSellPrice, $mBuyPrice, $slipPoint = 0.00035)
   Local $mSL = Number($sl)
   Local $mTP = Number($tp)
   Local $mPrice = Number($price)

   Local $marginSL = 0
   If $mSL > 0 Then
	  $marginSL = Abs(Round($mSL - $mPrice,4))
   EndIf

   Local $marginTP = 0
   If $mTP > 0 Then
	  $marginTP = Abs(Round($mTP - $mPrice,4))
   EndIf

;~    ConsoleWrite("$marginSL: " & $marginSL & "$marginTP: " & $marginTP & @LF)

   Local $newPrice
   Local $newSL
   Local $newTP
   If $orderType = "Sell Limit" Or $orderType = "Buy Stop" Then
	  If $orderType = "Sell Limit" Then
		 $newPrice = $mSellPrice + $slipPoint
	  Else
		 $newPrice = $mBuyPrice + $slipPoint
	  EndIf
   Else
	  If $orderType = "Sell Stop" Then
		 $newPrice = $mSellPrice - $slipPoint
	  Else ; Buy Limit
		 $newPrice = $mBuyPrice - $slipPoint
	  EndIf
   EndIf

   If $orderType = "Sell Limit" Or $orderType = "Sell Stop" Then
	  If $marginSL > 0 Then
		 $newSL = $newPrice + $marginSL
	  EndIf
	  If $marginTP > 0 Then
		 $newTP = $newPrice - $marginTP
	  EndIf
   Else
	  If $marginSL > 0 Then
		 $newSL = $newPrice - $marginSL
	  EndIf
	  If $marginTP > 0 Then
		 $newTP = $newPrice + $marginTP
	  EndIf
   EndIf

   $price =  String($newPrice)
   $sl =  String($newSL)
   $tp =  String($newTP)

EndFunc

Func Trade($tradeURL, $historyURL, $sAccountID, $sAction)
   ; Retrieve the position as well as height and width of the active window.
;~    Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hWin = WinWait("[TITLE:" & $sAccountID & "; CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
;~    ConsoleWrite(WinGetTitle($hWin) & @LF)
   WinActivate($hWin)

   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:ToolbarWindow32; INSTANCE:4]")
   Local $list = ControlGetHandle($hWin, "", "[CLASS:SysListView32; INSTANCE:1]")

   Local $tradeData = _HTTP_Get($tradeURL)
   local $tradeObj = Json_Decode($tradeData)

;~ 	; test
;~ 	$priceObj.Add("1.10756", True)


   Local $i = 0
   While 1

	   Local $count = _GUICtrlListView_GetItemCount($list)
	   Local $id = '[' & $i & '].'
	   Local $symbol = Json_Get($tradeObj, $id & 'symbol')
	   If @error Then ExitLoop

	   Local $price = Json_Get($tradeObj, $id & 'price')
	   Local $orderID = Json_Get($tradeObj, $id & 'orderID')

	   Local $orderType = Json_Get($tradeObj, $id & 'type')
	   If $sAction = "reverse" Then
;~ 		  first char is S => replace Sell=>Buy, else replace Buy=>Sell
		  $orderType = ReverseCommand($orderType)
	   EndIf

	   Local $volume = Json_Get($tradeObj, $id & 'volume')
	   Local $sl = Json_Get($tradeObj, $id & 'sl')
	   Local $tp = Json_Get($tradeObj, $id & 'tp')

	   ControlClick($hwnd, "", "","left", 1, 280, 10)

	  Local $hOrderWin = WinWait("Order", "", 10)

	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:2]", $volume)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:1]", $symbol)


	  Local $pricePair = ControlGetText($hOrderWin, "", "[CLASS:Static; INSTANCE:13]")
	  Local $priceArray = StringRegExp($pricePair, '([\d\.]+)\s*/\s*([\d\.]+)', $STR_REGEXPARRAYFULLMATCH)
	  Local $mSellPrice = Number($priceArray[1])
	  Local $mBuyPrice =  Number($priceArray[2])

;~ 	  If is market order
	  If $orderType = "Sell" Or $orderType = "Buy" Then
		 Local $mPrice = Number($price)
		 Local $aPos = WinGetPos($hOrderWin)
		 If $orderType = "Sell" Then
			Local $marginPrice = Abs(Round( $mSellPrice - $mPrice,4))
			If $marginPrice < 0.0005 Then
			   ConsoleWrite("Market execution: sell with margin Price " & $marginPrice & @LF)
			   MouseClick("left", $aPos[0] + 440, $aPos[1] + 270, 1)
			EndIf
		 Else
			Local $marginPrice = Abs(Round($mBuyPrice - $mPrice,4))
			If $marginPrice < 0.0005 Then
			   ConsoleWrite("Market execution: buy with margin Price " & $marginPrice & @LF)
			   MouseClick("left", $aPos[0] + 640, $aPos[1] + 270, 1)
			EndIf
		 EndIf
	  Else
;~ 		 can be sell buy stop/limit
		 ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:3]", "Pending Order")
		 ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:5]", $orderType)

;~ 		 change price, stop loss, take profit for reverse order
		 If $sAction = "reverse" Then
			ReversePrice($price, $sl, $tp, $orderType, $mSellPrice, $mBuyPrice)
		 EndIf

		 NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:2]", $sl)
		 NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:3]", $tp)
		 NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:6]", $price)
   ;~ 	  Send($price)

   ;~ 	  trigger increase then decrease to change data of price
   ;~ 	  $udPrice = ControlGetHandle($hOrderWin, "", "[CLASS:msctls_updown32; INSTANCE:3]");
   ;~ 	  ControlClick($udPrice, "", "","left", 1, 9, 2)
   ;~ 	  ControlClick($udPrice, "", "","left", 1, 9, 14)

		 Sleep(200)
		 ;~    click place then done
		 Local $hPlace = ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:16]")
   ;~ 	  ConsoleWrite("Place handle: " & $hPlace & @LF)
		 ControlClick($hPlace, "", "","left", 1, 5, 5)

;~    ;~ 	   close button ok if there is
;~ 		 Local $hOK = ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:22]")
;~ 		 ControlClick($hOK, "", "","left", 1, 5, 5)
	  EndIf

	  Local $copyOrderID = ""
	  Local $watchDog = 0
	  While 1
		 If _GUICtrlListView_GetItemCount($list) > $count Then
;~ 			must be order by last order is on top :D
			$copyOrderID = GetOrderID($list, 0)
			If $copyOrderID = "" Then
			   ; may be the second one
			   $copyOrderID = GetOrderID($list, 1)
			EndIf
			ExitLoop
		 EndIf
		 Sleep(200)
		 $watchDog += 1
		 If $watchDog > 10 Then
			ExitLoop
		 EndIf
	  WEnd

	  If Not $copyOrderID = "" Then
   ;~ 	   update command
		 _HTTP_Post($tradeURL, "orderID=" & URLEncode($orderID) & "&copyOrderID=" & $copyOrderID)
		  ConsoleWrite("Update trade: symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price & @LF)
	  EndIf

	  $i += 1
	WEnd

;~    sleep a little bit before closing
   Sleep(200)

   ClosePrice($list, $historyURL)

 EndFunc



;~ Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
;~ Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:SysListView32; INSTANCE:1]")

;~ WinActivate($hWin)

;~ Local $copyOrderID = GetLastOrderID($hwnd)
;~ ConsoleWrite("$copyOrderID: " & $copyOrderID & @LF)

Local $sAccountID = EnvGet("ACCOUNT_ID")
Local $sAction = EnvGet("ACTION")
ConsoleWrite("Account ID : " & $sAccountID & " ACTION: " & $sAction & @LF)

While 1
   Trade("http://localhost/data?type=trade", "http://localhost/data?type=history", $sAccountID, $sAction)
;~    before continuing
   Sleep(1000)
WEnd
