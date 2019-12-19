#include <StringConstants.au3>


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


;~  $order = ReverseCommand("Buy Limit")

;~  ConsoleWrite("order: " & $order & @LF)

$orderType = ReverseCommand("Sell Stop")
$price = "1.11240";
$sl = ""
$tp = ""
$mSellPrice = 1.11336
$mBuyPrice = 1.11356
ReversePrice($price, $sl, $tp, $orderType, $mSellPrice, $mBuyPrice)
ConsoleWrite($orderType & " Market: " & $mSellPrice & " / " & $mBuyPrice & " price: " & $price & " Stop Loss: " & $sl & " Take Profit: " & $tp & @LF)

