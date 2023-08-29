# PS WSL Manage

- Status of DEV branch: [![pswslmanage](https://github.com/shiftavenue/shiftavenue-pswslmanage/actions/workflows/dev.yml/badge.svg)](https://github.com/shiftavenue/shiftavenue-pswslmanage/actions/workflows/dev.yml)

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
  - [Authors / Contributors](#authors--contributors)

## Description

This module can be used to manage local WSL images. It enhance the default functionality of local ```wsl.exe``` and will be used as base for further enhancements.

## Supported OS

This script is tested on Windows 11 22H2.

Current supported OSe are

- Ubuntu 22.04 (tested)
- Ubuntu 20.04 (Not tested)

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

## Authors / Contributors

- [David Koenig](https://github.com/davidkoenig-shiftavenue)
