@echo off & setlocal enableextensions

powershell -noprofile -command ^"^& {$file='%~dpf1'; $BYTES_TO_TRIM=%2; ^
$byteEncodedContent = [System.IO.File]::ReadAllBytes($file); ^
$truncatedByteEncodedContent = $byteEncodedContent[ $BYTES_TO_TRIM..$byteEncodedContent.Length ]; ^
Set-Content -value $truncatedByteEncodedContent -encoding byte -path "$($file)"}"

endlocal & exit /b 0