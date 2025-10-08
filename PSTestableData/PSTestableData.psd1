@{
    RootModule = 'PSTestableData.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a20ba0ae-af91-4dde-8657-c21e140d50ec'
    Author = 'Joshua Wilson'
    CompanyName = 'PwshDevs'
    Copyright = '(c) 2025 PwshDevs. All rights reserved.'
    PowerShellVersion = '5.1'
    Description = 'A module to help convert and generate test data for Pester tests.'
    FunctionsToExport = @('ConvertTo-TestableData', 'New-ConfigurationFromSample', 'New-DataFromConfiguration', 'New-StructuredDataFromSample')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
                Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS', 'Test', 'Data', 'TestData', 'TestableData', 'Pester', 'YAML', 'JSON', 'Convert', 'Generate', 'Anonymize', 'Random', 'Structured', 'Object', 'Hashtable', 'Array')
                LicenseUri = 'https://github.com/pwshdevs/PSTestableData/blob/main/LICENSE'
                ProjectUri = 'https://github.com/pwshdevs/PSTestableData'
                ReleaseNotes = 'https://github.com/pwshdevs/PSTestableData/blob/main/CHANGELOG.md'

        }
    }
}
