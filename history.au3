#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <ScreenCapture.au3>
#include <GuiComboBoxEx.au3>
#include <GuiComboBox.au3>
#include <HTTP.au3>
#include <JSON.au3>
#include <StringConstants.au3>


Func Process()
   ; Retrieve the position as well as height and width of the active window.
   Local $hWin = WinWait("[CLASS:MetaQuotes::MetaTrader::4.00]", "", 10)
   Local $hwnd = ControlGetHandle($hWin, "", "[CLASS:SysListView32; INSTANCE:4]")

   Local $hOrderWin = WinWait("Order", "", 10)
   Local $price = "1.11345"
   Local $pricePair = ControlGetText($hOrderWin, "", "[CLASS:Static; INSTANCE:13]")
   Local $priceArray = StringRegExp($pricePair, '([\d\.]+)\s*/\s*([\d\.]+)', $STR_REGEXPARRAYFULLMATCH)
   Local $aPos = WinGetPos($hOrderWin)

   Local $marginPrice = Abs(Round( Number($priceArray[1]) - Number($price),4))

   ConsoleWrite("$marginPrice: " & $marginPrice & " np: " & Number($priceArray[1]) & @LF)

EndFunc   ;==>Example


Process()
