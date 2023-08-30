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



          #,New-ModuleManifest -Path "C:\Users\david\Documents\Development\shiftavenue\shiftavenue-pswslmanage\pswslmanage_test.psd1" -ModuleVersion "1.0.0" -Author "David Koenig" -Guid "a2d16567-94f2-4a76-8e0d-c29d40177c56" -CompanyName "shiftavenu" -Copyright "(c) shiftavenue. All rights reserved." -RootModule "pswslmanage.psm1" -Description "With this module you can install and maintain WSL images" -ProcessorArchitecture Amd64 -FunctionsToExport @("Add-WslImage", "Test-WslImage", "Get-WslImage", "Remove-WslImage", "Stop-WslImage", "Add-WslUser", "Add-WslRoleSSH" ) -CompatiblePSEditions Core -Tags "wsl, windows, linux, wsl2, windows subsystem for linux" -ProjectUri "https://github.com/shiftavenue/shiftavenue-pswslmanage" -IconUri "https://raw.githubusercontent.com/shiftavenue/shiftavenue-pswslmanage/main/Icon.png"
