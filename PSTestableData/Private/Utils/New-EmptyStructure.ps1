function New-EmptyStructure {
    <#
    .SYNOPSIS
        Creates an empty object structure with all fields set to null (Pass 1).

    .DESCRIPTION
        This function creates a complete object structure based on the configuration,
        with all leaf fields set to null. This is Pass 1 of the three-pass generation
        process, which establishes the structure before populating any values.

    .PARAMETER Config
        The configuration hashtable defining the structure to create.

    .EXAMPLE
        New-EmptyStructure -Config $config

        Creates an empty structure with all fields set to null.

    .OUTPUTS
        A hashtable representing the empty structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $result = @{}

    foreach ($key in $Config.Keys) {
        $fieldConfig = $Config[$key]

        if ($fieldConfig -is [hashtable]) {
            if ($fieldConfig.ContainsKey('Type') -and $fieldConfig.Type -eq 'array') {
                # Array field
                $arrayCount = if ($fieldConfig.ContainsKey('ArrayCount')) { $fieldConfig.ArrayCount } else { 1 }

                if ($fieldConfig.ContainsKey('ItemStructure')) {
                    # Array of objects - create array of empty structures
                    $result[$key] = @(1..$arrayCount | ForEach-Object {
                        New-EmptyStructure -Config $fieldConfig.ItemStructure
                    })
                }
                # Simple arrays without ItemStructure are not created in Pass 1
                # They will be populated entirely in Pass 2 (Set-NonLinkedFields)
            }
            elseif ($fieldConfig.ContainsKey('Type')) {
                # Leaf field - set to null
                $result[$key] = $null
            }
            else {
                # Nested object - recurse
                $result[$key] = New-EmptyStructure -Config $fieldConfig
            }
        }
    }

    return $result
}
