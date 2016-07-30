#cs ----------------------------------------------------------------------------

	File:           Busy.au3
	AutoIt Version: 3.3.0.0
	Author:         zorphnog (Michael Mims)

	Script Function:
	Provides a status window with text, progress bar, and gif animation

#ce ----------------------------------------------------------------------------

#include-once
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <File.au3>
#include <WinApi.au3>
#include "GIFAnimation.au3"

Global Const _
	$BSY_SIZE          = 14, _
	$BSY_MAINWIN       = 0, _
	$BSY_PARWIN        = 1, _
	$BSY_GIFOBJ        = 2, _
	$BSY_STATUSTEXT    = 3, _
	$BSY_STATUSBAR     = 4, _
	$BSY_SCREENWIN     = 5, _
	$BSY_THEME_DIR     = 6, _
	$BSY_THEME_BGCOLOR = 7, _
	$BSY_THEME_TEXT    = 8, _
	$BSY_THEME_BAR     = 9, _
	$BSY_THEME_BGBAR   = 10, _
	$BSY_THEME_SCREEN  = 11, _
	$BSY_THEME_GIF     = 12, _
	$BSY_THEME_CORNERS = 13
Global Const _
	$BUSY_SCREEN     = 0x1, _
	$BUSY_PROGRESS   = 0x2, _
	$BUSY_FULLSCREEN = 0x4, _
	$BUSY_TOPMOST    = 0x8
Global $g_aBsy_Info[$BSY_SIZE], $g_aBsy_GIFs, $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_iBsy_Transparency, $g_tBsy_CurrentFrame

; #FUNCTION# ====================================================================================================================
; Name...........: _Busy_Close
; Description ...: Closes the busy status window.
; Syntax.........: _Busy_Close()
; Parameters ....: None
; Return values .: Success - Returns a 0
;                  Failure - Returns a -1
;                  @Error  - 0 = No error
;                  |1 = Invalid busy array
; Author ........: zorphnog
; Remarks .......: None
; ===============================================================================================================================
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
EndFunc   ;==>_Busy_Close

; #FUNCTION# ====================================================================================================================
; Name...........: _Busy_Create
; Description ...: Creates and displays a busy status window.
; Syntax.........: _Busy_Create([$sStatus [, $iOptions [, $iTrans [, $hGui]]]])
; Parameters ....: $sStatusText - Status text for the busy window
;                  $iOptions    - Busy window options
;                                 |$BUSY_PROGRESS   = Creates a progress bar in the busy window
;                                 |$BUSY_SCREEN     = Create a transparent screen behind the busy window
;                                 |$BUSY_FULLSCREEN = Center the busy window in the monitor instead of the parent gui (Default if $hGui is not specified)
;                                 |$BUSY_TOPMOST    = Give the busy window the $WS_EX_TOPMOST attribute
;                  $iTrans      - The transparency number in the range 0 - 255
;                  $hGui        - Handle to a parent GUI
; Return values .: Success - Returns a 0
;                  Failure - Returns a -1
;                  @Error  - 0 = No error.
;                  |1 = Invalid busy array
; Author ........: zorphnog
; Remarks .......:
; ===============================================================================================================================
Func _Busy_Create($sStatusText = "", $iOptions = -1, $iTrans = -1, $hGui = 0)
	If Not IsArray($g_aBsy_Info) Or UBound($g_aBsy_Info) <> $BSY_SIZE Then Return SetError(1, 0, -1)
	If Not FileExists($g_aBsy_Info[$BSY_THEME_DIR]) Then _Busy_UseTheme("")
	Local $iGHeight = 85, $iGWidth = 150, $iHeight, $iWidth, $tRect, $tPoint
	Local $bProgress = False, $bFullScreen = False, $bTopmost = False

	; Set options
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

	; Create screen window
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

	; Create busy window
	If $bFullScreen Or $hGui = 0 Then
		$g_aBsy_Info[$BSY_MAINWIN] = GUICreate("", $iGWidth, $iGHeight, -1, -1, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW)
	Else
		Local $iX = (DllStructGetData($tRect, "Right") - $iGWidth) / 2 + DllStructGetData($tPoint, "X")
		Local $iY = (DllStructGetData($tRect, "Bottom") - $iGHeight) / 2 + DllStructGetData($tPoint, "Y")
		$g_aBsy_Info[$BSY_MAINWIN] = GUICreate("", $iGWidth, $iGHeight, $iX, $iY, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW, $hGui)
		GUISetState(@SW_LOCK, $hGui)
		GUISetState(@SW_DISABLE, $hGui)
	EndIf
	If $bTopmost Then WinSetOnTop($g_aBsy_Info[$BSY_MAINWIN], "", 1)
	GUISetBkColor($g_aBsy_Info[$BSY_THEME_BGCOLOR], $g_aBsy_Info[$BSY_MAINWIN])

	; Add corner images
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
	GUIRegisterMsg(15, "__Busy_Refresh"); WM_PAINT

	; Add progress controls
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
EndFunc   ;==>_Busy_Create

; #FUNCTION# ====================================================================================================================
; Name...........: _Busy_Update
; Description ...: Update the status text or progress of the busy window
; Syntax.........: _Busy_Update($sStatusText, $iStatusPercent)
; Parameters ....: $sStatusText    - The status text for the busy window
;                  $iStatusPercent - A percent number for the progress bar in the range 0 - 100
; Return values .: Success - Returns a 0
;                  Failure - Returns a -1
;                  @Error  - 0 = No error.
;                  |1 = Invalid busy array
; Author ........: zorphnog
; Remarks .......:
; ===============================================================================================================================
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
EndFunc   ;==>_Busy_Update

; #FUNCTION# ====================================================================================================================
; Name...........: _Busy_UseTheme
; Description ...: Use a custom theme for the busy window
; Syntax.........: _Busy_UseTheme($sThemeName)
; Parameters ....: $sThemeName - The name of the theme to use
; Return values .: Success - Returns a 0
;                  Failure - Returns a -1
;                  @Error  - 0 = No error.
;                  |1 = Invalid busy array
;                  |2 = Theme directory does not exist
;                  |3 = Settings file does not exist
; Author ........: zorphnog
; Remarks .......: Themes must be created in a folder named after theme located in the Busy folder of the script directory. Each
;                  theme must contain a settings.ini file with color hex values for the background, text, and progress bar. The
;                  animated gif must be named loader.gif. Each theme can also contain four images for the corners of the busy
;                  window. See default theme for an example.
; ===============================================================================================================================
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
EndFunc   ;==>_Busy_UseTheme

#Region internal functions

Func __ValidateThemeEntry($sEntry)
	If $sEntry = -1 Then Return SetError(1, 0, -1)
	Local $aResult = StringRegExp($sEntry, "(?i)([a-f0-9]{6})", 3)
	If Not @error Then Return "0x" & $aResult[0]
	Return SetError(2, 0, -1)
EndFunc  ;==__ValidateThemeEntry

Func __Busy_Reset()
	$g_aBsy_Info[$BSY_MAINWIN]    = 0
	$g_aBsy_Info[$BSY_STATUSTEXT] = 0
	$g_aBsy_Info[$BSY_STATUSBAR]  = 0
	$g_aBsy_Info[$BSY_SCREENWIN]  = 0
	$g_aBsy_Info[$BSY_GIFOBJ]     = 0
EndFunc   ;==>__Busy_Reset

Func __GetGifPixSize($s_gif, ByRef $pwidth, ByRef $pheight)
	If FileGetSize($s_gif) > 9 Then
		Local $sizes = FileRead($s_gif, 10)
		$pwidth = Asc(StringMid($sizes, 8, 1)) * 256 + Asc(StringMid($sizes, 7, 1))
		$pheight = Asc(StringMid($sizes, 10, 1)) * 256 + Asc(StringMid($sizes, 9, 1))
	EndIf
EndFunc   ;==>__GetGifPixSize

Func __Busy_Refresh($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	_RefreshGIF($g_aBsy_Info[$BSY_GIFOBJ], $g_aBsy_GIFs, $g_hBsy_GIFThread, $g_iBsy_Transparency, $g_tBsy_CurrentFrame)
EndFunc  ;==>_Refresh
#EndRegion internal functions