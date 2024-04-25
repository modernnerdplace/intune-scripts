<#
.SYNOPSIS
This PowerShell script is designed to change the desktop background image on a Windows machine. It does this by downloading an image from a specified URL, saving it to a local path, and then updating the Windows Registry to use this image as the new desktop background. The script also checks and creates necessary directories and registry keys if they do not exist.

.DESCRIPTION
This PowerShell script is designed to change the desktop background image on a Windows machine.

.EXAMPLE
SetDesktopBackground.ps1

.PARAMETER
None

.NOTES
File Name      : SetDesktopBackground.ps1
Prerequisite   : PowerShell V2.0
#>


# Define the registry key path and values
$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

# Define the registry key values
$DesktopPath = "DesktopImagePath"
$DesktopStatus = "DesktopImageStatus"
$DesktopUrl = "DesktopImageUrl"

# Define the status value
$StatusValue = "1"

# Define the URL of the desktop image
$Url = "${SUPERVISION_DESKTOPIMAGE}"

# Get the extension of the URL (e.g., jpg, png, etc.)
$UrlExtension = $url.Split(".")[-1]

# Define the local path of the desktop image
$DesktopImageValue = "C:\Windows\DesktopImage.$UrlExtension"

# Define the directory path
$Directory = "C:\Windows\"

# Check if the directory exists, if not create it
If ((Test-Path -Path $Directory) -eq $false)
{
	New-Item -Path $Directory -ItemType directory
}

# Download the image from the URL and save it to the local path
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($Url, $DesktopImageValue)

# Check if the registry key path exists, if not create it
if (!(Test-Path $RegKeyPath))
{
	Write-Host "Creating registry path $($RegKeyPath)."
	New-Item -Path $RegKeyPath -Force | Out-Null
}

# Update the registry key values
New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null

# Update the desktop background
RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True