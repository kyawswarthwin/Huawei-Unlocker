#include-once

#include "AndroidConstants.au3"
#include <Constants.au3>
#include <String.au3>
#include <StringConstants.au3>

; #INDEX# =======================================================================================================================
; Title .........: Android
; AutoIt Version : 3.3
; Language ......: English
; Description ...:
; Author(s) .....: Kyaw Swar Thwin
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _Android_Call
; _Android_CommandExists
; _Android_Connect
; _Android_Dial
; _Android_FileExists
; _Android_Flash
; _Android_ForceStopPackage
; _Android_GetBatteryHealth
; _Android_GetBatteryLevel
; _Android_GetBatteryPlugType
; _Android_GetBatteryStatus
; _Android_GetBatteryTechnology
; _Android_GetBatteryTemperature
; _Android_GetBatteryVoltage
; _Android_GetDeviceID
; _Android_GetExternalStorageDirectory
; _Android_GetLegacyExternalStorageDirectory
; _Android_GetNetworkClass
; _Android_GetNetworkCountryISO
; _Android_GetNetworkOperator
; _Android_GetNetworkOperatorName
; _Android_GetNetworkType
; _Android_GetNetworkTypeName
; _Android_GetPackageInfo
; _Android_GetPhoneType
; _Android_GetProperty
; _Android_GetSerialNumber
; _Android_GetSIMCountryISO
; _Android_GetSIMOperator
; _Android_GetSIMOperatorName
; _Android_GetSIMState
; _Android_GetState
; _Android_Install
; _Android_IsAirplaneModeOn
; _Android_IsBatteryCharged
; _Android_IsBatteryLow
; _Android_IsBatteryPresent
; _Android_IsBootloader
; _Android_IsBusyBoxInstalled
; _Android_IsNetworkRoaming
; _Android_IsOffline
; _Android_IsOnline
; _Android_IsRooted
; _Android_IsScreenOn
; _Android_Pull
; _Android_Push
; _Android_Reboot
; _Android_Remount
; _Android_Send
; _Android_SendSMS
; _Android_Shell
; _Android_StartActivity
; _Android_TakeSnapshot
; _Android_Uninstall
; _Android_WaitForDevice
; _Android_Wake
; _Android_WipeDataCache
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; __Android_GetBatteryInfo
; __Run
; __URLEncode
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __Android_GetBatteryInfo
; Description ...:
; Syntax ........: __Android_GetBatteryInfo($sMode)
; Parameters ....: $sMode               - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __Android_GetBatteryInfo($sMode)
	Local $aOutput = StringRegExp(_Android_Shell("dumpsys battery"), $sMode & ":(.*)", 3)
	If Not @error Then Return StringStripWS($aOutput[0], $STR_STRIPLEADING)
EndFunc   ;==>__Android_GetBatteryInfo

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __Run
; Description ...:
; Syntax ........: __Run($sCommand)
; Parameters ....: $sCommand            - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __Run($sCommand)
	Local $iPID, $sLine, $sOutput = ""
	$iPID = Run(@ComSpec & " /c " & $sCommand, @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	While 1
		$sLine = StdoutRead($iPID)
		If @error Then ExitLoop
		$sOutput &= $sLine
	WEnd
	Return StringStripCR(StringTrimRight($sOutput, StringLen(@CRLF)))
EndFunc   ;==>__Run

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __URLEncode
; Description ...:
; Syntax ........: __URLEncode($sURL)
; Parameters ....: $sURL                - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __URLEncode($sURL)
	Local $aChar, $sEncode = ""
	$aChar = StringSplit($sURL, "")
	For $i = 1 To $aChar[0]
		If Not StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", $aChar[$i]) Then
			$sEncode &= "%" & Hex(Asc($aChar[$i]), 2)
		Else
			$sEncode &= $aChar[$i]
		EndIf
	Next
	Return $sEncode
EndFunc   ;==>__URLEncode

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Call
; Description ...:
; Syntax ........: _Android_Call($sPhoneNumber)
; Parameters ....: $sPhoneNumber        - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Call($sPhoneNumber)
	Local $sOutput = _Android_Shell('service call phone 2 s16 \"' & __URLEncode($sPhoneNumber) & '\"')
	If $sOutput <> "Result: Parcel(00000000    '....')" Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_Android_Call

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_CommandExists
; Description ...:
; Syntax ........: _Android_CommandExists($sCommand)
; Parameters ....: $sCommand            - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_CommandExists($sCommand)
	Return _Android_Shell('command -v ' & $sCommand & ' > /dev/null 2>&1 && echo \"Found\" || echo \"Not Found\"') = "Found"
EndFunc   ;==>_Android_CommandExists

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Connect
; Description ...:
; Syntax ........: _Android_Connect()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Connect()
	Local $bOnline = _Android_IsOnline()
	If Not $bOnline Then
		__Run("adb kill-server")
		__Run("adb start-server")
		$bOnline = _Android_IsOnline()
	EndIf
	Return SetError(Int(Not $bOnline), 0, Int($bOnline))
EndFunc   ;==>_Android_Connect

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Dial
; Description ...:
; Syntax ........: _Android_Dial($sPhoneNumber)
; Parameters ....: $sPhoneNumber        - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Dial($sPhoneNumber)
	Local $sOutput = _Android_Shell('service call phone 1 s16 \"' & __URLEncode($sPhoneNumber) & '\"')
	If $sOutput <> "Result: Parcel(00000000    '....')" Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_Android_Dial

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_FileExists
; Description ...:
; Syntax ........: _Android_FileExists($sFilePath)
; Parameters ....: $sFilePath           - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_FileExists($sFilePath)
	Return _Android_Shell('if [ -e \"' & $sFilePath & '\" ]; then echo \"Found\"; else echo \"Not Found\"; fi') = "Found"
EndFunc   ;==>_Android_FileExists

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Flash
; Description ...:
; Syntax ........: _Android_Flash($sMode, $sFilePath)
; Parameters ....: $sMode               - A string value.
;                  $sFilePath           - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Flash($sMode, $sFilePath)
	Return __Run("fastboot flash " & $sMode & ' "' & $sFilePath & '"')
EndFunc   ;==>_Android_Flash

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_ForceStopPackage
; Description ...:
; Syntax ........: _Android_ForceStopPackage($sPackage)
; Parameters ....: $sPackage            - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_ForceStopPackage($sPackage)
	_Android_Shell("am force-stop " & $sPackage)
EndFunc   ;==>_Android_ForceStopPackage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryHealth
; Description ...:
; Syntax ........: _Android_GetBatteryHealth()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryHealth()
	Return __Android_GetBatteryInfo("health")
EndFunc   ;==>_Android_GetBatteryHealth

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryLevel
; Description ...:
; Syntax ........: _Android_GetBatteryLevel()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryLevel()
	Return (__Android_GetBatteryInfo("level") * 100) / __Android_GetBatteryInfo("scale")
EndFunc   ;==>_Android_GetBatteryLevel

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryPlugType
; Description ...:
; Syntax ........: _Android_GetBatteryPlugType()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryPlugType()
	If __Android_GetBatteryInfo("AC powered") = "true" Then
		Return $BATTERY_PLUGGED_AC
	ElseIf __Android_GetBatteryInfo("USB powered") = "true" Then
		Return $BATTERY_PLUGGED_USB
	ElseIf __Android_GetBatteryInfo("Wireless powered") = "true" Then
		Return $BATTERY_PLUGGED_WIRELESS
	EndIf
EndFunc   ;==>_Android_GetBatteryPlugType

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryStatus
; Description ...:
; Syntax ........: _Android_GetBatteryStatus()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryStatus()
	Return __Android_GetBatteryInfo("status")
EndFunc   ;==>_Android_GetBatteryStatus

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryTechnology
; Description ...:
; Syntax ........: _Android_GetBatteryTechnology()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryTechnology()
	Return __Android_GetBatteryInfo("technology")
EndFunc   ;==>_Android_GetBatteryTechnology

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryTemperature
; Description ...:
; Syntax ........: _Android_GetBatteryTemperature()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryTemperature()
	Return __Android_GetBatteryInfo("temperature")
EndFunc   ;==>_Android_GetBatteryTemperature

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetBatteryVoltage
; Description ...:
; Syntax ........: _Android_GetBatteryVoltage()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetBatteryVoltage()
	Return __Android_GetBatteryInfo("voltage")
EndFunc   ;==>_Android_GetBatteryVoltage

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetDeviceID
; Description ...:
; Syntax ........: _Android_GetDeviceID()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetDeviceID()
	Local $aOutput = StringRegExp(_Android_Shell("dumpsys iphonesubinfo"), "Device ID = (.*)", 3)
	If Not @error Then Return $aOutput[0]
EndFunc   ;==>_Android_GetDeviceID

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetExternalStorageDirectory
; Description ...:
; Syntax ........: _Android_GetExternalStorageDirectory()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetExternalStorageDirectory()
	Local $aOutput = StringSplit(_Android_Shell("echo $" & $ENV_SECONDARY_STORAGE), ":")
	Return $aOutput[1]
EndFunc   ;==>_Android_GetExternalStorageDirectory

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetLegacyExternalStorageDirectory
; Description ...:
; Syntax ........: _Android_GetLegacyExternalStorageDirectory()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetLegacyExternalStorageDirectory()
	Return _Android_Shell("echo $" & $ENV_EXTERNAL_STORAGE)
EndFunc   ;==>_Android_GetLegacyExternalStorageDirectory

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkClass
; Description ...:
; Syntax ........: _Android_GetNetworkClass($iNetworkType)
; Parameters ....: $iNetworkType        - An integer value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkClass($iNetworkType)
	Switch $iNetworkType
		Case $NETWORK_TYPE_GPRS, $NETWORK_TYPE_EDGE, $NETWORK_TYPE_CDMA, $NETWORK_TYPE_1xRTT, $NETWORK_TYPE_IDEN
			Return $NETWORK_CLASS_2_G
		Case $NETWORK_TYPE_UMTS, $NETWORK_TYPE_EVDO_0, $NETWORK_TYPE_EVDO_A, $NETWORK_TYPE_HSDPA, $NETWORK_TYPE_HSUPA, $NETWORK_TYPE_HSPA, $NETWORK_TYPE_EVDO_B, $NETWORK_TYPE_EHRPD, $NETWORK_TYPE_HSPAP
			Return $NETWORK_CLASS_3_G
		Case $NETWORK_TYPE_LTE
			Return $NETWORK_CLASS_4_G
		Case Else
			Return $NETWORK_CLASS_UNKNOWN
	EndSwitch
EndFunc   ;==>_Android_GetNetworkClass

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkCountryISO
; Description ...:
; Syntax ........: _Android_GetNetworkCountryISO()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkCountryISO()
	Return _Android_GetProperty($PROPERTY_OPERATOR_ISO_COUNTRY)
EndFunc   ;==>_Android_GetNetworkCountryISO

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkOperator
; Description ...:
; Syntax ........: _Android_GetNetworkOperator()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkOperator()
	Return _Android_GetProperty($PROPERTY_OPERATOR_NUMERIC)
EndFunc   ;==>_Android_GetNetworkOperator

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkOperatorName
; Description ...:
; Syntax ........: _Android_GetNetworkOperatorName()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkOperatorName()
	Return _Android_GetProperty($PROPERTY_OPERATOR_ALPHA)
EndFunc   ;==>_Android_GetNetworkOperatorName

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkType
; Description ...:
; Syntax ........: _Android_GetNetworkType()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkType()
	Switch _Android_GetNetworkTypeName()
		Case "GPRS"
			Return $NETWORK_TYPE_GPRS
		Case "EDGE"
			Return $NETWORK_TYPE_EDGE
		Case "UMTS"
			Return $NETWORK_TYPE_UMTS
		Case "CDMA"
			Return $NETWORK_TYPE_CDMA
		Case "CDMA - EvDo rev. 0"
			Return $NETWORK_TYPE_EVDO_0
		Case "CDMA - EvDo rev. A"
			Return $NETWORK_TYPE_EVDO_A
		Case "CDMA - 1xRTT"
			Return $NETWORK_TYPE_1xRTT
		Case "HSDPA"
			Return $NETWORK_TYPE_HSDPA
		Case "HSUPA"
			Return $NETWORK_TYPE_HSUPA
		Case "HSPA"
			Return $NETWORK_TYPE_HSPA
		Case "iDEN"
			Return $NETWORK_TYPE_IDEN
		Case "CDMA - EvDo rev. B"
			Return $NETWORK_TYPE_EVDO_B
		Case "LTE"
			Return $NETWORK_TYPE_LTE
		Case "CDMA - eHRPD"
			Return $NETWORK_TYPE_EHRPD
		Case "HSPA+"
			Return $NETWORK_TYPE_HSPAP
		Case Else
			Return $NETWORK_TYPE_UNKNOWN
	EndSwitch
EndFunc   ;==>_Android_GetNetworkType

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetNetworkTypeName
; Description ...:
; Syntax ........: _Android_GetNetworkTypeName()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetNetworkTypeName()
	Return _Android_GetProperty($PROPERTY_DATA_NETWORK_TYPE)
EndFunc   ;==>_Android_GetNetworkTypeName

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetPackageInfo
; Description ...:
; Syntax ........: _Android_GetPackageInfo($sFilePath, Byref $sPackage, Byref $sApplication, Byref $sIcon, Byref $sVersion,
;                  Byref $iVersionCode, Byref $iMinimumRequiredSDK, Byref $sPermissions)
; Parameters ....: $sFilePath           - A string value.
;                  $sPackage            - [in/out] A string value.
;                  $sApplication        - [in/out] A string value.
;                  $sIcon               - [in/out] A string value.
;                  $sVersion            - [in/out] A string value.
;                  $iVersionCode        - [in/out] An integer value.
;                  $iMinimumRequiredSDK - [in/out] An integer value.
;                  $sPermissions        - [in/out] A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetPackageInfo($sFilePath, ByRef $sPackage, ByRef $sApplication, ByRef $sIcon, ByRef $sVersion, ByRef $iVersionCode, ByRef $iMinimumRequiredSDK, ByRef $sPermissions)
	Local $aOutput, $sKey, $sValue, $aValue
	$sPermissions = ""
	$aOutput = StringSplit(__Run('aapt d badging "' & $sFilePath & '"'), @LF)
	For $i = 1 To $aOutput[0]
		$sKey = StringLeft($aOutput[$i], StringInStr($aOutput[$i], ":") - 1)
		$sValue = StringMid($aOutput[$i], StringInStr($aOutput[$i], ":") + 1)
		Switch $sKey
			Case "package"
				$aValue = _StringBetween($sValue, "name='", "'")
				$sPackage = $aValue[0]
				$aValue = _StringBetween($sValue, "versionCode='", "'")
				$iVersionCode = Int($aValue[0])
				$aValue = _StringBetween($sValue, "versionName='", "'")
				$sVersion = $aValue[0]
			Case "sdkVersion"
				$aValue = _StringBetween($sValue, "'", "'")
				$iMinimumRequiredSDK = Int($aValue[0])
			Case "uses-permission"
				$aValue = _StringBetween($sValue, "'", "'")
				$sPermissions &= $aValue[0] & @CRLF
			Case "application"
				$aValue = _StringBetween($sValue, "label='", "'")
				$sApplication = $aValue[0]
				$aValue = _StringBetween($sValue, "icon='", "'")
				$sIcon = $aValue[0]
		EndSwitch
	Next
EndFunc   ;==>_Android_GetPackageInfo

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetPhoneType
; Description ...:
; Syntax ........: _Android_GetPhoneType()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetPhoneType()
	Return _Android_GetProperty($CURRENT_ACTIVE_PHONE)
EndFunc   ;==>_Android_GetPhoneType

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetProperty
; Description ...:
; Syntax ........: _Android_GetProperty($sKey)
; Parameters ....: $sKey                - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetProperty($sKey)
	Return _Android_Shell("getprop " & $sKey)
EndFunc   ;==>_Android_GetProperty

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetSerialNumber
; Description ...:
; Syntax ........: _Android_GetSerialNumber()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetSerialNumber()
	Return __Run("adb get-serialno")
EndFunc   ;==>_Android_GetSerialNumber

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetSIMCountryISO
; Description ...:
; Syntax ........: _Android_GetSIMCountryISO()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetSIMCountryISO()
	Return _Android_GetProperty($PROPERTY_ICC_OPERATOR_ISO_COUNTRY)
EndFunc   ;==>_Android_GetSIMCountryISO

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetSIMOperator
; Description ...:
; Syntax ........: _Android_GetSIMOperator()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetSIMOperator()
	Return _Android_GetProperty($PROPERTY_ICC_OPERATOR_NUMERIC)
EndFunc   ;==>_Android_GetSIMOperator

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetSIMOperatorName
; Description ...:
; Syntax ........: _Android_GetSIMOperatorName()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetSIMOperatorName()
	Return _Android_GetProperty($PROPERTY_ICC_OPERATOR_ALPHA)
EndFunc   ;==>_Android_GetSIMOperatorName

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetSIMState
; Description ...:
; Syntax ........: _Android_GetSIMState()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_GetSIMState()
	Switch _Android_GetProperty($PROPERTY_SIM_STATE)
		Case "ABSENT"
			Return $SIM_STATE_ABSENT
		Case "PIN_REQUIRED"
			Return $SIM_STATE_PIN_REQUIRED
		Case "PUK_REQUIRED"
			Return $SIM_STATE_PUK_REQUIRED
		Case "NETWORK_LOCKED"
			Return $SIM_STATE_NETWORK_LOCKED
		Case "READY"
			Return $SIM_STATE_READY
		Case Else
			Return $SIM_STATE_UNKNOWN
	EndSwitch
EndFunc   ;==>_Android_GetSIMState

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_GetState
; Description ...:
; Syntax ........: _Android_GetState()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
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
EndFunc   ;==>_Android_GetState

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Install
; Description ...:
; Syntax ........: _Android_Install($sFilePath[, $iMode = 1[, $bReinstall = False]])
; Parameters ....: $sFilePath           - A string value.
;                  $iMode               - [optional] An integer value. Default is 1.
;                  $bReinstall          - [optional] A binary value. Default is False.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Install($sFilePath, $iMode = 1, $bReinstall = False)
	Local $aOutput
	If $iMode = Default Then $iMode = 1
	If $bReinstall = Default Then $bReinstall = False
	If $iMode = 2 Then; Install on SD Card
		If $bReinstall Then
			$aOutput = StringSplit(__Run('adb install -r -s "' & $sFilePath & '"'), @LF)
		Else
			$aOutput = StringSplit(__Run('adb install -s "' & $sFilePath & '"'), @LF)
		EndIf
	Else; Install on Internal Storage
		If $bReinstall Then
			$aOutput = StringSplit(__Run('adb install -r "' & $sFilePath & '"'), @LF)
		Else
			$aOutput = StringSplit(__Run('adb install "' & $sFilePath & '"'), @LF)
		EndIf
	EndIf
	If $aOutput[UBound($aOutput) - 1] <> "Success" Then
		$aOutput = _StringBetween($aOutput[UBound($aOutput) - 1], "[", "]")
		If Not @error Then
			Switch $aOutput[0]
				Case "INSTALL_FAILED_ALREADY_EXISTS"
					Return SetError(1, 0, $INSTALL_FAILED_ALREADY_EXISTS)
				Case "INSTALL_FAILED_INVALID_APK"
					Return SetError(1, 0, $INSTALL_FAILED_INVALID_APK)
				Case "INSTALL_FAILED_INVALID_URI"
					Return SetError(1, 0, $INSTALL_FAILED_INVALID_URI)
				Case "INSTALL_FAILED_INSUFFICIENT_STORAGE"
					Return SetError(1, 0, $INSTALL_FAILED_INSUFFICIENT_STORAGE)
				Case "INSTALL_FAILED_DUPLICATE_PACKAGE"
					Return SetError(1, 0, $INSTALL_FAILED_DUPLICATE_PACKAGE)
				Case "INSTALL_FAILED_NO_SHARED_USER"
					Return SetError(1, 0, $INSTALL_FAILED_NO_SHARED_USER)
				Case "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
					Return SetError(1, 0, $INSTALL_FAILED_UPDATE_INCOMPATIBLE)
				Case "INSTALL_FAILED_SHARED_USER_INCOMPATIBLE"
					Return SetError(1, 0, $INSTALL_FAILED_SHARED_USER_INCOMPATIBLE)
				Case "INSTALL_FAILED_MISSING_SHARED_LIBRARY"
					Return SetError(1, 0, $INSTALL_FAILED_MISSING_SHARED_LIBRARY)
				Case "INSTALL_FAILED_REPLACE_COULDNT_DELETE"
					Return SetError(1, 0, $INSTALL_FAILED_REPLACE_COULDNT_DELETE)
				Case "INSTALL_FAILED_DEXOPT"
					Return SetError(1, 0, $INSTALL_FAILED_DEXOPT)
				Case "INSTALL_FAILED_OLDER_SDK"
					Return SetError(1, 0, $INSTALL_FAILED_OLDER_SDK)
				Case "INSTALL_FAILED_CONFLICTING_PROVIDER"
					Return SetError(1, 0, $INSTALL_FAILED_CONFLICTING_PROVIDER)
				Case "INSTALL_FAILED_NEWER_SDK"
					Return SetError(1, 0, $INSTALL_FAILED_NEWER_SDK)
				Case "INSTALL_FAILED_TEST_ONLY"
					Return SetError(1, 0, $INSTALL_FAILED_TEST_ONLY)
				Case "INSTALL_FAILED_CPU_ABI_INCOMPATIBLE"
					Return SetError(1, 0, $INSTALL_FAILED_CPU_ABI_INCOMPATIBLE)
				Case "INSTALL_FAILED_MISSING_FEATURE"
					Return SetError(1, 0, $INSTALL_FAILED_MISSING_FEATURE)
				Case "INSTALL_FAILED_CONTAINER_ERROR"
					Return SetError(1, 0, $INSTALL_FAILED_CONTAINER_ERROR)
				Case "INSTALL_FAILED_INVALID_INSTALL_LOCATION"
					Return SetError(1, 0, $INSTALL_FAILED_INVALID_INSTALL_LOCATION)
				Case "INSTALL_FAILED_MEDIA_UNAVAILABLE"
					Return SetError(1, 0, $INSTALL_FAILED_MEDIA_UNAVAILABLE)
				Case "INSTALL_FAILED_VERIFICATION_TIMEOUT"
					Return SetError(1, 0, $INSTALL_FAILED_VERIFICATION_TIMEOUT)
				Case "INSTALL_FAILED_VERIFICATION_FAILURE"
					Return SetError(1, 0, $INSTALL_FAILED_VERIFICATION_FAILURE)
				Case "INSTALL_FAILED_PACKAGE_CHANGED"
					Return SetError(1, 0, $INSTALL_FAILED_PACKAGE_CHANGED)
				Case "INSTALL_FAILED_UID_CHANGED"
					Return SetError(1, 0, $INSTALL_FAILED_UID_CHANGED)
				Case "INSTALL_FAILED_VERSION_DOWNGRADE"
					Return SetError(1, 0, $INSTALL_FAILED_VERSION_DOWNGRADE)
				Case "INSTALL_FAILED_INTERNAL_ERROR"
					Return SetError(1, 0, $INSTALL_FAILED_INTERNAL_ERROR)
				Case "INSTALL_FAILED_USER_RESTRICTED"
					Return SetError(1, 0, $INSTALL_FAILED_USER_RESTRICTED)
			EndSwitch
		Else
			Return SetError(1, 0, 0)
		EndIf
	EndIf
	Return $INSTALL_SUCCEEDED
EndFunc   ;==>_Android_Install

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsAirplaneModeOn
; Description ...:
; Syntax ........: _Android_IsAirplaneModeOn()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsAirplaneModeOn()
	If _Android_GetProperty("ro.build.version.sdk") < 17 Then
		Return _Android_Shell("settings get system " & $AIRPLANE_MODE_ON) = 1
	Else
		Return _Android_Shell("settings get global " & $AIRPLANE_MODE_ON) = 1
	EndIf
EndFunc   ;==>_Android_IsAirplaneModeOn

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsBatteryCharged
; Description ...:
; Syntax ........: _Android_IsBatteryCharged()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsBatteryCharged()
	Return _Android_GetBatteryStatus() = $BATTERY_STATUS_FULL Or _Android_GetBatteryLevel() = 100
EndFunc   ;==>_Android_IsBatteryCharged

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsBatteryLow
; Description ...:
; Syntax ........: _Android_IsBatteryLow()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsBatteryLow()
	Return _Android_GetBatteryLevel() < $LOW_BATTERY_THRESHOLD
EndFunc   ;==>_Android_IsBatteryLow

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsBatteryPresent
; Description ...:
; Syntax ........: _Android_IsBatteryPresent()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsBatteryPresent()
	Return __Android_GetBatteryInfo("present") = "true"
EndFunc   ;==>_Android_IsBatteryPresent

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsBootloader
; Description ...:
; Syntax ........: _Android_IsBootloader()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsBootloader()
	Return __Run("fastboot devices") <> ""
EndFunc   ;==>_Android_IsBootloader

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsBusyBoxInstalled
; Description ...:
; Syntax ........: _Android_IsBusyBoxInstalled()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsBusyBoxInstalled()
	Return _Android_CommandExists("busybox")
EndFunc   ;==>_Android_IsBusyBoxInstalled

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsNetworkRoaming
; Description ...:
; Syntax ........: _Android_IsNetworkRoaming()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsNetworkRoaming()
	Return _Android_GetProperty($PROPERTY_OPERATOR_ISROAMING) = "true"
EndFunc   ;==>_Android_IsNetworkRoaming

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsOffline
; Description ...:
; Syntax ........: _Android_IsOffline()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsOffline()
	Return __Run("adb get-state") = "offline"
EndFunc   ;==>_Android_IsOffline

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsOnline
; Description ...:
; Syntax ........: _Android_IsOnline()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsOnline()
	Return __Run("adb get-state") = "device"
EndFunc   ;==>_Android_IsOnline

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsRooted
; Description ...:
; Syntax ........: _Android_IsRooted()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsRooted()
	Return _Android_Shell("echo Root Checker", True) = "Root Checker"
EndFunc   ;==>_Android_IsRooted

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_IsScreenOn
; Description ...:
; Syntax ........: _Android_IsScreenOn()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_IsScreenOn()
	Local $aOutput
	If _Android_GetProperty("ro.build.version.sdk") < 17 Then
		$aOutput = StringRegExp(_Android_Shell("dumpsys power"), "mPowerState=([0-9]+)", 3)
		If Not @error Then Return BitAND($aOutput[0], $SCREEN_ON_BIT) <> 0
	Else
		$aOutput = StringRegExp(_Android_Shell("dumpsys power"), "mScreenOn=(.*)", 3)
		If Not @error Then Return $aOutput[0] = "true"
	EndIf
	Return False
EndFunc   ;==>_Android_IsScreenOn

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Pull
; Description ...:
; Syntax ........: _Android_Pull($sRemotePath, $sLocalPath)
; Parameters ....: $sRemotePath         - A string value.
;                  $sLocalPath          - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Pull($sRemotePath, $sLocalPath)
	Return __Run('adb pull "' & $sRemotePath & '" "' & $sLocalPath & '"')
EndFunc   ;==>_Android_Pull

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Push
; Description ...:
; Syntax ........: _Android_Push($sLocalPath, $sRemotePath)
; Parameters ....: $sLocalPath          - A string value.
;                  $sRemotePath         - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Push($sLocalPath, $sRemotePath)
	Return __Run('adb push "' & $sLocalPath & '" "' & $sRemotePath & '"')
EndFunc   ;==>_Android_Push

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Reboot
; Description ...:
; Syntax ........: _Android_Reboot([$sMode = ""])
; Parameters ....: $sMode               - [optional] A string value. Default is "".
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
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
EndFunc   ;==>_Android_Reboot

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Remount
; Description ...:
; Syntax ........: _Android_Remount([$sMode = "rw"[, $sPath = "/system"]])
; Parameters ....: $sMode               - [optional] A string value. Default is "rw".
;                  $sPath               - [optional] A string value. Default is "/system".
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Remount($sMode = "rw", $sPath = "/system")
	If $sMode = Default Then $sMode = "rw"
	If $sPath = Default Then $sPath = "/system"
	Local $sOutput = _Android_Shell("mount -o remount," & $sMode & " " & $sPath, _Android_IsRooted(), True)
	If $sOutput <> "" Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_Android_Remount

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Send
; Description ...:
; Syntax ........: _Android_Send($vKeys)
; Parameters ....: $vKeys               - A variant value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Send($vKeys)
	If IsString($vKeys) Then
		_Android_Shell('export CLASSPATH=/system/framework/input.jar; exec app_process /system/bin com.android.commands.input.Input text \"' & $vKeys & '\"')
	Else
		_Android_Shell("input keyevent " & $vKeys)
	EndIf
EndFunc   ;==>_Android_Send

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_SendSMS
; Description ...:
; Syntax ........: _Android_SendSMS($sPhoneNumber, $sSMSBody)
; Parameters ....: $sPhoneNumber        - A string value.
;                  $sSMSBody            - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_SendSMS($sPhoneNumber, $sSMSBody)
	Local $sOutput = _Android_Shell('service call isms 5 s16 \"' & __URLEncode($sPhoneNumber) & '\" i32 0 i32 0 s16 \"' & $sSMSBody & '\"')
	If $sOutput <> "Result: Parcel(00000000    '....')" Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_Android_SendSMS

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Shell
; Description ...:
; Syntax ........: _Android_Shell($sCommand[, $bSuperuser = False[, $bBusyBox = False]])
; Parameters ....: $sCommand            - A string value.
;                  $bSuperuser          - [optional] A binary value. Default is False.
;                  $bBusyBox            - [optional] A binary value. Default is False.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
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
EndFunc   ;==>_Android_Shell

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_StartActivity
; Description ...:
; Syntax ........: _Android_StartActivity($sComponent)
; Parameters ....: $sComponent          - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_StartActivity($sComponent)
	Return _Android_Shell("am start -n " & $sComponent)
EndFunc   ;==>_Android_StartActivity

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_TakeSnapshot
; Description ...:
; Syntax ........: _Android_TakeSnapshot($sFilePath)
; Parameters ....: $sFilePath           - A string value.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_TakeSnapshot($sFilePath)
	_Android_Shell("screencap -p /data/local/tmp/screenshot.png")
	_Android_Pull("/data/local/tmp/screenshot.png", $sFilePath)
EndFunc   ;==>_Android_TakeSnapshot

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Uninstall
; Description ...:
; Syntax ........: _Android_Uninstall($sPackage[, $bKeepDataCache = False])
; Parameters ....: $sPackage            - A string value.
;                  $bKeepDataCache      - [optional] A binary value. Default is False.
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Uninstall($sPackage, $bKeepDataCache = False)
	Local $sOutput
	If $bKeepDataCache = Default Then $bKeepDataCache = False
	If $bKeepDataCache Then
		$sOutput = __Run("adb uninstall -k " & $sPackage)
	Else
		$sOutput = __Run("adb uninstall " & $sPackage)
	EndIf
	If $sOutput <> "Success" Then Return SetError(1, 0, 0)
	Return 1
EndFunc   ;==>_Android_Uninstall

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_WaitForDevice
; Description ...:
; Syntax ........: _Android_WaitForDevice([$sMode = ""])
; Parameters ....: $sMode               - [optional] A string value. Default is "".
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_WaitForDevice($sMode = "")
	If $sMode = Default Then $sMode = ""
	If $sMode = "bootloader" Then
		Do
			Sleep(250)
		Until _Android_IsBootloader()
	Else
		Do
			Sleep(250)
		Until _Android_IsOnline()
	EndIf
EndFunc   ;==>_Android_WaitForDevice

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_Wake
; Description ...:
; Syntax ........: _Android_Wake()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_Wake()
	If Not _Android_IsScreenOn() Then _Android_Send($KEYCODE_POWER)
EndFunc   ;==>_Android_Wake

; #FUNCTION# ====================================================================================================================
; Name ..........: _Android_WipeDataCache
; Description ...:
; Syntax ........: _Android_WipeDataCache()
; Parameters ....:
; Return values .: None
; Author ........: Kyaw Swar Thwin
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Android_WipeDataCache()
	If _Android_IsBootloader() Then
		__Run("fastboot -w")
	Else
		If Not _Android_IsRooted() Then Return SetError(1, 0, 0)
		_Android_Shell("wipe data", True)
	EndIf
	Return 1
EndFunc   ;==>_Android_WipeDataCache
