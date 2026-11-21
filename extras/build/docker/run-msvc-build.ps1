param(
    [switch] $Tests,
    [switch] $Msi
)

$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string] $Program, [string[]] $Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE)."
    }
}

if ($Msi -and $env:JAMI_ACCEPT_WIX_EULA -ne '1') {
    throw 'MSI packaging requires explicit acceptance of the WiX 7 EULA.'
}
if (!(Test-Path -LiteralPath C:\input\client.bundle -PathType Leaf)) {
    throw 'Missing source bundle. Run build-client-qt-windows-msvc.ps1 on the host.'
}

# A short path limits path lengths in the vcpkg build trees and MSYS tools.
Invoke-Checked git @('config', '--global', 'core.longpaths', 'true')
Invoke-Checked git @('config', '--global', 'core.autocrlf', 'false')
Invoke-Checked git @('init', '--quiet', 'C:\j')
Set-Location C:\j
Invoke-Checked git @('fetch', '--quiet', '--tags', 'C:\input\client.bundle', 'HEAD')
Invoke-Checked git @('checkout', '--quiet', '--detach', 'FETCH_HEAD')
Invoke-Checked git @('submodule', 'update', '--init', '--',
    'daemon', '3rdparty/hunspell', '3rdparty/md4c', '3rdparty/tidy-html5', '3rdparty/zxing-cpp')

$build = @('extras\scripts\build-windows.py', '--qt', $env:QT_DIR)
if ($Tests) {
    $build += '--tests'
}
Invoke-Checked python $build
Invoke-Checked python @('extras\build\docker\smoke-test-msvc.py', 'x64\Release\Jami.exe')
if ($Msi) {
    Invoke-Checked python @('extras\scripts\build-windows.py', '--qt', $env:QT_DIR,
        '--skip-build', '--skip-deploy', 'pack', '--msi')
}

Copy-Item -LiteralPath x64\Release -Destination C:\out\Jami -Recurse
if ($Msi) {
    $installer = @(Get-ChildItem -LiteralPath JamiInstaller\bin\Release\en-us -Filter 'jami-*.msi')
    if ($installer.Count -ne 1) {
        throw 'Expected one versioned MSI.'
    }
    Copy-Item -LiteralPath $installer[0].FullName -Destination C:\out
}
