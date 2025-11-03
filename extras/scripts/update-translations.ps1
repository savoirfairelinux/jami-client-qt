[cmdletbinding()]
param ([string]$QtDir);

$clientDir = Get-Location
if (-not $QtDir) {
    Write-Error "Qt directory path is required. Usage: .\update-translations.ps1 -QtDir 'C:\Qt\6.x.x\msvc2019_64'"
    exit 1
}
$lupdate = Join-Path -Path $QtDir -ChildPath "bin\lupdate.exe"
if (-not(Test-Path -Path $lupdate)) {
    Write-Error "lupdate not found: $lupdate"
    exit 1
}

$tsFileNames = Get-ChildItem -Path "$clientDir\translations" -Recurse -Include *.ts
Invoke-Expression("$lupdate -extensions cpp,h,qml $clientDir\src -ts $tsFileNames -no-obsolete")
