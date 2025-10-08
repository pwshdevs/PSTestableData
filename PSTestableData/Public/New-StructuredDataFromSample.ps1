function New-StructuredDataFromSample {
    <#
    .SYNOPSIS
        Analyzes structured data and generates new data following the same patterns and structure.

    .DESCRIPTION
        This function takes structured data (hashtables, arrays, PSCustomObjects) and analyzes their patterns
        to generate new data that follows the same structure. It can create realistic test data by examining
        existing data patterns including field types, array sizes, nested structures, and value formats.

    .PARAMETER InputObject
        The structured data to analyze and use as a template for generating new data.

    .PARAMETER Count
        The number of new data items to generate. Default is 1.

    .PARAMETER MaxArrayItems
        The maximum number of items to generate for arrays. Default is 5.

    .PARAMETER Anonymize
        Whether to anonymize the generated data values while preserving structure.

    .PARAMETER PreserveFields
        Array of field name patterns that should not be anonymized. Supports wildcards.
        Examples: 'apiVersion', 'kind', '*.phase', 'metadata.labels.*'

    .PARAMETER UseKubernetesPresets
        When enabled, automatically preserves common Kubernetes system fields like apiVersion, kind, phase, etc.

    .EXAMPLE
        $sample = @{
            name = "John Doe"
            age = 30
            items = @("item1", "item2")
        }
        New-StructuredDataFromSample -InputObject $sample

        Generates a new hashtable with the same structure but different values.

    .EXAMPLE
        $yamlData = ConvertFrom-Yaml $yamlString
        New-StructuredDataFromSample -InputObject $yamlData -Count 3

        Generates 3 new data structures based on the YAML input pattern.

    .OUTPUTS
        [object] - New structured data following the input pattern
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxArrayItems = 5,

        [Parameter(Mandatory = $false)]
        [switch]$Anonymize,

        [Parameter(Mandatory = $false)]
        [string[]]$PreserveFields = @(),

        [Parameter(Mandatory = $false)]
        [switch]$UseKubernetesPresets
    )

    begin {
        # Define comprehensive Kubernetes field preservation patterns
        $kubernetesPreservePatterns = @(
            # Core API fields
            'apiVersion', 'kind', 'type',

            # Status and phase fields (at any level)
            'status.phase', '*.status.phase', 'phase', '*.phase',
            'status.state', '*.status.state', 'state', '*.state',
            'status', '*.status',

            # Metadata fields
            'metadata.namespace', 'metadata.resourceVersion',
            'metadata.labels.*', 'metadata.annotations.*',

            # Spec fields
            'spec.type', 'spec.protocol', 'spec.clusterIP',

            # Array item patterns for Lists
            # 'items.*.apiVersion', 'items.*.kind', 'items.*.type',
            # 'items.*.status.phase', 'items.*.status.state', 'items.*.status',
            # 'items.*.metadata.namespace', 'items.*.metadata.resourceVersion',
            # 'items.*.metadata.labels.*', 'items.*.metadata.annotations.*',
            # 'items.*.spec.type', 'items.*.spec.protocol',

            # Nested patterns
            '*.apiVersion', '*.kind', '*.type'
        )
    }

    process {
        # Combine user patterns with Kubernetes presets if enabled
        $allPreservePatterns = $PreserveFields
        if ($UseKubernetesPresets) {
            $allPreservePatterns += $kubernetesPreservePatterns
            # Auto-enable anonymization when using Kubernetes presets
            # since preservation only works with anonymization enabled
            if (-not $Anonymize.IsPresent) {
                $Anonymize = $true
                Write-Verbose "Auto-enabling anonymization for Kubernetes presets"
            }
        }
    }

    end {
        Write-Verbose "Preserve Patterns: $($allPreservePatterns -join ', ')"
        Write-Verbose "Anonymization enabled: $($Anonymize -eq $true)"

        # Initialize custom random number generator for better randomization
        $customRandom = [System.Random]::new()

        # Analyze the input structure
        $structurePattern = Get-StructurePattern -Object $InputObject -PreservePatterns $allPreservePatterns

        # Determine if anonymization should be applied
        $shouldAnonymize = ($Anonymize -eq $true) -or $Anonymize.IsPresent

        # Generate the requested number of new items
        if ($Count -eq 1) {
            # Generate single item directly to avoid array unwrapping issues
            return New-DataFromStructure -Pattern $structurePattern -MaxArrayItems $MaxArrayItems -RandomGenerator $customRandom -Anonymize:$Anonymize
        }
        else {
            $results = @()
            for ($i = 0; $i -lt $Count; $i++) {
                $results += New-DataFromStructure -Pattern $structurePattern -MaxArrayItems $MaxArrayItems -RandomGenerator $customRandom -Anonymize:$Anonymize
            }
            return $results
        }
    }
}
