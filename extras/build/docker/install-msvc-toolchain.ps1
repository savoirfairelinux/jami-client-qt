param(
    [Parameter(Mandatory)]
    [ValidateSet('VisualStudio', 'Tools', 'Qt')]
    [string] $Component
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-Checked {
    param([string] $Program, [string[]] $Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE)."
    }
}

function Receive-PinnedFile {
    param(
        [string] $Url, [string] $Destination, [string] $Hash,
        [string] $Algorithm = 'SHA256'
    )
    Invoke-Checked curl.exe @('--fail', '--show-error', '--silent', '--location',
        '--retry', '3', '--output', $Destination, $Url)
    if ((Get-FileHash -LiteralPath $Destination -Algorithm $Algorithm).Hash -ne $Hash) {
        throw "Unexpected $Algorithm checksum for $Url."
    }
}

function Install-Archive {
    param(
        [string] $Url, [string] $Destination, [string] $Hash,
        [string] $Algorithm = 'SHA256'
    )
    $archive = Join-Path $env:TEMP ('jami-toolchain' + [IO.Path]::GetExtension($Url))
    Receive-PinnedFile $Url $archive $Hash $Algorithm
    if ($archive.EndsWith('.zip')) {
        Expand-Archive -LiteralPath $archive -DestinationPath $Destination
    } else {
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        Push-Location $Destination
        try {
            Invoke-Checked tar.exe @('-xf', $archive)
        } finally {
            Pop-Location
        }
    }
    Remove-Item -LiteralPath $archive
}

switch ($Component) {
    'VisualStudio' {
        # Fixed-version bootstrapper, not the moving Stable channel link.
        $version = '18.12.1'
        $hash = '6a3058c089e2564cac188178cf918d4cca106ea007f04c9f8bc52d7f5d7fe20f'
        $url = "https://download.visualstudio.microsoft.com/download/pr/646c5a89-4d3a-4f43-985e-9c4c6771f304/$hash/vs_BuildTools.exe"
        $installer = Join-Path $env:TEMP 'vs_BuildTools.exe'
        Receive-PinnedFile $url $installer $hash
        $options = @('--quiet', '--wait', '--norestart', '--nocache',
            '--installPath', 'C:\BuildTools',
            '--add', 'Microsoft.VisualStudio.Workload.VCTools',
            '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
            '--add', 'Microsoft.VisualStudio.Component.VC.ATL',
            '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.26100')
        $process = Start-Process -FilePath $installer -ArgumentList $options -Wait -PassThru
        if ($process.ExitCode -notin @(0, 3010)) {
            Get-ChildItem $env:TEMP -Filter 'dd_setup_*_errors.log' | Get-Content
            throw "Visual Studio setup failed (exit $($process.ExitCode))."
        }
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $instance = Invoke-Checked $vswhere @('-latest', '-products', 'Microsoft.VisualStudio.Product.BuildTools', '-format', 'json') |
            ConvertFrom-Json
        if ($instance.catalog.productDisplayVersion -ne $version) {
            throw "Expected Visual Studio $version; found $($instance.catalog.productDisplayVersion)."
        }
        Remove-Item -LiteralPath $installer
    }
    'Tools' {
        Install-Archive 'https://github.com/Kitware/CMake/releases/download/v4.2.5/cmake-4.2.5-windows-x86_64.zip' C:\ `
            '7eca5a76046d1b2fa2ba9e64b161e6d016c78470d9dfc6491a9f9ee666c7e2b4'
        Install-Archive 'https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1/MinGit-2.56.1-64-bit.zip' C:\git `
            '4a92850b6e917da4fd010669b614b55dccf5b0ec333a534cc4be4700dfefdafd'
        Install-Archive 'https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.404/dotnet-sdk-10.0.404-win-x64.zip' C:\dotnet `
            '330ddd2665b43cd2e428216a0d8ea1ac7bb19b5434fdc530e62010dc3b52823a620bf95489d628e1ed6f5122401793ee4887cca4a019122361a1231497f632ee' SHA512

        $installer = Join-Path $env:TEMP 'python-amd64.exe'
        Receive-PinnedFile 'https://www.python.org/ftp/python/3.13.12/python-3.13.12-amd64.exe' $installer `
            '96159fcb523ae404b707186a75b4104ee23851e476a5e838e14584cf1e03f981'
        $options = @('/quiet', 'InstallAllUsers=1', 'TargetDir=C:\python',
            'Include_doc=0', 'Include_launcher=0', 'Include_test=0', 'Include_tcltk=0')
        $process = Start-Process -FilePath $installer -ArgumentList $options -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Python setup failed (exit $($process.ExitCode))."
        }
        Remove-Item -LiteralPath $installer

        $installer = Join-Path $env:TEMP 'rustup-init.exe'
        Receive-PinnedFile 'https://static.rust-lang.org/rustup/archive/1.29.0/x86_64-pc-windows-msvc/rustup-init.exe' $installer `
            '86478e53f769379d7f0ebfa7c9aa97cb76ca92233f79aa2cc0dbee2efaac73c7'
        Invoke-Checked $installer @('-y', '--no-modify-path', '--profile', 'minimal',
            '--default-host', 'x86_64-pc-windows-msvc', '--default-toolchain', '1.100.0')
        Remove-Item -LiteralPath $installer

        foreach ($tool in @('cmake', 'git', 'python', 'cargo', 'dotnet')) {
            Invoke-Checked $tool @('--version')
        }
    }
    'Qt' {
        $base = 'https://download.qt.io/online/qtsdkrepository/windows_x86'
        foreach ($entry in Get-Content (Join-Path $PSScriptRoot 'qt-6.12.0-msvc2022.lock')) {
            if ($entry -match '^\s*(#.*)?$') { continue }
            $hash, $path = $entry -split '\s+', 2
            Install-Archive "$base/$path" $env:QT_DIR $hash SHA1
        }
        Set-Content -LiteralPath "$env:QT_DIR\bin\qt.conf" -Encoding Ascii -Value '[Paths]', 'Prefix=..'
        Invoke-Checked "$env:QT_DIR\bin\qtpaths.exe" @('--qt-version')
    }
}
