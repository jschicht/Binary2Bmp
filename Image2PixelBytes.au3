#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=Convert an image's pixels to a binary file of the pixelbytes
#AutoIt3Wrapper_Res_Description=Convert an image's pixels to a binary file of the pixelbytes
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;based on IronGeeks stego tool
#include <GDIPlus.au3>
#include <Color.au3>
$ImageToDecode = FileOpenDialog("Select input file to decode:", @ScriptDir, "All (*.*)")
If @error Then Exit
$FileToSaveTo = FileSaveDialog("Select where to save output:", @ScriptDir, "All (*.*)",16,$ImageToDecode&".pixelbytes")
If @error Then Exit
$DecodedImageData = DecodeImage($ImageToDecode)
$FileToSaveTo = FileOpen($FileToSaveTo,18)
FileWrite($FileToSaveTo, "0x"&$DecodedImageData)


Func DecodeImage($InputImage)
	Local $iPosX = 0, $iPosY = 0, $results = "", $Result0 = "", $base = 0
    _GDIPlus_Startup()
    $hImage = _GDIPlus_ImageLoadFromFile($InputImage)
	$iXmax = _GDIPlus_ImageGetWidth($hImage)
	$iYmax = _GDIPlus_ImageGetHeight($hImage)
    For $iPosY = 0 To $iYmax - 1
		TrayTip("LSBExtract", "Processed " & Round(($iPosY/$iYmax)*100,1) & " %", 0)
		For $iPosX = 0 To $iXmax - 1
			$colval = _GDIPlus_BitmapGetPixel($hImage, $iPosX, $iPosY)
			$Result0 &= $colval
		Next
    Next
	_GDIPlus_ImageDispose($hImage)
	_GDIPlus_Shutdown()
	Return $Result0
EndFunc

 ;Just get the color of a pixel
 Func _GDIPlus_BitmapGetPixel($hBitmap, $iX, $iY)
     Local $tArgb, $pArgb, $aRet
     $tArgb = DllStructCreate("dword Argb")
     $pArgb = DllStructGetPtr($tArgb)
     $aRet = DllCall($ghGDIPDll, "int", "GdipBitmapGetPixel", "hwnd", $hBitmap, "int", $iX, "int", $iY, "ptr", $pArgb)
     Return Hex(DllStructGetData($tArgb, "Argb"), 6)
 EndFunc   ;==>_GDIPlus_BitmapGetPixel

Func _DecToBinary($iDec)
	Local $i, $sBinChar = ""
	If StringRegExp($iDec,'[[:digit:]]') then
		$i = 1
		Do
			$x = 16^$i
			$i +=1
; Determine the Octets
		Until $iDec < $x
		For $n = 4*($i-1) To 1 Step -1
			If BitAND(2 ^ ($n-1), $iDec) Then
				$sBinChar &= "1"
			Else
				$sBinChar &= "0"
			EndIf
		Next
		If StringLen($sBinChar) = 4 Then $sBinChar = "0000"&$sBinChar
;		ConsoleWrite("DecToBinary: " & $sBinChar & @CRLF)
		Return $sBinChar
	Else
		MsgBox(0,"Error","Wrong input, try again ...")
		Return
	EndIf
EndFunc

Func _BinaryToDec($strBin)
	Local $Return
	Local $lngResult
	Local $intIndex
	If StringRegExp($strBin,'[0-1]') then
		$lngResult = 0
		For $intIndex = StringLen($strBin) to 1 step -1
			$strDigit = StringMid($strBin, $intIndex, 1)
			Select
				case $strDigit="0"
; do nothing
				case $strDigit="1"
					$lngResult = $lngResult + (2 ^ (StringLen($strBin)-$intIndex))
				case else
; invalid binary digit, so the whole thing is invalid
					$lngResult = 0
					$intIndex = 0 ; stop the loop
			EndSelect
		Next

		$Return = $lngResult
;		ConsoleWrite("BinaryToDec: " & $Return & @CRLF)
		Return $Return
	Else
		MsgBox(0,"Error","Wrong input, try again ...")
		Return
	EndIf
EndFunc
