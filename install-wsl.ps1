###############################################################################################################
## Author: 						David Koenig
## Date: 						2023-08-18
## Description: 				Installs an Ubuntu WSL on your maschine
##
## Prerequisites (packages):
##		- You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11.
###############################################################################################################

<#
    .SYNOPSIS
        Install a WSL on your local maschine.

    .DESCRIPTION
        Install a WSL on your local maschine which will be well-configured and has created 2 users.

    .PARAMETER WslConfigPath
        The path to an JSON formatted configuration file. 
        Example for a configuration file: 
        {
            "wslBasePath":"${env:localappdata}\\<YOURPROJECT>\\wsl",
            "wslDistroPath":"distros",
            "wslName":"shiftavenue-ci",
            "wslRemoveExisting":"True",
            "wslRootPwd":"Start123",
            "wslWorkUser":"Work",
            "wslWorkUserPwd":"Start123",
            "wslWorkUserSSHPubKey":"dummy"
        }

    .PARAMETER WslName
        The name of the WSL-image you want to create.

    .PARAMETER WslRemoveExisting
        If true, a WSL image with the given name will be deleted first. Otherwise the existing image will be updated.
        This parameter overwrite a given parameter in wslconfig-file.

    .PARAMETER WslRootPwd
        The root password.

    .PARAMETER WslWorkUser
        A user which you can use for daily work.

    .PARAMETER WslWorkUserPwd
        The password for the work user. 
    
    .PARAMETER WslWorkUserDefault
        If set, the work user will get the default user of the WSL. 

    .PARAMETER WslWorkUserSSHPubKey
        The SSH key for the work user.

    .PARAMETER WslSshServer
        Decide to install a SSH server.

    .PARAMETER WslSshServerPort
        Define the SSH server port.

    .EXAMPLE
        .\install-wsl.ps1
        Use the configuration file which is stored at $PSScriptRoot\install-wsl.json

    .EXAMPLE
        .\install-wsl.ps1 -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslWorkUser work -WslRootPwd "Start123" -WslWorkUserPwd "Start123" -Verbose
        Ignore configuration file and configure the WSL with parameters
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$WslConfigPath="$PSScriptRoot/install-wsl.secret",
    
    [Parameter(Mandatory=$false)]
    [string]$WslName = "MyProject",
    
    [Parameter(Mandatory=$false)]
    [switch]$WslRemoveExisting,
    
    [Parameter(Mandatory=$false)]
    [string]$WslRootPwd = "Start123",
    
    [Parameter(Mandatory=$false)]
    [string]$WslWorkUser = "work",
    
    [Parameter(Mandatory=$false)]
    [switch]$WslWorkUserDefault,
    
    [Parameter(Mandatory=$false)]
    [string]$WslWorkUserPwd = "Start123",
    
    [Parameter(Mandatory=$false)]
    [string]$WslWorkUserSSHPubKey = "dummy",
    
    [Parameter(Mandatory=$false)]
    [switch]$WslSshServer,
    
    [Parameter(Mandatory=$false)]
    [int]$WslSshServerPort,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Ubuntu2004", "Ubuntu2204")]
    [string]$WslDistroName
)

# Show header
# Generated with https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Standard&text=WSL
Write-Verbose "__        ______  _     "
Write-Verbose "\ \      / / ___|| |    "
Write-Verbose " \ \ /\ / /\___ \| |    "
Write-Verbose "  \ V  V /  ___) | |___ "
Write-Verbose "   \_/\_/  |____/|_____|"
Write-Verbose "Installation script for a WSL image"                       

##################################################################################
# Include helper
##################################################################################
. $PSScriptRoot/install-wsl-helper.ps1

##################################################################################
# Set static variables
##################################################################################
$_wslDistroPath = "distros"
$_wslBaseImagePath = "${env:localappdata}\shiftavenue\wsl\baseimg"
$_wslManageUserScript = "$PSScriptRoot/create-linux-user-with-ssh.sh"
$_wslJson = $null
$_wslMinMajorVersion = 5
$_wslMinMinorVersion = 10
$_wslDisableKernelCheck = $False # This is for an emergency case and allows you to disable the kernel version
$_wslImageExist = $False

##################################################################################
# Get the distribution details from json file
##################################################################################

if(-Not (Test-Path -Path "$PSScriptRoot\pswslmanage-distrolist.json")) {
    throw """pswslmanage-distrolist.json"" file does not exist. Exiting."
}

$_wslConfig = Get-Content "$PSScriptRoot\pswslmanage-distrolist.json" | ConvertFrom-Json
foreach($_wslDistro in $_wslConfig.wslDistroList) { 
    if ($_wslDistro.wslDistroUniqueName -eq $WslDistroName) { 
        $_wslDistroUniqueName = $_wslDistro.wslDistroUniqueName
        $_wslDistroUrl = $_wslDistro.wslDistroUrl
        $_wslDistroVersion = $_wslDistro.wslDistroVersion
        $_wslDistroX64FileName = $_wslDistro.wslDistroX64FileName
    }
}
##################################################################################
# Read config file
##################################################################################

if (![string]::IsNullOrEmpty($WslConfigPath)) {
    if (Test-Path -Path "$WslConfigPath") {
        try {
            Write-Verbose "Load configuration file from ""$WslConfigPath"""
            $_wslJson=Get-Content "$WslConfigPath" -Raw | ConvertFrom-Json
        } catch {
            throw "Failed to load configuration file ""$WslConfigPath"". Details: $_"
        }
    }
}

##################################################################################
# Set dynamic variables
##################################################################################

if($null -eq $_wslJson) {
    Write-Verbose "No configuration file found"
    [string]$_wslBasePath = "${env:localappdata}\shiftavenue\wsl"
    [string]$_wslName = $WslName
    [bool]$_wslRemoveExisting = $WslRemoveExisting
    [string]$_wslRootPwd = $WslRootPwd
    [string]$_wslWorkUser = $WslWorkUser
    [bool]$_wslWorkUserDefault = $WslWorkUserDefault
    [string]$_wslWorkUserPwd = $WslWorkUserPwd
    [string]$_wslWorkUserSSHPubKey = $WslWorkUserSSHPubKey
    [string]$_wslSshServer = $WslSshServer
    [int]$_wslSshServerPort = $WslSshServerPort
    [string]$_wslDistroName = $WslDistroName
} else {
    Write-Verbose "Found configuration file in ""$WslConfigPath"""
    [string]$_wslBasePath =  $ExecutionContext.InvokeCommand.ExpandString($_wslJson.wslBasePath)
    [string]$_wslDistroPath = $_wslJson.wslDistroPath
    [string]$_wslName = $_wslJson.wslName
    [bool]$_wslRemoveExisting = $_wslJson.wslRemoveExisting
    [string]$_wslRootPwd = $_wslJson.wslRootPwd
    [string]$_wslWorkUser = $_wslJson.wslWorkUser
    [bool]$_wslWorkUserDefault = $_wslJson.wslWorkUserDefault
    [string]$_wslWorkUserPwd = $_wslJson.wslWorkUserPwd
    [string]$_wslWorkUserSSHPubKey = $_wslJson.wslWorkUserSSHPubKey
    [string]$_wslSshServer = $_wslJson.wslSshServer
    [int]$_wslSshServerPort = $_wslJson.wslSshServerPort
    [string]$_wslDistroName = $_wslJson.wslDistroName
}

# Its possible to combine config with the parameter "WSLRemoveExisting". Let overwrite it here, so parameter will win in every case
[bool]$_wslRemoveExisting = $WslRemoveExisting

$_wslDistroUrl = $_wslDistroList["$_wslDistro"]

##################################################################################
# Check prerequisites
##################################################################################

# Check admin permissions. Will fail if process runs "as admin"
Test-WSLLocalAdmin

# Extract kernel version from cmdline output (not the best method, but the only one i found) and test version
if($False -eq $_wslDisableKernelCheck) {
    $_wslKernelVersion=(((wsl.exe --status).Replace("`0","")).trim() | ForEach-Object { if (![string]::IsNullOrEmpty($_) -and ($_ -like "Kernel?Version:*")){Write-Output "$_"} })

    if(![string]::IsNullOrEmpty($_wslKernelVersion)) {
        $_wslKernelVersion=$_wslKernelVersion.split(":")[1].Trim()
        $_wslKernelMajor = $_wslKernelVersion.split(".")[0]
        $_wslKernelMinor = $_wslKernelVersion.split(".")[1]
        if(($_wslKernelMajor -ge $_wslMinMajorVersion) -and ($_wslKernelMinor -ge $_wslMinMinorVersion)) {
        } else { 
            throw "You need at minimum kernel version $_wslMinMajorVersion.$_wslMinMinorVersion. Installed version is $_wslKernelMajor.$_wslKernelMinor."
        }
    } else {
        throw "Cannot identify kernel version. Exiting. "
    }
} else {
    Write-Host "Kernel version check is disabled. Use this script on your own risk."
}

# Check if image already exist
if(((wsl.exe -l).Replace("`0","")) -like "*${_wslName}*") {
    $_wslImageExist = $True
}

##################################################################################
# Output for debugging
##################################################################################
Write-Verbose "Print variables:"
Write-Verbose "Base storage path for wsl:                 $_wslBasePath"
Write-Verbose "Sub folder for your wsl images:            $_wslDistroPath"
Write-Verbose "Sub folder for caching distribution files: $_wslBaseImagePath"
Write-Verbose "Name for the wsl image:                    $_wslName"
Write-Verbose "Remove existing wsl image:                 $_wslRemoveExisting"
Write-Verbose "Work user:                                 $_wslWorkUser"
Write-Verbose "Set work user as default:                  $_wslWorkUserDefault"
Write-Verbose "Linux kernel version:                      $_wslKernelMajor.$_wslKernelMinor"
Write-Verbose "WSL image exist:                           $_wslImageExist"
Write-Verbose "Install a SSH server:                      $_wslSshServer"
Write-Verbose "SSH server port:                           $_wslSshServerPort"

#######################################################
# Remove existing WSL and related files
#######################################################
if($_wslRemoveExisting -and $_wslImageExist) {
    Write-Verbose "Image exist. Unregister existing WSL image."
    wsl --unregister ${_wslName}
    $_wslCmdReturn=$?
    if($_wslCmdReturn -ne $True) {
        throw "Failed to unregister. Leaving."
    }

    if (Test-Path "$_wslBasePath\$_wslDistroPath\$_wslName") {
        Write-Verbose "Remove existing image files."
        Remove-Item -Path "$_wslBasePath\$_wslDistroPath\$_wslName" -Recurse -Force
    }
} else {
    Write-Verbose "Image exist and will just be update. Skipping refresh process."
}

#######################################################
# Download appx image
#######################################################
# If image doesn't exist or previous version should be removed, lets download the sources and create the WSL image
if(-not ($_wslRemoveExisting -or (-not $_wslImageExist))) {
    Write-Verbose "Image exist and should not be refreshed. Skipping download and installation process."
} else { 

    if (-Not (Test-Path -Path "$_wslBaseImagePath\$_wslDistroName.tar.gz")) {
        Write-Verbose "AppX-Image doesn't exist. Create it."

        if (-Not (Test-Path -Path "$_wslBaseImagePath")) {
            Write-Verbose "Create base image path ($_wslBaseImagePath)"
            New-Item -Path "$_wslBaseImagePath" -ItemType Directory  | Out-Null 
        }

        if (-Not (Test-Path -Path "$_wslBaseImagePath\$_wslDistroName.appx")) { 
            Write-Verbose "Download the image"
            Invoke-WebRequest -Uri "$_wslDistroUrl" -OutFile "$_wslBaseImagePath\$_wslDistroName.appx" -UseBasicParsing
        }

        $_wslDistroUniqueName = $_wslDistro.wslDistroUniqueName
        $_wslDistroUrl = $_wslDistro.wslDistroUrl
        $_wslDistroVersion = $_wslDistro.wslDistroVersion
        $_wslDistroX64FileName = $_wslDistro.wslDistroX64FileName

        Write-Verbose "Extract the image (phase 1)"
        Rename-Item "$_wslBaseImagePath\$_wslDistro.appx" "$_wslBaseImagePath\$_wslDistroName.zip"
        Expand-Archive -Path "$_wslBaseImagePath\$_wslDistroName.zip" -DestinationPath "$_wslBaseImagePath\$_wslDistroName" -Force | Out-Null

        Write-Verbose "Extract the image (phase 2)"
        Rename-Item "$_wslBaseImagePath\$_wslDistroName\$_wslDistroX64FileName.appx" "$_wslBaseImagePath\$_wslDistroName\$_wslDistroName-x64.zip"
        Expand-Archive -Path "$_wslBaseImagePath\$_wslDistroName\$_wslDistroName-x64.zip" -DestinationPath "$_wslBaseImagePath\$_wslDistroName\$_wslDistroName-x64" -Force | Out-Null
        Move-Item "$_wslBaseImagePath\$_wslDistroName\$_wslDistroName-x64\install.tar.gz" "$_wslBaseImagePath\$_wslDistroName-x64.tar.gz"
        
        Write-Verbose "Cleanup"
        Remove-Item -Path "$_wslBaseImagePath\$_wslDistroName" -Recurse -Force
        Remove-Item -Path "$_wslBaseImagePath\$_wslDistroName.zip" -Recurse -Force
    }


    #######################################################
    # Create the distribution
    #######################################################
    # Thats a bit tricky, because wsl print some null values you have to remove before comparing the string

    Write-Verbose "WSL instance ""${_wslName}"" not found. Create it."
    if (-Not (Test-Path -Path "$_wslBasePath\$_wslDistroPath")) { 
        Write-Verbose "Create WSL distro directory"
        New-Item -Name $_wslDistroPath -ItemType Directory -Path $_wslBasePath | Out-Null
    } 

    if (-Not (Test-Path -Path "$_wslBasePath\$_wslDistroPath\$_wslName")) { 
        Write-Verbose "Create WSL directory"
        New-Item -Name $_wslName -ItemType Directory -Path $_wslBasePath\$_wslDistroPath | Out-Null 
    } 
    Write-Verbose "Create the WSL environment"
    wsl --import $_wslName "$_wslBasePath\$_wslDistroPath\$_wslName" "$_wslBaseImagePath\ubuntu-20.04.03-x64.tar.gz" --version 2
    $_wslCmdReturn=$?
    if($_wslCmdReturn -ne $True) {
        throw "Failed to import. Leaving."
    }
}

#######################################################
# Manage the VM (update and all that shit)
#######################################################

Write-Verbose "Update packages"
Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt update -y" -User root

Write-Verbose "Upgrade packages (Please be patient, this can take a while)"
Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt upgrade -y" -User root

Write-Verbose "Removing packages that are not needed anymore"
Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt autoremove -y" -User root

#######################################################
# Manage the users in WSL image
#######################################################

Write-Verbose "Set root password"
Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""sudo echo root:$_wslRootPwd | chpasswd""" -User root

if((-Not [string]::IsNullOrEmpty($_wslWorkUser)) -or (-Not [string]::IsNullOrEmpty($_wslMgmtUser))) {
    Write-Verbose "Create user for work and management"
    
    Write-Verbose "Copy script to manage users"
    Copy-WSLFileToTarget -Distribution $_wslName -LocalPath "$_wslManageUserScript" -TargetPath "/root/manage-users.sh" -User root
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""chmod +x /root/manage-users.sh""" -User root
    
    Write-Verbose "Invoke manage user command for work user"
    $_wslBashCommand=$ExecutionContext.InvokeCommand.ExpandString("/root/manage-users.sh --username ""$_wslWorkUser"" --password ""$_wslWorkUserPwd"" --pubkey ""$_wslWorkUserSSHPubKey"" --sudoperm 1")
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""$_wslBashCommand""" -User root

    Write-Verbose "Reset wsl-conf"
    $_wslInstallationDate=$(Get-Date -Format 'yyyy-mm-dd_HH:MM:ss')
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[info]"" > /etc/wsl.conf""" -User root
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""changedate=$_wslInstallationDate"" >> /etc/wsl.conf""" -User root

    Write-Verbose "Set hostname to wsl name"
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[network]"" >> /etc/wsl.conf""" -User root
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""hostname=$_wslName"" >> /etc/wsl.conf""" -User root

    if($_wslWorkUserDefault) {
        Write-Verbose "Make work user the default user"
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[user]"" >> /etc/wsl.conf""" -User root
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""default=$_wslWorkUser"" >> /etc/wsl.conf""" -User root
    }
    
    Write-Verbose "Invoke manage user command for management user"
    $_wslBashCommand=$ExecutionContext.InvokeCommand.ExpandString("/root/manage-users.sh --username ""$_wslMgmtUser"" --password ""$_wslMgmtUserPwd"" --pubkey ""$_wslMgmtUserSSHPubKey"" --sudonopwd 1")
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""$_wslBashCommand""" -User root
    Invoke-WSLCommand -Distribution $_wslName -Command "rm -f ""root\manage-users.sh""" -User root
}

#######################################################
# Finalize
#######################################################
Write-Verbose "Cleanup"
$_wslBasePath = ""
$_wslDistroPath = ""
$_wslBaseImagePath = ""
$_wslName = ""
$_wslRemoveExisting = $False
$_wslRootPwd = ""
$_wslWorkUser = ""
$_wslWorkUserPwd = ""
$_wslWorkUserSSHPubKey = ""
$_wslMgmtUser = ""
$_wslMgmtUserPwd = ""
$_wslMgmtUserSSHPubKey = ""

Write-Verbose "Shutdown WSL"
wsl --shutdown --distribution $_wslName
$_wslCmdReturn=$?
if($_wslCmdReturn -ne $True) {
    throw "Failed to import. Leaving."
}
