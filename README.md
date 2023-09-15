# PS WSL Manage

![GitHub Workflow Status (dev)](https://img.shields.io/github/actions/workflow/status/shiftavenue/shiftavenue-pswslmanage/dev.yml?label=DEV%20build&logo=data:image/png;base64,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)

![GitHub Workflow Status (prd)](https://img.shields.io/github/actions/workflow/status/shiftavenue/shiftavenue-pswslmanage/prd.yml?label=PRD%20build&logo=data:image/png;base64,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)

![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/pswslmanage?label=PS%20Gallery%20downloads&logo=data:image/png;base64,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)

![GitHub issues](https://img.shields.io/github/issues/shiftavenue/shiftavenue-pswslmanage?label=Issues&logo=data:image/png;base64,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)


## Table of contents

- [PS WSL Manage](#ps-wsl-manage)
  - [Table of contents](#table-of-contents)
  - [Description](#description)
  - [Supported OS](#supported-os)
  - [Why to use this module](#why-to-use-this-module)
  - [Installation](#installation)
  - [Examples](#examples)
    - [Create a WSL system with parameters](#create-a-wsl-system-with-parameters)
    - [Create a WSL system with a config file](#create-a-wsl-system-with-a-config-file)
    - [Check if image exist](#check-if-image-exist)
    - [Stop image](#stop-image)
    - [Remove image](#remove-image)
    - [Get information from WSL](#get-information-from-wsl)
    - [Add the SSH damon to an existing WSL](#add-the-ssh-damon-to-an-existing-wsl)
  - [Ideas / Backlog](#ideas--backlog)
  - [CI/CD](#cicd)
  - [Authors / Contributors](#authors--contributors)

## Description

This module can be used to manage local WSL images. It enhance the default functionality of local ```wsl.exe``` and will be used as base for further enhancements.

## Supported OS

This script is tested on Windows 11 22H2.

## Why to use this module

The following functionality is implemented and is done automatically by the module:

- Store every configuration detail in a JSON file to recreate WSL images repeatably.
- System update (update and upgrade) will done automatically.
- You can create users with a simple function in the WSL.
- SSL role with all needed settings can be added.
- The ```wsl.conf``` will be configured for you automatically.

## Installation

PsWslManage is published to the Powershell Gallery and can be installed as follows:

```Install-Module PsWslManage```

## Examples

The central function is "Add-WslImage" which allows you to create a WSL image.

Additionally to the OS itself, the following tools will be installed:

- OS udpate
- crudini (for INI file modification)

### Create a WSL system with parameters

You can run the script just with input parameter. Please execute ```Get-Help Add-WSLImage``` to get further details.

```powershell

.\Add-WSLImage -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslRootPwd "Start123" -WslDistroName Ubuntu2204 

```

### Create a WSL system with a config file

Create the following configuration file in c:\temp\wsl.secret. Please execute ```Get-Help Add-WSLImage``` to get further details.

```json
{
    "wslBasePath":"${env:localappdata}\\shiftavenue\\wsl",
    "wslDistroPath":"distros",
    "wslName":"shiftavenue-ci",
    "wslRemoveExisting":1,
    "wslRootPwd":"Start123",
    "wslDistroName":"Ubuntu2204"
}
```

Execute the following command:

```powershell
.\Add-WSLImage -WslConfigPath "c:\temp\wsl.secret"
```

### Check if image exist

Just call ```Test-WslImage -WslName shiftavenue-ci``` to know if the image exist.

### Stop image

Just call ```Stop-WslImage -WslName shiftavenue-ci``` to stop a running machine.

### Remove image

The command ```Remove-WslImage -WslName shiftavenue-ci``` will remove the WSL like the ```--unregister``` switch of the wsl.exe will do. With the optional parameters "WslBasePath" and "WithFile" you can also remove all related binary files.
Example:

```Remove-WSLImage -WslName shiftavenue-ci -WslBasePath c:\temp\shiftavenue\wsl-temp-maschine -WithFile```

### Get information from WSL

The information you get from the wsl.exe are very basic. Use the following command to get more and have powershell compatible way to access the properties.

```Get-WslImage -WslName shiftavenue-ci```

The available values are:

- Name
- Version
- IP
- State
  
### Add the SSH damon to an existing WSL

Its not very simple to add SSH to a WSL image, but for some scenarios its really useful to have that available. With the "Add-WslRoleSSH" it is totally easy to do that, just by executing the following command.  

```Add-WslRoleSSH -WslName shiftavenue-ci -WslSSHPort 22222```

## Ideas / Backlog

Please use [GH issue tracker](https://github.com/shiftavenue/shiftavenue-pswslmanage/issues) of this repository.

## CI/CD

This is build and deployed witha  GitHub CI/CD workflow. Please follow [this](./docs/ci/README.md) guideline to learn how to configure the workflow.

## Authors / Contributors

- [David Koenig](https://github.com/davidkoenig-shiftavenue)
