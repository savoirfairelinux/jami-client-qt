#!/usr/bin/env powershell
<# Description: This script will use wingetcreate to create a new manifest file for the
    package, and optionally submit it to the repository. This script wraps the wingetcreate
    tool, and helps extract the version from the MSI file prior to creating the manifest.
    The script handles remote MSI files, and will download remote MSI file to a temporary
    directory before extracting the version.
    
    The winget command may look like this:
    PS > wingetcreate.exe update --submit --token <GITHUB_API_TOKEN>
                --urls <InstallerUrl> --version <Version> <PackageIdentifier>
    
    Arguments:
    -PackageId: The package identifier
    -Url: The URL to the MSI file
    [-Version: The version of the MSI file]
    [-Submit: Submit the package to the repository]
    [-Token: The GitHub personal access token]
    
    Usage:
    PS > Update-WingetPackage -PackageId <PackageIdentifier> -Url <InstallerUrl>                                    
    
    This script requires the wingetcreate tool to be installed, and will install it if
    it is not already installed.
#>

function Update-WingetPackage {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageId,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Url,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Version,
        [parameter(Mandatory = $false)]
        [switch] $Submit,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    # Make sure wingetcreate is installed.
    if (-not (Get-Command wingetcreate -ErrorAction SilentlyContinue)) {
        Write-Host "Installing wingetcreate ..."
        winget install wingetcreate -e
    }

    # Optionally get the version of the MSI file from the URL.
    if (-not $Version) {
        $MsiPath = Get-LocalMsiPath -Url $Url
        $Version = Get-MsiVersion -Path $MsiPath
        Write-Host "Extracted version $Version from $Url."
        Remove-Item -Path $MsiPath -Force
    }

    # Update the package.
    Update-Package -PackageId $PackageId -Version $Version -Url $Url -Submit $Submit -Token $Token   
}

# Get the absolute path to the downloaded temp MSI file.
function Get-LocalMsiPath ($Url) {
    # Download the MSI file to a temporary file.
    $TempFile = [System.IO.Path]::GetTempFileName()
    $WebClient = New-Object System.Net.WebClient
    Write-Host "Downloading $Url to $TempFile ..."
    $WebClient.DownloadFile($Url, $TempFile)
    return (New-Object System.IO.FileInfo $TempFile)
}

# Extract the version from an MSI database.
function Get-MsiVersion {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo] $Path
    )
    try {
        $Installer = New-Object -com WindowsInstaller.Installer
        $Msi = $Installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $Installer, @($Path.FullName, 0))
        $Query = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $Msi.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Msi, ($Query))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) | Out-Null
        $Record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null )
        $Version = $Record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $Record, 1 )

        # Close the view and database objects.
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($View) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Msi) | Out-Null
        return $Version
    }
    catch {
        throw "Failed to get MSI file version: {0}." -f $_
    }    
}

# Submit the package to the repository.
function Update-Package ($PackageId, $Version, $Url, $Submit, $Token) {
    $Arguments = "update $PackageId --version $Version --urls $Url"
    if ($Submit) {
        if (-not $Token) {
            throw "The GitHub personal access token is required if -Submit is specified."
        }
        $Arguments += " --submit"
    }
    # The token can be supplied to undo the API rate limit when not submitting as well.
    if ($Token) {
        $Arguments += " --token $Token"
    }
    $Process = Start-Process -NoNewWindow -FilePath "wingetcreate" -ArgumentList $Arguments -Wait -PassThru
    if ($Process.ExitCode -ne 0) {
        throw "Failed to update the package."
    }
    else {
        Write-Host "Successfully updated the package."
    }
}
