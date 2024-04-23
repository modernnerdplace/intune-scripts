$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

$DesktopPath = "DesktopImagePath"
$DesktopStatus = "DesktopImageStatus"
$DesktopUrl = "DesktopImageUrl"

$StatusValue = "1"

$Url = "https://wallpaperaccess.com/download/xp-90279" # CHANGE THIS VALUE
$DesktopImageValue = "C:\Windows\DesktopImage.jpg"
$Directory = "C:\Windows\"


If ((Test-Path -Path $Directory) -eq $false)
{
	New-Item -Path $Directory -ItemType directory
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($Url, $DesktopImageValue)

if (!(Test-Path $RegKeyPath))
{
	Write-Host "Creating registry path $($RegKeyPath)."
	New-Item -Path $RegKeyPath -Force | Out-Null
}

New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True