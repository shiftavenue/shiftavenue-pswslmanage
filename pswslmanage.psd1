@{

    RootModule = 'pswslmanage.psm1'
    ModuleVersion = '1.0.161'
    CompatiblePSEditions = 'Core'
    GUID = 'a2d16567-94f2-4a76-8e0d-c29d40177c56'
    PowerShellVersion = '5.1'
    Author = 'David Koenig'
    CompanyName = 'shiftavenue'
    Copyright = '(c) shiftavenue. All rights reserved.'
    Description = 'With this module you can install and maintain WSL images'
    FunctionsToExport = @("Add-WslImage", "Test-WslImage", "Get-WslImage", "Remove-WslImage", "Stop-WslImage", "Add-WslUser", "Add-WslRoleSSH" )
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    PrivateData = @{

        PSData = @{
            # Tags = @()
            # LicenseUri = ''
            # ProjectUri = ''
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''
}