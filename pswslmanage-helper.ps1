###############################################################################################################
## Author: 						David Koenig
## Date: 						2022-02-22
## Description: 				Helper functions to manage a WSL
##
## Prerequisites (packages):
##		- You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11.
###############################################################################################################

#######################################################
# Function to invoke a command against the WSL 
#######################################################
function Invoke-WSLCommand {
    param(
        $Distribution=$null,
        $Command=$null,
        $User
    )

    if([string]::IsNullOrEmpty($Distribution)) {
       throw "No distribution set. Leaving."
    }

    if([string]::IsNullOrEmpty($Command)) {
       throw "No command given. Leaving."
    }

    $_wslProcess=(Start-Process -FilePath "wsl.exe" -ArgumentList "--distribution $Distribution --user $User -- $Command" -Wait -NoNewWindow -PassThru)

    if($_wslProcess.ExitCode -ne 0) {
        throw "Failed to execute command (Returncode: $($_wslProcess.ExitCode)). Command Details: ""$Command"". Leaving."
    }
}

##################################################################################
# Convert a given local path to a WSL path ("C:\..\.." to "/mnt/c/../..")
##################################################################################
function Convert-WSLPath {
    param(
        [string]$LocalPath
    )

    # Replace all backslashes with forward slashes
    $WSLPath=$LocalPath.Replace('\', '/')
    
    # Extract driveletter
    if($WSLPath.Substring(0,3) -like "?:/") { $_driveLetter=$WSLPath.Substring(0,1).ToLower() }

    # Replace "C:" with "/mnt/c"
    $WSLPath=$WSLPath.Replace($WSLPath.Substring(0,2), "/mnt/$_driveLetter")

    if(([string]::IsNullOrEmpty($WSLPath)) -or (-not ($WSLPath.StartsWith("/mnt/")))) {
        throw "Failed to get WSL path from local path."
    }
    return $WSLPath
}

##################################################################################
# Copy a folder to target system
##################################################################################
function Copy-WSLFolderToTarget {
    param(
        [string]$Distribution=$null,
        [string]$LocalPath,
        [string]$TargetPath,
        [string]$User
    )

    Write-Verbose "Convert local path to WSL path"
    $_wslSourcePath = Convert-WSLPath -LocalPath "$LocalPath"
    Invoke-WSLCommand -Distribution $Distribution -Command "cp -r ""$_wslSourcePath"" ""$TargetPath""" -User $User
}

##################################################################################
# Copy a file to target system
##################################################################################
function Copy-WSLFileToTarget {
    param(
        [string]$Distribution=$null,
        [string]$LocalPath,
        [string]$TargetPath,
        [string]$User
    )

    Write-Verbose "Convert local path to WSL path"
    $_wslSourcePath = Convert-WSLPath -LocalPath "$LocalPath"
    Invoke-WSLCommand -Distribution $Distribution -Command "cp ""$_wslSourcePath"" ""$TargetPath""" -User $User
}

##################################################################################
# Check local permissions
##################################################################################
function Test-WSLLocalAdmin {
    if ($True -eq ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
        throw "Script must run as normal user. Do NOT run in administrative context"
    } else {
        Write-Verbose "Script runs in normal user context. Thats fine. Going forward."
    }
}
