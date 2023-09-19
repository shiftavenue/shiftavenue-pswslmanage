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
  $_gh_runner_hash="fdfdsfdys"
  $_gh_runner_token="mytoken"
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
