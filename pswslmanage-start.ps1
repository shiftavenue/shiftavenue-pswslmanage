[CmdletBinding()]
param (
    [Parameter()]
    [switch]$RunLinter,    
    [Parameter()]
    [switch]$RunTests
)

try {
    if($RunLinter) {
        # Check scripts against Script-analyzer
        if (-Not (Get-Module PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser }
        Invoke-ScriptAnalyzer "$PSScriptRoot\pswslmanage.psm1"
        Invoke-ScriptAnalyzer "$PSScriptRoot\pswslmanage-helper.ps1"
        Invoke-ScriptAnalyzer "$PSScriptRoot\pswslmanage-roles.ps1"

    }
    
    if($RunTests) {
        if (-Not (Get-Module Pester)) { Install-Module -Name Pester -Force -Scope CurrentUser }
        Invoke-Pester $PSScriptRoot\tests\pswslmanage.tests.ps1
    } else {
        # Remove module first to get the newest version in session
        if (Get-Module pswslmanage) { 
            Remove-Module pswslmanage -Force
        }

        # Import the module
        Import-Module "$PSScriptRoot\pswslmanage.psd1" -Force
    }

} catch {
    throw $_.Exception.Message
}


