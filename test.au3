#include <StringConstants.au3>


Func ReverseCommand($orderType)

   If StringLeft($orderType, 1) = "S" Then
	   $orderType = StringReplace($orderType, "Sell", "Buy")
	Else
	   $orderType = StringReplace($orderType, "Buy", "Sell")
	EndIf
   return $orderType
 EndFunc


 $order = ReverseCommand("Buy Limit")

 ConsoleWrite("order: " & $order & @LF)