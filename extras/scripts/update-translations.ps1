[cmdletbinding()]
param ([string]$qtver);

$clientDir = Get-Location
$qtver = If ($qtver) { $qtver } Else { "5.15.0" }
$QtDir = "C:\Qt\$qtver\msvc2019_64"
if (-not(Test-Path -Path $QtDir)) {
    $QtDir = "C:\Qt\$qtver\msvc2017_64"
}
$lupdate = "$QtDir\bin\lupdate.exe"

$tsFileNames = Get-ChildItem -Path "$clientDir\translations" -Recurse -Include *.ts
Invoke-Expression("$lupdate $clientDir\src -extensions cpp,h,qml,qrc -ts $tsFileNames -no-obsolete")
