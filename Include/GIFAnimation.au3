#include-once


; #FUNCTION# ;===============================================================================
;
; Name...........: _GUICtrlCreateGIF
; Description ...: Creates GIF control for the GUI
; Syntax.........: _GUICtrlCreateGIF($sFileName, $iLeft, $iTop, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $iTransparency, ByRef $pCurrentFrame)
; Parameters ....: $sFileName - full path to the GIF file
;                  $iLeft - left side of the control
;                  $iTop - the top of the control
;                  $aGIFArrayOfIconHandles - variable that receives handles of the icons generated from GIF. Will be an array.
;                  $hGIFThread - variable that receives handle to the thread in which GIF is animated
;                  $iTransparency -  variable that receives transparency value (1 - transparent, 0 - not transparent)
;                  $pCurrentFrame - variable that receives structure (dword) that holds current number of frame. First frame is 0.
; Return values .: Success - Returns controlID of the new control
;                          - Sets @error to 0
;                  Failure - Returns 0 sets @error:
;                  |1 - GDI+ related error
;                  |2 - Animation failed
; Author ........: trancexx
;
;==========================================================================================
Func _GUICtrlCreateGIF($sFileName, $iLeft, $iTop, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $iTransparency, ByRef $tCurrentFrame)

	Local $hGIF = GUICtrlCreateIcon("", "", 0, 0)

	$aGIFArrayOfIconHandles = _CreateArrayHIconsFromGIFFile($hGIF, $sFileName, $iLeft, $iTop, $iTransparency)

	If @error Then
		GUICtrlDelete($hGIF)
		$hGIF = 0
		Return SetError(1, 0, 0)
	EndIf

	If UBound($aGIFArrayOfIconHandles) > 1 Then ; if GIF is animated one

		$hGIFThread = _AnimateGifInAnotherThread($hGIF, $aGIFArrayOfIconHandles, $iTransparency, $tCurrentFrame)

		If @error Then
			For $i = 0 To UBound($aGIFArrayOfIconHandles) - 1
				DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0])
			Next
			Return SetError(2, 0, 0)
		EndIf

	EndIf

	Return SetError(0, 0, $hGIF)

EndFunc   ;==>_GUICtrlCreateGIF

Func _GUICtrlCreateGIFFromBinary($bData, $iLeft, $iTop, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $iTransparency, ByRef $tCurrentFrame)
	
	Local $hGIF = GUICtrlCreateIcon("", "", 0, 0)
	
	$aGIFArrayOfIconHandles = _CreateArrayHIconsFromGIFBinaryImage($hGIF, $bData, $iLeft, $iTop, $iTransparency)
	
	If @error Then
		GUICtrlDelete($hGIF)
		$hGIF = 0
		Return SetError(1, 0, 0)
	EndIf
	
	If UBound($aGIFArrayOfIconHandles) > 1 Then ; if GIF is animated one

		$hGIFThread = _AnimateGifInAnotherThread($hGIF, $aGIFArrayOfIconHandles, $iTransparency, $tCurrentFrame)

		If @error Then
			For $i = 0 To UBound($aGIFArrayOfIconHandles) - 1
				DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0])
			Next
			Return SetError(2, 0, 0)
		EndIf

	EndIf

	Return SetError(0, 0, $hGIF)
EndFunc  ;==>_GUICtrlCreateGIFFromBinary

; #FUNCTION# ;===============================================================================
;
; Name...........: _GUICtrlDeleteGIF
; Description ...: Deletes GIF control
; Syntax.........: _GUICtrlDeleteGIF(ByRef $hGIF, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $tCurrentFrame)
; Parameters ....: $hGIF - GIF controlID
;                  $aGIFArrayOfIconHandles - array of icon handles returned by _GUICtrlCreateGIF() function
;                  $hGIFThread - handle to the thread in which GIF is animated (returned by _GUICtrlCreateGIF() function)
;                  $tCurrentFrame - structure that holds current number of frame (returned by _GUICtrlCreateGIF() function)
; Return values .: Returns 1 regardless of success
; Author ........: trancexx
;
;==========================================================================================
Func _GUICtrlDeleteGIF(ByRef $hGIF, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $tCurrentFrame)

	_ExitGIFAnimation($aGIFArrayOfIconHandles, $hGIFThread, 1)
	GUICtrlDelete($hGIF)
	$hGIF = 0
	$tCurrentFrame = 0

	Return 1

EndFunc   ;==>_GUICtrlDeleteGIF


; #FUNCTION# ;===============================================================================
;
; Name...........: _StopGIFAnimation
; Description ...: Stops animation of GIF control
; Syntax.........: _StopGIFAnimation($hGIFThread)
; Parameters ....: $hGIFThread - handle to the thread in which GIF is animated (returned by _GUICtrlCreateGIF() function)
; Return values .: Success - Returns 1
;                          - Sets @error to 0
;                  Failure - Returns 0 sets @error:
;                  |1 - SuspendThread function or call to it failed
; Author ........: trancexx
;
;==========================================================================================
Func _StopGIFAnimation($hGIFThread)

	If $hGIFThread Then

		Local $a_iCall = DllCall("kernel32.dll", "dword", "SuspendThread", "ptr", $hGIFThread)

		If @error Or $a_iCall[0] = -1 Then
			Return SetError(1, 0, 0)
		EndIf

		If $a_iCall[0] Then
			DllCall("kernel32.dll", "dword", "ResumeThread", "ptr", $hGIFThread)
		EndIf

		Return 1

	EndIf

EndFunc   ;==>_StopGIFAnimation


; #FUNCTION# ;===============================================================================
;
; Name...........: _ResumeGIFAnimation
; Description ...: Resumes stopped animation of GIF control
; Syntax.........: _ResumeGIFAnimation($hGIFThread)
; Parameters ....: $hGIFThread - handle to the thread in which GIF is animated (returned by _GUICtrlCreateGIF() function)
; Return values .: Success - Returns 1
;                          - Sets @error to 0
;                  Failure - Returns 0 sets @error:
;                  |1 - ResumeThread function or call to it failed
; Author ........: trancexx
;
;==========================================================================================
Func _ResumeGIFAnimation($hGIFThread)

	If $hGIFThread Then

		Local $a_iCall = DllCall("kernel32.dll", "dword", "ResumeThread", "ptr", $hGIFThread)

		If @error Or $a_iCall[0] = -1 Then
			Return SetError(1, 0, 0)
		EndIf

		If $a_iCall[0] = 2 Then
			DllCall("kernel32.dll", "dword", "SuspendThread", "ptr", $hGIFThread)
		EndIf

		Return 1

	EndIf

EndFunc   ;==>_ResumeGIFAnimation


; #FUNCTION# ;===============================================================================
;
; Name...........: _ExitGIFAnimation
; Description ...: Exits animation of GIF control
; Syntax.........: _ExitGIFAnimation(ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread [, iTotal])
; Parameters ....: $aGIFArrayOfIconHandles - array of icon handles returned by _GUICtrlCreateGIF() function
;                  $hGIFThread - handle to the thread in which GIF is animated (returned by _GUICtrlCreateGIF() function)
;                  iTotal - optional parameter to set behaviour of function. Can be:
;                                                                                0 - Default - Destroy all icon handles but first
;                                                                                1 - Destroy all icon handles
; Return values .: Returns 1
;                  Sets @error to 0
; Author ........: trancexx
;
;==========================================================================================
Func _ExitGIFAnimation(ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, $iTotal = 0)

	If $hGIFThread Then
		DllCall("kernel32.dll", "ptr", "TerminateThread", "ptr", $hGIFThread, "dword", 0)
		$hGIFThread = 0
	EndIf

	If IsArray($aGIFArrayOfIconHandles) Then
		If $iTotal Then
			For $i = 0 To UBound($aGIFArrayOfIconHandles) - 1
				DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0]) ; destroy icons
			Next
			$aGIFArrayOfIconHandles = 0
		Else
			For $i = 1 To UBound($aGIFArrayOfIconHandles) - 1 ; all but the first frame
				DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0]) ; destroy icons
			Next
			ReDim $aGIFArrayOfIconHandles[1][3]
		EndIf
	EndIf

	Return 1

EndFunc   ;==>_ExitGIFAnimation


; #FUNCTION# ;===============================================================================
;
; Name...........: _RefreshGIF
; Description ...: Refreshes GIF control
; Syntax.........: _RefreshGIF($hGIFControl, $aGIFArrayOfIconHandles, $hGIFThread, $iGIFTransparent, $tFrameCurrent)
; Parameters ....: $hGIFControl - GIF control ID returned by _GUICtrlCreateGIF() function
;                  $aGIFArrayOfIconHandles - array of icon handles returned by _GUICtrlCreateGIF() function
;                  $hGIFThread - thread in which GIF is animated, returned by _GUICtrlCreateGIF() function
;                  $iGIFTransparent - transparency value returned by _GUICtrlCreateGIF() function
;                  $tFrameCurrent - structure that holds current number of frame, returned by _GUICtrlCreateGIF() function
; Return values .: Success - Refreshes GIF control
;                  Failure - Nothing
; Author ........: trancexx
;
;==========================================================================================
Func _RefreshGIF($hGIFControl, $aGIFArrayOfIconHandles, $hGIFThread, $iGIFTransparent, $tFrameCurrent)

	If $hGIFThread Then
		If Not $iGIFTransparent And IsArray($aGIFArrayOfIconHandles) Then

			Local $hControl = GUICtrlGetHandle($hGIFControl)

			Local $aCall = DllCall("user32.dll", "hwnd", "GetDC", "hwnd", $hControl)
			If @error Then
				Return
			EndIf
			Local $hDC = $aCall[0]

			Local $iFrameCurrent = DllStructGetData($tFrameCurrent, 1)
			If $iFrameCurrent > UBound($aGIFArrayOfIconHandles) - 1 Then
				$iFrameCurrent = 0
			EndIf

			Local $hIcon = $aGIFArrayOfIconHandles[$iFrameCurrent][0]

			DllCall("User32.dll", "int", "DrawIconEx", _
					"hwnd", $hDC, _
					"int", 0, _
					"int", 0, _
					"hwnd", $hIcon, _
					"int", 0, _
					"int", 0, _
					"dword", 0, _
					"hwnd", 0, _
					"dword", 3) ; DI_NORMAL

			DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $hControl, "hwnd", $hDC)

		EndIf
	EndIf

EndFunc   ;==>_RefreshGIF


; #FUNCTION# ;===============================================================================
;
; Name...........: _GIFGetDimension
; Description ...: Returns array of GIF image dimension
; Syntax.........: _GIFGetDimension($sFile)
; Parameters ....: $sFile - full path to the GIF file
; Return values .: Success - Returns array which first element [0] is width,
;                                        second element [1] is height,
;                          - Sets @error to 0
;                  Failure - Returns array which first element [0] 0 (zero),
;                                        second element [1] 0 (zero),
;                          - Sets @error:
;                           |1, 2 - unable to use gdiplus.dll
;                           |3 - GdiplusStartup or call to it failed
;                           |4 - GdipLoadImageFromFile or call to it failed
;                           |5 - GdipGetImageDimension or call to it failed
; Author ........: trancexx
;
;==========================================================================================
Func _GIFGetDimension($sFile)

	Local $aOut[2] = [0, 0]

	Local $a_hCall = DllCall("kernel32.dll", "hwnd", "GetModuleHandleW", "wstr", "gdiplus.dll")

	If @error Then
		Return SetError(1, 0, $aOut)
	EndIf

	If Not $a_hCall[0] Then
		Local $hDll = DllOpen("gdiplus.dll")
		If @error Or $hDll = -1 Then
			Return SetError(2, 0, $aOut)
		EndIf
	EndIf

	Local $tGdiplusStartupInput = DllStructCreate("dword GdiplusVersion;" & _
			"ptr DebugEventCallback;" & _
			"int SuppressBackgroundThread;" & _
			"int SuppressExternalCodecs")

	DllStructSetData($tGdiplusStartupInput, "GdiplusVersion", 1)

	Local $a_iCall = DllCall("gdiplus.dll", "dword", "GdiplusStartup", _
			"dword*", 0, _
			"ptr", DllStructGetPtr($tGdiplusStartupInput), _
			"ptr", 0)

	If @error Or $a_iCall[0] Then
		Return SetError(3, 0, $aOut)
	EndIf

	Local $hGDIplus = $a_iCall[1]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipLoadImageFromFile", _
			"wstr", $sFile, _
			"ptr*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(4, 0, $aOut)
	EndIf

	Local $pBitmap = $a_iCall[2]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetImageDimension", _
			"ptr", $pBitmap, _
			"float*", 0, _
			"float*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(5, 0, $aOut)
	EndIf

	$aOut[0] = $a_iCall[2]
	$aOut[1] = $a_iCall[3]

	DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
	DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)

	Return SetError(0, 0, $aOut)

EndFunc   ;==>_GIFGetDimension


; #FUNCTION# ;===============================================================================
;
; Name...........: _AnimateGifInAnotherThread
; Description ...: Animates GIF control
; Syntax.........: _AnimateGifInAnotherThread($hGIFControl, $aArrayOfHandlesAndTimes, $iTransparent, $pCurrentFrame)
; Remarks .......: This function if for internal useage by this script
; Author ........: trancexx
;
;==========================================================================================
Func _AnimateGifInAnotherThread($hGIFControl, $aArrayOfHandlesAndTimes, $iTransparent, ByRef $tCurrentFrame)

	Local $aCall = DllCall("kernel32.dll", "ptr", "GetModuleHandleW", "wstr", "kernel32.dll")
	If @error Or Not $aCall[0] Then
		Return SetError(1, 0, "")
	EndIf

	Local $hHandle = $aCall[0]

	Local $aSleep = DllCall("kernel32.dll", "ptr", "GetProcAddress", "ptr", $hHandle, "str", "Sleep")
	If @error Or Not $aSleep[0] Then
		Return SetError(2, 0, "")
	EndIf

	Local $pSleep = $aSleep[0]

	Local $iUbound = UBound($aArrayOfHandlesAndTimes)

	$tCurrentFrame = DllStructCreate("dword")
	Local $pCurrentFrame = DllStructGetPtr($tCurrentFrame)

	Local $tagCodeBuffer
	Local $tCodeBuffer
	Local $pRemoteCode

	If $iTransparent Then

		$aCall = DllCall("kernel32.dll", "ptr", "GetModuleHandleW", "wstr", "user32.dll")
		If @error Or Not $aCall[0] Then
			Return SetError(3, 0, "")
		EndIf

		$hHandle = $aCall[0]

		Local $aSendMessageW = DllCall("kernel32.dll", "ptr", "GetProcAddress", "ptr", $hHandle, "str", "SendMessageW")
		If @error Or Not $aSendMessageW[0] Then
			Return SetError(4, 0, "")
		EndIf

		Local $pSendMessageW = $aSendMessageW[0]

		For $i = 1 To $iUbound
			$tagCodeBuffer &= "byte[39];"
		Next
		$tagCodeBuffer &= "byte[6]"

		$tCodeBuffer = DllStructCreate($tagCodeBuffer)

		$pRemoteCode = DllCall("kernel32.dll", "ptr", "VirtualAlloc", _
				"ptr", 0, _
				"dword", DllStructGetSize($tCodeBuffer), _
				"dword", 4096, _ ; MEM_COMMIT
				"dword", 64) ; PAGE_EXECUTE_READWRITE

		$pRemoteCode = $pRemoteCode[0]

		For $i = 1 To $iUbound

			DllStructSetData($tCodeBuffer, $i, _
					"0x" & _
					"68" & SwapEndian(0) & _                                   ; push lParam
					"68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][0]) & _ ; push handle to the icon
					"68" & SwapEndian(368) & _                                 ; push STM_SETICON
					"68" & SwapEndian(GUICtrlGetHandle($hGIFControl)) & _      ; push HANDLE
					"B8" & SwapEndian($pSendMessageW) & _                      ; mov eax, SendMessageW
					"FFD0" & _                                                 ; call eax
					"68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][1]) & _ ; push Milliseconds
					"B8" & SwapEndian($pSleep) & _                             ; mov eax, Sleep
					"FFD0" _                                                   ; call eax
					)

		Next

		DllStructSetData($tCodeBuffer, $iUbound + 1, _
				"0x" & _
				"E9" & SwapEndian(-($iUbound * 39 + 5)) & _                    ; jump [start address]
				"C3" _                                                         ; ret
				)

	Else

		$aCall = DllCall("kernel32.dll", "ptr", "GetModuleHandleW", "wstr", "user32.dll")
		If @error Or Not $aCall[0] Then
			Return SetError(3, 0, "")
		EndIf

		$hHandle = $aCall[0]

		Local $aDrawIconEx = DllCall("kernel32.dll", "ptr", "GetProcAddress", "ptr", $hHandle, "str", "DrawIconEx")
		If @error Or Not $aDrawIconEx[0] Then
			Return SetError(5, 0, "")
		EndIf

		Local $pDrawIconEx = $aDrawIconEx[0]

		For $i = 1 To $iUbound
			$tagCodeBuffer &= "byte[74];"
		Next
		$tagCodeBuffer &= "byte[6]"

		$tCodeBuffer = DllStructCreate($tagCodeBuffer)

		$pRemoteCode = DllCall("kernel32.dll", "ptr", "VirtualAlloc", _
				"ptr", 0, _
				"dword", DllStructGetSize($tCodeBuffer), _
				"dword", 4096, _ ; MEM_COMMIT
				"dword", 64) ; PAGE_EXECUTE_READWRITE

		$pRemoteCode = $pRemoteCode[0]

		$aCall = DllCall("user32.dll", "hwnd", "GetDC", "hwnd", GUICtrlGetHandle($hGIFControl))
		If @error Or Not $aCall[0] Then
			Return SetError(6, 0, "")
		EndIf

		Local $hDC = $aCall[0]

		For $i = 1 To $iUbound

			DllStructSetData($tCodeBuffer, $i, _
					"0x" & _
					"68" & SwapEndian(3) & _                                   ; push Flags DI_NORMAL
					"68" & SwapEndian(0) & _                                   ; push FlickerFreeDraw
					"68" & SwapEndian(0) & _                                   ; push IfAniCur
					"68" & SwapEndian(0) & _                                   ; push Height
					"68" & SwapEndian(0) & _                                   ; push Width
					"68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][0]) & _ ; push handle to the icon
					"68" & SwapEndian(0) & _                                   ; push Top
					"68" & SwapEndian(0) & _                                   ; push Left
					"68" & SwapEndian($hDC) & _                                ; push DC
					"B8" & SwapEndian($pDrawIconEx) & _                        ; mov eax, DrawIconEx
					"FFD0" & _                                                 ; call eax
					"B8" & SwapEndian($i - 1) & _                              ; mov eax, $i-1
					"A3" & SwapEndian($pCurrentFrame) & _                      ; mov $pCurrentFrame, eax
					"68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][1]) & _ ; push Milliseconds
					"B8" & SwapEndian($pSleep) & _                             ; mov eax, Sleep
					"FFD0" _                                                   ; call eax
					)

		Next

		DllStructSetData($tCodeBuffer, $iUbound + 1, _
				"0x" & _
				"E9" & SwapEndian(-($iUbound * 74 + 5)) & _                    ; jump [start address]
				"C3" _                                                         ; ret
				)

	EndIf

	DllCall("kernel32.dll", "none", "RtlMoveMemory", _
			"ptr", $pRemoteCode, _
			"ptr", DllStructGetPtr($tCodeBuffer), _
			"dword", DllStructGetSize($tCodeBuffer))

	$aCall = DllCall("kernel32.dll", "ptr", "CreateThread", "ptr", 0, "dword", 0, "ptr", $pRemoteCode, "ptr", 0, "dword", 0, "dword*", 0)

	If @error Or Not $aCall[0] Then
		Return SetError(7, 0, "")
	EndIf

	Local $hGIFThread = $aCall[0]

	Return SetError(0, 0, $hGIFThread) ; this is success

EndFunc   ;==>_AnimateGifInAnotherThread


; #FUNCTION# ;===============================================================================
;
; Name...........: SwapEndian
; Description ...: 4 byte endian swapper
; Syntax.........: SwapEndian($iValue)
; Remarks .......: This function if for internal useage by this script
; Author ........: trancexx
;
;==========================================================================================
Func SwapEndian($iValue)

	Return Hex(BinaryMid($iValue, 1, 4))

EndFunc   ;==>SwapEndian


; #FUNCTION# ;===============================================================================
;
; Name...........: _CreateArrayHIconsFromGIFFile
; Description ...: Create array of icon handles out of GIF file
; Syntax.........: _CreateArrayHIconsFromGIFFile($sFile, ByRef $iWidth, ByRef $iHeight, ByRef $iTransparency)
; Remarks .......: This function if for internal useage by this script
; Author ........: trancexx (GDI+ part originally by ProgAndy)
;
;==========================================================================================
Func _CreateArrayHIconsFromGIFFile($hGIF, $sFile, $iLeft, $iTop, ByRef $iTransparency)

	Local $a_hCall = DllCall("kernel32.dll", "hwnd", "GetModuleHandleW", "wstr", "gdiplus.dll")

	If @error Then
		Return SetError(1, 0, "")
	EndIf

	If Not $a_hCall[0] Then
		Local $hDll = DllOpen("gdiplus.dll")
		If @error Or $hDll = -1 Then
			Return SetError(2, 0, "")
		EndIf
	EndIf

	Local $tGdiplusStartupInput = DllStructCreate("dword GdiplusVersion;" & _
			"ptr DebugEventCallback;" & _
			"int SuppressBackgroundThread;" & _
			"int SuppressExternalCodecs")

	DllStructSetData($tGdiplusStartupInput, "GdiplusVersion", 1)

	Local $a_iCall = DllCall("gdiplus.dll", "dword", "GdiplusStartup", _
			"dword*", 0, _
			"ptr", DllStructGetPtr($tGdiplusStartupInput), _
			"ptr", 0)

	If @error Or $a_iCall[0] Then
		Return SetError(3, 0, "")
	EndIf

	Local $hGDIplus = $a_iCall[1]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipLoadImageFromFile", _
			"wstr", $sFile, _
			"ptr*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(4, 0, "")
	EndIf

	Local $pBitmap = $a_iCall[2]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetImageDimension", _
			"ptr", $pBitmap, _
			"float*", 0, _
			"float*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(5, 0, "")
	EndIf

	Local $iWidth = $a_iCall[2]
	Local $iHeight = $a_iCall[3]

	GUICtrlSetPos($hGIF, $iLeft, $iTop, $iWidth, $iHeight)

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsCount", _
			"ptr", $pBitmap, _
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(6, 0, "")
	EndIf

	Local $iFrameDimensionsCount = $a_iCall[2]

	Local $tGUID = DllStructCreate("int;short;short;byte[8]")

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsList", _
			"ptr", $pBitmap, _
			"ptr", DllStructGetPtr($tGUID), _
			"dword", $iFrameDimensionsCount)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(7, 0, "")
	EndIf

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameCount", _
			"ptr", $pBitmap, _
			"ptr", DllStructGetPtr($tGUID), _
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(8, 0, "")
	EndIf

	Local $iFrameCount = $a_iCall[3]

	Local $aHBitmaps[$iFrameCount][3]

	Local $x = 1

	For $i = 0 To $iFrameCount - 1

		$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageSelectActiveFrame", _
				"ptr", $pBitmap, _
				"ptr", DllStructGetPtr($tGUID), _
				"dword", $i)

		If @error Or $a_iCall[0] Then
			$aHBitmaps[$i][0] = 0
			ContinueLoop
		EndIf

		$a_iCall = DllCall("gdiplus.dll", "dword", "GdipCreateHICONFromBitmap", _
				"ptr", $pBitmap, _
				"hwnd*", 0)

		If @error Or $a_iCall[0] Then
			$aHBitmaps[$i][0] = 0
			ContinueLoop
		EndIf

		$aHBitmaps[$i][0] = $a_iCall[2]

		If $x Then ; first valid frame gets drawn
			GUICtrlSendMsg($hGIF, 368, $aHBitmaps[$i][0], 0) ;STM_SETICON
			$x = 0
		EndIf

	Next

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItemSize", _
			"ptr", $pBitmap, _
			"dword", 20736, _ ; PropertyTagFrameDelay
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(9, 0, "")
	EndIf

	Local $iPropertyItemSize = $a_iCall[3]

	Local $tRawPropItem = DllStructCreate("byte[" & $iPropertyItemSize & "]")

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItem", _
			"ptr", $pBitmap, _
			"dword", 20736, _ ; PropertyTagFrameDelay
			"dword", DllStructGetSize($tRawPropItem), _
			"ptr", DllStructGetPtr($tRawPropItem))

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(10, 0, "")
	EndIf

	Local $tPropItem = DllStructCreate("int Id;" & _
			"dword Length;" & _
			"ushort Type;" & _
			"ptr Value", _
			DllStructGetPtr($tRawPropItem))

	Local $iSize = DllStructGetData($tPropItem, "Length") / 4 ; 'Delay Time' is dword type

	Local $tPropertyData = DllStructCreate("dword[" & $iSize & "]", DllStructGetData($tPropItem, "Value"))

	For $i = 0 To $iFrameCount - 1
		$aHBitmaps[$i][1] = DllStructGetData($tPropertyData, 1, $i + 1) * 10 ; 1 = 10 msec
		$aHBitmaps[$i][2] = $aHBitmaps[$i][1] ; read values
		If Not $aHBitmaps[$i][1] Then
			$aHBitmaps[$i][1] = 130 ; 0 is interpreted as 130 ms
		EndIf
		If $aHBitmaps[$i][1] < 50 Then ; will slow it down to prevent more extensive cpu usage
			$aHBitmaps[$i][1] = 50
		EndIf
	Next

	$iTransparency = 1 ; predefining

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipBitmapGetPixel", _
			"ptr", $pBitmap, _
			"int", 0, _  ; left
			"int", 0, _  ; upper
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		Return SetError(11, 0, "")
	EndIf

	If $a_iCall[4] > 16777215 Then
		$iTransparency = 0
	EndIf

	DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
	DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)

	Return SetError(0, 0, $aHBitmaps)

EndFunc   ;==>_CreateArrayHIconsFromGIFFile


; #FUNCTION# ;===============================================================================
;
; Name...........: _CreateArrayHIconsFromGIFBinaryImage
; Description ...: Create array of icon handles out of binary data
; Syntax.........: _CreateArrayHIconsFromGIFFile($sFile, ByRef $iWidth, ByRef $iHeight, ByRef $iTransparency)
; Remarks .......: This function if for internal useage by this script
; Author ........: trancexx (originally by ProgAndy)
;
;==========================================================================================
Func _CreateArrayHIconsFromGIFBinaryImage($hGIF, $bBinary, $iLeft, $iTop, ByRef $iTransparency)

	Local $tBinary = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
	DllStructSetData($tBinary, 1, $bBinary)

	Local $a_hCall = DllCall("kernel32.dll", "hwnd", "GlobalAlloc", _
			"dword", 2, _  ; LMEM_MOVEABLE
			"dword", DllStructGetSize($tBinary))

	If @error Or Not $a_hCall[0] Then
		Return SetError(1, 0, "")
	EndIf

	Local $hMemory = $a_hCall[0]

	Local $a_pCall = DllCall("kernel32.dll", "ptr", "GlobalLock", "hwnd", $hMemory)

	If @error Or Not $a_pCall[0] Then
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(2, 0, "")
	EndIf

	Local $pMemory = $a_pCall[0]

	DllCall("kernel32.dll", "none", "RtlMoveMemory", _
			"ptr", $pMemory, _
			"ptr", DllStructGetPtr($tBinary), _
			"dword", DllStructGetSize($tBinary))

	DllCall("kernel32.dll", "int", "GlobalUnlock", "hwnd", $hMemory)

	Local $a_iCall = DllCall("ole32.dll", "int", "CreateStreamOnHGlobal", _
			"ptr", $pMemory, _
			"int", 1, _
			"ptr*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(3, 0, "")
	EndIf

	Local $pStream = $a_iCall[3]

	Local $tGdiplusStartupInput = DllStructCreate("dword GdiplusVersion;" & _
			"ptr DebugEventCallback;" & _
			"int SuppressBackgroundThread;" & _
			"int SuppressExternalCodecs")

	DllStructSetData($tGdiplusStartupInput, "GdiplusVersion", 1)

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdiplusStartup", _
			"dword*", 0, _
			"ptr", DllStructGetPtr($tGdiplusStartupInput), _
			"ptr", 0)

	If @error Or $a_iCall[0] Then
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(4, 0, "")
	EndIf

	Local $hGDIplus = $a_iCall[1]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipCreateBitmapFromStream", _ ; GdipLoadImageFromStream
			"ptr", $pStream, _
			"ptr*", 0)

	If @error Or $a_iCall[0] Then
		ConsoleWrite("! FromStream > " & @error & " " & $a_iCall[0] & @LF)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(5, 0, "")
	EndIf

	Local $pBitmap = $a_iCall[2]

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetImageDimension", _
			"ptr", $pBitmap, _
			"float*", 0, _
			"float*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(5, 0, "")
	EndIf

	Local $iWidth = $a_iCall[2]
	Local $iHeight = $a_iCall[3]

	GUICtrlSetPos($hGIF, $iLeft, $iTop, $iWidth, $iHeight)
	
	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsCount", _
			"ptr", $pBitmap, _
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(8, 0, "")
	EndIf

	Local $iFrameDimensionsCount = $a_iCall[2]

	Local $tGUID = DllStructCreate("int;short;short;byte[8]")

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsList", _
			"ptr", $pBitmap, _
			"ptr", DllStructGetPtr($tGUID), _
			"dword", $iFrameDimensionsCount)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(9, 0, "")
	EndIf

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameCount", _
			"ptr", $pBitmap, _
			"ptr", DllStructGetPtr($tGUID), _
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(10, 0, "")
	EndIf

	Local $iFrameCount = $a_iCall[3]

	Local $aHBitmaps[$iFrameCount][3]
	
	Local $x = 1

	For $i = 0 To $iFrameCount - 1

		$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageSelectActiveFrame", _
				"ptr", $pBitmap, _
				"ptr", DllStructGetPtr($tGUID), _
				"dword", $i)

		If @error Or $a_iCall[0] Then
			$aHBitmaps[$i][0] = 0
			ContinueLoop
		EndIf

		$a_iCall = DllCall("gdiplus.dll", "dword", "GdipCreateHICONFromBitmap", _
				"ptr", $pBitmap, _
				"hwnd*", 0)

		If @error Or $a_iCall[0] Then
			$aHBitmaps[$i][0] = 0
			ContinueLoop
		EndIf

		$aHBitmaps[$i][0] = $a_iCall[2]

		If $x Then ; first valid frame gets drawn
			GUICtrlSendMsg($hGIF, 368, $aHBitmaps[$i][0], 0) ;STM_SETICON
			$x = 0
		EndIf
		
	Next

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItemSize", _
			"ptr", $pBitmap, _
			"dword", 20736, _ ; PropertyTagFrameDelay
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(11, 0, "")
	EndIf

	Local $iPropertyItemSize = $a_iCall[3]

	Local $tRawPropItem = DllStructCreate("byte[" & $iPropertyItemSize & "]")

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItem", _
			"ptr", $pBitmap, _
			"dword", 20736, _ ; PropertyTagFrameDelay
			"dword", DllStructGetSize($tRawPropItem), _
			"ptr", DllStructGetPtr($tRawPropItem))

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(12, 0, "")
	EndIf

	Local $tPropItem = DllStructCreate("int Id;" & _
			"dword Length;" & _
			"ushort Type;" & _
			"ptr Value", _
			DllStructGetPtr($tRawPropItem))

	Local $iSize = DllStructGetData($tPropItem, "Length") / 4 ; 'Delay Time' is dword type

	Local $tPropertyData = DllStructCreate("dword[" & $iSize & "]", DllStructGetData($tPropItem, "Value"))

	For $i = 0 To $iFrameCount - 1
		$aHBitmaps[$i][1] = DllStructGetData($tPropertyData, 1, $i + 1) * 10 ; 1 = 10 msec
		$aHBitmaps[$i][2] = $aHBitmaps[$i][1] ; read values
		If Not $aHBitmaps[$i][1] Then
			$aHBitmaps[$i][1] = 130 ; 0 is interpreted as 130 ms
		EndIf
		If $aHBitmaps[$i][1] < 50 Then ; will slow it down to prevent more extensive cpu usage
			$aHBitmaps[$i][1] = 50
		EndIf
	Next

	$iTransparency = 1 ; predefining

	$a_iCall = DllCall("gdiplus.dll", "dword", "GdipBitmapGetPixel", _
			"ptr", $pBitmap, _
			"int", 0, _  ; left
			"int", 0, _  ; upper
			"dword*", 0)

	If @error Or $a_iCall[0] Then
		DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
		DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
		DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)
		Return SetError(13, 0, "")
	EndIf

	If $a_iCall[4] > 16777215 Then
		$iTransparency = 0
	EndIf

	DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
	DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
	DllCall("kernel32.dll", "int", "GlobalFree", "hwnd", $hMemory)

	Return SetError(0, 0, $aHBitmaps)

EndFunc   ;==>_CreateArrayHIconsFromGIFBinaryImage
