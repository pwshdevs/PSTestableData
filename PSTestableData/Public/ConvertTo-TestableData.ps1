function ConvertTo-TestableData {
    <#
    .SYNOPSIS
    Converts JSON or YAML data to PowerShell objects and writes them to a .ps1 file for dot-sourcing.

    .DESCRIPTION
    This function takes JSON or YAML input as a string, converts it to PowerShell objects
    (hashtables/PSCustomObjects), and writes the converted data to a PowerShell script file
    that can be dot-sourced. The output file will contain two variables based on the Name parameter.

    .PARAMETER InputObject
    The raw JSON or YAML data as a string to be converted.

    .PARAMETER Name
    The base name used to define the variable in the output file.
    Creates variable: $Name

    .PARAMETER Path
    The file path where the .ps1 file will be written.

    .PARAMETER From
    Specifies the input format of the data. Valid values are 'json' or 'yaml'.

    .PARAMETER Anonymize
    When specified, anonymizes sensitive data in the output by replacing strings, numbers, and dates with randomized but consistent values.

    .PARAMETER AsHashtable
    Converts the input data to hashtable format in the output.

    .PARAMETER AsPSCustomObject
    Converts the input data to PSCustomObject format in the output.

    .PARAMETER Force
    Overwrites the output file if it already exists.

    .PARAMETER Append
    Appends the output to the existing file instead of overwriting it.

    .EXAMPLE
    $jsonData = '{"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}]}'
    ConvertTo-TestableData -InputObject $jsonData -Name "TestUsers" -Path "C:\temp\TestUsers.ps1" -From json

    This example converts a JSON string containing an array of user objects into a PowerShell script file.
    The output file will contain variables $TestUsers (the original JSON string) and $TestUsersObject
    (the converted PowerShell object), which can be dot-sourced for testing purposes.

    .EXAMPLE
    $yamlData = @"
    database:
      host: localhost
      port: 5432
      name: testdb
    "@
    ConvertTo-TestableData -InputObject $yamlData -Name "DatabaseConfig" -Path "C:\temp\DatabaseConfig.ps1" -From yaml

    This example converts a YAML string defining database configuration into a PowerShell script file.
    The resulting file will have $DatabaseConfig (original YAML) and $DatabaseConfigObject
    (converted PowerShell hashtable), allowing for easy testing of database-related code.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'TestableData')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'AnonymizedTestableData')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'HashtableTestableData')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'PSCustomObjectTestableData')]
        [string]$InputObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'TestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'HashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PSCustomObjectTestableData')]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'TestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'HashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PSCustomObjectTestableData')]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'TestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'HashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PSCustomObjectTestableData')]
        [ValidateSet('yaml', 'json')]
        [string]$From,

        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [switch]$Anonymize,

        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedHashtableTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'HashtableTestableData')]
        [switch]$AsHashtable,

        [Parameter(Mandatory = $true, ParameterSetName = 'AnonymizedPSCustomObjectTestableData')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PSCustomObjectTestableData')]
        [switch]$AsPSCustomObject,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Append
    )

    begin {
        # Input/Output function checks
        if(-not (Get-Command ConvertFrom-Json -ErrorAction SilentlyContinue)) {
            Write-Warning "ConvertFrom-Json cmdlet is not available. Please ensure you are running PowerShell 3.0 or later."
            return
        }

        if(-not (Get-Command ConvertTo-Json -ErrorAction SilentlyContinue)) {
            Write-Warning "ConvertTo-Json cmdlet is not available. Please ensure you are running PowerShell 3.0 or later."
            return
        }

        if(-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
            Write-Warning "ConvertFrom-Yaml cmdlet is not available. YAML input will not be supported unless the powershell-yaml module is installed."
            return
        }

        if(-not (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue)) {
            Write-Warning "ConvertTo-Yaml cmdlet is not available. YAML output will not be supported unless the powershell-yaml module is installed."
            return
        }

        Write-Verbose "Starting conversion process for '$Name'"
        Write-Verbose "Output path: $Path"
        $InputData = ""
    }

    process {
        $InputData += $InputObject + "`n"
    }

    end {
        $InputData = $InputData.Trim()
        Write-Verbose "Received input data:`n$InputData"
        try {
            if($null -eq $InputData -or [string]::IsNullOrWhiteSpace($InputData)) {
                Write-Warning "InputObject cannot be null or empty."
                return
            }

            if($null -eq $Name -or [string]::IsNullOrWhiteSpace($Name)) {
                Write-Warning "Name cannot be null or empty."
                return
            }

            if($null -eq $Path -or [string]::IsNullOrWhiteSpace($Path)) {
                Write-Warning "Path cannot be null or empty."
                return
            }

            if((Test-Path -Path $Path) -and (-not $Force) -and (-not $Append)) {
                Write-Warning "The file at path '$Path' already exists. Use -Force to overwrite or -Append to append."
                return
            }

            if($null -eq $From -or [string]::IsNullOrWhiteSpace($From)) {
                Write-Warning "From parameter cannot be null or empty. Specify 'json' or 'yaml'."
                return
            }


            # Determine if input is JSON or YAML
            $convertedObject = $null

            switch($From) {
                'json' {
                    try {
                        $convertedObject = $InputData | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Failed to convert from JSON: $($_.Exception.Message)"
                        return
                    }
                }
                'yaml' {
                    try {
                        $convertedObject = $InputData | ConvertFrom-Yaml -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Failed to convert from YAML: $($_.Exception.Message)"
                        return
                    }
                }
                default {
                    Write-Warning "Invalid value for -From parameter. Use 'json' or 'yaml'."
                    return
                }
            }

            if($null -eq $convertedObject) {
                Write-Warning "Conversion resulted in null object. Please check the input data."
                return
            }

            # Get the original type of the converted object
            $originalType = $convertedObject.GetType().Name
            Write-Verbose "Original object type: $originalType"

            # Always include original string data (preserve InputData exactly as provided)
            $originalString = $InputData

            # Generate converted object syntax based on format
            $convertedObjectSyntax = ""
            $dataTypeString = ""


            if($AsHashtable) {
                $hashtableData = ConvertTo-Hashtable -InputObject $convertedObject -Anonymize:$Anonymize
                $convertedObjectSyntax = Out-Determinizer -InputObject $hashtableData -Anonymize:$Anonymize
            } elseif($AsPSCustomObject) {
                $pscustomData = ConvertTo-PSCustomObject -InputObject $convertedObject -Anonymize:$Anonymize
                $convertedObjectSyntax = Out-Determinizer -InputObject $pscustomData -Anonymize:$Anonymize
            } else {
                $convertedObjectSyntax = Out-Determinizer -InputObject $convertedObject -Anonymize:$Anonymize
            }

            $outputContent = @"
# Generated by ConvertTo-TestableData on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Output format: $dataTypeString

`$$Name = @'
$originalString
'@

`$${Name}Object = $convertedObjectSyntax
"@

            # Ensure the directory exists
            $directory = Split-Path -Path $Path -Parent
            if (-not (Test-Path -Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
                Write-Verbose "Created directory: $directory"
            }

            # Write the content to file
            $outputContent | Out-File -FilePath $Path -Encoding utf8 -Force:$Force -Append:$Append

            # Write-Verbose "Successfully wrote testable data to: $Path"
            # Write-Host "Created PowerShell data file: $Path" -ForegroundColor Green
            # Write-Host "Variables created: `$$Name, `$${Name}Object" -ForegroundColor Green
            # Write-Host "Output format: $OutputFormat" -ForegroundColor Green
            # Write-Host "To use: . '$Path'" -ForegroundColor Cyan

            # Return information about what was created
            return [PSCustomObject]@{
                OutputPath = $Path
                VariableNames = @($Name, "${Name}Object")
                OutputFormat = $OutputFormat
                OriginalType = $originalType
                Success = $true
                Force = $Force
                Append = $Append
            }
        }
        catch {
            Write-Error "Failed to convert data: $($_.Exception.Message)"
            return [PSCustomObject]@{
                OutputPath = $Path
                VariableNames = @()
                DataType = 'Unknown'
                Success = $false
                Error = $_.Exception.Message
                ErrorStackTrace = $_.ScriptStackTrace
            }
        }
    }
}
