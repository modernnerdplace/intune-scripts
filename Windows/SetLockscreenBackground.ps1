$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

$LockScreenPath = "LockScreenImagePath"
$LockScreenStatus = "LockScreenImageStatus"
$LockScreenUrl = "LockScreenImageUrl"

$StatusValue = "1"

$Url = "https://wallpaperaccess.com/download/xp-90279" # CHANGE THIS VALUE
$LockScreenImageValue = "C:\Windows\LockScreenImage.jpg"
$Directory = "C:\Windows\"


If ((Test-Path -Path $Directory) -eq $false)
{
	New-Item -Path $Directory -ItemType directory
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($Url, $LockScreenImageValue)

if (!(Test-Path $RegKeyPath))
{
	Write-Host "Creating registry path $($RegKeyPath)."
	New-Item -Path $RegKeyPath -Force | Out-Null
}

New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True