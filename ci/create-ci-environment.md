# Create the CI environment

This describes how to create the CI environment for the PsWslManage.

## Walkthrough

- Create a windows maschine somewhere
- Install GH Actions runner on it
  - mkdir "C:\ProgramData\GitHub-Actions-Runner"
  - Set-Location -Path "C:\ProgramData\GitHub-Actions-Runner"
  - Add-Type -AssemblyName System.IO.Compression.FileSystem
  - [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\ProgramData\shiftavenue\unattendbuilder\custom\github-runner\actions-runner-win-x64.zip", "$PWD")
  - .\config.cmd --unattended --url "https://github.com/shiftavenue/shiftavenue-pswslmanage" --token BB3T63KDVPJOLH6Y7W6X6L3E5WZIA --name sa-ci-win --runasservice
- Execute Add-WslImage -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslRootPwd "Start123" -WslDistroName Ubuntu2204
