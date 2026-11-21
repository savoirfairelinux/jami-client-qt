# Copyright (C) 2019-2026 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.


<#
.SYNOPSIS
    Install the tools needed to build the Jami Qt client on Windows.

.DESCRIPTION
    Used on build hosts and by the Windows container image. A component that is
    already present is left untouched, so the script can be rerun safely and
    does not replace a host's existing Visual Studio, tools or Qt. Use -WhatIf
    to see what would be installed.

    VisualStudio  Visual Studio Build Tools with the C++ workload, unless
                  Visual Studio 2022 or later with the C++ tools is installed.
                  An existing one must also have ATL and a Windows SDK; the
                  script stops if it lacks them rather than modifying it.
                  Requires an elevated prompt.
    Tools         CMake, Git, Python, .NET SDK 8 or later (MSI packaging) and
                  Rust, each only if not found on PATH. Rust follows
                  CARGO_HOME and RUSTUP_HOME if set. The others go under
                  -ToolsDir.
    Qt            Qt from qt-6.12.0-msvc2022.lock into -QtDir, unless that
                  directory already holds a Qt kit.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('VisualStudio', 'Tools', 'Qt')]
    [string[]] $Component = @('VisualStudio', 'Tools', 'Qt'),
    [string] $ToolsDir = (Join-Path $env:LOCALAPPDATA 'Jami\build-tools'),
    [string] $QtDir = 'C:\Qt\6.12.0\msvc2022_64'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-Checked {
    param([string] $Program, [string[]] $Arguments)
    # With 'Stop', Windows PowerShell makes redirected native stderr fatal.
    $ErrorActionPreference = 'Continue'
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE)."
    }
}

function Receive-PinnedFile {
    param([string] $Url, [string] $Destination, [string] $Hash,
          [string] $Algorithm = 'SHA256')
    Invoke-Checked curl.exe @('--fail', '--show-error', '--silent', '--location',
        '--retry', '3', '--output', $Destination, $Url)
    if ((Get-FileHash -LiteralPath $Destination -Algorithm $Algorithm).Hash -ne $Hash) {
        throw "Unexpected $Algorithm checksum for $Url."
    }
}

# Extracts a pinned .zip or .7z archive. With -Subdir, only that top-level
# directory of the archive becomes $Destination.
function Install-Archive {
    param([string] $Url, [string] $Destination, [string] $Hash,
          [string] $Algorithm = 'SHA256', [string] $Subdir)
    # Work beside the destination, so that the final move stays on one volume.
    $parent = Split-Path $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $work = Join-Path $parent ('.jami-deps-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $work | Out-Null
    try {
        $archive = Join-Path $work 'archive'
        Receive-PinnedFile $Url $archive $Hash $Algorithm
        $target = if ($Subdir) { Join-Path $work 'x' } else { $Destination }
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        # bsdtar reads both formats, whatever the file name.
        Invoke-Checked tar.exe @('-xf', $archive, '-C', $target)
        if ($Subdir) {
            Move-Item -LiteralPath (Join-Path $target $Subdir) -Destination $Destination
        }
    } finally {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}

function Test-Command([string] $Name) {
    # Skip the Microsoft Store aliases, which only open the Store.
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
    if ($command) {
        Write-Host "$Name found: $($command.Source)"
    }
    return [bool] $command
}

function Assert-Elevated([string] $What) {
    $principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Installing $What requires an elevated prompt."
    }
}

function Install-VisualStudio {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $required = @('Microsoft.VisualStudio.Component.VC.Tools.x86.x64', 'Microsoft.VisualStudio.Component.VC.ATL')
    if (Test-Path -LiteralPath $vswhere) {
        $json = Invoke-Checked $vswhere @('-latest', '-products', '*', '-version', '[17.0,19.0)',
            '-requires', $required[0], '-include', 'packages', '-format', 'json')
        $existing = @(($json -join "`n") | ConvertFrom-Json)[0]
        if ($existing) {
            $ids = $existing.packages.id
            $missing = @($required | Where-Object { $_ -notin $ids })
            if (!($ids -match '^Microsoft\.VisualStudio\.Component\.Windows1[01]SDK\.\d+$')) {
                $missing += 'a Windows SDK (for example Microsoft.VisualStudio.Component.Windows11SDK.26100)'
            }
            if ($missing) {
                throw "Visual Studio at $($existing.installationPath) lacks $($missing -join ', '). Add them with the Visual Studio Installer."
            }
            Write-Host "Visual Studio with C++ tools found: $($existing.installationPath)"
            return
        }
    }
    # Fixed-version bootstrapper, not the moving Stable channel link.
    $version = '18.12.1'
    $hash = '6a3058c089e2564cac188178cf918d4cca106ea007f04c9f8bc52d7f5d7fe20f'
    if (!$PSCmdlet.ShouldProcess("Visual Studio Build Tools $version", 'Install')) { return }
    Assert-Elevated 'Visual Studio Build Tools'
    $installer = Join-Path $env:TEMP 'vs_BuildTools.exe'
    Receive-PinnedFile "https://download.visualstudio.microsoft.com/download/pr/646c5a89-4d3a-4f43-985e-9c4c6771f304/$hash/vs_BuildTools.exe" `
        $installer $hash
    $options = @('--quiet', '--wait', '--norestart', '--nocache',
        '--add', 'Microsoft.VisualStudio.Workload.VCTools',
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '--add', 'Microsoft.VisualStudio.Component.VC.ATL',
        '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.26100')
    $process = Start-Process -FilePath $installer -ArgumentList $options -Wait -PassThru
    Remove-Item -LiteralPath $installer
    if ($process.ExitCode -notin @(0, 3010)) {
        Get-ChildItem $env:TEMP -Filter 'dd_setup_*_errors.log' | Get-Content
        throw "Visual Studio setup failed (exit $($process.ExitCode))."
    }
    $instance = Invoke-Checked $vswhere @('-latest', '-products', 'Microsoft.VisualStudio.Product.BuildTools',
        '-format', 'json') | ConvertFrom-Json
    if ($instance.catalog.productDisplayVersion -ne $version) {
        throw "Expected Visual Studio $version; found $($instance.catalog.productDisplayVersion)."
    }
}

function Install-Tools {
    $added = @()
    if (!(Test-Command cmake) -and $PSCmdlet.ShouldProcess("$ToolsDir\cmake", 'Install CMake 4.2.5')) {
        Install-Archive 'https://github.com/Kitware/CMake/releases/download/v4.2.5/cmake-4.2.5-windows-x86_64.zip' `
            "$ToolsDir\cmake" '7eca5a76046d1b2fa2ba9e64b161e6d016c78470d9dfc6491a9f9ee666c7e2b4' `
            -Subdir 'cmake-4.2.5-windows-x86_64'
        $added += "$ToolsDir\cmake\bin"
    }
    if (!(Test-Command git) -and $PSCmdlet.ShouldProcess("$ToolsDir\git", 'Install MinGit 2.56.1')) {
        Install-Archive 'https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1/MinGit-2.56.1-64-bit.zip' `
            "$ToolsDir\git" '4a92850b6e917da4fd010669b614b55dccf5b0ec333a534cc4be4700dfefdafd'
        $added += "$ToolsDir\git\cmd"
    }
    # The NuGet package is a relocatable Python; it changes no registry or PATH.
    if (!(Test-Command python) -and $PSCmdlet.ShouldProcess("$ToolsDir\python", 'Install Python 3.13.12')) {
        Install-Archive 'https://api.nuget.org/v3-flatcontainer/python/3.13.12/python.3.13.12.nupkg' `
            "$ToolsDir\python" '389c0228afbb3530f6cd079f5cec44139b1441dd51c85ec704f7a63f1c9f3802' `
            -Subdir 'tools'
        $added += "$ToolsDir\python"
    }
    # A dotnet with only runtimes cannot build the installer.
    $dotnetSdks = if (Test-Command dotnet) {
        @(& { $ErrorActionPreference = 'Continue'; dotnet --list-sdks } | Where-Object { [int]($_ -split '\.')[0] -ge 8 })
    }
    if (!$dotnetSdks -and $PSCmdlet.ShouldProcess("$ToolsDir\dotnet", 'Install .NET SDK 10.0.404')) {
        Install-Archive 'https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.404/dotnet-sdk-10.0.404-win-x64.zip' `
            "$ToolsDir\dotnet" '330ddd2665b43cd2e428216a0d8ea1ac7bb19b5434fdc530e62010dc3b52823a620bf95489d628e1ed6f5122401793ee4887cca4a019122361a1231497f632ee' `
            -Algorithm SHA512
        $added += "$ToolsDir\dotnet"
        if (Get-Command dotnet -ErrorAction SilentlyContinue) {
            Write-Host "Put $ToolsDir\dotnet before the existing dotnet in PATH."
        }
    }
    $cargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $HOME '.cargo' }
    $cargoFound = Test-Command cargo
    if (!$cargoFound -and (Test-Path -LiteralPath "$cargoHome\bin\cargo.exe")) {
        Write-Host "cargo found: $cargoHome\bin\cargo.exe"
        $added += "$cargoHome\bin"
    } elseif (!$cargoFound -and $PSCmdlet.ShouldProcess('rustup', 'Install Rust 1.100.0')) {
        $installer = Join-Path $env:TEMP 'rustup-init.exe'
        Receive-PinnedFile 'https://static.rust-lang.org/rustup/archive/1.29.0/x86_64-pc-windows-msvc/rustup-init.exe' $installer `
            '86478e53f769379d7f0ebfa7c9aa97cb76ca92233f79aa2cc0dbee2efaac73c7'
        Invoke-Checked $installer @('-y', '--no-modify-path', '--profile', 'minimal',
            '--default-host', 'x86_64-pc-windows-msvc', '--default-toolchain', '1.100.0')
        Remove-Item -LiteralPath $installer
        $added += "$cargoHome\bin"
    }
    if ($added) {
        Write-Host 'Add these directories to PATH:'
        $added | ForEach-Object { Write-Host "  $_" }
    }
}

function Install-Qt {
    if (Test-Path -LiteralPath "$QtDir\bin\qtpaths.exe") {
        Write-Host "Qt found: $QtDir"
        return
    }
    if (!$PSCmdlet.ShouldProcess($QtDir, 'Install Qt 6.12.0')) { return }
    $base = 'https://download.qt.io/online/qtsdkrepository/windows_x86'
    foreach ($entry in Get-Content (Join-Path $PSScriptRoot 'qt-6.12.0-msvc2022.lock')) {
        if ($entry -match '^\s*(#.*)?$') { continue }
        $hash, $path = $entry -split '\s+', 2
        Install-Archive "$base/$path" $QtDir $hash
    }
    # These two Qt runtime archives contain DLLs at the archive root.
    Move-Item -LiteralPath "$QtDir\d3dcompiler_47.dll", "$QtDir\opengl32sw.dll" -Destination "$QtDir\bin"
    Set-Content -LiteralPath "$QtDir\bin\qt.conf" -Encoding Ascii -Value '[Paths]', 'Prefix=..'
    Invoke-Checked "$QtDir\bin\qtpaths.exe" @('--qt-version')
}

if ('VisualStudio' -in $Component) { Install-VisualStudio }
if ('Tools' -in $Component) { Install-Tools }
if ('Qt' -in $Component) { Install-Qt }
