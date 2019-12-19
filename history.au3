#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>
#include <HTTP.au3>
#include <JSON.au3>
#include <StringConstants.au3>


Func GetAccountList()
   Local $aList = WinList("[CLASS:MetaQuotes::MetaTrader::4.00]")
   Local $ret = ""
   ; Loop through the array displaying only visable windows with a title.
   For $i = 1 To $aList[0][0]
        If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
			Local $aArray = StringRegExp($aList[$i][0], '(\d+):', $STR_REGEXPARRAYFULLMATCH)
;~             ConsoleWrite("Title: " & $aList[$i][0] & @LF)
			$ret &= $aArray[1] & " "
        EndIf
	 Next
	 ConsoleWrite($ret)
EndFunc

Func Process()
   ; Retrieve the position as well as height and width of the active window.
   Local $sAccountID = EnvGet("ACCOUNT_ID")
   ConsoleWrite("Account ID : " & $sAccountID& @LF)
   Local $hWin = WinWait("[TITLE:" & $sAccountID & "; CLASS:MetaQuotes::MetaTrader::4.00]", "", 2)
   WinActivate($hWin)
   Local $hOrderWin = WinWait("Order", "", 2)
   Local $price = "1.11345"
   Local $pricePair = ControlGetText($hOrderWin, "", "[CLASS:Static; INSTANCE:13]")
   Local $priceArray = StringRegExp($pricePair, '([\d\.]+)\s*/\s*([\d\.]+)', $STR_REGEXPARRAYFULLMATCH)
   If UBound($priceArray) = 3 Then
	  Local $aPos = WinGetPos($hOrderWin)

	  Local $marginPrice = Abs(Round( Number($priceArray[1]) - Number($price),4))

	  ConsoleWrite("$marginPrice: " & $marginPrice & " np: " & Number($priceArray[1]) & @LF)
   EndIf

EndFunc   ;==>Example

;~ While 1
;~  Process()
;~ WEnd

GetAccountList()