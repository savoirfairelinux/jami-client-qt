param(
    [string] $ArtifactsDir = 'build-artifacts\windows-msvc',
    [ValidateSet('process', 'hyperv')]
    [string] $Isolation = 'process',
    [switch] $Tests,
    [switch] $Msi,
    [switch] $AcceptWixEula
)

$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([string] $Program, [string[]] $Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE)."
    }
}

if ($Msi -and !$AcceptWixEula) {
    throw 'Pass -AcceptWixEula with -Msi only after reviewing https://docs.firegiant.com/wix/osmf/.'
}
if ((Invoke-Checked docker @('info', '--format', '{{.OSType}}')) -ne 'windows') {
    throw 'Switch Docker to Windows containers before building Jami.'
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$changes = Invoke-Checked git @('-C', $root, 'status', '--porcelain', '--untracked-files=no',
    '--ignore-submodules=all')
if ($changes) {
    throw 'Commit tracked changes before building. The container builds only the committed tree.'
}
$output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ArtifactsDir)
if ((Test-Path -LiteralPath $output) -and (Get-ChildItem -LiteralPath $output -Force | Select-Object -First 1)) {
    throw "Artifact destination '$output' must be empty."
}
New-Item -ItemType Directory -Force -Path $output | Out-Null

$image = 'jami-client-qt-windows-msvc'
Invoke-Checked docker @('build', "--isolation=$Isolation", '--force-rm', '--tag', $image,
    '--file', (Join-Path $PSScriptRoot 'Dockerfile.client-qt-windows-msvc'), $PSScriptRoot)

$inputDir = Join-Path ([IO.Path]::GetTempPath()) ('jami-build-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $inputDir | Out-Null
$bundle = Join-Path $inputDir 'client.bundle'
try {
    Invoke-Checked git @('-C', $root, 'bundle', 'create', $bundle, 'HEAD', '--tags')
    $dockerArgs = @('run', '--rm', "--isolation=$Isolation",
        '--mount', "type=bind,source=$inputDir,target=C:\input,readonly",
        '--mount', "type=bind,source=$output,target=C:\out")
    if ($Msi) { $dockerArgs += '--env', 'JAMI_ACCEPT_WIX_EULA=1' }
    $dockerArgs += $image
    if ($Tests) { $dockerArgs += '-Tests' }
    if ($Msi) { $dockerArgs += '-Msi' }
    Invoke-Checked docker $dockerArgs
} finally {
    if (Test-Path -LiteralPath $bundle) { Remove-Item -LiteralPath $bundle }
    Remove-Item -LiteralPath $inputDir
}
