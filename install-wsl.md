# Install WSL

## Examples

### Install with parameters

You can run the script just with input parameter

```powershell
.\install-wsl.ps1 -WslConfigPath "" -WslName shiftavenue-ci -WslRemoveExisting -WslWorkUser work -WslWorkUserDefault -WslRootPwd "Start123" -WslWorkUserPwd "Start123" -WslMgmtUser "ansible" -WslMgmtUserPwd "Start123" -Verbose
```

### Install with config file

Create the following configuration file

```json
{
    "wslBasePath":"${env:localappdata}\\<YOURPROJECT>\\wsl",
    "wslDistroPath":"distros",
    "wslName":"shiftavenue-ci",
    "wslRemoveExisting":"True",
    "wslRootPwd":"Start123",
    "wslWorkUser":"Work",
    "wslWorkUserPwd":"Start123",
    "wslWorkUserDefault":"True",
    "wslWorkUserSSHPubKey":"dummy",
    "wslMgmtUser":"ansible",
    "wslMgmtUserPwd":"Start123",
    "wslMgmtUserSSHPubKey":"dummy"
}
```

### More details

Please execute ```Get-Help install-ansible.ps1``` to get further details
