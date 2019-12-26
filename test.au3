#include <StringConstants.au3>
#include <Array.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
;#include <GUIListViewEx.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>


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
		 $newPrice = $mBuyPrice - $slipPoint
	  EndIf
   Else
	  If $orderType = "Sell Stop" Then
		 $newPrice = $mSellPrice - $slipPoint
	  Else
		 $newPrice = $mBuyPrice + $slipPoint
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


Func GetOrderData($list, $ind)
   WinClose("Order")
   _GUICtrlListView_ClickItem($list, $ind, "left", False, 2)
   Local $hOrderWin = WinWait("Order", "", 1)
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

;~  $order = ReverseCommand("Buy Limit")

;~  ConsoleWrite("order: " & $order & @LF)

;~ $orderType = ReverseCommand("Sell Stop")
;~ $price = "1.11240";
;~ $sl = ""
;~ $tp = ""
;~ $mSellPrice = 1.11336
;~ $mBuyPrice = 1.11356
;~ ReversePrice($price, $sl, $tp, $orderType, $mSellPrice, $mBuyPrice)
;~ ConsoleWrite($orderType & " Market: " & $mSellPrice & " / " & $mBuyPrice & " price: " & $price & " Stop Loss: " & $sl & " Take Profit: " & $tp & @LF)

;~ $count = 2
;~ Local $avArrayTarget[] = []
;~ _ArrayPush($avArrayTarget, "hehe")
;~ _ArrayPush($avArrayTarget, "hihi")
;~ $sText = _ArrayToString($avArrayTarget, @LF)
;~ ConsoleWrite($sText & $avArrayTarget[1] & @LF)

;~  sort by asc, check market num, limit num, for the first time
;~  make sure asc order
;~  if add => last item, update index
;~  if delete => remove index

$winTitle = "[TITLE:1003415: SMFX-Demo - Demo Account; CLASS:MetaQuotes::MetaTrader::4.00]"

Local $hWin = WinWait($winTitle, "", 10)
Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:ToolbarWindow32; INSTANCE:4]")
ControlClick($hwnd, "", "","left", 1, 280, 10)

;~ Local $data = _GUICtrlListView_GetContents($hWnd)

;~ ConsoleWrite("$data: " & $data & @LF)
