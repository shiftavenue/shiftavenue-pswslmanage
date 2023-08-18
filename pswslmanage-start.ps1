try {
        # Check scripts against Script-analyzer
        if (-Not (Get-Module PSScriptAnalyzer)) { Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser }
        Invoke-ScriptAnalyzer "$PSScriptRoot\pswslmanage.psm1"
        
        # if (-Not (Get-Module Pester)) { Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck }
        # Invoke-Pester $PSScriptRoot\asgard\tests\Asgard.Tests.ps1


    # Remove module first to get the newest version in session
    if (Get-Module pswslmanage) { 
        Remove-Module pswslmanage -Force
    }

    # Import the module
    Import-Module "$PSScriptRoot\pswslmanage.psd1" -Force

    Add-WSLImage 

} catch {
    throw $_.Exception.Message
}


