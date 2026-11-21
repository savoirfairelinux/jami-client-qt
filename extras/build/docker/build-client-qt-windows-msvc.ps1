<#
.SYNOPSIS
    Build the committed client tree in a Windows container.

.DESCRIPTION
    Arguments after -- are passed to build-windows.py in the container, for
    example: .\build-client-qt-windows-msvc.ps1 -- --tests
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string] $ArtifactsDir = 'build-artifacts\windows-msvc',
    [ValidateSet('process', 'hyperv')]
    [string] $Isolation = 'hyperv',
    # Hyper-V isolation defaults to 1 GB, too little for the client compile.
    [string] $Memory = '16g',
    [int] $Cpus = [Environment]::ProcessorCount,
    [switch] $AcceptWixEula,
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $BuildArgs = @()
)

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
$previous = docker image ls --quiet $image
Invoke-Checked docker @('build', "--isolation=$Isolation", "--memory=$Memory", '--force-rm',
    '--tag', $image, '--file', (Join-Path $PSScriptRoot 'Dockerfile.client-qt-windows-msvc'),
    (Join-Path $root 'extras'))
# A rebuilt image leaves the previous one untagged; remove it unless in use.
if ($previous -and $previous -ne (docker image ls --quiet $image)) {
    & { $ErrorActionPreference = 'Continue'; docker image rm $previous *> $null }
}

$inputDir = Join-Path ([IO.Path]::GetTempPath()) ('jami-build-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $inputDir | Out-Null
$bundle = Join-Path $inputDir 'client.bundle'
try {
    Invoke-Checked git @('-C', $root, 'bundle', 'create', $bundle, 'HEAD', '--tags')
    $dockerArgs = @('run', '--rm', "--isolation=$Isolation", "--memory=$Memory", "--cpus=$Cpus",
        '--mount', "type=bind,source=$inputDir,target=C:\input,readonly",
        '--mount', "type=bind,source=$output,target=C:\out")
    if ($AcceptWixEula) { $dockerArgs += '--env', 'JAMI_ACCEPT_WIX_EULA=1' }
    Invoke-Checked docker ($dockerArgs + $image + $BuildArgs)
} finally {
    # A container left running (client interrupted) keeps the input mounted.
    Remove-Item -LiteralPath $inputDir -Recurse -ErrorAction Continue
}
