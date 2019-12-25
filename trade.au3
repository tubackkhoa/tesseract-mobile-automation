#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
;#include <GUIListViewEx.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>
#include <HTTP.au3>
#include <JSON.au3>
#include <Array.au3>
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


Func GetOrderData($list, $ind)
   Local $hOrderWin
   Return GetOrderDataBy($list, $ind, $hOrderWin)
EndFunc

Func GetOrderDataBy($list, $ind, ByRef $hOrderWin)
   WinClose("Order")
   _GUICtrlListView_ClickItem($list, $ind, "left", False, 2)
   $hOrderWin = WinWait("Order", "", 1)
   Local $sText = WinGetTitle($hOrderWin)
   Return $sText
EndFunc

Func GetOrderIDFromData($sText)
   Local $aArray = StringRegExp($sText, '#(\d+)', $STR_REGEXPARRAYFULLMATCH)
   If UBound($aArray) == 2 Then
	  Local $copyOrderID = $aArray[1]
	  return $copyOrderID
   EndIf
   Return ""
EndFunc

Func GetOrderID($list, $ind)
   Local $sText = GetOrderData($list, $ind)
   Return GetOrderIDFromData($sText)
EndFunc

Func ClosePrice($list, $historyURL, ByRef $marketNum, ByRef $limitNum, ByRef $sortDesc)
   Local $historyData = _HTTP_Get($historyURL)
   Local $historyObj = Json_Decode($historyData)
;~    Local $numToDelete = UBound($historyObj)

   Local $count = _GUICtrlListView_GetItemCount($list)

   $marketNum = 0
   $limitNum = 0
   Local $isMarket = True

   Local $lastMarketOrder = 0
   Local $lastLimitOrder = 0

   Local $rowInd = 0
   Local $totalCount = $count
   For $ind = 0 To $count - 1 Step 1

;~ 	  If $numToDelete = 0 Then
;~ 		 ExitLoop
;~ 	  EndIf
	  Local $hOrderWin
	  Local $sText = GetOrderDataBy($list, $rowInd, $hOrderWin)

	  If $sText = "" Then
		 $isMarket = False
		 ContinueLoop
	  EndIf

	  Local $copyOrderID = GetOrderIDFromData($sText)
	  Local $nOrderID= Number($copyOrderID)

	  If $isMarket Then
		 $marketNum += 1
		 If $lastMarketOrder > 0 Then
			$sortDesc = $lastMarketOrder > $nOrderID
		 EndIf
		 $lastMarketOrder = $nOrderID
	  Else
		 $limitNum += 1
		 If $lastLimitOrder Then
			$sortDesc = $lastLimitOrder > $nOrderID
		 EndIf
		 $lastLimitOrder = $nOrderID
	  EndIf

;~ 	  ConsoleWrite($ind & ") " & $sText & @LF)

	  Local $orderID = HasCopyOrder($historyObj, $copyOrderID)
	  If Not $orderID = "" Then
		 Local $aPos = WinGetPos($hOrderWin)
;~ 			Delete or Close button here
		 MouseClick("left", $aPos[0] + 630, $aPos[1] + 293, 1)
		 ;~ 	   update command
		 _HTTP_Post($historyURL, "orderID=" & URLEncode($orderID) & "&copyOrderID=" & $copyOrderID)


;~ 		 remain rowInd but need to wait for list change
		 Local $differ = WaitForListChanged($list, $totalCount)
		 $totalCount -= $differ
		 ConsoleWrite("$sortDesc: " & $sortDesc & " Close price: orderID: #" & $copyOrderID & " total row : " & $totalCount & @LF)
;~ 		 Sleep(200)
;~ 		 $numToDelete -= 1
	  Else
		 $rowInd += 1
	  EndIf

   Next


EndFunc

Func WaitForListChanged($list, $count, $timeout = 5000)
   Local $watchDog = 0
   Local $interval = 200
   Local $differ = 0
   Local $maxTimes = Round($timeout / $interval, 0)
   While 1
	  $differ = _GUICtrlListView_GetItemCount($list) - $count
	  If Not $differ = 0 Then
		 ExitLoop
	  EndIf
	  Sleep(200)
	  $watchDog += 1
	  If $watchDog > $maxTimes Then
		 ExitLoop
	  EndIf
   WEnd

   Return $differ
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

;~ Global $pubListCount = 0
;~ Global $pubMarketNum = -1
;~ Global $pubLimitNum = -1
Global $lastMarketOrder = ""
Global $lastLimitOrder = ""
Global $sortDesc = True

Func UpdateLastOrderID($list, $marketNum, $lastInd, $isLimit)
   Local $copyOrderID = ""
   If $sortDesc Then
	  If $isLimit Then
		 $copyOrderID = GetOrderID($list, $marketNum + 1)
	  Else
		 $copyOrderID = GetOrderID($list, 0)
	  EndIf
   Else
	  If $isLimit Then
		 $copyOrderID = GetOrderID($list, $lastInd)
	  Else
		 $copyOrderID = GetOrderID($list, $marketNum - 1)
	  EndIf
   EndIf

   ConsoleWrite("$copyOrderID: " & $copyOrderID & " $lastMarketOrder: " & $lastMarketOrder & " $isLimit : " & $isLimit & @LF)

   If $isLimit Then
;~ 	  If Not $lastLimitOrder = $copyOrderID Then
		 $lastLimitOrder = $copyOrderID
;~ 		 Return $copyOrderID
;~ 	  EndIf
   Else
;~ 	  If Not $lastMarketOrder = $copyOrderID Then
		 $lastMarketOrder = $copyOrderID
;~ 		 Return $copyOrderID
;~ 	  EndIf
   EndIf

   Return $copyOrderID

;~    different sorting
;~    $sortDesc = Not $sortDesc
;~    Return UpdateLastOrderID($list, $marketNum, $lastInd, $isLimit)
EndFunc

Global $marketNum = -1
Global $limitNum = -1
Func UpdateAndGetData($list, $count)
   $marketNum = 0
   $limitNum = 0
;~    $pubListCount = $count
   Local $isMarket = True
   If Not $count Then
	  $count = 1
   EndIf

   Local $sData[$count-1] = []
;~    ConsoleWrite("count: " & $count & @LF)
   For $ind = 0 To $count - 1 Step 1

	  Local $sText = GetOrderData($list, $ind)

	  If $sText = "" Then
;~ 		 $isMarket = False
		 ContinueLoop
	  EndIf

	  If $isMarket Then
		 $marketNum += 1
	  Else
		 $limitNum += 1
	  EndIf

	  _ArrayPush($sData, $sText)
   Next
   Return $sData
EndFunc

Func UpdateAndGetDataString($list, $count)
   Local $listData = UpdateAndGetData($list, $count)
   Local $orderData = _ArrayToString($listData, @LF)
   Return URLEncode($orderData)
EndFunc

;~  return 1: add, 2: close
Func DoCrawl($URL, $sPubAccountID)
;~    because it is not meaningful when we copy all past trades
;~    If $pubListCount change => update publish count, post to server, then return True, else return False
;~   Should watch fast, The change could be: length > 1 => new trade (first if market, or number of market +1 if limit), by store
;~  number of market, and last orderid, we can figure out change, if last orderid is differ => we get it
;~  incase length < 1 go to history and get the first one, that should be enough, instead of loop through because human only process 1 by 1
   Local $hWin = WinWait("[TITLE:" & $sPubAccountID & "; CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $list = ControlGetHandle($hWin, "", "[ID:33217]")
   Local $count = _GUICtrlListView_GetItemCount($list)
;~    ConsoleWrite("count: " & $count & " current count: " & $pubListCount & " win: " & "[TITLE:" & $sPubAccountID & "; CLASS:MetaQuotes::MetaTrader::4.00]" & @LF)
;~    WinActivate($hWin)

   ;~ 	  First time, update
   If $pubMarketNum = -1 Then
	  Local $orderData = UpdateAndGetDataString($list, $count)
	  _HTTP_Post($URL & "/initTrade", "tradeData=" & $orderData)
   EndIf

;~    If $pubListCount = $count Then
;~ 	  check last limit order and market order
;~ 	  Return 0
;~    EndIf

;~    ConsoleWrite("count: " & $count & " $pubListCount " & $pubListCount & " $pubMarketNum: " & $pubMarketNum & @LF)
;~    Return False

;~    Local $shouldAdd =  $count > $pubListCount
   Local $orderData = UpdateAndGetDataString($list, $count)

;~    ConsoleWrite($orderData & @LF)
   _HTTP_Post($URL & "/updateTrade", "tradeData=" & $orderData)

;~    If $shouldAdd Then
;~ 	  Local $oldPubMarketNum = $pubMarketNum
;~ 	  Local $listData = UpdateAndGetData($list, $count)
;~ 	  Local $orderData

;~ 	  If $pubMarketNum > $oldPubMarketNum Then
;~ 		 $orderData = $listData[0]
;~ 	  Else
;~ 		 do not increase by 1 because this is not list, this is list data
;~ 		 $orderData = $listData[$pubMarketNum]
;~ 	  EndIf
;~ 	  add orderData to server to know which is added
;~ 	  _HTTP_Post($URL & "/addTrade", "tradeData=" & $orderData)
;~ 	  Return 1
;~    Else
;~ 	  loop again to find where then update, server will know which is disappear
;~ 	  Local $listData = UpdateAndGetData($list, $count)
;~ 	  Local $orderData = _ArrayToString($listData, @LF)
;~ 	  post to server this to know which is deleted
;~ 	  _HTTP_Post($URL & "/closeTrade", "tradeData=" & $orderData)
;~ 	  Return 2
;~    EndIf

;~    Return True

EndFunc

Func MakeSureSort($hWnd, $sortBy = 'asc')
   ControlClick($hwnd, "", "","left", 1, 300, 10)
   ControlClick($hwnd, "", "","left", 1, 60, 10)
   If $sortBy = 'desc' Then
	  Sleep(1000)
	  $sortDesc = True
   Else
	  $sortDesc = False
   EndIf
EndFunc

Func Trade($URL, $sSubAccountID, $sAction, $marginLimit, $retries)
   ; Retrieve the position as well as height and width of the active window.
;~    Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
;~    Local $needTrade =
;~    DoCrawl($URL, $sPubAccountID)
;~    Return
;~    If Not $needTrade Then
;~ 	  Return
;~    EndIf

   Local $tradeURL = $URL & "/data?type=trade"
   Local $historyURL = $URL & "/data?type=history"
   Local $closeURL = $URL & "/close"
   Local $hWin = WinWait("[TITLE:" & $sSubAccountID & "; CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
;~    ConsoleWrite(WinGetTitle($hWin) & @LF)
;~    WinActivate($hWin)

   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:ToolbarWindow32; INSTANCE:4]")
   Local $hListHeader = ControlGetHandle($hWin, "", "[CLASS:SysHeader32; INSTANCE:1]")
   Local $list = ControlGetHandle($hWin, "", "[ID:33217]")
   Local $count = _GUICtrlListView_GetItemCount($list)

   MakeSureSort($hListHeader)

    If $marketNum = -1 Then
	  Local $orderData = UpdateAndGetDataString($list, $count)
	  _HTTP_Post($URL & "/initTrade", "tradeData=" & $orderData)
   EndIf

   ConsoleWrite("Do closing" & @LF)
   While 1
;~    close trade
;~    If $actionTrade = 2 Then
;~    ClosePrice($list, $historyURL, $marketNum, $limitNum, $sortDesc)
	  Local $closeData = _HTTP_Get($closeURL)
	  Local $closeObj = Json_Decode($closeData)

	  Local $orderID = Json_Get($closeObj, 'orderID')
;~ 	  may empty
	  If @error Then ExitLoop
	  Local $copyOrderID = Json_Get($closeObj, 'copyOrderID')
	  Local $copyOrderIndex = Json_Get($closeObj, 'copyOrderIndex')
	  Local $orderType = Json_Get($closeObj, 'type')
	  Local $hOrderWin
	  Local $sText = GetOrderDataBy($list, $rowInd, $hOrderWin)
	  Local $checkCopyOrderID = GetOrderIDFromData($sText)
	  If $checkCopyOrderID = $copyOrderID Then
		 Local $aPos = WinGetPos($hOrderWin)
   ;~ 			Delete or Close button here
		 MouseClick("left", $aPos[0] + 630, $aPos[1] + 293, 1)

   ;~ 		 remain rowInd but need to wait for list change
		 Local $differ = WaitForListChanged($list, $count)
		 $count -= $differ

		 If $orderType = "Sell" Or $orderType = "Buy" Then
			$marketNum -= $differ
		 Else
			$limitNum -= $differ
		 EndIf
		 ;~ 	   update command
		 _HTTP_Post($historyURL, "orderID=" & URLEncode($orderID) & "&copyOrderID=" & $copyOrderID)
		 ConsoleWrite("$sortDesc: " & $sortDesc & " Close price: orderID: #" & $copyOrderID & " total row : " & $count & " marketNum: " & $marketNum & " limitNum: " & $limitNum & @LF)
	  EndIf
   WEnd

   ConsoleWrite("Do trading" & @LF)

;~ 	  Return
;~    EndIf
   Sleep(500)

;~    sleep a little bit before doing trade
   Local $tradeData = _HTTP_Get($tradeURL)
   local $tradeObj = Json_Decode($tradeData)

;~    ConsoleWrite("Total $marketNum " & $marketNum & @LF)

   Local $i = 0
   Local $watchDogRetries = $retries
   While 1

;~ 	  WinClose("Order")


	   If $count > $countLimit Then
		  Return
	   EndIf

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

;~ 	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:2]", $volume)
	  ComboBox_SelectString($hOrderWin, "", "[CLASS:ComboBox; INSTANCE:1]", $symbol)
	  NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:1]", $volume)


	  Local $pricePair = ControlGetText($hOrderWin, "", "[CLASS:Static; INSTANCE:13]")
	  Local $priceArray = StringRegExp($pricePair, '([\d\.]+)\s*/\s*([\d\.]+)', $STR_REGEXPARRAYFULLMATCH)
	  If Not UBound($priceArray) = 3 Then
		 ConsoleWrite("Pair prices: " & $pricePair & @LF)
		 ExitLoop
	  EndIf

	  Local $mSellPrice = Number($priceArray[1])
	  Local $mBuyPrice =  Number($priceArray[2])
	  Local $isLimit = True

	  ConsoleWrite("$sortDesc: " & $sortDesc & " Do trade: symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price & @LF)

;~ 	  If is market order
	  If $orderType = "Sell" Or $orderType = "Buy" Then
;~ 		 update stop lost and take profit
		 NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:2]", $sl)
		 NumberControl_SetText($hOrderWin, "", "[CLASS:Edit; INSTANCE:3]", $tp)

		 Local $mPrice = Number($price)
		 Local $aPos = WinGetPos($hOrderWin)
		 Local $canTrade = False
;~ 		 use margin 1.5%
		 If $orderType = "Sell" Then
			Local $marginPrice = Abs(Round(($mSellPrice - $mPrice)/$mPrice,4))
			If $marginPrice < $marginLimit Then
			   MouseClick("left", $aPos[0] + 440, $aPos[1] + 270, 1)
			   $canTrade = True
			EndIf
		 Else
			Local $marginPrice = Abs(Round(($mBuyPrice - $mPrice)/$mPrice,4))
			If $marginPrice < $marginLimit Then
			   MouseClick("left", $aPos[0] + 640, $aPos[1] + 270, 1)
			   $canTrade = True
			EndIf
		 EndIf

		 If Not $canTrade Then
			_HTTP_Post($tradeURL, "orderID=" & URLEncode($orderID) & "&marginPrice=" & $marginPrice)
			ConsoleWrite("Ignore trade: symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price & " with margin Price " & $marginPrice & @LF)
		 Else
			ConsoleWrite("Market execution: " & $orderType & " with margin Price " & $marginPrice & @LF)
		 EndIf
		 $isLimit = False
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
	  Local $differ = WaitForListChanged($list, $count)
;~ 	  should be 1
	  If $differ > 0 Then
;~ 			must be 0 if is market, otherwise is $marketNum + 1
;~ 		  if desc => try desc, if lastOrderID still the same => change desc, try otherway
		 $count += $differ
		 If  $isLimit Then
			$limitNum += $differ
		 Else
			;~ 			one more market order
			$marketNum += $differ
		 EndIf
		 $copyOrderID = UpdateLastOrderID($list, $marketNum, $count, $isLimit)
		 ConsoleWrite("$sortDesc: " & $sortDesc & " $copyOrderID: " & $copyOrderID & " $count: " & $count & " $marketNum: " & $marketNum & @LF)
	  EndIf

	  If Not $copyOrderID = "" Then
   ;~ 	   update command
		 _HTTP_Post($tradeURL, "orderID=" & URLEncode($orderID) & "&copyOrderID=" & $copyOrderID)
		  ConsoleWrite("$sortDesc: " & $sortDesc & " Update trade: symbol: " & $symbol & " type: " & $orderType & " volume: " & $volume & " price: " & $price & @LF)
;~ 		  reset watchdog
		 $watchDogRetries = 0
	  EndIf

	  If $watchDogRetries = 0 Then
		 $i += 1
		 $watchDogRetries = $retries

	  Else
		 $watchDogRetries -= 1
	  EndIf
	  Sleep(200)
;~ 	  retry forever or whatdog ?

	WEnd

 EndFunc


Local $sSubAccountID = EnvGet("SUBSCRIBE_ACCOUNT_ID")
Global $delay = 200
Global $countLimit = 20
If Not $sSubAccountID Then
;~    $sPubAccountID = "1003413: SMFX-Demo - Demo Account"
;~    Local
   $sSubAccountID = "1003415: SMFX-Demo - Demo Account"
   Local $sAction = "copy"
   Local $marginLimit = "0.015"
   $delay = 4000
Else
;~    Local $sSubAccountID = EnvGet("SUBSCRIBE_ACCOUNT_ID")
   Local $sAction = EnvGet("ACTION")
   Local $marginLimit = Number(EnvGet("MARGIN_LIMIT"))
EndIf


ConsoleWrite("Account ID : " & $sSubAccountID & " ACTION: " & $sAction & " MARGIN_LIMIT: " & $marginLimit & @LF)

While 1
   Trade("http://localhost", $sSubAccountID, $sAction, $marginLimit, 4)
;~    before continuing
   Sleep($delay)
WEnd
