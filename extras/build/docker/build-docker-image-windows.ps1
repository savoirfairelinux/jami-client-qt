# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2025 Savoir-faire Linux Inc.
#
# Builds the Windows MSVC Docker image, skipping the build if an image with the
# same Dockerfile content hash already exists locally.
#
# Usage:
#   .\build-docker-image-windows.ps1 [-Force] [-Tag <registry/name>]
#
# Options:
#   -Force    Always rebuild even if the image is cached
#   -Tag      Override the image name/tag prefix (default: jami-client-qt-windows-msvc)
#
# Running the container:
#   $imageTag = .\build-docker-image-windows.ps1
#   docker run --rm -v "${PWD}:C:\jami-client-qt" $imageTag
#
# Dev mode (iterate on pywinmake without rebuilding the image):
#   docker run --rm `
#     -v "C:\path\to\jami-client-qt:C:\jami-client-qt" `
#     -v "C:\path\to\pywinmake:C:\pywinmake" `
#     $imageTag
#   The container detects C:\pywinmake and installs it with pip before building.

param(
    [switch] $Force,
    [string] $Tag = "jami-client-qt-windows-msvc"
)

$ErrorActionPreference = "Stop"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot    = Resolve-Path (Join-Path $scriptDir "..\..\..")
$dockerfile  = Join-Path $scriptDir "Dockerfile.client-qt-windows-msvc"

# Compute a short hash of the Dockerfile to use as the image tag.
$hash = (Get-FileHash $dockerfile -Algorithm SHA256).Hash.Substring(0, 12).ToLower()
$imageTag = "${Tag}:${hash}"

Write-Host "Dockerfile hash : $hash"
Write-Host "Image tag       : $imageTag"

# Check whether an image with this tag already exists locally.
$existing = docker images --quiet $imageTag 2>$null
if ($existing -and !$Force) {
    Write-Host "Image '$imageTag' already exists locally - skipping build."
} else {
    if ($Force) { Write-Host "Force rebuild requested." }
    Write-Host "Building Docker image..."
    docker build `
        --progress=plain `
        --file $dockerfile `
        --tag  $imageTag `
        $repoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Image '$imageTag' built successfully."
}

# Print the resolved tag so callers can use it.
Write-Output $imageTag
