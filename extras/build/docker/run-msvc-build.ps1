# Container entry point. Arguments are passed to build-windows.py.

$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string] $Program, [string[]] $Arguments)
    # With 'Stop', Windows PowerShell makes redirected native stderr fatal.
    $ErrorActionPreference = 'Continue'
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE)."
    }
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
Invoke-Checked git @('submodule', 'update', '--init', '--', 'daemon')
Invoke-Checked python @('extras\scripts\build-windows.py', '--init')

if ($env:JAMI_ACCEPT_WIX_EULA -eq '1') {
    Invoke-Checked dotnet @('build', 'JamiInstaller\JamiInstaller.wixproj', '-t:AcceptEula', '-p:EulaId=wix7')
}

# The container is discarded, so dependency build trees are only wasted space.
Invoke-Checked python (@('extras\scripts\build-windows.py', '--qt', $env:QT_DIR, '--clean-deps') + $args)

if (Test-Path -LiteralPath x64\Release\Jami.exe -PathType Leaf) {
    Copy-Item -LiteralPath x64\Release -Destination C:\out\Jami -Recurse
}
Get-ChildItem -LiteralPath JamiInstaller\bin\Release\en-us -Filter 'jami-*.msi' -ErrorAction SilentlyContinue |
    Copy-Item -Destination C:\out
