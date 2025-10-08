function New-DataFromConfiguration {
    <#
    .SYNOPSIS
        Generates new data based on a configuration file and optional seed data.

    .DESCRIPTION
        This function uses a configuration file (created by New-ConfigurationFromSample) to generate
        test data. The configuration controls how each field is handled (Preserve, Anonymize, or
        Randomize), field types, and array sizes. Optionally, seed data can be provided to sample
        values from when preserving or anonymizing fields.

    .PARAMETER ConfigPath
        Path to the configuration file (.ps1) created by New-ConfigurationFromSample.
        The file will be dot-sourced to load the configuration.

    .PARAMETER Config
        Configuration hashtable directly (alternative to ConfigPath).
        Use this when you want to pass the configuration object directly without saving to a file.

    .PARAMETER SeedData
        Seed data to use as a source for preserved or anonymized values.
        This parameter accepts pipeline input, allowing you to pipe actual data directly.

    .PARAMETER Count
        The number of data items to generate. Default is 1.

    .PARAMETER AsJson
        Return the generated data as JSON string.

    .PARAMETER AsYaml
        Return the generated data as YAML string (requires powershell-yaml module).

    .EXAMPLE
        # Generate multiple items with seed data from pipeline
        $actualData | New-DataFromConfiguration -ConfigPath '.\config.ps1' -Count 5

        Pipes actual data as seed and generates 5 new items using it as source for preserved/anonymized values.

    .EXAMPLE
        # Generate and output as JSON
        $seed | New-DataFromConfiguration -ConfigPath '.\config.ps1' -AsJson

        Pipes seed data and returns generated data as a JSON string.

    .EXAMPLE
        # Use configuration hashtable directly
        $config = New-ConfigurationFromSample -SampleObject $sample
        $data = New-DataFromConfiguration -Config $config -SeedData $sample

        Generates data using a configuration hashtable without saving to file.

    .OUTPUTS
        [object] - New data following the configuration pattern
        [string] - JSON or YAML string if AsJson or AsYaml is specified
    #>
    [CmdletBinding(DefaultParameterSetName = 'FromPath')]
    [OutputType([object], [string])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'FromPath')]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Configuration file not found: $_"
            }
            if ($_ -notmatch '\.ps1$') {
                throw "Configuration file must be a .ps1 file"
            }
            $true
        })]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromHashtable')]
        [ValidateNotNull()]
        [hashtable]$Config,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$SeedData,

        [Parameter(Mandatory = $false)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [switch]$AsJson,

        [Parameter(Mandatory = $false)]
        [switch]$AsYaml
    )

    begin {
        # Load the configuration
        if ($PSCmdlet.ParameterSetName -eq 'FromPath') {
            try {
                $resolvedPath = Resolve-Path $ConfigPath -ErrorAction Stop
                $configuration = . $resolvedPath
                Write-Verbose "Configuration loaded from: $resolvedPath"
            }
            catch {
                throw "Failed to load configuration from '$ConfigPath': $_"
            }

            if (-not $configuration -or $configuration -isnot [hashtable]) {
                throw "Invalid configuration file. Expected a hashtable but got: $($configuration.GetType().Name)"
            }
        }
        else {
            # Using hashtable directly
            $configuration = $Config
            Write-Verbose "Using configuration hashtable provided directly"
        }

        Test-LinkedFieldConfiguration -Config $configuration
    }

    process {
        $results = [System.Collections.ArrayList]::new()

        for ($i = 0; $i -lt $Count; $i++) {
            Write-Verbose "Generating data item $($i + 1) of $Count"

            # Use the three-pass approach from Initialize-DataFromConfig
            $generatedData = Initialize-DataFromConfig -Config $configuration -SeedObject $SeedData

            [void]$results.Add($generatedData)
        }

        # Return single item if Count is 1, otherwise return array
        $output = if ($Count -eq 1) { $results[0] } else { @($results.ToArray()) }

        # Handle output format
        if ($AsJson) {
            return $output | ConvertTo-Json -Depth 10
        }
        elseif ($AsYaml) {
            if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
                return $output | ConvertTo-Yaml
            }
            else {
                Write-Warning "ConvertTo-Yaml command not found. Install powershell-yaml module. Returning object instead."
                return $output
            }
        }
        else {
            return $output
        }
    }
}
