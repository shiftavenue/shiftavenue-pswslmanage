# Create the CI environment

This describes how to create the CICD environment for the PsWslManage. I tried also to to do that with GitHub packages which fails. The documentation about that is available [here](PublishToGitHubPackages.md).

## Create a PowershellGallery API key

Please go to your [api key manage](https://www.powershellgallery.com/account/apikeys) and create an API key. The key has a maximum validity of 365 days. Outdated keys can easily refreshed with the "Regenerate" Button.
The current key was created 2023-09-21.

## Install Powershell Core

Execute the following script to install Powershell Core on the system.

```powershell
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.3.6/PowerShell-7.3.6-win-x64.msi -OutFile $env:temp\pwsh.msi
Start-Process -FilePath "msiexec" -ArgumentList "/package ""$env:temp\pwsh.msi"" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1 USE_MU=0 ENABLE_MU=0 ADD_PATH=1 DISABLE_TELEMETRY=1"
Remove-Item $env:temp\pwsh.msi -Force
Restart-Computer
```

## Install the GitHub runner on Windows Server 2022

- Create a windows maschine somewhere
- Navigate to "https://github.com/shiftavenue/shiftavenue-pswslmanage/settings/actions/runners/new?arch=x64&os=win" and get the following values in the example script:
  - Current version of the GitHub runner
  - Hash code for the GitHub runner binary
  - The token for the runner
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
  if((Get-FileHash -Path actions-runner-win-x64.zip -Algorithm SHA256).Hash.ToUpper() -ne $($_gh_runner_hash).ToUpper()){ throw 'Computed checksum did not match' }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\ProgramData\GitHub-Actions-Runner\actions-runner-win-x64.zip", "$PWD")
  .\config.cmd --unattended --url "https://github.com/shiftavenue/shiftavenue-pswslmanage" --token "$_gh_runner_token" --name sa-ci-win --runasservice
```

When the GitHub runner is installed, you have to start the workflow "sa-ci-init".
