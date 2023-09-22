# Publish a Powershell module to GitHub Packages

This is also discussed [at stacoverflow](https://stackoverflow.com/questions/77107833/publish-module-raises-401-when-using-github-action)

My first attempt was, to publish the dev-builds to GitHub packages instead of the Powershell Gallery (with prerelease flag), which was not successful. The v2-Powershell commands where not compatible with GitHub Pacakges. It is needed to install the v3-PSResourceGet commands together with the compatibility module "CompatPowerShellGet". I was successful by running the commands manually. I was able to Publish (```Publish-Module ...```) the module, to find (```Find-Module -Name pswslmanage -Repository SAPSGallery```) and to install the module (```Install-Module ...```) from the GitHub Packages.

But within a GitHub action it failes with the following output:

```log
VERBOSE: Performing the operation "Publish-PSResource" on target "Publish resource 'C:\ProgramData\GitHub-Actions-Runner\_work\shiftavenue-pswslmanage\shiftavenue-pswslmanage\pswslmanage' from the machine".
VERBOSE: The newly created nuspec is: C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp\233a4e7a-ceca-4894-9705-9001f72f5585\pswslmanage.nuspec
VERBOSE: Successfully packed the resource into a .nupkg
VERBOSE: Not able to publish resource to 'https://nuget.pkg.github.com/shiftavenue/index.json'
VERBOSE: Deleting temporary directory 'C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp\233a4e7a-ceca-4894-9705-9001f72f5585'
Publish-PSResource: C:\ProgramData\GitHub-Actions-Runner\_work\_temp\5615f135-c32d-49aa-81ec-3147104bfb1c.ps1:39
Line |
  39 |  Publish-Module -Path "$_repo_dir" -Repository "$_repo_name" -NuGetApi …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Repository 'SAPSGallery': Response status code does not indicate success: 403 (Forbidden).
Error: Process completed with exit code 1.

```

To not loose the KnowHow, how i did that (i like the idea so propably i try that again later) here is the code from the publishing part of the GitHub workflow.

```yaml
      - name: Publish
        run: |
          $_repo_name = "SAPSGallery"
          $_repo_owner = "shiftavenue"
          $_feed = "https://nuget.pkg.github.com/$_repo_owner/index.json"
          $_user = "github"
          $_token = $($env:GH_TOKEN)
          $_token = "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"
          $_token_enc = "$_token" | ConvertTo-SecureString -AsPlainText -Force
          $_creds = New-Object System.Management.Automation.PSCredential -ArgumentList @($_user, $_token_enc)
          $_module_name = "pswslmanage"
          $_repo_dir = "{0}\shiftavenue-pswslmanage\pswslmanage" -f $($env:RUNNER_WORKSPACE)

          echo "-----------------"
          echo "repo_name:   $_repo_name"
          echo "repo_owner:  $_repo_owner"
          echo "feeds:       $_feed"
          echo "user:        $_user"
          echo "module_name: $_module_name"
          echo "repo_dir:   $_repo_dir"
          echo "-----------------"

          echo "Activate TLS 1.2"
          [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
          
          echo "Import the PSResouceGet module"
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module -Name Microsoft.PowerShell.PSResourceGet -AllowClobber -AllowPrerelease -Force -Scope CurrentUser
          Import-Module -Name Microsoft.PowerShell.PSResourceGet
          
          echo "Import the PowerShellGet Comapt Module"
          Install-Module -Name CompatPowerShellGet -AllowClobber -Force -Scope CurrentUser
          Import-Module -Name CompatPowerShellGet -Force
          Set-PSRepository PSGallery -InstallationPolicy Untrusted
          
          echo "Register repository"
          if(Get-PSRepository -Name SAPSGallery -ErrorAction SilentlyContinue) { Unregister-PSRepository -Name SAPSGallery }
          Register-PSRepository -Name $_repo_name -SourceLocation $_feed -PublishLocation $_feed -InstallationPolicy 'Trusted' -Credential $_creds
          
          echo "Publish the package"
          Publish-Module -Path "$_repo_dir" -Repository "$_repo_name" -NuGetApiKey "$_token" -Verbose
        env:
          GH_TOKEN: ${{secrets.GITHUB_TOKEN}}
        shell: pwsh
```
