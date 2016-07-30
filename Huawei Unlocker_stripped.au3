#NoTrayIcon
Global Const $STDOUT_CHILD = 2
Global Const $STDERR_CHILD = 4
Global Const $UBOUND_DIMENSIONS = 0
Global Const $UBOUND_ROWS = 1
Global Const $UBOUND_COLUMNS = 2
Global Const $CREATE_NEW = 1
Global Const $CREATE_ALWAYS = 2
Global Const $OPEN_EXISTING = 3
Global Const $OPEN_ALWAYS = 4
Global Const $TRUNCATE_EXISTING = 5
Global Const $FILE_END = 2
Global Const $FILE_ATTRIBUTE_READONLY = 0x00000001
Global Const $FILE_ATTRIBUTE_HIDDEN = 0x00000002
Global Const $FILE_ATTRIBUTE_SYSTEM = 0x00000004
Global Const $FILE_ATTRIBUTE_ARCHIVE = 0x00000020
Global Const $FILE_SHARE_READ = 0x00000001
Global Const $FILE_SHARE_WRITE = 0x00000002
Global Const $FILE_SHARE_DELETE = 0x00000004
Global Const $GENERIC_EXECUTE = 0x20000000
Global Const $GENERIC_WRITE = 0x40000000
Global Const $GENERIC_READ = 0x80000000
Global Const $MB_ICONERROR = 16
Global Const $MB_ICONINFORMATION = 64
Global Const $MB_APPLMODAL = 0
Func __Run($sCommand)
Local $iPID, $sLine, $sOutput = ""
$iPID = Run(@ComSpec & " /c " & $sCommand, @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
While 1
$sLine = StdoutRead($iPID)
If @error Then ExitLoop
$sOutput &= $sLine
WEnd
Return StringStripCR(StringTrimRight($sOutput, StringLen(@CRLF)))
EndFunc
Func _Android_CommandExists($sCommand)
Return _Android_Shell('command -v ' & $sCommand & ' > /dev/null 2>&1 && echo \"Found\" || echo \"Not Found\"') = "Found"
EndFunc
Func _Android_Connect()
Local $bOnline = _Android_IsOnline()
If Not $bOnline Then
__Run("adb kill-server")
__Run("adb start-server")
$bOnline = _Android_IsOnline()
EndIf
Return SetError(Int(Not $bOnline), 0, Int($bOnline))
EndFunc
Func _Android_FileExists($sFilePath)
Return _Android_Shell('if [ -e \"' & $sFilePath & '\" ]; then echo \"Found\"; else echo \"Not Found\"; fi') = "Found"
EndFunc
Func _Android_GetDeviceID()
Local $aOutput = StringRegExp(_Android_Shell("dumpsys iphonesubinfo"), "Device ID = (.*)", 3)
If Not @error Then Return $aOutput[0]
EndFunc
Func _Android_GetProperty($sKey)
Return _Android_Shell("getprop " & $sKey)
EndFunc
Func _Android_GetState()
If _Android_IsOnline() Then
Return "Online"
ElseIf _Android_IsOffline() Then
Return "Offline"
ElseIf _Android_IsBootloader() Then
Return "Bootloader"
Else
Return "Unknown"
EndIf
EndFunc
Func _Android_IsBootloader()
Return __Run("fastboot devices") <> ""
EndFunc
Func _Android_IsBusyBoxInstalled()
Return _Android_CommandExists("busybox")
EndFunc
Func _Android_IsOffline()
Return __Run("adb get-state") = "offline"
EndFunc
Func _Android_IsOnline()
Return __Run("adb get-state") = "device"
EndFunc
Func _Android_IsRooted()
Return _Android_Shell("echo Root Checker", True) = "Root Checker"
EndFunc
Func _Android_Pull($sRemotePath, $sLocalPath)
Return __Run('adb pull "' & $sRemotePath & '" "' & $sLocalPath & '"')
EndFunc
Func _Android_Push($sLocalPath, $sRemotePath)
Return __Run('adb push "' & $sLocalPath & '" "' & $sRemotePath & '"')
EndFunc
Func _Android_Reboot($sMode = "")
If $sMode = Default Then $sMode = ""
Switch $sMode
Case "recovery"
If Not _Android_IsOnline() Then Return SetError(1, 0, 0)
__Run("adb reboot recovery")
Case "bootloader"
If _Android_IsBootloader() Then
__Run("fastboot reboot-bootloader")
Else
__Run("adb reboot bootloader")
EndIf
Case "download"
If Not _Android_IsOnline() Then Return SetError(1, 0, 0)
If _Android_GetProperty("ro.product.manufacturer") <> "Samsung" Then Return SetError(2, 0, 0)
__Run("adb reboot download")
Case Else
If _Android_IsBootloader() Then
__Run("fastboot reboot")
Else
__Run("adb reboot")
EndIf
EndSwitch
Return 1
EndFunc
Func _Android_Shell($sCommand, $bSuperuser = False, $bBusyBox = False)
If $bSuperuser = Default Then $bSuperuser = False
If $bBusyBox = Default Then $bBusyBox = False
If $bSuperuser Then
If $bBusyBox Then
If Not _Android_IsBusyBoxInstalled() Then
If _Android_Shell("/data/local/tmp/busybox echo BusyBox Checker") <> "BusyBox Checker" Then
_Android_Push("busybox", "/data/local/tmp")
_Android_Shell("chmod 755 /data/local/tmp/busybox")
EndIf
Return _Android_Shell("export PATH=/data/local/tmp:$PATH; busybox " & $sCommand, True)
Else
Return _Android_Shell("busybox " & $sCommand, True)
EndIf
Else
Return __Run('adb shell su -c "' & $sCommand & '"')
EndIf
Else
If $bBusyBox Then
If Not _Android_IsBusyBoxInstalled() Then
If _Android_Shell("/data/local/tmp/busybox echo BusyBox Checker") <> "BusyBox Checker" Then
_Android_Push("busybox", "/data/local/tmp")
_Android_Shell("chmod 755 /data/local/tmp/busybox")
EndIf
Return _Android_Shell("export PATH=/data/local/tmp:$PATH; busybox " & $sCommand)
Else
Return _Android_Shell("busybox " & $sCommand)
EndIf
Else
Return __Run('adb shell "' & $sCommand & '"')
EndIf
EndIf
EndFunc
Global Const $WS_BORDER = 0x00800000
Global Const $WS_DISABLED = 0x08000000
Global Const $WS_POPUP = 0x80000000
Global Const $WS_EX_LAYERED = 0x00080000
Global Const $WS_EX_TOOLWINDOW = 0x00000080
Global Const $WM_COMMAND = 0x0111
Global Const $WM_DEVICECHANGE = 0x0219
Global Const $GUI_EVENT_CLOSE = -3
Global Const $GUI_RUNDEFMSG = 'GUI_RUNDEFMSG'
Global Const $GUI_SHOW = 16
Global Const $GUI_HIDE = 32
Global Const $GUI_DISABLE = 128
Global Const $SS_CENTER = 0x1
Func _ArrayToString(Const ByRef $avArray, $sDelim_Item = "|", $iStart_Row = 0, $iEnd_Row = 0, $sDelim_Row = @CRLF, $iStart_Col = 0, $iEnd_Col = 0)
If $sDelim_Item = Default Then $sDelim_Item = "|"
If $sDelim_Row = Default Then $sDelim_Row = @CRLF
If $iStart_Row = Default Then $iStart_Row = 0
If $iEnd_Row = Default Then $iEnd_Row = 0
If $iStart_Col = Default Then $iStart_Col = 0
If $iEnd_Col = Default Then $iEnd_Col = 0
If Not IsArray($avArray) Then Return SetError(1, 0, -1)
Local $iDim_1 = UBound($avArray, $UBOUND_ROWS) - 1
If $iEnd_Row = 0 Then $iEnd_Row = $iDim_1
If $iStart_Row < 0 Or $iEnd_Row < 0 Then Return SetError(3, 0, -1)
If $iStart_Row > $iDim_1 Or $iEnd_Row > $iDim_1 Then Return SetError(3, 0, "")
If $iStart_Row > $iEnd_Row Then Return SetError(4, 0, -1)
Local $sRet = ""
Switch UBound($avArray, $UBOUND_DIMENSIONS)
Case 1
For $i = $iStart_Row To $iEnd_Row
$sRet &= $avArray[$i] & $sDelim_Item
Next
Return StringTrimRight($sRet, StringLen($sDelim_Item))
Case 2
Local $iDim_2 = UBound($avArray, $UBOUND_COLUMNS) - 1
If $iEnd_Col = 0 Then $iEnd_Col = $iDim_2
If $iStart_Col < 0 Or $iEnd_Col < 0 Then Return SetError(5, 0, -1)
If $iStart_Col > $iDim_2 Or $iEnd_Col > $iDim_2 Then Return SetError(5, 0, -1)
If $iStart_Col > $iEnd_Col Then Return SetError(6, 0, -1)
For $i = $iStart_Row To $iEnd_Row
For $j = $iStart_Col To $iEnd_Col
$sRet &= $avArray[$i][$j] & $sDelim_Item
Next
$sRet = StringTrimRight($sRet, StringLen($sDelim_Item)) & $sDelim_Row
Next
Return StringTrimRight($sRet, StringLen($sDelim_Row))
Case Else
Return SetError(2, 0, -1)
EndSwitch
Return 1
EndFunc
Global Const $tagRECT = "struct;long Left;long Top;long Right;long Bottom;endstruct"
Global Const $tagREBARBANDINFO = "uint cbSize;uint fMask;uint fStyle;dword clrFore;dword clrBack;ptr lpText;uint cch;" & "int iImage;hwnd hwndChild;uint cxMinChild;uint cyMinChild;uint cx;handle hbmBack;uint wID;uint cyChild;uint cyMaxChild;" & "uint cyIntegral;uint cxIdeal;lparam lParam;uint cxHeader" &((@OSVersion = "WIN_XP") ? "" : ";" & $tagRECT & ";uint uChevronState")
Global Const $tagSECURITY_ATTRIBUTES = "dword Length;ptr Descriptor;bool InheritHandle"
Global Const $HGDI_ERROR = Ptr(-1)
Global Const $INVALID_HANDLE_VALUE = Ptr(-1)
Global Const $KF_EXTENDED = 0x0100
Global Const $KF_ALTDOWN = 0x2000
Global Const $KF_UP = 0x8000
Global Const $LLKHF_EXTENDED = BitShift($KF_EXTENDED, 8)
Global Const $LLKHF_ALTDOWN = BitShift($KF_ALTDOWN, 8)
Global Const $LLKHF_UP = BitShift($KF_UP, 8)
Func _WinAPI_ClientToScreen($hWnd, ByRef $tPoint)
Local $aRet = DllCall("user32.dll", "bool", "ClientToScreen", "hwnd", $hWnd, "struct*", $tPoint)
If @error Or Not $aRet[0] Then Return SetError(@error + 10, @extended, 0)
Return $tPoint
EndFunc
Func _WinAPI_CloseHandle($hObject)
Local $aResult = DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hObject)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Func _WinAPI_CreateFile($sFileName, $iCreation, $iAccess = 4, $iShare = 0, $iAttributes = 0, $pSecurity = 0)
Local $iDA = 0, $iSM = 0, $iCD = 0, $iFA = 0
If BitAND($iAccess, 1) <> 0 Then $iDA = BitOR($iDA, $GENERIC_EXECUTE)
If BitAND($iAccess, 2) <> 0 Then $iDA = BitOR($iDA, $GENERIC_READ)
If BitAND($iAccess, 4) <> 0 Then $iDA = BitOR($iDA, $GENERIC_WRITE)
If BitAND($iShare, 1) <> 0 Then $iSM = BitOR($iSM, $FILE_SHARE_DELETE)
If BitAND($iShare, 2) <> 0 Then $iSM = BitOR($iSM, $FILE_SHARE_READ)
If BitAND($iShare, 4) <> 0 Then $iSM = BitOR($iSM, $FILE_SHARE_WRITE)
Switch $iCreation
Case 0
$iCD = $CREATE_NEW
Case 1
$iCD = $CREATE_ALWAYS
Case 2
$iCD = $OPEN_EXISTING
Case 3
$iCD = $OPEN_ALWAYS
Case 4
$iCD = $TRUNCATE_EXISTING
EndSwitch
If BitAND($iAttributes, 1) <> 0 Then $iFA = BitOR($iFA, $FILE_ATTRIBUTE_ARCHIVE)
If BitAND($iAttributes, 2) <> 0 Then $iFA = BitOR($iFA, $FILE_ATTRIBUTE_HIDDEN)
If BitAND($iAttributes, 4) <> 0 Then $iFA = BitOR($iFA, $FILE_ATTRIBUTE_READONLY)
If BitAND($iAttributes, 8) <> 0 Then $iFA = BitOR($iFA, $FILE_ATTRIBUTE_SYSTEM)
Local $aResult = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", $sFileName, "dword", $iDA, "dword", $iSM, "ptr", $pSecurity, "dword", $iCD, "dword", $iFA, "ptr", 0)
If @error Or($aResult[0] = $INVALID_HANDLE_VALUE) Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_GetClientRect($hWnd)
Local $tRect = DllStructCreate($tagRECT)
Local $aRet = DllCall("user32.dll", "bool", "GetClientRect", "hwnd", $hWnd, "struct*", $tRect)
If @error Or Not $aRet[0] Then Return SetError(@error + 10, @extended, 0)
Return $tRect
EndFunc
Func _WinAPI_GetFileSizeEx($hFile)
Local $aResult = DllCall("kernel32.dll", "bool", "GetFileSizeEx", "handle", $hFile, "int64*", 0)
If @error Or Not $aResult[0] Then Return SetError(@error, @extended, -1)
Return $aResult[2]
EndFunc
Func _WinAPI_HiWord($iLong)
Return BitShift($iLong, 16)
EndFunc
Func _WinAPI_LoWord($iLong)
Return BitAND($iLong, 0xFFFF)
EndFunc
Func _WinAPI_ReadFile($hFile, $pBuffer, $iToRead, ByRef $iRead, $pOverlapped = 0)
Local $aResult = DllCall("kernel32.dll", "bool", "ReadFile", "handle", $hFile, "ptr", $pBuffer, "dword", $iToRead, "dword*", 0, "ptr", $pOverlapped)
If @error Then Return SetError(@error, @extended, False)
$iRead = $aResult[4]
Return $aResult[0]
EndFunc
Func _WinAPI_SetFilePointer($hFile, $iPos, $iMethod = 0)
Local $aResult = DllCall("kernel32.dll", "INT", "SetFilePointer", "handle", $hFile, "long", $iPos, "ptr", 0, "long", $iMethod)
If @error Then Return SetError(@error, @extended, -1)
Return $aResult[0]
EndFunc
Func _WinAPI_WriteFile($hFile, $pBuffer, $iToWrite, ByRef $iWritten, $pOverlapped = 0)
Local $aResult = DllCall("kernel32.dll", "bool", "WriteFile", "handle", $hFile, "ptr", $pBuffer, "dword", $iToWrite, "dword*", 0, "ptr", $pOverlapped)
If @error Then Return SetError(@error, @extended, False)
$iWritten = $aResult[4]
Return $aResult[0]
EndFunc
Func _GUICtrlCreateGIF($sFileName, $iLeft, $iTop, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $iTransparency, ByRef $tCurrentFrame)
Local $hGIF = GUICtrlCreateIcon("", "", 0, 0)
$aGIFArrayOfIconHandles = _CreateArrayHIconsFromGIFFile($hGIF, $sFileName, $iLeft, $iTop, $iTransparency)
If @error Then
GUICtrlDelete($hGIF)
$hGIF = 0
Return SetError(1, 0, 0)
EndIf
If UBound($aGIFArrayOfIconHandles) > 1 Then
$hGIFThread = _AnimateGifInAnotherThread($hGIF, $aGIFArrayOfIconHandles, $iTransparency, $tCurrentFrame)
If @error Then
For $i = 0 To UBound($aGIFArrayOfIconHandles) - 1
DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0])
Next
Return SetError(2, 0, 0)
EndIf
EndIf
Return SetError(0, 0, $hGIF)
EndFunc
Func _GUICtrlDeleteGIF(ByRef $hGIF, ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, ByRef $tCurrentFrame)
_ExitGIFAnimation($aGIFArrayOfIconHandles, $hGIFThread, 1)
GUICtrlDelete($hGIF)
$hGIF = 0
$tCurrentFrame = 0
Return 1
EndFunc
Func _ExitGIFAnimation(ByRef $aGIFArrayOfIconHandles, ByRef $hGIFThread, $iTotal = 0)
If $hGIFThread Then
DllCall("kernel32.dll", "ptr", "TerminateThread", "ptr", $hGIFThread, "dword", 0)
$hGIFThread = 0
EndIf
If IsArray($aGIFArrayOfIconHandles) Then
If $iTotal Then
For $i = 0 To UBound($aGIFArrayOfIconHandles) - 1
DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0])
Next
$aGIFArrayOfIconHandles = 0
Else
For $i = 1 To UBound($aGIFArrayOfIconHandles) - 1
DllCall("user32.dll", "int", "DestroyIcon", "hwnd", $aGIFArrayOfIconHandles[$i][0])
Next
ReDim $aGIFArrayOfIconHandles[1][3]
EndIf
EndIf
Return 1
EndFunc
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
DllCall("User32.dll", "int", "DrawIconEx", "hwnd", $hDC, "int", 0, "int", 0, "hwnd", $hIcon, "int", 0, "int", 0, "dword", 0, "hwnd", 0, "dword", 3)
DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $hControl, "hwnd", $hDC)
EndIf
EndIf
EndFunc
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
$pRemoteCode = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "dword", DllStructGetSize($tCodeBuffer), "dword", 4096, "dword", 64)
$pRemoteCode = $pRemoteCode[0]
For $i = 1 To $iUbound
DllStructSetData($tCodeBuffer, $i, "0x" & "68" & SwapEndian(0) & "68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][0]) & "68" & SwapEndian(368) & "68" & SwapEndian(GUICtrlGetHandle($hGIFControl)) & "B8" & SwapEndian($pSendMessageW) & "FFD0" & "68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][1]) & "B8" & SwapEndian($pSleep) & "FFD0" )
Next
DllStructSetData($tCodeBuffer, $iUbound + 1, "0x" & "E9" & SwapEndian(-($iUbound * 39 + 5)) & "C3" )
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
$pRemoteCode = DllCall("kernel32.dll", "ptr", "VirtualAlloc", "ptr", 0, "dword", DllStructGetSize($tCodeBuffer), "dword", 4096, "dword", 64)
$pRemoteCode = $pRemoteCode[0]
$aCall = DllCall("user32.dll", "hwnd", "GetDC", "hwnd", GUICtrlGetHandle($hGIFControl))
If @error Or Not $aCall[0] Then
Return SetError(6, 0, "")
EndIf
Local $hDC = $aCall[0]
For $i = 1 To $iUbound
DllStructSetData($tCodeBuffer, $i, "0x" & "68" & SwapEndian(3) & "68" & SwapEndian(0) & "68" & SwapEndian(0) & "68" & SwapEndian(0) & "68" & SwapEndian(0) & "68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][0]) & "68" & SwapEndian(0) & "68" & SwapEndian(0) & "68" & SwapEndian($hDC) & "B8" & SwapEndian($pDrawIconEx) & "FFD0" & "B8" & SwapEndian($i - 1) & "A3" & SwapEndian($pCurrentFrame) & "68" & SwapEndian($aArrayOfHandlesAndTimes[$i - 1][1]) & "B8" & SwapEndian($pSleep) & "FFD0" )
Next
DllStructSetData($tCodeBuffer, $iUbound + 1, "0x" & "E9" & SwapEndian(-($iUbound * 74 + 5)) & "C3" )
EndIf
DllCall("kernel32.dll", "none", "RtlMoveMemory", "ptr", $pRemoteCode, "ptr", DllStructGetPtr($tCodeBuffer), "dword", DllStructGetSize($tCodeBuffer))
$aCall = DllCall("kernel32.dll", "ptr", "CreateThread", "ptr", 0, "dword", 0, "ptr", $pRemoteCode, "ptr", 0, "dword", 0, "dword*", 0)
If @error Or Not $aCall[0] Then
Return SetError(7, 0, "")
EndIf
Local $hGIFThread = $aCall[0]
Return SetError(0, 0, $hGIFThread)
EndFunc
Func SwapEndian($iValue)
Return Hex(BinaryMid($iValue, 1, 4))
EndFunc
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
Local $tGdiplusStartupInput = DllStructCreate("dword GdiplusVersion;" & "ptr DebugEventCallback;" & "int SuppressBackgroundThread;" & "int SuppressExternalCodecs")
DllStructSetData($tGdiplusStartupInput, "GdiplusVersion", 1)
Local $a_iCall = DllCall("gdiplus.dll", "dword", "GdiplusStartup", "dword*", 0, "ptr", DllStructGetPtr($tGdiplusStartupInput), "ptr", 0)
If @error Or $a_iCall[0] Then
Return SetError(3, 0, "")
EndIf
Local $hGDIplus = $a_iCall[1]
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipLoadImageFromFile", "wstr", $sFile, "ptr*", 0)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(4, 0, "")
EndIf
Local $pBitmap = $a_iCall[2]
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetImageDimension", "ptr", $pBitmap, "float*", 0, "float*", 0)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(5, 0, "")
EndIf
Local $iWidth = $a_iCall[2]
Local $iHeight = $a_iCall[3]
GUICtrlSetPos($hGIF, $iLeft, $iTop, $iWidth, $iHeight)
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsCount", "ptr", $pBitmap, "dword*", 0)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(6, 0, "")
EndIf
Local $iFrameDimensionsCount = $a_iCall[2]
Local $tGUID = DllStructCreate("int;short;short;byte[8]")
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameDimensionsList", "ptr", $pBitmap, "ptr", DllStructGetPtr($tGUID), "dword", $iFrameDimensionsCount)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(7, 0, "")
EndIf
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageGetFrameCount", "ptr", $pBitmap, "ptr", DllStructGetPtr($tGUID), "dword*", 0)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(8, 0, "")
EndIf
Local $iFrameCount = $a_iCall[3]
Local $aHBitmaps[$iFrameCount][3]
Local $x = 1
For $i = 0 To $iFrameCount - 1
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipImageSelectActiveFrame", "ptr", $pBitmap, "ptr", DllStructGetPtr($tGUID), "dword", $i)
If @error Or $a_iCall[0] Then
$aHBitmaps[$i][0] = 0
ContinueLoop
EndIf
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipCreateHICONFromBitmap", "ptr", $pBitmap, "hwnd*", 0)
If @error Or $a_iCall[0] Then
$aHBitmaps[$i][0] = 0
ContinueLoop
EndIf
$aHBitmaps[$i][0] = $a_iCall[2]
If $x Then
GUICtrlSendMsg($hGIF, 368, $aHBitmaps[$i][0], 0)
$x = 0
EndIf
Next
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItemSize", "ptr", $pBitmap, "dword", 20736, "dword*", 0)
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(9, 0, "")
EndIf
Local $iPropertyItemSize = $a_iCall[3]
Local $tRawPropItem = DllStructCreate("byte[" & $iPropertyItemSize & "]")
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipGetPropertyItem", "ptr", $pBitmap, "dword", 20736, "dword", DllStructGetSize($tRawPropItem), "ptr", DllStructGetPtr($tRawPropItem))
If @error Or $a_iCall[0] Then
DllCall("gdiplus.dll", "dword", "GdipDisposeImage", "ptr", $pBitmap)
DllCall("gdiplus.dll", "none", "GdiplusShutdown", "dword*", $hGDIplus)
Return SetError(10, 0, "")
EndIf
Local $tPropItem = DllStructCreate("int Id;" & "dword Length;" & "ushort Type;" & "ptr Value", DllStructGetPtr($tRawPropItem))
Local $iSize = DllStructGetData($tPropItem, "Length") / 4
Local $tPropertyData = DllStructCreate("dword[" & $iSize & "]", DllStructGetData($tPropItem, "Value"))
For $i = 0 To $iFrameCount - 1
$aHBitmaps[$i][1] = DllStructGetData($tPropertyData, 1, $i + 1) * 10
$aHBitmaps[$i][2] = $aHBitmaps[$i][1]
If Not $aHBitmaps[$i][1] Then
$aHBitmaps[$i][1] = 130
EndIf
If $aHBitmaps[$i][1] < 50 Then
$aHBitmaps[$i][1] = 50
EndIf
Next
$iTransparency = 1
$a_iCall = DllCall("gdiplus.dll", "dword", "GdipBitmapGetPixel", "ptr", $pBitmap, "int", 0, "int", 0, "dword*", 0)
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
EndFunc
Global Const $BSY_SIZE = 14, $BSY_MAINWIN = 0, $BSY_PARWIN = 1, $BSY_GIFOBJ = 2, $BSY_STATUSTEXT = 3, $BSY_STATUSBAR = 4, $BSY_SCREENWIN = 5, $BSY_THEME_DIR = 6, $BSY_THEME_BGCOLOR = 7, $BSY_THEME_TEXT = 8, $BSY_THEME_BAR = 9, $BSY_THEME_BGBAR = 10, $BSY_THEME_SCREEN = 11, $BSY_THEME_GIF = 12, $BSY_THEME_CORNERS = 13
Global Const $BUSY_SCREEN = 0x1, $BUSY_PROGRESS = 0x2, $BUSY_FULLSCREEN = 0x4, $BUSY_TOPMOST = 0x8
Global $g_aBsy_Info[$BSY_SIZE], $g_aBsy_GIFs, $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_iBsy_Transparency, $g_tBsy_CurrentFrame
Func _Busy_Close()
If Not IsArray($g_aBsy_Info) Or UBound($g_aBsy_Info) <> $BSY_SIZE Then Return SetError(1, 0, -1)
GUIRegisterMsg(15, "")
_GUICtrlDeleteGIF($g_aBsy_Info[$BSY_GIFOBJ], $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_tBsy_CurrentFrame)
GUISetState(@SW_ENABLE, $g_aBsy_Info[$BSY_PARWIN])
GUISetState(@SW_UNLOCK, $g_aBsy_Info[$BSY_PARWIN])
GUIDelete($g_aBsy_Info[$BSY_MAINWIN])
If $g_aBsy_Info[$BSY_SCREENWIN] <> 0 Then GUIDelete($g_aBsy_Info[$BSY_SCREENWIN])
__Busy_Reset()
Return 0
EndFunc
Func _Busy_Create($sStatusText = "", $iOptions = -1, $iTrans = -1, $hGui = 0)
If Not IsArray($g_aBsy_Info) Or UBound($g_aBsy_Info) <> $BSY_SIZE Then Return SetError(1, 0, -1)
If Not FileExists($g_aBsy_Info[$BSY_THEME_DIR]) Then _Busy_UseTheme("")
Local $iGHeight = 85, $iGWidth = 150, $iHeight, $iWidth, $tRect, $tPoint
Local $bProgress = False, $bFullScreen = False, $bTopmost = False
If $iOptions < 0 Or IsKeyword($iOptions) Then $iOptions = 0
If $iTrans < 0 Or IsKeyword($iTrans) Then $iTrans = 225
If $iTrans > 255 Then $iTrans = 255
If $hGui = 0 Or IsKeyword($hGui) Then
$hGui = 0
Else
$tRect = _WinAPI_GetClientRect($hGui)
$tPoint = DllStructCreate("int X;int Y")
_WinAPI_ClientToScreen($hGui, $tPoint)
EndIf
$g_aBsy_Info[$BSY_PARWIN] = $hGui
If BitAND($iOptions, $BUSY_PROGRESS) = $BUSY_PROGRESS Then
$iGHeight += 10
$bProgress = True
EndIf
If BitAND($iOptions, $BUSY_FULLSCREEN) = $BUSY_FULLSCREEN Then $bFullScreen = True
If BitAND($iOptions, $BUSY_TOPMOST) = $BUSY_TOPMOST Then $bTopmost = True
If BitAND($iOptions, $BUSY_SCREEN) = $BUSY_SCREEN Then
If $bFullScreen Or $hGui = 0 Then
$g_aBsy_Info[$BSY_SCREENWIN] = GUICreate("", @DesktopWidth, @DesktopHeight, 0, 0, BitOR($WS_POPUP, $WS_DISABLED), $WS_EX_TOOLWINDOW)
Else
$g_aBsy_Info[$BSY_SCREENWIN] = GUICreate("", DllStructGetData($tRect, "Right"), DllStructGetData($tRect, "Bottom"), DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y"), BitOR($WS_POPUP, $WS_DISABLED), $WS_EX_TOOLWINDOW, $hGui)
EndIf
GUISetBkColor($g_aBsy_Info[$BSY_THEME_SCREEN], $g_aBsy_Info[$BSY_SCREENWIN])
WinSetTrans($g_aBsy_Info[$BSY_SCREENWIN], "", $iTrans)
If $bTopmost Then WinSetOnTop($g_aBsy_Info[$BSY_SCREENWIN], "", 1)
GUISetState(@SW_SHOW, $g_aBsy_Info[$BSY_SCREENWIN])
EndIf
If $bFullScreen Or $hGui = 0 Then
$g_aBsy_Info[$BSY_MAINWIN] = GUICreate("", $iGWidth, $iGHeight, -1, -1, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW)
Else
Local $iX =(DllStructGetData($tRect, "Right") - $iGWidth) / 2 + DllStructGetData($tPoint, "X")
Local $iY =(DllStructGetData($tRect, "Bottom") - $iGHeight) / 2 + DllStructGetData($tPoint, "Y")
$g_aBsy_Info[$BSY_MAINWIN] = GUICreate("", $iGWidth, $iGHeight, $iX, $iY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW, $hGui)
GUISetState(@SW_LOCK, $hGui)
GUISetState(@SW_DISABLE, $hGui)
EndIf
If $bTopmost Then WinSetOnTop($g_aBsy_Info[$BSY_MAINWIN], "", 1)
GUISetBkColor($g_aBsy_Info[$BSY_THEME_BGCOLOR], $g_aBsy_Info[$BSY_MAINWIN])
If $g_aBsy_Info[$BSY_THEME_CORNERS] = True Then
GUISetStyle($WS_POPUP, BitOR($WS_EX_TOOLWINDOW, $WS_EX_LAYERED), $g_aBsy_Info[$BSY_MAINWIN])
GUICtrlCreatePic($g_aBsy_Info[$BSY_THEME_DIR] & "\tr.bmp", $iGWidth - 5, 0, 5, 5)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlCreatePic($g_aBsy_Info[$BSY_THEME_DIR] & "\br.bmp", $iGWidth - 5, $iGHeight - 5, 5, 5)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlCreatePic($g_aBsy_Info[$BSY_THEME_DIR] & "\bl.bmp", 0, $iGHeight - 5, 5, 5)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlCreatePic($g_aBsy_Info[$BSY_THEME_DIR] & "\tl.bmp", 0, 0, 5, 5)
GUICtrlSetState(-1, $GUI_DISABLE)
EndIf
__GetGifPixSize($g_aBsy_Info[$BSY_THEME_GIF], $iHeight, $iWidth)
$g_aBsy_Info[$BSY_GIFOBJ] = _GUICtrlCreateGIF($g_aBsy_Info[$BSY_THEME_GIF], Int(($iGWidth - $iWidth) / 2), 10, $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_iBsy_Transparency, $g_tBsy_CurrentFrame)
GUIRegisterMsg(15, "__Busy_Refresh")
If $bProgress Then
GUICtrlCreateLabel("", 15, $iHeight + 18, 120, 2)
GUICtrlSetBkColor(-1, $g_aBsy_Info[$BSY_THEME_BGBAR])
$g_aBsy_Info[$BSY_STATUSBAR] = GUICtrlCreateLabel("", 15, $iHeight + 18, 120, 2)
GUICtrlSetBkColor(-1, $g_aBsy_Info[$BSY_THEME_BAR])
GUICtrlSetState(-1, $GUI_HIDE)
$g_aBsy_Info[$BSY_STATUSTEXT] = GUICtrlCreateLabel($sStatusText, 5, $iHeight + 25, $iGWidth - 10, 15, BitOR(0x50000000, $SS_CENTER))
GUICtrlSetColor(-1, $g_aBsy_Info[$BSY_THEME_TEXT])
GUICtrlSetFont(-1, -1, -1, -1, "Arial")
Else
$g_aBsy_Info[$BSY_STATUSTEXT] = GUICtrlCreateLabel($sStatusText, 5, $iHeight + 15, $iGWidth - 10, 15, BitOR(0x50000000, $SS_CENTER))
GUICtrlSetColor(-1, $g_aBsy_Info[$BSY_THEME_TEXT])
GUICtrlSetFont(-1, -1, -1, -1, "Arial")
EndIf
GUISetState(@SW_SHOW, $g_aBsy_Info[$BSY_MAINWIN])
Return 0
EndFunc
Func _Busy_Update($sStatusText = "", $iStatusPercent = -1)
If Not IsArray($g_aBsy_Info) Or UBound($g_aBsy_Info) <> $BSY_SIZE Then Return SetError(1, 0, -1)
If $sStatusText <> GUICtrlRead($g_aBsy_Info[$BSY_STATUSTEXT]) Then GUICtrlSetData($g_aBsy_Info[$BSY_STATUSTEXT], $sStatusText)
If $iStatusPercent > -1 Then
If $iStatusPercent > 100 Then $iStatusPercent = 100
If $iStatusPercent = 0 Then
GUICtrlSetState($g_aBsy_Info[$BSY_STATUSBAR], $GUI_HIDE)
Else
GUICtrlSetPos($g_aBsy_Info[$BSY_STATUSBAR], 15, 66, 120 * $iStatusPercent / 100)
If BitAND(GUICtrlGetState($g_aBsy_Info[$BSY_STATUSBAR]), $GUI_HIDE) = $GUI_HIDE Then GUICtrlSetState($g_aBsy_Info[$BSY_STATUSBAR], $GUI_SHOW)
EndIf
EndIf
Return 0
EndFunc
Func _Busy_UseTheme($sThemeName)
If Not IsArray($g_aBsy_Info) Or UBound($g_aBsy_Info) <> $BSY_SIZE Then Return SetError(1, 0, -1)
Local $sDir, $sSettingsFile, $sTemp
$sDir = @TempDir & "\" & $sAppName & "\" & $sThemeName
If Not FileExists($sDir) Then Return SetError(2, 0, -1)
$sSettingsFile = $sDir & "\settings.ini"
If Not FileExists($sSettingsFile) Then Return SetError(3, 0, -1)
$g_aBsy_Info[$BSY_THEME_DIR] = $sDir
$g_aBsy_Info[$BSY_THEME_BGCOLOR] = __ValidateThemeEntry(IniRead($sSettingsFile, "colors", "background", -1))
If @error Then $g_aBsy_Info[$BSY_THEME_BGCOLOR] = 0x000000
$g_aBsy_Info[$BSY_THEME_TEXT] = __ValidateThemeEntry(IniRead($sSettingsFile, "colors", "text", -1))
If @error Then $g_aBsy_Info[$BSY_THEME_TEXT] = 0xFFFFFF
$g_aBsy_Info[$BSY_THEME_BAR] = __ValidateThemeEntry(IniRead($sSettingsFile, "colors", "bar", -1))
If @error Then $g_aBsy_Info[$BSY_THEME_BAR] = 0xFFFFFF
$g_aBsy_Info[$BSY_THEME_BGBAR] = __ValidateThemeEntry(IniRead($sSettingsFile, "colors", "bar background", -1))
If @error Then $g_aBsy_Info[$BSY_THEME_BGBAR] = 0x000000
$g_aBsy_Info[$BSY_THEME_SCREEN] = __ValidateThemeEntry(IniRead($sSettingsFile, "colors", "screen", -1))
If @error Then $g_aBsy_Info[$BSY_THEME_SCREEN] = 0xFFFFFF
$g_aBsy_Info[$BSY_THEME_CORNERS] = IniRead($sSettingsFile, "theme", "corners", False)
If $g_aBsy_Info[$BSY_THEME_CORNERS] = "true" Then
$g_aBsy_Info[$BSY_THEME_CORNERS] = True
Else
$g_aBsy_Info[$BSY_THEME_CORNERS] = False
EndIf
$g_aBsy_Info[$BSY_THEME_GIF] = $sDir & "\loader.gif"
__Busy_Reset()
EndFunc
Func __ValidateThemeEntry($sEntry)
If $sEntry = -1 Then Return SetError(1, 0, -1)
Local $aResult = StringRegExp($sEntry, "(?i)([a-f0-9]{6})", 3)
If Not @error Then Return "0x" & $aResult[0]
Return SetError(2, 0, -1)
EndFunc
Func __Busy_Reset()
$g_aBsy_Info[$BSY_MAINWIN] = 0
$g_aBsy_Info[$BSY_STATUSTEXT] = 0
$g_aBsy_Info[$BSY_STATUSBAR] = 0
$g_aBsy_Info[$BSY_SCREENWIN] = 0
$g_aBsy_Info[$BSY_GIFOBJ] = 0
EndFunc
Func __GetGifPixSize($s_gif, ByRef $pwidth, ByRef $pheight)
If FileGetSize($s_gif) > 9 Then
Local $sizes = FileRead($s_gif, 10)
$pwidth = Asc(StringMid($sizes, 8, 1)) * 256 + Asc(StringMid($sizes, 7, 1))
$pheight = Asc(StringMid($sizes, 10, 1)) * 256 + Asc(StringMid($sizes, 9, 1))
EndIf
EndFunc
Func __Busy_Refresh($hWnd, $iMsg, $wParam, $lParam)
#forceref $hWnd, $iMsg, $wParam, $lParam
_RefreshGIF($g_aBsy_Info[$BSY_GIFOBJ], $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_iBsy_Transparency, $g_tBsy_CurrentFrame)
EndFunc
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
EndFunc
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
EndFunc
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
EndFunc
Global Const $PROV_RSA_AES = 24
Global Const $CRYPT_VERIFYCONTEXT = 0xF0000000
Global Const $HP_HASHSIZE = 0x0004
Global Const $HP_HASHVAL = 0x0002
Global Const $CRYPT_USERDATA = 1
Global Const $CALG_MD5 = 0x00008003
Global $__g_aCryptInternalData[3]
Func _Crypt_Startup()
If __Crypt_RefCount() = 0 Then
Local $hAdvapi32 = DllOpen("Advapi32.dll")
If $hAdvapi32 = -1 Then Return SetError(1, 0, False)
__Crypt_DllHandleSet($hAdvapi32)
Local $iProviderID = $PROV_RSA_AES
Local $aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptAcquireContext", "handle*", 0, "ptr", 0, "ptr", 0, "dword", $iProviderID, "dword", $CRYPT_VERIFYCONTEXT)
If @error Or Not $aRet[0] Then
Local $iError = @error + 10, $iExtended = @extended
DllClose(__Crypt_DllHandle())
Return SetError($iError, $iExtended, False)
Else
__Crypt_ContextSet($aRet[1])
EndIf
EndIf
__Crypt_RefCountInc()
Return True
EndFunc
Func _Crypt_Shutdown()
__Crypt_RefCountDec()
If __Crypt_RefCount() = 0 Then
DllCall(__Crypt_DllHandle(), "bool", "CryptReleaseContext", "handle", __Crypt_Context(), "dword", 0)
DllClose(__Crypt_DllHandle())
EndIf
EndFunc
Func _Crypt_HashData($vData, $iALG_ID, $bFinal = True, $hCryptHash = 0)
Local $aRet = 0, $hBuff = 0, $iError = 0, $iExtended = 0, $iHashSize = 0, $vReturn = 0
_Crypt_Startup()
Do
If $hCryptHash = 0 Then
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptCreateHash", "handle", __Crypt_Context(), "uint", $iALG_ID, "ptr", 0, "dword", 0, "handle*", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 10
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$hCryptHash = $aRet[5]
EndIf
$hBuff = DllStructCreate("byte[" & BinaryLen($vData) & "]")
DllStructSetData($hBuff, 1, $vData)
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptHashData", "handle", $hCryptHash, "struct*", $hBuff, "dword", DllStructGetSize($hBuff), "dword", $CRYPT_USERDATA)
If @error Or Not $aRet[0] Then
$iError = @error + 20
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
If $bFinal Then
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptGetHashParam", "handle", $hCryptHash, "dword", $HP_HASHSIZE, "dword*", 0, "dword*", 4, "dword", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 30
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$iHashSize = $aRet[3]
$hBuff = DllStructCreate("byte[" & $iHashSize & "]")
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptGetHashParam", "handle", $hCryptHash, "dword", $HP_HASHVAL, "struct*", $hBuff, "dword*", DllStructGetSize($hBuff), "dword", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 40
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$vReturn = DllStructGetData($hBuff, 1)
Else
$vReturn = $hCryptHash
EndIf
Until True
If $hCryptHash <> 0 And $bFinal Then DllCall(__Crypt_DllHandle(), "bool", "CryptDestroyHash", "handle", $hCryptHash)
_Crypt_Shutdown()
Return SetError($iError, $iExtended, $vReturn)
EndFunc
Func __Crypt_RefCount()
Return $__g_aCryptInternalData[0]
EndFunc
Func __Crypt_RefCountInc()
$__g_aCryptInternalData[0] += 1
EndFunc
Func __Crypt_RefCountDec()
If $__g_aCryptInternalData[0] > 0 Then $__g_aCryptInternalData[0] -= 1
EndFunc
Func __Crypt_DllHandle()
Return $__g_aCryptInternalData[1]
EndFunc
Func __Crypt_DllHandleSet($hAdvapi32)
$__g_aCryptInternalData[1] = $hAdvapi32
EndFunc
Func __Crypt_Context()
Return $__g_aCryptInternalData[2]
EndFunc
Func __Crypt_ContextSet($hCryptContext)
$__g_aCryptInternalData[2] = $hCryptContext
EndFunc
Global Const $ES_READONLY = 2048
Global Const $EN_CHANGE = 0x300
Global Const $GUI_SS_DEFAULT_INPUT = 0x00000080
Func _Singleton($sOccurenceName, $iFlag = 0)
Local Const $ERROR_ALREADY_EXISTS = 183
Local Const $SECURITY_DESCRIPTOR_REVISION = 1
Local $tSecurityAttributes = 0
If BitAND($iFlag, 2) Then
Local $tSecurityDescriptor = DllStructCreate("byte;byte;word;ptr[4]")
Local $aRet = DllCall("advapi32.dll", "bool", "InitializeSecurityDescriptor", "struct*", $tSecurityDescriptor, "dword", $SECURITY_DESCRIPTOR_REVISION)
If @error Then Return SetError(@error, @extended, 0)
If $aRet[0] Then
$aRet = DllCall("advapi32.dll", "bool", "SetSecurityDescriptorDacl", "struct*", $tSecurityDescriptor, "bool", 1, "ptr", 0, "bool", 0)
If @error Then Return SetError(@error, @extended, 0)
If $aRet[0] Then
$tSecurityAttributes = DllStructCreate($tagSECURITY_ATTRIBUTES)
DllStructSetData($tSecurityAttributes, 1, DllStructGetSize($tSecurityAttributes))
DllStructSetData($tSecurityAttributes, 2, DllStructGetPtr($tSecurityDescriptor))
DllStructSetData($tSecurityAttributes, 3, 0)
EndIf
EndIf
EndIf
Local $aHandle = DllCall("kernel32.dll", "handle", "CreateMutexW", "struct*", $tSecurityAttributes, "bool", 1, "wstr", $sOccurenceName)
If @error Then Return SetError(@error, @extended, 0)
Local $aLastError = DllCall("kernel32.dll", "dword", "GetLastError")
If @error Then Return SetError(@error, @extended, 0)
If $aLastError[0] = $ERROR_ALREADY_EXISTS Then
If BitAND($iFlag, 1) Then
DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aHandle[0])
If @error Then Return SetError(@error, @extended, 0)
Return SetError($aLastError[0], $aLastError[0], 0)
Else
Exit -1
EndIf
EndIf
Return $aHandle[0]
EndFunc
Global Const $sAppName = "Huawei Unlocker"
Global Const $sAppVersion = "1.0"
Global Const $sAppPublisher = "Kyaw Swar Thwin"
Global Const $DBT_DEVNODES_CHANGED = 0x0007
Global $sTitle = $sAppName
Global $sDeviceState, $sManufacturer, $sModelNumber, $sDeviceID, $bRootAccess
_Singleton($sAppName & " v" & $sAppVersion)
OnAutoItExitRegister("_OnExit")
DirRemove(@TempDir & "\" & $sAppName, 1)
DirCreate(@TempDir & "\" & $sAppName)
FileInstall("res\banner.bmp", @TempDir & "\" & $sAppName & "\banner.bmp")
FileInstall("res\bg.bmp", @TempDir & "\" & $sAppName & "\bg.bmp")
FileInstall("res\bl.bmp", @TempDir & "\" & $sAppName & "\bl.bmp")
FileInstall("res\br.bmp", @TempDir & "\" & $sAppName & "\br.bmp")
FileInstall("res\loader.gif", @TempDir & "\" & $sAppName & "\loader.gif")
FileInstall("res\settings.ini", @TempDir & "\" & $sAppName & "\settings.ini")
FileInstall("res\tl.bmp", @TempDir & "\" & $sAppName & "\tl.bmp")
FileInstall("res\tr.bmp", @TempDir & "\" & $sAppName & "\tr.bmp")
$hGUI = GUICreate($sTitle, 400, 340, -1, -1)
$idFileMenu = GUICtrlCreateMenu("&File")
$idFileExitMenu = GUICtrlCreateMenuItem("E&xit", $idFileMenu)
$idToolsMenu = GUICtrlCreateMenu("&Tools")
$idToolsNetworkMenu = GUICtrlCreateMenu("Network", $idToolsMenu)
$idToolsNetworkUnlockMenu = GUICtrlCreateMenuItem("Unlock", $idToolsNetworkMenu)
$idToolsNetworkRelockMenu = GUICtrlCreateMenuItem("Relock", $idToolsNetworkMenu)
$idToolsBootloaderMenu = GUICtrlCreateMenu("Bootloader", $idToolsMenu)
$idToolsBootloaderRequestKeyMenu = GUICtrlCreateMenuItem("Request Key", $idToolsBootloaderMenu)
GUICtrlCreateMenuItem("", $idToolsBootloaderMenu)
$idToolsBootloaderUnlockMenu = GUICtrlCreateMenuItem("Unlock", $idToolsBootloaderMenu)
$idToolsBootloaderRelockMenu = GUICtrlCreateMenuItem("Relock", $idToolsBootloaderMenu)
$idHelpMenu = GUICtrlCreateMenu("&Help")
$idHelpAboutMenu = GUICtrlCreateMenuItem("&About " & $sAppName & "...", $idHelpMenu)
$idBannerPic = GUICtrlCreatePic(@TempDir & "\" & $sAppName & "\banner.bmp", 0, 0, 400, 160)
$idProductModelLabel = GUICtrlCreateLabel("Product Model:", 10, 180, 76, 17)
$idProductModelInput = GUICtrlCreateInput("", 10, 195, 380, 21)
$idProductIMEIMEIDLabel = GUICtrlCreateLabel("Product IMEI/MEID:", 10, 220, 101, 17)
$idProductIMEIMEIDInput = GUICtrlCreateInput("", 10, 235, 380, 21)
$idProductIDLabel = GUICtrlCreateLabel("Product ID:", 10, 260, 58, 17)
$idProductIDInput = GUICtrlCreateInput("", 10, 275, 380, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_READONLY))
GUIRegisterMsg($WM_DEVICECHANGE, "_WM_DEVICECHANGE")
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
GUISetState()
_GetDeviceInfo()
While 1
$iMsg = GUIGetMsg()
Switch $iMsg
Case $GUI_EVENT_CLOSE, $idFileExitMenu
Exit
Case $idToolsNetworkUnlockMenu
If $sDeviceState <> "Online" Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Found.", Default, $hGUI)
Else
Switch $sManufacturer
Case "Huawei"
If Not _Android_FileExists("/dev/block/mmcblk0p5") Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
If Not $bRootAccess Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Root Access Is Required.", Default, $hGUI)
Else
_Busy_Create("Checking...", $BUSY_SCREEN, 200, $hGUI)
_Android_Shell("mkdir /data/local/tmp", True)
_Android_Shell("rm -r /data/local/tmp/*", True)
_Android_Shell("cat /dev/block/mmcblk0p5 > /data/local/tmp/mmcblk0p5.img", True)
_Android_Pull("/data/local/tmp/mmcblk0p5.img", @TempDir & "\" & $sAppName & "\mmcblk0p5.img")
$iOffset = _Hex_Search(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", Binary("0x010010"))
If $iOffset = -1 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
$dData1 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3)
$dData2 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3 + 16 + 3)
$dData3 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3 + 16 + 3 + 16 + 3)
If $dData2 <> $dData3 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
If $dData1 = $dData2 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "Network Is Already Unlocked.", Default, $hGUI)
Else
_Busy_Update("Unlocking...")
_Hex_Write(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", $dData2, $iOffset + 3)
_Android_Push(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", "/data/local/tmp")
_Android_Shell("cat /data/local/tmp/mmcblk0p5.img > /dev/block/mmcblk0p5", True)
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Update("Rebooting...")
_Android_Reboot()
_Busy_Close()
EndIf
EndIf
EndIf
EndIf
EndIf
Case Else
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
EndSwitch
EndIf
Case $idToolsNetworkRelockMenu
If $sDeviceState <> "Online" Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Found.", Default, $hGUI)
Else
Switch $sManufacturer
Case "Huawei"
If Not _Android_FileExists("/dev/block/mmcblk0p5") Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
If Not $bRootAccess Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Root Access Is Required.", Default, $hGUI)
Else
_Busy_Create("Checking...", $BUSY_SCREEN, 200, $hGUI)
_Android_Shell("mkdir /data/local/tmp", True)
_Android_Shell("rm -r /data/local/tmp/*", True)
_Android_Shell("cat /dev/block/mmcblk0p5 > /data/local/tmp/mmcblk0p5.img", True)
_Android_Pull("/data/local/tmp/mmcblk0p5.img", @TempDir & "\" & $sAppName & "\mmcblk0p5.img")
$iOffset = _Hex_Search(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", Binary("0x010010"))
If $iOffset = -1 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
$dData1 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3)
$dData2 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3 + 16 + 3)
$dData3 = _Hex_Read(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", 16, $iOffset + 3 + 16 + 3 + 16 + 3)
If $dData2 <> $dData3 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
Else
If $dData1 <> $dData2 Then
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Close()
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "Network Is Already Relocked.", Default, $hGUI)
Else
_Busy_Update("Relocking...")
_Hex_Write(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", Binary("0x00000000000000000000000000000000"), $iOffset + 3)
_Android_Push(@TempDir & "\" & $sAppName & "\mmcblk0p5.img", "/data/local/tmp")
_Android_Shell("cat /data/local/tmp/mmcblk0p5.img > /dev/block/mmcblk0p5", True)
FileDelete(@TempDir & "\" & $sAppName & "\*.img")
_Android_Shell("rm -r /data/local/tmp/*", True)
_Busy_Update("Rebooting...")
_Android_Reboot()
_Busy_Close()
EndIf
EndIf
EndIf
EndIf
EndIf
Case Else
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Supported.", Default, $hGUI)
EndSwitch
EndIf
Case $idToolsBootloaderRequestKeyMenu
__Run("start http://www.emui.com/plugin.php?id=unlock&mod=detail")
Case $idToolsBootloaderUnlockMenu
If $sDeviceState <> "Online" And $sDeviceState <> "Bootloader" Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Found.", Default, $hGUI)
Else
If $sDeviceState <> "Bootloader" Then
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "This Function Only Works In Bootloader Mode.", Default, $hGUI)
Else
While 1
$sKey = InputBox($sTitle, "Key:", Default, Default, 305, 130, Default, Default, Default, $hGUI)
If @error = 1 Or $sKey <> "" Then
ExitLoop
Else
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "Key Should Not Be Empty.", Default, $hGUI)
EndIf
WEnd
If Not @error Then
_Busy_Create("Unlocking...", $BUSY_SCREEN, 200, $hGUI)
__Run("fastboot oem unlock " & $sKey)
_Busy_Close()
EndIf
EndIf
EndIf
Case $idToolsBootloaderRelockMenu
If $sDeviceState <> "Online" And $sDeviceState <> "Bootloader" Then
MsgBox(BitOR($MB_ICONERROR, $MB_APPLMODAL), "Error", "Device Is Not Found.", Default, $hGUI)
Else
If $sDeviceState <> "Bootloader" Then
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "This Function Only Works In Bootloader Mode.", Default, $hGUI)
Else
While 1
$sKey = InputBox($sTitle, "Key:", Default, Default, 305, 130, Default, Default, Default, $hGUI)
If @error = 1 Or $sKey <> "" Then
ExitLoop
Else
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), $sTitle, "Key Should Not Be Empty.", Default, $hGUI)
EndIf
WEnd
If Not @error Then
_Busy_Create("Relocking...", $BUSY_SCREEN, 200, $hGUI)
__Run("fastboot oem relock " & $sKey)
_Busy_Close()
EndIf
EndIf
EndIf
Case $idHelpAboutMenu
MsgBox(BitOR($MB_ICONINFORMATION, $MB_APPLMODAL), "About", $sAppName & @CRLF & @CRLF & "Version: " & $sAppVersion & @CRLF & "Developed By: " & $sAppPublisher, Default, $hGUI)
EndSwitch
WEnd
Func _WM_DEVICECHANGE($hWnd, $iMsg, $iwParam, $ilParam)
#forceref $hWnd, $iMsg, $ilParam
Switch $iwParam
Case $DBT_DEVNODES_CHANGED
_GetDeviceInfo()
EndSwitch
Return $GUI_RUNDEFMSG
EndFunc
Func _WM_COMMAND($hWnd, $iMsg, $iwParam, $ilParam)
#forceref $hWnd, $iMsg, $ilParam
Switch _WinAPI_LoWord($iwParam)
Case $idProductModelInput, $idProductIMEIMEIDInput
Switch _WinAPI_HiWord($iwParam)
Case $EN_CHANGE
GUICtrlSetData($idProductIDInput, _GenerateProductID(GUICtrlRead($idProductModelInput), GUICtrlRead($idProductIMEIMEIDInput)))
EndSwitch
EndSwitch
EndFunc
Func _GetDeviceInfo()
Local $sNewDeviceState, $sOldDeviceState
$sNewDeviceState = _Android_GetState()
If $sDeviceState <> $sNewDeviceState Then
$sModelNumber = ""
$sDeviceID = ""
$sOldDeviceState = $sDeviceState
$sDeviceState = $sNewDeviceState
Switch $sDeviceState
Case "Online"
$sManufacturer = _Android_GetProperty("ro.product.manufacturer")
$sModelNumber = _Android_GetProperty("ro.product.model")
$sDeviceID = _Android_GetDeviceID()
$bRootAccess = _Android_IsRooted()
Case "Offline"
_Connect()
Case "Bootloader"
Case Else
If $sOldDeviceState = "" Then _Connect()
EndSwitch
GUICtrlSetData($idProductModelInput, $sModelNumber)
GUICtrlSetData($idProductIMEIMEIDInput, $sDeviceID)
EndIf
EndFunc
Func _Connect()
_Busy_Create("Connecting...", $BUSY_SCREEN, 200, $hGUI)
_Android_Connect()
_Busy_Close()
EndFunc
Func _GenerateProductID($sModelNumber, $sDeviceID)
_Crypt_Startup()
Local $sMD5, $aChar, $aProductID[8] = [0, 0, 0, 0, 0, 0, 0, 0]
$sMD5 = StringMid(_Crypt_HashData($sModelNumber & $sDeviceID, $CALG_MD5), 3)
$aChar = StringSplit(__Hex(BitXOR(Dec(StringLeft($sMD5, 8)), Dec(StringRight($sMD5, 8)))), "")
For $i = 1 To $aChar[0]
If StringInStr("ABCDEF", $aChar[$i]) Then
$aProductID[$i - 1] = Chr(Asc($aChar[$i]) - 17)
Else
$aProductID[$i - 1] = $aChar[$i]
EndIf
Next
_Crypt_Shutdown()
Return _ArrayToString($aProductID, "")
EndFunc
Func _OnExit()
DirRemove(@TempDir & "\" & $sAppName, 1)
EndFunc
Func __Hex($iDec)
Local $sHex = Hex($iDec)
While StringLeft($sHex, 1) = "0"
$sHex = StringMid($sHex, 2)
If StringLeft($sHex, 1) <> "0" Then ExitLoop
WEnd
Return $sHex
EndFunc
