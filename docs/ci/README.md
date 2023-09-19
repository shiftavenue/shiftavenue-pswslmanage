# Create the CI environment

This describes how to create the CI environment for the PsWslManage.

## Install Powershell Core

Execute the following script to install Powershell Core on the system.

```powershell
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.3.6/PowerShell-7.3.6-win-x64.msi -OutFile $env:temp\pwsh.msi
Start-Process -FilePath "msiexec" -ArgumentList "/package ""$env:temp\pwsh.msi"" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1 USE_MU=0 ENABLE_MU=0 ADD_PATH=1 DISABLE_TELEMETRY=1"
Restart-Computer
#Remove-Item $env:temp\pwsh.msi -Force
```

## Configure Powershell core

In Powershell core several components must be available. Please open "pwsh" and execute the following commands.

### Disable TLS 1.3

The NuGet pacakge provider does not work with TLS 1.3

```powershell
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -PropertyType 'Dword' -Value 1 -Force | Out-Null
New-ItemProperty -path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -PropertyType 'Dword' -Value 1 -Force | Out-Null
```

### Install NuGet components

To have NuGet available, it must be installed in Powershell Core.

```powershell
Set-PSRepository PSGallery -InstallationPolicy Trusted
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12´
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
Install-Module PowershellGet -Force
Set-PSRepository PSGallery -InstallationPolicy Untrusted
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null

$_local_nuget_path = "{0}\Microsoft\Windows\PowerShell\PowerShellGet" -f $($env:PROGRAMDATA)
if (-Not (Test-Path -Path $_local_nuget_path)) {New-Item -Path $_local_nuget_path -ItemType Directory -Force}
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://aka.ms/psget-nugetexe" -OutFile "$_local_nuget_path\nuget.exe"
```

### Update Powershell package management

Only the new PowerShellGet version is working with GitHub packages.

```powershell
echo "Remove module < version 3"
Remove-Module PackageManagement -ErrorAction SilentlyContinue
Remove-Module PowershellGet -ErrorAction SilentlyContinue

echo "Uninstall old version of package management"
Uninstall-Module PackageManagement -ErrorAction SilentlyContinue
Uninstall-Module PowershellGet -ErrorAction SilentlyContinue

echo "Set PS Gallery to trusted"
Set-PSRepository PSGallery -InstallationPolicy Trusted

echo "Install PSResourceGet module"
Install-Module Microsoft.PowerShell.PSResourceGet -AllowClobber -AllowPrerelease -Force

echo "Install the compat-module which allows us to work with normal Credential objects"
Install-Module -Name CompatPowerShellGet -AllowClobber -Force

echo "Set PS Gallery to untrusted"
Set-PSRepository PSGallery -InstallationPolicy Untrusted
```

### Install PSScriptAnalyzer

The PSScriptAnalyzer is used to check all scripts.

```powershell
Set-PSRepository PSGallery -InstallationPolicy Trusted
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module PSScriptAnalyzer -AllowClobber -Force
Set-PSRepository PSGallery -InstallationPolicy Untrusted
```

## Install the GitHub runner on Windows Server 2022

- Create a windows maschine somewhere
- Navigate to "https://github.com/shiftavenue/shiftavenue-pswslmanage/settings/actions/runners/new?arch=x64&os=win" and get the following values in the example script:
  - Current version of the GitHub runner
  - Hash code for the GitHub runner binary
  - The token fo rthe runner
- Set all 3 variables in the script below
- Remove an existing runner entry
- Execute the script to install the GitHub runner as Windows Service

```powershell
  $_gh_runner_version="2.309.0"
  $_gh_runner_hash="You hash code"
  $_gh_runner_token="your token"
  mkdir "C:\ProgramData\GitHub-Actions-Runner"
  Set-Location -Path "C:\ProgramData\GitHub-Actions-Runner"
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v$($_gh_runner_version)/actions-runner-win-x64-$($_gh_runner_version).zip -OutFile actions-runner-win-x64.zip
  if((Get-FileHash -Path actions-runner-win-x64-2.309.0.zip -Algorithm SHA256).Hash.ToUpper() -ne $($_gh_runner_hash).ToUpper()){ throw 'Computed checksum did not match' }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\ProgramData\GitHub-Actions-Runner\actions-runner-win-x64.zip", "$PWD")
  .\config.cmd --unattended --url "https://github.com/shiftavenue/shiftavenue-pswslmanage" --token "$_gh_runner_token" --name sa-ci-win --runasservice
```

With the default configuration, the GitHub runner is running as "Network Service" Account which prevents the execution of admininistrative commands. One way is to reconfigure the service to run as "LOCAL SYSTEM". This permission is needed to run the [init.yml](./../../.github/workflows/init.yaml) workflow which will configure the system to successful run the CI/CD workflows. If you don't want to reconfigure the system this way, you can run the powershell commands in the [init.yml](./../../.github/workflows/init.yaml) by yourself.

```powershell
  $_gh_runner_service_name=(Get-Service actions.runner.*).name
  Start-Process -FilePath "sc" -ArgumentList "config ""$_gh_runner_service_name"" obj=""NT AUTHORITY\SYSTEM"" type=own"
```

When the GitHub runner is installed, you have to start the workflow "sa-ci-init".
