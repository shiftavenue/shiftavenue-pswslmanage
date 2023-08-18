# PS WSL Manage

This module can be used to manage local WSL images. It enhance the default functionality of local ```wsl.exe``` and will be used as base for further enhancements.

## Why to use this module

The following functionality is implemented and is done automatically by the module:

- Store every configuration detail in a JSON file to recreate WSL images repeatably.
- System update (update and upgrade) will done automatically.
- A default work user will be created.
- The ```wsl.conf``` will be configured.

## Examples

### Install with parameters

You can run the script just with input parameter

```powershell

.\Add-WSLImage.ps1 -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslRootPwd "Start123" -WslWorkUser work -WslWorkUserPwd "Start123" -WslWorkUserDefault -WslWorkUserSSHPubKey "ssh-rsa as4fj..." -WslSshServer -WslSshPort 30122 -WslDistroName Ubuntu2204 Ignore configuration file and configure the WSL with parameters

```

### Install with config file

Create the following configuration file in c:\temp\wsl.secret

```json

{
    "wslBasePath":"${env:localappdata}\\shiftavenue\\wsl",
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
```

Execute the following command:

```powershell

.\Add-WSLImage.ps1 -WslConfigPath ""
```

### More details

Please execute ```Get-Help Add-WSLImage.ps1``` to get further details
