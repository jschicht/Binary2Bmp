#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Turn any file into a bmp
#AutoIt3Wrapper_Res_Description=Turn any file into a bmp
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
$File = FileOpenDialog("Select binary file with pixel bytes",@ScriptDir,"All (*.*)")
If @error Then Exit
ConsoleWrite("File: " & $File & @CRLF)
$hFile = FileOpen($File,16)
$rFile = FileRead($hFile)
$Startpos = 3
$Signature = "424d"
$SizeDec = BinaryLen($rFile)+54
$Size = _SwapEndian(Hex($SizeDec,8))
$Reserved = "00000000" ; 4 bytes
$OffsetPixelArray = 54 ; default value
$OffsetPixelArray = _SwapEndian(Hex($OffsetPixelArray,8))
; DIB header
$DIBHeaderSize = 40
$DIBHeaderSize = _SwapEndian(Hex($DIBHeaderSize,8))
$GuessedWidth = Int(Sqrt($SizeDec/6)*2)
$DIBImageWidthDec = InputBox("Set wanted image width (X)","The height will be automatically set",$GuessedWidth)
If @error Then Exit
$DIBImageWidth = _SwapEndian(Hex($DIBImageWidthDec,8))
$DIBNumberOfPlanes = 1 ;2 bytes
$DIBNumberOfPlanes = _SwapEndian(Hex($DIBNumberOfPlanes,4))
$DIBBppDec = 24;2 bytes
$DIBBpp = _SwapEndian(Hex($DIBBppDec,4))
$DIBCompression = "00000000";4 bytes
$DIBImageSize = BinaryLen($rFile);4 bytes
$DIBImageSize = _SwapEndian(Hex($DIBImageSize,8))
$DIBXPixPerMeter = 2835;4 bytes
$DIBXPixPerMeter = _SwapEndian(Hex($DIBXPixPerMeter,8))
$DIBYPixPerMeter = 2835;4 bytes
$DIBYPixPerMeter = _SwapEndian(Hex($DIBYPixPerMeter,8))
$DIBColorsInTable = "00000000";4 bytes
$DIBImportantColorCount = "00000000";4 bytes

$TargetSize = BinaryLen($rFile)
$SizeX = $DIBImageWidthDec*6 ; Size of width x default colors per pixel
$MaxHeight = Ceiling(($TargetSize*2)/$SizeX)  ; Y
$TestSize = $DIBImageWidthDec*$MaxHeight*3 ; Caclulated total needed pixels
$TestDiff = $TestSize-$TargetSize ; Calculate diff to estimated image size
If $TestDiff > 0 Then ; Align total pixels according to X/Y
	For $i = 1 To $TestDiff
		$rFile &= "00"
	Next
EndIf
$TargetSize = BinaryLen($rFile)
$RowCounter = 0
$Processed = 0
$TempRow = ""

Dim $NewPixArray[$MaxHeight+1]
Local $begin = TimerInit()
Do ; Loop through each row
	$RowN = StringMid($rFile,$Startpos+$Processed,$SizeX)
	$TempRow = ""
	$PixOffset = 1
	TrayTip("RecreateBMP", "Processed " & Round(($RowCounter/$MaxHeight)*100,1) & " %", 0)
	For $i = 1 To $SizeX ; Concatenate each color per pixel in reversed order
		$PixN = StringMid($RowN,$PixOffset,6)
		$Red = StringLeft($PixN,2)
		$Green = StringMid($PixN,3,2)
		$Blue = StringRight($PixN,2)
		$TempRow &= $Blue&$Green&$Red
		$PixOffset += 6
	Next
	If Mod(StringLen($TempRow)/2,4) Then ; Align row size to dword
		Do
			$TempRow &= "00"
		Until Mod(StringLen($TempRow)/2,4)=0
	EndIf
	$NewPixArray[$RowCounter] = $TempRow ; Add each row into an array
	$Processed += $SizeX
	$RowCounter += 1
Until $Processed > $TargetSize*2
$timerdiff = TimerDiff($begin)
$timerdiff = Round(($timerdiff / 1000), 2)
ConsoleWrite("Job took: " & $timerdiff & " seconds" & @CRLF)
$RecompiledPixArray = ""
For $i = UBound($NewPixArray)-1 To 0 Step -1 ; Loop through array and concatenate array elements (rows) in correct order (upside down)
	$RecompiledPixArray &= $NewPixArray[$i]
Next
$NewSize = StringLen($RecompiledPixArray)/2
$NewSizeWithHeader = $NewSize+54
$NewSize = _SwapEndian(Hex(Int($NewSize),8))
$NewSizeWithHeader = _SwapEndian(Hex(Int($NewSizeWithHeader),8))
$MaxHeightDec = $MaxHeight
$MaxHeight = _SwapEndian(Hex($MaxHeight,8))
; Recreate BMP header + DIB header
$RecreatedHeader = $Signature&$NewSizeWithHeader&$Reserved&$OffsetPixelArray&$DIBHeaderSize&$DIBImageWidth&$MaxHeight&$DIBNumberOfPlanes&$DIBBpp&$DIBCompression&$NewSize&$DIBXPixPerMeter&$DIBYPixPerMeter&$DIBColorsInTable&$DIBImportantColorCount
$OutData = "0x"&$RecreatedHeader&$RecompiledPixArray
; Name output file to indicate which X/Y it's recreated from
$OutFile = FileOpen($File&"."&$DIBImageWidthDec&"x"&$MaxHeightDec&".bmp",18)
FileWrite($OutFile,$OutData)
FileClose($hFile)
FileClose($OutFile)

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc
