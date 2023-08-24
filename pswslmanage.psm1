###############################################################################################################
## Author: 						David Koenig
## Date: 						2023-08-18
## Description: 				Installs an Ubuntu WSL on your maschine
##
## Prerequisites (packages):
##		- You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11.
###############################################################################################################

. $PSScriptRoot/pswslmanage-helper.ps1
. $PSScriptRoot/pswslmanage-roles.ps1

function Add-WslImage {
    <#
        .SYNOPSIS
            Install a WSL on your local maschine.

        .DESCRIPTION
            Install a WSL on your local maschine which will be well-configured and has created 2 users.

        .PARAMETER WslConfigPath
            The path to an JSON formatted configuration file. Default is "$PSScriptRoot/pswslmanage.secret".
            If fiel exist but you want to work with parameters, please specify parameter with an empty string.
            Example for a configuration file:
            {
                "wslBasePath":"${env:localappdata}\\<YOURPROJECT>\\wsl",
                "wslDistroPath":"distros",
                "wslName":"shiftavenue-ci",
                "wslRemoveExisting":1,
                "wslRootPwd":"Start123",
                "wslWorkUser":"Work",
                "wslWorkUserDefault":1,
                "wslWorkUserPwd":"Start123",
                "wslWorkUserSSHPubKey":"dummy",
                "wslMgmtUser":"ansible",
                "wslMgmtUserPwd":"Start123",
                "wslMgmtUserSSHPubKey":"5j43tz098t988jv98wh875hzgtiuh7843578trh...98uh= ansible",
                "wslSshServer":1,
                "wslSshServerPort":30122,
                "wslDistroName":"Ubuntu2204"
            }

        .PARAMETER WslBasePath
            The work directory used for all files. Default is "${env:localappdata}\shiftavenue\wsl".

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

        .PARAMETER WslDistroName
            Define the name of the distribution you want to install.

        .EXAMPLE
            .\Add-WSLImage.ps1
            Use the configuration file which is stored at $PSScriptRoot\pswslmanage.secret

        .EXAMPLE
            .\Add-WSLImage.ps1 -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslWorkUser work -WslRootPwd "Start123" -WslWorkUserPwd "Start123" -WslWorkUserDefault -WslDistroName Ubuntu2204
            Ignore configuration file and configure the WSL with parameters

        .EXAMPLE
            .\Add-WSLImage.ps1 -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslRootPwd "Start123" -WslWorkUser work -WslWorkUserPwd "Start123" -WslWorkUserDefault -WslWorkUserSSHPubKey "ssh-rsa as4f$j..." -WslSshServer -WslSshPort 30122 -WslDistroName Ubuntu2204
            Ignore configuration file and configure the WSL with parameters
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$WslConfigPath="$PSScriptRoot/pswslmanage.secret",

        [Parameter(Mandatory=$false)]
        [string]$WslBasePath = "${env:localappdata}\shiftavenue\wsl",

        [Parameter(Mandatory=$false)]
        [string]$WslName = "MyProject",

        [Parameter(Mandatory=$false)]
        [switch]$WslRemoveExisting,

        [Parameter(Mandatory=$false)]
        [string]$WslRootPwd = "Start123",

        [Parameter(Mandatory=$false)]
        [string]$WslWorkUser = "work",

        [Parameter(Mandatory=$false)]
        [string]$WslWorkUserPwd = "Start123",

        [Parameter(Mandatory=$false)]
        [string]$WslWorkUserSSHPubKey = "dummy",

        [Parameter(Mandatory=$false)]
        [switch]$WslWorkUserDefault,

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
    Write-Output "__        ______  _     "
    Write-Output "\ \      / / ___|| |    "
    Write-Output " \ \ /\ / /\___ \| |    "
    Write-Output "  \ V  V /  ___) | |___ "
    Write-Output "   \_/\_/  |____/|_____|"
    Write-Output "Installation script for a WSL image"

    ##################################################################################
    # Set static variables
    ##################################################################################
    $_wslDistroPath = "distros"
    $_wslBaseImagePath = "baseimg"
    $_wslManageUserScript = "$PSScriptRoot/pswslmanage-create-linux-user.sh"
    $_wslJson = $null
    $_wslMinMajorVersion = 5
    $_wslMinMinorVersion = 10
    $_wslDisableKernelCheck = $False # This is for an emergency case and allows you to disable the kernel version
    $_wslImageExist = $False

    ##################################################################################
    # Read config file
    ##################################################################################

    if (![string]::IsNullOrEmpty($WslConfigPath)) {
        if (Test-Path -Path "$WslConfigPath") {
            try {
                Write-Output "Load configuration file from ""$WslConfigPath"""
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
        Write-Output "No configuration file found"
        [string]$_wslBasePath = $WslBasePath
        [string]$_wslName = $WslName
        [bool]$_wslRemoveExisting = $WslRemoveExisting
        [string]$_wslRootPwd = $WslRootPwd
        [string]$_wslWorkUser = $WslWorkUser
        [bool]$_wslWorkUserDefault = $WslWorkUserDefault
        [string]$_wslWorkUserPwd = $WslWorkUserPwd
        [string]$_wslWorkUserSSHPubKey = $WslWorkUserSSHPubKey
        [string]$_wslSshServer = $WslSshServer
        [int]$_wslSshServerPort = $WslSshServerPort
        [string]$_wslDistroUniqueName = $WslDistroName
    } else {
        Write-Output "Found configuration file in ""$WslConfigPath"""
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
        [string]$_wslDistroUniqueName = $_wslJson.wslDistroName
    }

    ##################################################################################
    # Get the distribution details from json file
    ##################################################################################

    if(-Not (Test-Path -Path "$PSScriptRoot\pswslmanage-distrolist.json")) {
        throw """pswslmanage-distrolist.json"" file does not exist. Exiting."
    }

    $_wslConfig = Get-Content "$PSScriptRoot\pswslmanage-distrolist.json" | ConvertFrom-Json
    foreach($_wslDistro in $_wslConfig.wslDistroList) {
        if ($_wslDistro.wslDistroUniqueName -eq $_wslDistroUniqueName) {
            $_wslDistroUrl = $_wslDistro.wslDistroUrl
            $_wslDistroX64FileName = $_wslDistro.wslDistroX64FileName
        }
    }

    if([string]::IsNullOrEmpty($_wslDistroUrl)) {
        throw "Failed to set the variable ""_wslDistroUrl"" from distrolist.json."
    }
    if([string]::IsNullOrEmpty($_wslDistroX64FileName)) {
        throw "Failed to set the variable ""_wslDistroX64FileName"" from distrolist.json."
    }

    ##################################################################################
    # Check prerequisites
    ##################################################################################

    # Check admin permissions. Will fail if process runs "as admin"
    Test-WSLLocalAdmin

    # Extract kernel version from cmdline output (not the best method, but the only one i found) and test version
    if($False -eq $_wslDisableKernelCheck) {
        $_wslKernelVersion=(((wsl.exe --version).Replace("`0","")).trim() | ForEach-Object { if (![string]::IsNullOrEmpty($_) -and ($_ -like "Kernelversion:*")){Write-Output "$_"} })

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
        Write-Output "Kernel version check is disabled. Use this script on your own risk."
    }

    # Check if image already exist
    if(((wsl.exe -l).Replace("`0","")) -like "*${_wslName}*") {
        $_wslImageExist = $True
    }

    ##################################################################################
    # Output for debugging
    ##################################################################################
    Write-Output "Print variables:"
    Write-Output "Base storage path for wsl:                 $_wslBasePath"
    Write-Output "Sub folder for your wsl images:            $_wslDistroPath"
    Write-Output "Sub folder for caching distribution files: $_wslBaseImagePath"
    Write-Output "Name for the wsl image:                    $_wslName"
    Write-Output "Remove existing wsl image:                 $_wslRemoveExisting"
    Write-Output "Work user:                                 $_wslWorkUser"
    Write-Output "Set work user as default:                  $_wslWorkUserDefault"
    Write-Output "Linux kernel version:                      $_wslKernelMajor.$_wslKernelMinor"
    Write-Output "WSL image exist:                           $_wslImageExist"
    Write-Output "Install a SSH server:                      $_wslSshServer"
    Write-Output "SSH server port:                           $_wslSshServerPort"
    Write-Output "The WSL image which should be installed:   $_wslDistroUniqueName"

    #######################################################
    # Remove existing WSL and related files
    #######################################################
    if($_wslRemoveExisting -and $_wslImageExist) {
        Write-Output "Image exist. Unregister existing WSL image."
        wsl --unregister ${_wslName}
        $_wslCmdReturn=$?
        if($_wslCmdReturn -ne $True) {
            throw "Failed to unregister. Leaving."
        }

        if (Test-Path "$_wslBasePath\$_wslDistroPath\$_wslName") {
            Write-Output "Remove existing image files."
            Remove-Item -Path "$_wslBasePath\$_wslDistroPath\$_wslName" -Recurse -Force
        }
    } else {
        Write-Output "Image exist and will just be update. Skipping refresh process."
    }

    #######################################################
    # Download appx image
    #######################################################
    # If image doesn't exist or previous version should be removed, lets download the sources and create the WSL image
    if(-not ($_wslRemoveExisting -or (-not $_wslImageExist))) {
        Write-Output "Image exist and should not be refreshed. Skipping download and installation process."
    } else {

        if (-Not (Test-Path -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.tar.gz")) {
            Write-Output "AppX-Image doesn't exist. Create it."

            if (-Not (Test-Path -Path "$_wslBasePath\$_wslBaseImagePath")) {
                Write-Output "Create base image path ($_wslBasePath\$_wslBaseImagePath)"
                New-Item -Path "$_wslBasePath\$_wslBaseImagePath" -ItemType Directory  | Out-Null
            }

            if (-Not (Test-Path -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.appx")) {
                Write-Output "Download the image"
                Invoke-WebRequest -Uri "$_wslDistroUrl" -OutFile "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.appx" -UseBasicParsing
            }

            Write-Output "Extract the image (phase 1)"
            Copy-Item "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.appx" "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.zip"
            Expand-Archive -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.zip" -DestinationPath "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName" -Force | Out-Null

            Write-Output "Extract the image (phase 2)"
            Rename-Item "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName\$_wslDistroX64FileName.appx" "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName\$_wslDistroUniqueName-x64.zip"
            Expand-Archive -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName\$_wslDistroUniqueName-x64.zip" -DestinationPath "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName\$_wslDistroUniqueName-x64" -Force | Out-Null
            Move-Item "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName\$_wslDistroUniqueName-x64\install.tar.gz" "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName-x64.tar.gz"

            Write-Output "Cleanup"
            Remove-Item -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName" -Recurse -Force
            Remove-Item -Path "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName.zip" -Recurse -Force
        }


        #######################################################
        # Create the distribution
        #######################################################
        # Thats a bit tricky, because wsl print some null values you have to remove before comparing the string

        Write-Output "WSL instance ""${_wslName}"" not found. Create it."
        if (-Not (Test-Path -Path "$_wslBasePath\$_wslDistroPath")) {
            Write-Output "Create WSL distro directory"
            New-Item -Name $_wslDistroPath -ItemType Directory -Path $_wslBasePath | Out-Null
        }

        if (-Not (Test-Path -Path "$_wslBasePath\$_wslDistroPath\$_wslName")) {
            Write-Output "Create WSL directory"
            New-Item -Name $_wslName -ItemType Directory -Path $_wslBasePath\$_wslDistroPath | Out-Null
        }
        Write-Output "Create the WSL environment"
        wsl --import $_wslName "$_wslBasePath\$_wslDistroPath\$_wslName" "$_wslBasePath\$_wslBaseImagePath\$_wslDistroUniqueName-x64.tar.gz" --version 2
        $_wslCmdReturn=$?
        if($_wslCmdReturn -ne $True) {
            throw "Failed to import. Leaving."
        }
    }

    #######################################################
    # Manage the VM (update and all that shit)
    #######################################################

    Write-Output "Update packages (Please be patient, this can take a while)"
    Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt update -y > /dev/null 2>&1" -User root

    Write-Output "Upgrade packages (Please be patient, this can take a while)"
    Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt upgrade -y > /dev/null 2>&1" -User root

    Write-Output "Removing packages that are not needed anymore"
    Invoke-WSLCommand -Distribution $_wslName -Command "sudo apt autoremove -y > /dev/null 2>&1" -User root

    #######################################################
    # Manage the users in WSL image
    #######################################################

    Write-Output "Set root password"
    Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""sudo echo root:$_wslRootPwd | chpasswd""" -User root

    if((-Not [string]::IsNullOrEmpty($_wslWorkUser))) {
        Write-Output "Create user for daily work"

        Write-Output "Copy script to manage users"
        Copy-WSLFileToTarget -Distribution $_wslName -LocalPath "$_wslManageUserScript" -TargetPath "/root/manage-users.sh" -User root
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""chmod +x /root/manage-users.sh""" -User root

        Write-Output "Invoke manage user command for work user"
        #$_wslBashCommand=$ExecutionContext.InvokeCommand.ExpandString("/root/manage-users.sh --username ""$_wslWorkUser"" --password ""$_wslWorkUserPwd"" --pubkey ""$_wslWorkUserSSHPubKey"" --sudoperm 1 > /dev/null 2>&1")
        $_wslBashCommand='/root/manage-users.sh --username "{0}" --password "{1}" --pubkey "{2}" --sudoperm 1 > /dev/null 2>&1' -f $_wslWorkUser, $_wslWorkUserPwd, $_wslWorkUserSSHPubKey
        Invoke-WSLCommand -Distribution $_wslName -Command "$_wslBashCommand" -User root

        Write-Output "Remove the user management script from WSL"
        Invoke-WSLCommand -Distribution $_wslName -Command "rm -f ""root\manage-users.sh""" -User root

        Write-Output "Reset wsl-conf"
        $_wslInstallationDate=$(Get-Date -Format 'yyyy-mm-dd_HH:MM:ss')
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[info]"" > /etc/wsl.conf""" -User root
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""changedate=$_wslInstallationDate"" >> /etc/wsl.conf""" -User root

        Write-Output "Set hostname to wsl name"
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[network]"" >> /etc/wsl.conf""" -User root
        Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""hostname=$_wslName"" >> /etc/wsl.conf""" -User root

        if($_wslWorkUserDefault) {
            Write-Output "Make work user the default user"
            Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""[user]"" >> /etc/wsl.conf""" -User root
            Invoke-WSLCommand -Distribution $_wslName -Command "bash -c ""echo ""default=$_wslWorkUser"" >> /etc/wsl.conf""" -User root
        }
    }

    #######################################################
    # Finalize
    #######################################################
    Write-Output "Cleanup"
    $_wslBasePath = ""
    $_wslDistroPath = ""
    $_wslBaseImagePath = ""
    $_wslName = ""
    $_wslRemoveExisting = $False
    $_wslRootPwd = ""
    $_wslWorkUser = ""
    $_wslWorkUserPwd = ""
    $_wslWorkUserSSHPubKey = ""

    Write-Output "Shutdown WSL"
    wsl --shutdown --distribution $_wslName
    $_wslCmdReturn=$?
    if($_wslCmdReturn -ne $True) {
        throw "Failed to import. Leaving."
    }
}

function Test-WslImage {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslName
    )

    . $PSScriptRoot/pswslmanage-helper.ps1

    if($null -eq (Get-WslImage -WslName $WslName)) {
        return $false
    } else {
        return $true
    }
}

function Get-WslImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslName
    )

    Write-Output "Try to get information from WslImage $WslName"

    $_image_property_string =(((wsl.exe -l -v).Replace("`0","")).trim() | ForEach-Object { if (![string]::IsNullOrEmpty($_) -and ($_ -like "*$($WslName)*")){$_out = $($_ -replace '\s+', ';'); Write-Output $_out} })

    if([string]::IsNullOrEmpty($_image_property_string)) {
        return $null
    }

    $_image_properties = New-Object -Type PSObject
    if (($_image_property_string.Split(";")[0]) -eq "*") {
        $_image_properties | Add-Member -MemberType NoteProperty -Name "IsDefault" -Value $True -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "Name" -Value $_image_property_string.Split(";")[1] -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "State" -Value $_image_property_string.Split(";")[2] -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "Version" -Value $_image_property_string.Split(";")[3] -Force
    } else {
        $_image_properties | Add-Member -MemberType NoteProperty -Name "IsDefault" -Value $False -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "Name" -Value $_image_property_string.Split(";")[0] -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "State" -Value $_image_property_string.Split(";")[1] -Force
        $_image_properties | Add-Member -MemberType NoteProperty -Name "Version" -Value $_image_property_string.Split(";")[2] -Force
    }

    # Get the internet-connected IP of the WSL by trying to reach the gooogle DNS server
    $_wsl_ip = Invoke-WSLCommand -Distribution $WslName -Command 'printf $(ip route get 8.8.8.8 | awk -F src ''{print $2}''| awk ''{print $1}'')' -User root
    $_image_properties | Add-Member -MemberType NoteProperty -Name "IP" -Value $_wsl_ip -Force

    return $_image_properties
}

function Stop-WslImage {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='None')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslName
    )
    $PSCmdlet.ShouldProcess("dummy") | Out-Null

    if(Test-WslImage -WslName $WslName) {
        $_wslProcess=(Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown $WslName" -Wait -NoNewWindow -PassThru)
    }

    if($_wslProcess.ExitCode -ne 0) {
        throw "Failed to remove WSL instance (Returncode: $($_wslProcess.ExitCode)). Command Details: ""$Command"". Leaving."
    }
}

function Remove-WslImage {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='None')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslName,
        [string]$WslBasePath,
        [switch]$WithFile
    )
    $PSCmdlet.ShouldProcess("dummy") | Out-Null

    if(Test-WslImage -WslName $WslName) {
        $_wslProcess=(Start-Process -FilePath "wsl.exe" -ArgumentList "--unregister $WslName" -Wait -NoNewWindow -PassThru)
    }

    if((Test-Path -Path $WslBasePath) -and $WithFile) {
        Remove-Item -Path $WslBasePath -Force -Recurse
    }

    if($_wslProcess.ExitCode -ne 0) {
        throw "Failed to remove WSL instance (Returncode: $($_wslProcess.ExitCode)). Command Details: ""$Command"". Leaving."
    }
}
