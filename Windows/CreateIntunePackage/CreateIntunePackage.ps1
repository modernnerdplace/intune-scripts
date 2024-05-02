<#
.SYNOPSIS

Special thanks to 1do for sponsoring this script!

This PowerShell script is used to set up utilities and tools for creating Intune packages. It checks for the existence of certain utilities and downloads them if they are not found.

.PARAMETER
The script uses a hashtable `$Params` to store paths to various utilities and directories. These include:

- `IntuneWinAppUtil`: Path to the Intune Windows App Utility.
- `ConvertExe`: Path to the ImageMagick convert utility.
- `ExtractIcon`: Path to the ExtractIcon utility.
- `TempMsiExtract`: Path to the temporary directory for MSI extraction.
- `OutputFolder`: Path to the output directory.
- `IconOutput`: Path to the directory for storing icons.
- `ScriptDir`: Directory of the current script.
- `FolderName`: Name of the folder containing the current script.
- `CurrentScriptName`: Name of the current script.

.FUNCTIONS
The script defines several functions:

- `DownloadTools`: Used to download the tools. The function takes three parameters: `UtilityPath`, `downloadUrl`, `targetFolder`.

- `SetupTools`: This function checks if a utility exists at the specified path. If not, it attempts to set up the utility using the `DownloadTools` function. If the setup fails, it prompts the user to manually download and place the utility at the specified path. The function takes three parameters: `UtilityPath`, `DownloadUrl`, `TargetFolder`.

- `CreateIntunePackage`: This function creates an Intune package using the Intune Windows App Utility. It takes several parameters including the source folder, setup file, output folder, and others.

- `ExtractIconFromExe`: This function extracts an icon from an executable file using the ExtractIcon utility. It takes two parameters: the path to the executable file and the output path for the icon.

- `ConvertIconToPng`: This function converts an icon file to a PNG image using the ImageMagick convert utility. It takes two parameters: the path to the icon file and the output path for the PNG image.

.LINK
ExtractIcon.exe: https://github.com/bertjohnson/ExtractIcon

ImageMagick - x64 16 bit Portable version - Only need convert.exe: https://imagemagick.org/script/download.php#windows

.USAGE
Place and run the script in an Administrator PowerShell console from the folder you want to create the intune package from. If a PowerShell script is selected for packaging, the script will also create a text file with the install and uninstall commands (if an uninstall script is found that starts with ).
If any of the utilities are missing, the script will prompt you to download and set up the utilities. If the automatic setup fails, you will be prompted to manually download and place the utility at the specified path.
#>



# Settable parameters
# User settable variables
$Params = @{
    'IntuneWinAppUtil' = "C:\Intune\testenv\IntuneWinAppUtil.exe"
    'ConvertExe'       = "C:\Intune\testenv\Tools\ImageMagick\convert.exe"
    'ExtractIcon'      = "C:\Intune\testenv\Tools\Extracticon\extracticon.exe"
    'TempMsiExtract'   = "C:\Temp\msi_extraction\"
    'OutputFolder'     = "C:\Intune\Output"
    'IconOutput'       = "C:\Intune\Logos"
}

# Non-user settable variables
$Params += @{
    'ScriptDir'        = Split-Path -Parent $MyInvocation.MyCommand.Definition
    'FolderName'       = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Leaf
    'CurrentScriptName'= $MyInvocation.MyCommand.Name
}


function DownloadTools {
    param (
        [string]$UtilityPath,
        [string]$downloadUrl,
        [string]$targetFolder
    )

    if (-not (Test-Path $UtilityPath)) {
        if (-not (Test-Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory | Out-Null
        }
        $userConsent = Read-Host "Utility missing at '$UtilityPath'. Download to '$targetFolder'? (Y/N)"
        if ($userConsent -eq 'Y') {
            try {
                Write-Output "Downloading to $UtilityPath..."
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($downloadUrl, $UtilityPath)
                Write-Output "Download completed."
            } catch {
                Write-Output "Download failed: $_.Exception.Message"
                return $false
            }
        } else {
            Write-Output "Download canceled by user."
            return $false
        }
    }
    return $true
}

function SetupTools {
    param (
        [string]$UtilityPath,
        [string]$DownloadUrl,
        [string]$TargetFolder
    )

    try {
        if (-not (Test-Path $UtilityPath)) {
            Write-Output "Error: Utility not found at: $UtilityPath"
            $checkUtility = DownloadTools -utilityPath $UtilityPath -downloadUrl $DownloadUrl -targetFolder $TargetFolder
            if ($checkUtility[1] -eq $false) {
                Write-Output "Setup of $UtilityPath is required for the script to continue, but the automatic setup has failed. Please download it manually and place it at the specified path."
                Write-Output "You can download the file from: $DownloadUrl"
                while (-not (Test-Path $UtilityPath)) {
                    $userResponse = Read-Host "Has the file been downloaded and placed the file at the location $UtilityPath, enter 'Y' to continue or 'N' to exit."
                    if ($userResponse -eq 'Y') {
                        break
                    } elseif ($userResponse -eq 'N') {
                        write-output "Cannot continue without this file. Exiting..."
                        exit
                    }
                }
            }
        }
    } catch {
        Write-Output "An error occurred while setting up the utility: $_.Exception.Message"
    }
}

function DisplayFilesAndPromptChoice($path, $extensions) {
    try {
        $files = Get-ChildItem -Path $path -File | Where-Object { $_.Extension -match $extensions -and $_.Name -ne $Params.CurrentScriptName }

        # Check if files are found
        if (-not $files) {
            Write-Host "No matching files found in the directory."
            exit
        }

        # Display files for user to choose using Write-Host
        $index = 1
        $files | ForEach-Object {
            Write-Host "$index. $($_.Name)"
            $index++
        }

        $choice = Read-Host "Enter the number of the file"
        Write-Host ""
        while ($choice -lt 1 -or $choice -gt $files.Count) {
            Write-Host "Invalid choice. Please choose a valid file number."
            $choice = Read-Host "Enter the number of the file"
        }
        
        return $files[$choice - 1]
    } catch {
        Write-Host "An error occurred while displaying files: $($_.Exception.Message)"
        exit
    }
}
function ExtractIconFromExecutableOrMSI {
    try {
        $selectedFile = DisplayFilesAndPromptChoice $Params.ScriptDir ".(exe|msi)$"
        
        # If MSI, extract contents and allow user to choose .exe
        if ($selectedFile.Extension -eq ".msi") {
            $processedMsi = $true
            $msiexecArgs = "/a `"$($selectedFile.FullName)`" /qb TARGETDIR=`"$($Params.TempMsiExtract)`""
            try {
                Start-Process -FilePath "msiexec.exe" -ArgumentList $msiexecArgs -Wait
            } catch {
                Write-Host "An error occurred while extracting MSI contents: $($_.Exception.Message)"
                exit
            }
            
            $exeFilesInMsi = Get-ChildItem -Path $Params.TempMsiExtract -Recurse | Where-Object { $_.Extension -eq ".exe" }
            $exeFilesDirectory = Join-Path $Params.TempMsiExtract "ExeFiles"
            if (-not (Test-Path $exeFilesDirectory)) { 
                try {
                    New-Item -Path $exeFilesDirectory -ItemType Directory -Force | Out-Null 
                } catch {
                    Write-Host "An error occurred while creating the directory for extracted EXE files: $($_.Exception.Message)"
                    exit
                }
            }

            # Move files with handling for name collisions
            $exeFilesInMsi | ForEach-Object {
            $destinationPath = Join-Path $exeFilesDirectory $_.Name
            $uniqueId = 1
            while (Test-Path $destinationPath) {
                $destinationPath = Join-Path $exeFilesDirectory ("$($_.BaseName)_$uniqueId$($_.Extension)")
                $uniqueId++
            }
            try {
                Move-Item -Path $_.FullName -Destination $destinationPath
            } catch {
                Write-Host "An error occurred while moving the extracted EXE file: $($_.Exception.Message)"
                exit
            }
            }
            
            # Start Explorer
            try {
                Start-Process explorer.exe -ArgumentList $exeFilesDirectory
            } catch {
                Write-Host "An error occurred while starting Explorer: $($_.Exception.Message)"
                exit
            }
            write-host "Please select the .exe file you want the icon to be extracted from."
            $selectedFile = DisplayFilesAndPromptChoice $exeFilesDirectory ".exe$"
        }
        
        try {
            # Extract Icon
            $tempOutputPngPath = Join-Path $Params.ScriptDir "temp_icon.png"
            Start-Process "$($Params.ExtractIcon)" -ArgumentList "`"$($selectedFile.FullName)`" `"$tempOutputPngPath`"" -Wait
        } catch {
            Write-Host "An error occurred while extracting the icon: $($_.Exception.Message)"
            exit
        }
    
        # Rename and move operations for the .png and .ico files
        $tempOutputPngPath = Join-Path $Params.ScriptDir "temp_icon.png"
        $finalPngPath = Join-Path $Params.ScriptDir "$($Params.FolderName).png"
    
        # Check if a file with the desired name already exists and remove it
        if (Test-Path $finalPngPath) {
            Remove-Item -Path $finalPngPath -Force
        }
    
        # Rename the PNG to match the folder name
        Rename-Item -Path $tempOutputPngPath -NewName "$($Params.FolderName).png"
    
        # Move the extracted icon to the specified IconOutputFolder
        if (-not (Test-Path $Params.IconOutput)) {
            New-Item -Path $Params.IconOutput -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $Params.ScriptDir "$($Params.FolderName).png") -Destination $Params.IconOutput -Force
    
        # Similar adjustments for the .ico file
        $pngFilePath = Join-Path $Params.ScriptDir "$($Params.FolderName).png"
        $icoOutputPath = Join-Path $Params.ScriptDir "$($Params.FolderName).ico"
        $ConvertExeLocation = $Params.ConvertExe
        try {
            Start-Process "$ConvertExeLocation" -ArgumentList "`"$pngFilePath`" -define icon:auto-resize=256,128,48,32,16 `"$icoOutputPath`"" -Wait
            Write-Output "PNG file converted to ICO successfully."
        } catch {
            Write-Host "An error occurred while converting the PNG file to ICO: $($_.Exception.Message)"
            exit
        }
    
        try {
            # Remove the dedicated directory containing the .exe files
            if ($processedMsi -and (Test-Path $exeFilesDirectory)) {
                Remove-Item -Path $exeFilesDirectory -Recurse -Force
            }
        } catch {
            Write-Host "An error occurred while removing the directory: $($_.Exception.Message)"
            Write-Host "Please manually delete the directory: $exeFilesDirectory"
        }
    
        # Remove the temporary .png file
        try {
            if (Test-Path $pngFilePath) {
            Remove-Item -Path $pngFilePath -Force
            }
        } catch {
            Write-Host "An error occurred while removing the temporary .png file: $($_.Exception.Message)"
            Write-Host "Please manually delete the file: $pngFilePath"
        }
        # Clean up the temp MSI extraction directory
        $msiExtractionPath = $Params.TempMsiExtract
        if (Test-Path $msiExtractionPath) {
            try {
            Write-Output "Cleaning up MSI extraction directory..."
            Remove-Item -Path $msiExtractionPath -Recurse -Force
            Write-Output "MSI extraction directory cleaned up."
            } catch {
            Write-Output "An error occurred while cleaning up the MSI extraction directory: $($_.Exception.Message)"
            Write-Output "Please manually delete the directory: $msiExtractionPath"
            }
        }
    
        # Inform the user
        Write-Output "Icon extracted in PNG format, renamed to $($Params.FolderName).png, and moved to $($Params.IconOutput)."
        Write-Output "PNG file converted to ICO and saved as $($Params.FolderName).ico."
        Write-Output "Temporary files have been cleaned up."
    } catch {
        Write-Output "An error occurred while extracting the icon: $($_.Exception.Message)"
    }
}
function GenerateIntuneWinPackages {
        try {
        $selectedFile = DisplayFilesAndPromptChoice $Params.ScriptDir ".(ps1|exe|bat|cmd|msi)$"
        
        $tempOutput = "$env:TEMP\IntuneOutput"
        if (-not (Test-Path $tempOutput)) {
            New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null
        }

        try {
            & $Params.IntuneWinAppUtil -c "$($Params.ScriptDir)" -s "$($selectedFile.Name)" -o "$tempOutput"
        } catch {
            Write-Host "An error occurred while running IntuneWinAppUtil: $($_.Exception.Message)"
            exit
        }

        # Rename and move the output file
        try {
            $originalOutputFile = Get-ChildItem -Path $tempOutput -Filter *.intunewin
            Rename-Item -Path $originalOutputFile.FullName -NewName "$($Params.FolderName).intunewin"
            Move-Item -Path "$tempOutput\$($Params.FolderName).intunewin" -Destination "$($Params.OutputFolder)" -Force
        } catch {
            Write-Host "An error occurred while renaming or moving the output file: $($_.Exception.Message)"
            exit
        }

        if ($selectedFile.Extension -eq ".ps1") {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($selectedFile.Name)
            $logFileName = "$baseName.txt"
            $installCommand = "Powershell.exe -NoProfile -ExecutionPolicy ByPass -Command ""& { .\$($selectedFile.Name) -Verbose *> %programdata%\Microsoft\IntuneManagementExtension\Logs\$logFileName }"""

            # Search for uninstall scripts
            $uninstallScript = Get-ChildItem -Path $Params.ScriptDir -Filter "*.ps1" | Where-Object {
                $_.Name -like "uninstall*" -or $_.Name -like "Undeploy*"
            } | Select-Object -First 1

            if ($null -eq $uninstallScript) {
                Write-Output "No specific uninstall script found, using install script for uninstall."
                $uninstallCommand = $installCommand
            } else {
                $uninstallLogFileName = "$($uninstallScript.BaseName).txt"
                $uninstallCommand = "Powershell.exe -NoProfile -ExecutionPolicy ByPass -Command ""& { .\$($uninstallScript.Name) -Verbose *> %programdata%\Microsoft\IntuneManagementExtension\Logs\$uninstallLogFileName }"""
            }

            $commandText = 
@"
Install command:

$installCommand

Uninstall command:

$uninstallCommand
"@
            $commandsFilePath = Join-Path $Params.ScriptDir "Install_Uninstall_Commands.txt"
            $commandText | Out-File $commandsFilePath -Force
            Write-Output "Commands file created at: $commandsFilePath"
            write-output ""
        }
        # Cleanup temporary folder
        try {
            Remove-Item -Path $tempOutput -Recurse -Force
        } catch {
            Write-Host "An error occurred while cleaning up the temporary folder: $($_.Exception.Message)"
        }
    } catch {
        Write-Output "An error occurred in the GenerateIntuneWinPackages function: $($_.Exception.Message)"
    }
}

# Script logic
Write-Host "_  _ ____ ___  ____ ____ _  _    _  _ ____ ____ ___  ___  _    ____ ____ ____ " -ForegroundColor Green
write-host "|\/| |  | |  \ |___ |__/ |\ |    |\ | |___ |__/ |  \ |__] |    |__| |    |___ " -ForegroundColor Green
write-host "|  | |__| |__/ |___ |  \ | \|    | \| |___ |  \ |__/ |    |___ |  | |___ |___ " -ForegroundColor Green
Write-host " "
Write-Host "_ _  _ ___ _  _ _  _ ____    ___  ____ ____ _  _ ____ ____ ____    ____ ____ _  _ ____ ____ ____ ___ ____ ____ " -ForegroundColor Green
write-host "| |\ |  |  |  | |\ | |___    |__] |__| |    |_/  |__| | __ |___    | __ |___ |\ | |___ |__/ |__|  |  |  | |__/ " -ForegroundColor Green
write-host "| | \|  |  |__| | \| |___    |    |  | |___ | \_ |  | |__] |___    |__] |___ | \| |___ |  \ |  |  |  |__| |  \ " -ForegroundColor Green
Write-Host "Made by Boyd Heeres" -ForegroundColor Darkblue
write-host " "

# Check Utility Existence
SetupTools -UtilityPath $Params.ConvertExe -DownloadUrl "https://github.com/Nakazen/MNP-intune-scripts/raw/main/Windows/CreateIntunePackage/Tools/convert.exe" -TargetFolder (Split-Path $Params.ConvertExe)
SetupTools -UtilityPath $Params.IntuneWinAppUtil -DownloadUrl "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/v1.8.6/IntuneWinAppUtil.exe" -TargetFolder (Split-Path $Params.IntuneWinAppUtil)
SetupTools -UtilityPath $Params.ExtractIcon -DownloadUrl "https://github.com/Nakazen/MNP-intune-scripts/raw/main/Windows/CreateIntunePackage/Tools/extracticon.exe" -TargetFolder (Split-Path $Params.ExtractIcon)

# Icon extraction
Write-Host "First time? Read the Synopsis and modify the Settable parameters section in the script." -ForegroundColor DarkGray
write-host " "
if ((Read-Host "Extract icon from executable or MSI? (Y/N)") -eq 'Y') {
    ExtractIconFromExecutableOrMSI
}

# Generate IntuneWin Packages
Write-host ""
Write-Host "Select the script or executable file to create an Intune package."
GenerateIntuneWinPackages

# Inform user
Read-Host "Press Enter to continue..."