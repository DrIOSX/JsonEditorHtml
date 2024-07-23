BeforeAll {
    $script:moduleName = 'JsonEditorHtml'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}


Describe 'ConvertTo-JsonEditorHtml' {

    Context 'Parameter validation' {
        It 'Throws an error if the JsonFilePath does not exist' {
            { ConvertTo-JsonEditorHtml -JsonFilePath 'NonExistentPath.json' -OutputHtmlFilePath (Join-Path $TestDrive 'output.html') } | Should -Throw
        }

        It 'Does not throw an error if JsonString is provided' {
            { ConvertTo-JsonEditorHtml -JsonString '{"key": "value"}' -OutputHtmlFilePath (Join-Path $TestDrive 'output.html') } | Should -Not -Throw
        }

        It 'Throws an error if neither JsonFilePath nor JsonString are provided' {
            { ConvertTo-JsonEditorHtml -OutputHtmlFilePath (Join-Path $TestDrive 'output.html') } | Should -Throw
        }
    }

    Context 'HTML generation' {
        It 'Generates an HTML file with JSON content from a file' {
            $outputPath = "$TestDrive\output.html"
            $jsonFilePath = "$TestDrive\input.json"
            Set-Content -Path $jsonFilePath -Value '{"key": "value"}'
            ConvertTo-JsonEditorHtml -JsonFilePath $jsonFilePath -OutputHtmlFilePath $outputPath
            Test-Path $outputPath | Should -Be $true
        }

        It 'Generates an HTML file with JSON content from a string' {
            $outputPath = "$TestDrive\output.html"
            ConvertTo-JsonEditorHtml -JsonString '{"key": "value"}' -OutputHtmlFilePath $outputPath
            Test-Path $outputPath | Should -Be $true
        }
    }
}


