#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icon.ico
#AutoIt3Wrapper_Outfile=Release\Huawei Unlocker.exe
#AutoIt3Wrapper_Res_Description=Huawei Unlocker
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2014 Kyaw Swar Thwin
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "Include\Android.au3"
#include "Include\Busy.au3"
#include "Include\Hex.au3"
#include <Array.au3>
#include <Crypt.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <WinAPI.au3>

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
EndFunc   ;==>_WM_DEVICECHANGE

Func _WM_COMMAND($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $ilParam
	Switch _WinAPI_LoWord($iwParam)
		Case $idProductModelInput, $idProductIMEIMEIDInput
			Switch _WinAPI_HiWord($iwParam)
				Case $EN_CHANGE
					GUICtrlSetData($idProductIDInput, _GenerateProductID(GUICtrlRead($idProductModelInput), GUICtrlRead($idProductIMEIMEIDInput)))
			EndSwitch
	EndSwitch
EndFunc   ;==>_WM_COMMAND

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
EndFunc   ;==>_GetDeviceInfo

Func _Connect()
	_Busy_Create("Connecting...", $BUSY_SCREEN, 200, $hGUI)
	_Android_Connect()
	_Busy_Close()
EndFunc   ;==>_Connect

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
EndFunc   ;==>_GenerateProductID

Func _OnExit()
	DirRemove(@TempDir & "\" & $sAppName, 1)
EndFunc   ;==>_OnExit

Func __Hex($iDec)
	Local $sHex = Hex($iDec)
	While StringLeft($sHex, 1) = "0"
		$sHex = StringMid($sHex, 2)
		If StringLeft($sHex, 1) <> "0" Then ExitLoop
	WEnd
	Return $sHex
EndFunc   ;==>__Hex
