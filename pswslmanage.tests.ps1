Describe 'Common asgard tests' {
    
    BeforeAll {
        try {

            $script:_wsl_test_workdir = "c:\temp\wsl"
            

            Write-Host "Test prerequisites: Prequisites done"
        } catch {
            Write-Host "Test prerequisites: Failed to prepare pester tests. Details: $($_.Exception.Message)"
            throw "Exit"
        }
    }

    It 'Test the InModule function ""Get-AsgardFileName""' {

        if($script:_test_get_asgardfilename -eq $true) {

            InModuleScope Asgard -Parameters @{ _local_test_data_dir = $script:_local_test_data_dir } {             
                
                $_file_timestamp = Get-Date -format "yyyyMMdd"
                Write-Host "Test Get-AsgardFileName: Create test files in $($_local_test_data_dir)"
                "DUMMY000" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_000.json"
                "DUMMY001" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_001.json"
                "DUMMY002" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_002.json"
                "DUMMY003" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_003.json"
                "DUMMY004" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_004.json"
                "DUMMY005" | Out-File -Encoding UTF8 -FilePath "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_005.json"

                Write-Host "Test Get-AsgardFileName: Get the dump"
                $_file = Get-AsgardFileName -Path "$_local_test_data_dir/CE-Dump"
                $_file | Should -Be "$($_file_timestamp)_006.json"

                Write-Host "Test Get-AsgardFileName: Remove test files"
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_000.json" -Force
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_001.json" -Force
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_002.json" -Force
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_003.json" -Force
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_004.json" -Force
                Remove-Item -Path "$_local_test_data_dir/CE-Dump/$($_file_timestamp)_005.json" -Force
            }
        }
    }

    AfterAll {
        Write-Host "Test cleanup: Delete the ce list"
        $_sp_test_ce_list = $(Get-PnPList | Where-Object { $_.Title -eq "$_sp_test_ce_list_name" }) # This is needed, because it is not allowed to use complex variables that are create in the BeforeAll block.
        Remove-PnPList -Identity $_sp_test_ce_list -Force

        Write-Host "Test cleanup: Delete the hs list"
        $_sp_test_hs_list = $(Get-PnPList | Where-Object { $_.Title -eq "$_sp_test_hs_list_name" }) # This is needed, because it is not allowed to use complex variables that are create in the BeforeAll block.
        Remove-PnPList -Identity $_sp_test_hs_list -Force

        Write-Host "Test cleanup: Delete the local data directory"
        if(Test-Path -Path "$script:_local_test_data_dir") {
            Remove-Item "$script:_local_test_data_dir" -Force -Recurse
        }
    } 
}
