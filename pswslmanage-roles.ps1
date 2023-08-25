function Add-WslRoleSSH {
    
    <#
        .SYNOPSIS
            Add the SSH daemon to an existing WSL image.

        .DESCRIPTION
            Add the SSH daemon to an existing WSL image.

        .PARAMETER WslName
            The name of the WSL-image you want to remove.

        .PARAMETER WslSSHPort
            The port where the SSH daemon is listening to.
        .EXAMPLE
            Add-WslRoleSSH -WslName shiftavenue-ci -WslSSHPort 22222
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$WslName,
        [Parameter(Mandatory=$true)]
        [string]$WslSSHPort
    )

    Write-Output "Install openssh server"
    Invoke-WSLCommand -Distribution $WslName -Command "bash -c ""sudo apt install openssh-server -y > /dev/null 2>&1""" -User root

    Write-Output "Configure openssh server"
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""Include /etc/ssh/sshd_config.d/*.conf"" > /etc/ssh/sshd_config"' -User root
    $_command = 'bash -c "echo ""Port {0}"" >> /etc/ssh/sshd_config"' -f $WslSSHPort
    Invoke-WSLCommand -Distribution $WslName -Command $_command -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""ListenAddress 0.0.0.0"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""PubkeyAuthentication yes"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""AuthorizedKeysFile .ssh/authorized_keys"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""HostbasedAuthentication no"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""PasswordAuthentication no"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""KerberosAuthentication no"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""GSSAPIAuthentication no"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""UsePAM no"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""AcceptEnv LANG LC_*"" >> /etc/ssh/sshd_config"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""Subsystem sftp /usr/lib/openssh/sftp-server"" >> /etc/ssh/sshd_config"' -User root

    #TODO: Here i added statically the boot section. Better to check if section exist
    # Added the start of cron to the boot section to keep the wsl image running
    Write-Output "Add SSH to the boot parameter"
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c "echo ""[boot]"" >> /etc/wsl.conf"' -User root
    Invoke-WSLCommand -Distribution $WslName -Command 'bash -c ''echo "command=service cron start; service ssh start" >> /etc/wsl.conf''' -User root

    Write-Host "Restart the image"
    Stop-WslImage -WslName $WslName
    Invoke-WSLCommand -Distribution $WslName -Command 'ls ~ > /dev/null' -User root
    
}