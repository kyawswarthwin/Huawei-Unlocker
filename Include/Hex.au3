#include-once

#include <WinAPI.au3>

; #INDEX# =======================================================================================================================
; Title .........: Hex
; AutoIt Version : 3.3
; Language ......: English
; Description ...:
; Author(s) .....: Kyaw Swar Thwin
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _Hex_Read
; _Hex_Search
; _Hex_Write
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _Hex_Read
; Description ...:
; Syntax ........: _Hex_Read($sFilePath[, $iCount = 0[, $iOffset = 0]])
; Parameters ....: $sFilePath           - A string value.
;                  $iCount              - [optional] An integer value. Default is 0.
;                  $iOffset             - [optional] An integer value. Default is 0.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Hex_Read($sFilePath, $iCount = 0, $iOffset = 0)
	Local $hFile, $iFileSize, $tBuffer, $iByte
	If $iOffset = Default Then $iOffset = 0
	$hFile = _WinAPI_CreateFile($sFilePath, 2, 2)
	If Not $hFile Then Return SetError(1, 0, "")
	$iFileSize = _WinAPI_GetFileSizeEx($hFile)
	If $iFileSize < $iOffset Then
		_WinAPI_CloseHandle($hFile)
		Return SetError(2, 0, "")
	EndIf
	If $iCount = Default Or $iCount < 1 Then $iCount = $iFileSize
	If $iFileSize < $iOffset + $iCount Then
		_WinAPI_CloseHandle($hFile)
		Return SetError(3, 0, "")
	EndIf
	_WinAPI_SetFilePointer($hFile, $iOffset)
	$tBuffer = DllStructCreate("byte[" & $iCount & "]")
	_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $iCount, $iByte)
	_WinAPI_CloseHandle($hFile)
	Return DllStructGetData($tBuffer, 1)
EndFunc   ;==>_Hex_Read

; #FUNCTION# ====================================================================================================================
; Name ..........: _Hex_Search
; Description ...:
; Syntax ........: _Hex_Search($sFilePath, $vData[, $iCaseSensitive = 0[, $iStartOffset = 0]])
; Parameters ....: $sFilePath           - A string value.
;                  $vData               - A variant value.
;                  $iCaseSensitive      - [optional] An integer value. Default is 0.
;                  $iStartOffset        - [optional] An integer value. Default is 0.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Hex_Search($sFilePath, $vData, $iCaseSensitive = 0, $iStartOffset = 0)
	Local $hFile, $iFileSize, $tBuffer, $iBufferSize = 2048, $iOffset, $iByte, $iResult
	If $iCaseSensitive = Default Then $iCaseSensitive = 0
	If $iStartOffset = Default Then $iStartOffset = 0
	$hFile = _WinAPI_CreateFile($sFilePath, 2, 2, 1)
	If Not $hFile Then Return SetError(1, 0, -1)
	$iFileSize = _WinAPI_GetFileSizeEx($hFile)
	If $iFileSize < $iStartOffset Then
		_WinAPI_CloseHandle($hFile)
		Return SetError(2, 0, -1)
	EndIf
	_WinAPI_SetFilePointer($hFile, $iStartOffset)
	$tBuffer = DllStructCreate("byte[" & $iBufferSize & "]")
	$iOffset = $iStartOffset
	While 1
		_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $iBufferSize, $iByte)
		$iResult = StringInStr(BinaryToString(DllStructGetData($tBuffer, 1)), BinaryToString($vData), $iCaseSensitive)
		If $iResult > 0 Then ExitLoop
		If $iByte < $iBufferSize Then
			_WinAPI_CloseHandle($hFile)
			Return -1
		EndIf
		$iOffset += $iByte
	WEnd
	_WinAPI_CloseHandle($hFile)
	$iResult = $iOffset + $iResult - 1
	Return $iResult
EndFunc   ;==>_Hex_Search

; #FUNCTION# ====================================================================================================================
; Name ..........: _Hex_Write
; Description ...:
; Syntax ........: _Hex_Write($sFilePath, $vData[, $iOffset = -1])
; Parameters ....: $sFilePath           - A string value.
;                  $vData               - A variant value.
;                  $iOffset             - [optional] An integer value. Default is -1.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Hex_Write($sFilePath, $vData, $iOffset = -1)
	Local $hFile, $iBinaryLen, $tBuffer, $iByte
	$hFile = _WinAPI_CreateFile($sFilePath, 3, 4)
	If Not $hFile Then Return SetError(1, 0, 0)
	If $iOffset = Default Or $iOffset < 0 Then
		_WinAPI_SetFilePointer($hFile, 0, $FILE_END)
	Else
		_WinAPI_SetFilePointer($hFile, $iOffset)
	EndIf
	$iBinaryLen = BinaryLen($vData)
	$tBuffer = DllStructCreate("byte[" & $iBinaryLen & "]")
	DllStructSetData($tBuffer, 1, $vData)
	_WinAPI_WriteFile($hFile, DllStructGetPtr($tBuffer), $iBinaryLen, $iByte)
	_WinAPI_CloseHandle($hFile)
	Return 1
EndFunc   ;==>_Hex_Write
