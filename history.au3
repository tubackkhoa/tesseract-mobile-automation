#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>
#include <HTTP.au3>
#include <JSON.au3>
#include <StringConstants.au3>

Func ClosePrice($list, $price)
   Local $count = _GUICtrlListView_GetItemCount($list)
;~    ConsoleWrite("Total " & $count & @LF)
   For $ind = 0 To $count - 1 Step 1


	  WinClose("Order")
	  _GUICtrlListView_ClickItem($list, $ind, "left", False, 2)
	  Local $hOrderWin = WinWait("Order", "", 1)
	  Local $sText = WinGetTitle($hOrderWin)

;~ 	  If Not $sText Then ContinueLoop
	  ConsoleWrite($ind & ") " & $sText & @LF)
	  Local $aArray = StringRegExp($sText, 'at ([^\s]+)', $STR_REGEXPARRAYFULLMATCH)
	  If UBound($aArray) == 2 And $aArray[1] == $price Then
;~ 		 Local $closeBtn =  ControlGetHandle($hOrderWin, "", "[CLASS:Button; INSTANCE:9]")
;~ 		 ConsoleWrite("Close price: " & $price & " handle " & $closeBtn & @LF)

;~ 		 Send("+{TAB}")
		 ;Send("+{TAB}")
;~ 		 Sleep(500)
;~ 		 MouseClick($MOUSE_CLICK_LEFT)
		 ;Presses SHIFT+TAB 4 times
;~ 		 Send("{ENTER}")
;~ 		 WinActivate($hOrderWin)
		 Local $aPos = WinGetPos($hOrderWin)
;~ 		 ConsoleWrite("X: " & $aPos[0] & " Y: " & $aPos[1] & @LF)
		 MouseClick("left", $aPos[0] + 630, $aPos[1] + 280, 1)

		 Sleep(500)
		 ExitLoop
	  EndIf

   Next
EndFunc

Func Close($tradeURL, $verbose)
   ; Retrieve the position as well as height and width of the active window.
   Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:SysListView32; INSTANCE:1]")


   Local $count = _GUICtrlListView_GetItemCount($hwnd)

   WinActivate($hWin)

   ClosePrice($hwnd, "1.11320")



;~    Local $tradeData = _HTTP_Get($tradeURL)
;~    local $tradeObj = Json_Decode($tradeData)

;~    Local $i = 0
;~    While 1
;~ 	   Local $id = '[' & $i & '].'
;~  	   Local $symbol = Json_Get($tradeObj, $id & 'symbol')
;~ 	   If @error Then ExitLoop

;~ 	  Local $price = Json_Get($tradeObj, $id & 'price')


;~



;~ 	   ControlClick($hwnd, "", "","left", 1, 280, 10)

;~

;;	   update command
;~       _HTTP_Post($tradeURL, "price=" & URLEncode($price))
;~ 	   ConsoleWrite("close price: " & $price & @LF)

;~ 	  Sleep(500)



;~ 	   $i += 1
;~ 	WEnd


;~    Sleep(2000)
;~    Close($tradeURL, $verbose)


EndFunc   ;==>Example



Close("http://localhost/data?type=history", 0)


