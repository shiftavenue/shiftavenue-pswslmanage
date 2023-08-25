Describe 'Common pswslmanage tests' {
    
    BeforeAll {
        try {
            
            # The following thre parameters are just for development and can be ignored.
            $script:_wsl_test_use_existing_image = $false   # Default: false
            $script:_wsl_test_existing_suffix = "hjd"       # Default: empty
            $script:_wsl_test_keep_image = $false           # Default: false

            if(!$script:_wsl_test_use_existing_image) {
                # Create a random name used for the test-image and directories
                $script:_wsl_test_target_environment = $(-join ((65..90) + (97..122) | Get-Random -Count 3 | Foreach-Object {[char]$_}))
            } else {
                $script:_wsl_test_target_environment = $script:_wsl_test_existing_suffix
            }

            # Define root path for all created objects 
            $script:_wsl_test_base_path = "$($env:localappdata)\shiftavenue\pswslmanage-test-$script:_wsl_test_target_environment"

            # The name of the target image
            $script:_wsl_test_name = "pswslmanage-test-$($script:_wsl_test_target_environment)"

            # Flags to disable/enable single tests, please just change in case of development and set to true before check-in.
            #$script:_test_invoke_asgarddatarefinement = $true

            Write-Host "Test prerequisites: Start to create all prerequisites"
            Write-Host "Test prerequisites: Name suffix       - $script:_wsl_test_target_environment"
            Write-Host "Test prerequisites: Working directory - $script:_wsl_test_base_path"
            Write-Host "Test prerequisites: WSL image         - $script:_wsl_test_name"
            
            # Remove module first to get the newest version in session
            if (Get-Module pswslmanage) { 
                Remove-Module pswslmanage -Force
            }

            # Create the baseimg path (will be created by the module when it doesn't exist, but we need it for certs and other things)"
            Write-Host "Test prerequisites: Create the baseimg path"
            New-Item -Path "$script:_wsl_test_base_path" -Name "baseimg" -ItemType "Directory" -ErrorAction SilentlyContinue

            # Try to create the image locally to prevent the download from internet
            if(Test-Path "$($env:localappdata)\\shiftavenue\pswslmanage-test\Ubuntu2204.appx") {

                Write-Host "Test prerequisites: Copy image from cache into target directory"
                Copy-Item -Path "$($env:localappdata)\shiftavenue\pswslmanage-test\Ubuntu2204.appx" -Destination "$script:_wsl_test_base_path\baseimg\Ubuntu2204.appx"
            }

            # Import the module
            Import-Module "$PSScriptRoot\..\pswslmanage.psd1" -Force

            if((Test-WSLImage -WslName $script:_wsl_test_name) -and $script:_wsl_test_use_existing_image) {
                Write-Host "Test prerequisites: Skip image creation, existing image will be used"
            } else {

                Write-Host "Test prerequisites: Create the certificate which is used for the tests"
                ssh-keygen -b 4096 -t rsa -f $script:_wsl_test_base_path\ssh.key -q -N ''
                $_wsl_test_ssh_key_pub = $(Get-Content -Path "$script:_wsl_test_base_path\ssh.key.pub")

                Write-Host "Test prerequisites: Create the new image"
                # Create the WSL image which is used for the most of the tests
                Add-WSLImage    -WslConfigPath "" `
                                -WslBasePath $script:_wsl_test_base_path `
                                -WslName $script:_wsl_test_name `
                                -WslRemoveExisting `
                                -WslRootPwd "WslTestRootPwd" `
                                -WslWorkUser "WslTestUser" `
                                -WslWorkUserPwd "WslTestWorkPwd" `
                                -WslWorkUserSSHPubKey $_wsl_test_ssh_key_pub `
                                -WslWorkUserDefault `
                                -WslSshServer `
                                -WslSshServerPort 30022 `
                                -WslDistroName "Ubuntu2204"
            }

            Write-Host "Test prerequisites: Prerequisites done"
        } catch {
            Write-Host "Test prerequisites: Failed to prepare pester tests. Details: $($_.Exception.Message)"
            throw "Exit"
        }
    }

    It 'Check if central test-image exist' {
        Write-Host "Test: Check if central test-image exist"
        Test-WSLImage -WslName $script:_wsl_test_name | Should -Be $true
    }

    It 'Test shutdown against central test-image' {
        Write-Host "Test: Test shutdown against central test-image"
        Stop-WslImage -WslName $script:_wsl_test_name
        (Get-WSLImage -WslName $script:_wsl_test_name).State | Should -Be "Stopped"
    }

    It 'Get the properties of the central test-image' {
        Write-Host "Test: Get the properties of the central test-image"
        $_wsl_test_image_properties = Get-WSLImage -WslName $script:_wsl_test_name 
        $_wsl_test_image_properties.Name | Should -Be $script:_wsl_test_name
        $_wsl_test_image_properties.Version | Should -Be 2
        $_wsl_test_image_properties.IP | Should -not -BeNullOrEmpty
    }

    It 'Test the SSH access to the central test-image' {
        Write-Host "Test: Install SSH role to image"
        Add-WslRoleSSH -WslName $script:_wsl_test_name -WslSSHPort "22222"
        
        $_wsl_test_image_properties = Get-WSLImage -WslName $script:_wsl_test_name
        # Wake up the maschine
        $_wsl_status_count = 1
        $_wsl_status = "Stopped"
        
        Do {
            try {
                Write-Host "Test: Try to contact maschine via SSH ($_wsl_status_count/5)"
                Invoke-WSLCommand -Distribution $script:_wsl_test_name -Command "ls ~ > /dev/null" -User root
                $_ssh_wsl_key = $(ssh -q -o "StrictHostKeyChecking no" WslTestUser@$($_wsl_test_image_properties.IP) -p 22222 -i "$script:_wsl_test_base_path\ssh.key" cat /home/WslTestUser/.ssh/authorized_keys)
                if(-Not ([string]::IsNullOrEmpty($_ssh_wsl_key))) {
                    $_wsl_status = "OK"
                }
            } catch {  
                $_wsl_status = "Stopped"
            }
            Start-Sleep 2

            $_wsl_status_count++
            if($_wsl_status_count -eq 6) {
                throw "Test: WSL start timed out"
            }
        }
        while ($_wsl_status -ne "OK")
        
        $_ssh_lcl_key = Get-Content -Path "$script:_wsl_test_base_path\ssh.key.pub"
        $_ssh_wsl_key | Should -Be $_ssh_lcl_key

    }

    AfterAll {
        if(!$script:_wsl_test_keep_image) {
            Write-Host "Test finalization: Remove the WslImage"
            Remove-WslImage -WslName "$script:_wsl_test_name" -WslBasePath "$script:_wsl_test_base_path" -WithFile
        }
    } 
}
