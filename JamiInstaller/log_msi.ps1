# Run and log an MSI installation
# Usage: log_msi.ps1 <msi> <log>
# Example: log_msi.ps1 "C:\Program Files\MyApp\MyApp.msi" "C:\Program Files\MyApp\MyApp.log"
# If the log file already exists, it will be overwritten
# If the log file cannot be written due to permissions, a default write location will be used

# Get the MSI and log file paths
$msi = $args[0]
$log = $args[1]

# If no log file was specified, use the current directory
if ($null -eq $log) {
    $log = "msi_install.log"
}

# Check if the log file can be written
if (!(Test-Path $log)) {
    # If it can't, use the default write location
    $log = $env:TEMP + "\" + $log
}

# Check if the log file already exists
if (Test-Path $log) {
    # If it does, delete it
    Remove-Item $log
}

# Print the MSI and log file paths
Write-Host "MSI: $msi"
Write-Host "Log: $log"

# Run the MSI installation and wait for it to finish
msiexec /i $msi /L*V $log