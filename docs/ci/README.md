# Create the CI environment

This describes how to create the CI environment for the PsWslManage.

## Install the GitHub runner on Windows Server 2022

- Create a windows maschine somewhere
- Navigate to "https://github.com/shiftavenue/shiftavenue-pswslmanage/settings/actions/runners/new?arch=x64&os=win" and get the following values in the example script:
  - Current version of the GitHub runner
  - Hash code for the GitHub runner binary
  - The token fo rthe runner
- Set all 3 variables in the script below
- Execute the script to install the GitHub runner as Windows Service

```powershell
  $_gh_runner_version="2.309.0"
  $_gh_runner_hash="cd1920154e365689103aa1f90258e0da47faecce547d0374475cdd2554dbf09a"
  $_gh_runner_token="mytoken"
  mkdir "C:\ProgramData\GitHub-Actions-Runner"
  Set-Location -Path "C:\ProgramData\GitHub-Actions-Runner"
  Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v$($_gh_runner_version)/actions-runner-win-x64-$($_gh_runner_version).zip -OutFile actions-runner-win-x64.zip
  if((Get-FileHash -Path actions-runner-win-x64-2.309.0.zip -Algorithm SHA256).Hash.ToUpper() -ne $($_gh_runner_hash).ToUpper()){ throw 'Computed checksum did not match' }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\ProgramData\shiftavenue\unattendbuilder\custom\github-runner\actions-runner-win-x64.zip", "$PWD")
  .\config.cmd --unattended --url "https://github.com/shiftavenue/shiftavenue-pswslmanage" --token "$_gh_runner_token" --name sa-ci-win --runasservice
```

With the default configuration, the GitHub runner is running as "Network Service" Account which prevents the execution of admininistrative commands. One way is to reconfigure the service to run as "LOCAL SYSTEM". This permission is needed to run the [init.yml](./../../.github/workflows/init.yaml) workflow which will configure the system to successful run the CI/CD workflows. If you don't want to reconfigure the system this way, you can run the powershell commands in the [init.yml](./../../.github/workflows/init.yaml) by yourself.

```powershell
  $_gh_runner_service_name=(Get-Service actions.runner.*).name
  Start-Process -FilePath "sc" -ArgumentList "config ""$_gh_runner_service_name"" obj=""NT AUTHORITY\SYSTEM"" type=own"
```



#,New-ModuleManifest -Path "C:\Users\david\Documents\Development\shiftavenue\shiftavenue-pswslmanage\pswslmanage_test.psd1" -ModuleVersion "1.0.0" -Author "David Koenig" -Guid "a2d16567-94f2-4a76-8e0d-c29d40177c56" -CompanyName "shiftavenu" -Copyright "(c) shiftavenue. All rights reserved." -RootModule "pswslmanage.psm1" -Description "With this module you can install and maintain WSL images" -ProcessorArchitecture Amd64 -FunctionsToExport @("Add-WslImage", "Test-WslImage", "Get-WslImage", "Remove-WslImage", "Stop-WslImage", "Add-WslUser", "Add-WslRoleSSH" ) -CompatiblePSEditions Core -Tags "wsl, windows, linux, wsl2, windows subsystem for linux" -ProjectUri "https://github.com/shiftavenue/shiftavenue-pswslmanage" -IconUri "https://raw.githubusercontent.com/shiftavenue/shiftavenue-pswslmanage/main/Icon.png"
