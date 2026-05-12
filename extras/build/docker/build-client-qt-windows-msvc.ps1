param(
    [string] $SourceDir = $env:JAMI_SOURCE_DIR,
    [string] $QtDir = $env:QT_DIR,
    [string] $SdkVersion = $env:WINDOWS_SDK_VERSION,
    [string] $TempDir = $env:JAMI_TEMP_DIR,
    [string] $DaemonCacheDir = $env:JAMI_DAEMON_CACHE_DIR,
    [switch] $Testing,
    [switch] $SkipInit
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SourceDir)) {
    $SourceDir = "C:\jami-client-qt"
}

if ([string]::IsNullOrWhiteSpace($QtDir)) {
    $QtDir = "C:\Qt\6.10.3\msvc2022_64"
}

if ([string]::IsNullOrWhiteSpace($SdkVersion)) {
    $SdkVersion = "10.0.26100.0"
}

if ([string]::IsNullOrWhiteSpace($TempDir)) {
    $TempDir = "C:\jami-tmp"
}

if (!(Test-Path $SourceDir)) {
    throw "Source directory '$SourceDir' does not exist. Mount the repository at this path or set JAMI_SOURCE_DIR."
}

$vsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (!(Test-Path $vsWhere)) {
    throw "vswhere.exe was not found at '$vsWhere'."
}

$vsPath = & $vsWhere -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ([string]::IsNullOrWhiteSpace($vsPath)) {
    throw "Visual Studio Build Tools with the MSVC x64 toolchain were not found."
}

$vcVars = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"
if (!(Test-Path $vcVars)) {
    throw "vcvarsall.bat was not found at '$vcVars'."
}

$vcVarsArgs = @("x64")
if (![string]::IsNullOrWhiteSpace($SdkVersion)) {
    $vcVarsArgs += $SdkVersion
}

$cmd = Join-Path $env:SystemRoot "System32\cmd.exe"
$vcEnvironment = & $cmd /s /c "`"$vcVars`" $($vcVarsArgs -join ' ') >nul && set"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

foreach ($line in $vcEnvironment) {
    if ($line -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

New-Item -ItemType Directory -Force $TempDir | Out-Null
$env:TEMP = $TempDir
$env:TMP = $TempDir

if ([string]::IsNullOrWhiteSpace($env:CMAKE_GENERATOR)) {
    $env:CMAKE_GENERATOR = "Visual Studio 18 2026"
}
if ([string]::IsNullOrWhiteSpace($env:CMAKE_GENERATOR_PLATFORM)) {
    $env:CMAKE_GENERATOR_PLATFORM = "x64"
}
$env:QT_QPA_PLATFORM = "offscreen"
$env:QT_QUICK_BACKEND = "software"
$env:QT_QPA_FONTDIR = Join-Path $SourceDir "resources\fonts"
$env:MSYS2_PATH_TYPE = "inherit"
if ([string]::IsNullOrWhiteSpace($env:JAMI_MSBUILD_MAX_CPU)) {
    $env:JAMI_MSBUILD_MAX_CPU = "4"
}
if ([string]::IsNullOrWhiteSpace($env:JAMI_FFMPEG_MAKE_JOBS)) {
    $env:JAMI_FFMPEG_MAKE_JOBS = "4"
}

git config --global --add safe.directory "*"

# Dev mode: if pywinmake source is mounted at C:\pywinmake, install it
# directly so the image doesn't need rebuilding during development.
if (Test-Path C:\pywinmake) {
    Write-Host "Dev mode: installing pywinmake from C:\pywinmake"
    python -m pip install --no-deps -q C:\pywinmake
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Set-Location $SourceDir

# Daemon contrib cache restore.
# The cache is keyed by the daemon submodule commit SHA so that a pre-built
# contrib tree is reused across builds that pin the same daemon revision.
# pywinmake reads the stamp files in contrib/build/ and skips packages that
# are already built, so simply copying them in is enough.
$daemonBuildDir = Join-Path $SourceDir "daemon\contrib\build"
$daemonSha = $null
if (![string]::IsNullOrWhiteSpace($DaemonCacheDir)) {
    $daemonSha = (git -C (Join-Path $SourceDir "daemon") rev-parse HEAD 2>$null)
    if ($daemonSha) {
        $cacheEntry = Join-Path $DaemonCacheDir $daemonSha
        if (Test-Path $cacheEntry) {
            Write-Host "Restoring daemon contrib cache for $daemonSha ..."
            New-Item -ItemType Directory -Force $daemonBuildDir | Out-Null
            robocopy $cacheEntry $daemonBuildDir /E /NFL /NDL /NJH /NJS | Out-Null
            Write-Host "Cache restored."
        } else {
            Write-Host "No daemon contrib cache found for $daemonSha — full build will run."
        }
    }
}

if (!$SkipInit) {
    python .\build.py --init --qt $QtDir
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$buildArgs = @(".\build.py", "--install", "--qt", $QtDir, "--sdk", $SdkVersion)
if ($Testing) {
    $buildArgs += "--testing"
}

python @buildArgs
$buildExitCode = $LASTEXITCODE

# Daemon contrib cache save (only on success so a failed/partial build is
# not cached and does not poison future runs).
if ($buildExitCode -eq 0 -and
    ![string]::IsNullOrWhiteSpace($DaemonCacheDir) -and
    $daemonSha -and
    (Test-Path $daemonBuildDir)) {
    $cacheEntry = Join-Path $DaemonCacheDir $daemonSha
    Write-Host "Saving daemon contrib cache for $daemonSha ..."
    New-Item -ItemType Directory -Force $cacheEntry | Out-Null
    robocopy $daemonBuildDir $cacheEntry /E /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "Cache saved."
}

exit $buildExitCode
