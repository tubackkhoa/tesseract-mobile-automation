

#include <Array.au3>
#include <Constants.au3>
#include-once

Global Const $DICT2_ERR_CREATION_FAIL = -1
Global Const $DICT2_ERR_INITIAL_NON_ARRAY = 1
Global Const $DICT2_ERR_WRONG_DIMENSIONS = 2

Global Const $__dict2_obj_id = "la;jsd0f9j'34j5;lkdjf[0asuejlakjsd;flj345109j;lajks;lejkr039uj5q;okjas;lkdjf;lkj0q9j;lakj"

_AutoItObject_StartUp()


Func _DictCreate($aInitial=Default, $oIDMe=Default)
  If $oIDMe <> Default Then
    Return $oIDMe.__dict_object_identifier = $__dict2_obj_id
  EndIf

  ; Create object and dictionary
  Local $this = _AutoItObject_Class()
  Local $_dict = ObjCreate("Scripting.Dictionary")

  ; If we have initial key-value pairs, add them to the dict
  If $aInitial <> Default Then
    If Not IsArray($aInitial) Then Return SetError($DICT2_ERR_INITIAL_NON_ARRAY, 0, $DICT2_ERR_CREATION_FAIL)
    If UBound($aInitial, $UBOUND_COLUMNS) <> 2 Then Return SetError($DICT2_ERR_WRONG_DIMENSIONS, 0, $DICT2_ERR_CREATION_FAIL)

    For $i = 0 To UBound($aInitial) - 1
      $_dict.Add($aInitial[$i][0], $aInitial[$i][1])
    Next
  EndIf

  $this.Create()

  $this.AddProperty("__dict_object_identifier", $ELSCOPE_PUBLIC, $__dict2_obj_id)
  $this.AddProperty("_dict", $ELSCOPE_PRIVATE, $_dict)
  $this.AddProperty("debug_output", $ELSCOPE_PUBLIC, False)

  $this.AddMethod("set", "__set")
  $this.AddMethod("contains", "__contains")
  $this.AddMethod("get", "__get")
  $this.AddMethod("del", "__del")
  $this.AddMethod("del_all", "__del_all")
  $this.AddMethod("len", "__len")
  $this.AddMethod("pairs", "__pairs")
  $this.AddMethod("keys", "__keys")
  $this.AddMethod("values", "__values")

  $this.AddMethod("histogram", "__histogram")
  $this.AddMethod("increment", "__increment")

  $this.AddMethod("display", "__display")

  $this.AddMethod("_dbg", "__dbg")

  Return $this.Object
EndFunc

Func __set($this, $key, $value)
  If $this._dict.Exists($key) Then
    $this._dbg("Updating value for existing key")
    $this._dict.Item($key) = $value
  Else
    $this._dbg("Creating new key-value pair")
    $this._dict.Add($key, $value)
  EndIf
EndFunc

Func __contains($this, $key)
  Return $this._dict.Exists($key)
EndFunc

Func __get($this, $key)
  If $this._dict.Exists($key) Then
    Return $this._dict.Item($key)
  EndIf
  $this._dbg($key & " does not exist")
EndFunc

Func __del($this, $key)
  If $this._dict.Exists($key) Then
    $this._dict.Remove($key)
  EndIf
  $this._dbg($key & " does not exist")
EndFunc

Func __del_all($this)
  Local $aKeys = $this.keys()
  For $key In $aKeys
    $this.del($key)
  Next
EndFunc

Func __len($this)
  Return $this._dict.Count
EndFunc

Func __pairs($this)
  If $this._dict.Count Then
    $this._dbg("building array for " & $this._dict.Count & " items")
    Local $aItems[$this._dict.Count][2]
    Local $aKeys = $this.keys
    For $i = 0 To $this._dict.Count - 1
      $aItems[$i][0] = $aKeys[$i]
      $aItems[$i][1] = $this.get($aKeys[$i])
    Next
    Return $aItems
  EndIf
  $this._dbg("dictionary is empty")
EndFunc

Func __keys($this)
  Return $this._dict.Keys
EndFunc

Func __values($this, $aKeyList=Default)
  If $aKeyList == Default Then Return $this._dict.Items

  Local $aValues[UBound($aKeyList)]

  For $i = 0 To UBound($aKeyList) - 1
    $aValues[$i] = $this.get($aKeyList[$i])
  Next

  Return $aValues
EndFunc

Func __histogram($this, $aArray)
  If UBound($aArray, $UBOUND_DIMENSIONS ) == 1 Then
    For $value In $aArray
      $iCount = $this.increment($value)
    Next
  ElseIf UBound($aArray, $UBOUND_DIMENSIONS) == 2 Then
    For $x = 0 To UBound($aArray, $UBOUND_ROWS) -1
      For $y = 0 To UBound($aArray, $UBOUND_COLUMNS)-1
        $iCount = $this.increment($aArray[$x][$y])
      Next
    Next
  EndIf
EndFunc

Func __increment($this, $key)
  If $this.contains($key) And IsInt($this.get($key)) Then
    $this.set($key, $this.get($key) + 1)
  Else
    $this.set($key, 1)
  EndIf

  Return $this.get($key)
EndFunc

Func __display($this, $fSort=True, $fSortOnValues=True, $sTitle="DictDisplay")
  $aPairs = $this.pairs()
  If $fSort Then
    If $fSortOnValues Then
      _ArraySort($aPairs, 1, 0, 0, 1)
    Else
      _ArraySort($aPairs, 1)
    EndIf
  EndIf
  _ArrayDisplay($aPairs, $sTitle)
EndFunc

Func __dbg($this, $msg)
  If Not $this.debug_output Then Return
  ConsoleWrite($msg & @CRLF)
EndFunc

Func IsDict($dDict)
  If Not IsObj($dDict) Then Return False
  Return _DictCreate(Default, $dDict)
EndFunc