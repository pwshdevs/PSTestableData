function New-ValueFromConfig {
    <#
    .SYNOPSIS
        Generates a value based on field configuration and action type.

    .DESCRIPTION
        This function generates values for fields based on their Type and Action properties.
        Supports Preserve, Anonymize, Randomize, and Link actions. Handles various data types
        including string, int, long, double, bool, datetime, and guid.

    .PARAMETER FieldConfig
        The field configuration hashtable containing Type and Action properties.

    .PARAMETER SeedValue
        Optional seed value to use for Preserve or Anonymize actions.

    .PARAMETER FieldPath
        The path to the field (used for error messages and warnings).

    .PARAMETER ResultContext
        Optional context hashtable for resolving linked values.

    .PARAMETER FullConfig
        Optional full configuration for on-demand generation of linked fields.

    .PARAMETER FullSeed
        Optional full seed data for on-demand generation.

    .PARAMETER CurrentResult
        Optional current result hashtable for storing generated linked values.

    .EXAMPLE
        New-ValueFromConfig -FieldConfig @{ Type = 'string'; Action = 'Randomize' } -FieldPath 'name'

        Generates a random string value.

    .OUTPUTS
        The generated value based on the field configuration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FieldConfig,

        [Parameter(Mandatory = $false)]
        [object]$SeedValue,

        [Parameter(Mandatory = $true)]
        [string]$FieldPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$ResultContext = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]$FullConfig = $null,

        [Parameter(Mandatory = $false)]
        [object]$FullSeed = $null,

        [Parameter(Mandatory = $false)]
        [hashtable]$CurrentResult = $null
    )

    $type = $FieldConfig.Type
    $action = $FieldConfig.Action

    # Handle null type
    if ($type -eq 'null') {
        return $null
    }

    # If action is Link, get value from linked field
    if ($action -eq 'Link') {
        if ($FieldConfig.ContainsKey('LinkTo')) {
            $linkPath = $FieldConfig.LinkTo

            # First, try to find the value in ResultContext
            $linkedValue = Get-LinkedValue -Result $ResultContext -LinkPath $linkPath

            # If not found and we have config/seed, try CurrentResult (local scope)
            if ($null -eq $linkedValue -and $null -ne $CurrentResult) {
                $linkedValue = Get-LinkedValue -Result $CurrentResult -LinkPath $linkPath
                if ($null -ne $linkedValue) {
                    Write-Verbose "New-ValueFromConfig: Found '$linkPath' in CurrentResult, value='$linkedValue'"
                }
            }

            # If still not found and we have the config, generate it on-demand
            if ($null -eq $linkedValue -and $null -ne $FullConfig -and $FullConfig.ContainsKey($linkPath)) {
                Write-Verbose "New-ValueFromConfig: Linked field '$linkPath' not found, generating on-demand"
                $targetConfig = $FullConfig[$linkPath]
                $targetSeed = Get-SeedValue -SeedObject $FullSeed -FieldPath $linkPath
                $linkedValue = New-ValueFromConfig -FieldConfig $targetConfig -SeedValue $targetSeed -FieldPath $linkPath -ResultContext $ResultContext -FullConfig $FullConfig -FullSeed $FullSeed -CurrentResult $CurrentResult

                # Store the generated value in CurrentResult so other fields can use it
                if ($null -ne $CurrentResult) {
                    $CurrentResult[$linkPath] = $linkedValue
                    Write-Verbose "New-ValueFromConfig: Stored generated value for '$linkPath' in CurrentResult"
                }
            }

            Write-Verbose "New-ValueFromConfig: Link action, LinkTo='$linkPath', linkedValue='$linkedValue'"
            return $linkedValue
        }
        else {
            Write-Verbose "Field '$FieldPath' has Link action but no LinkTo property. Generating random value."
            # Fall through to generate random value
            $action = 'Randomize'
        }
    }

    # If action is Preserve and we have seed data, use it
    if ($action -eq 'Preserve' -and $null -ne $SeedValue) {
        return $SeedValue
    }

    # Generate value based on type
    switch ($type) {
        'string' {
            if ($action -eq 'Anonymize' -and $null -ne $SeedValue -and $SeedValue -is [string]) {
                # Simple anonymization: scramble the string but keep length
                $length = $SeedValue.Length
                return -join ((65..90) + (97..122) | Get-Random -Count ([math]::Max(1, $length)) | ForEach-Object { [char]$_ })
            }
            else {
                # Generate random string
                $words = @('alpha', 'beta', 'gamma', 'delta', 'epsilon', 'zeta', 'theta', 'kappa', 'lambda', 'omega')
                return $words | Get-Random
            }
        }
        'int' {
            if ($action -eq 'Anonymize' -and $null -ne $SeedValue -and ($SeedValue -is [int] -or $SeedValue -is [int32])) {
                # Keep in similar range
                $range = [math]::Max(100, [math]::Abs($SeedValue))
                return Get-Random -Minimum ([math]::Max(0, $SeedValue - $range)) -Maximum ($SeedValue + $range)
            }
            else {
                return Get-Random -Minimum 1 -Maximum 1000
            }
        }
        'long' {
            if ($action -eq 'Anonymize' -and $null -ne $SeedValue) {
                $range = [math]::Max(1000, [math]::Abs($SeedValue))
                return [long](Get-Random -Minimum ([math]::Max(0, $SeedValue - $range)) -Maximum ($SeedValue + $range))
            }
            else {
                return [long](Get-Random -Minimum 1000 -Maximum 999999)
            }
        }
        'double' {
            if ($action -eq 'Anonymize' -and $null -ne $SeedValue) {
                return [double](Get-Random -Minimum 0.0 -Maximum 1000.0)
            }
            else {
                return [double](Get-Random -Minimum 0.0 -Maximum 1000.0)
            }
        }
        'bool' {
            return (Get-Random -Minimum 0 -Maximum 2) -eq 1
        }
        'datetime' {
            if ($action -eq 'Anonymize' -and $null -ne $SeedValue -and $SeedValue -is [datetime]) {
                # Random date within +/- 365 days
                $days = Get-Random -Minimum -365 -Maximum 365
                return $SeedValue.AddDays($days).ToString('yyyy-MM-ddTHH:mm:ssZ')
            }
            else {
                $days = Get-Random -Minimum -365 -Maximum 365
                return (Get-Date).AddDays($days).ToString('yyyy-MM-ddTHH:mm:ssZ')
            }
        }
        'guid' {
            return [guid]::NewGuid().ToString()
        }
        'array' {
            # Simple array - check if we have ItemType and ItemAction in FieldConfig
            if ($FieldConfig.ContainsKey('ItemType')) {
                $itemType = $FieldConfig.ItemType
                $itemAction = if ($FieldConfig.ContainsKey('ItemAction')) { $FieldConfig.ItemAction } else { 'Preserve' }
                $arrayCount = if ($FieldConfig.ContainsKey('ArrayCount')) { $FieldConfig.ArrayCount } else { 3 }

                # If Preserve action and we have seed value that's an array/list, use it
                if ($itemAction -eq 'Preserve' -and $null -ne $SeedValue) {
                    if ($SeedValue -is [array]) {
                        return , $SeedValue
                    }
                    elseif ($SeedValue -is [System.Collections.IList]) {
                        # Convert IList to array and return with comma operator
                        $arrayResult = @()
                        foreach ($item in $SeedValue) {
                            $arrayResult += $item
                        }
                        return , $arrayResult
                    }
                }

                # Generate array of values based on ItemType
                $items = @()
                for ($i = 0; $i -lt $arrayCount; $i++) {
                    # Create a simple field config for item generation
                    $itemFieldConfig = @{
                        Type = $itemType
                        Action = $itemAction
                    }
                    $itemValue = New-ValueFromConfig -FieldConfig $itemFieldConfig -SeedValue $null -FieldPath "$FieldPath[$i]"
                    $items += $itemValue
                }
                return , $items
            }
            else {
                Write-Verbose "Array type for field '$FieldPath' has no ItemType defined, using empty array"
                return , @()
            }
        }
        default {
            Write-Verbose "Unknown type '$type' for field '$FieldPath', using empty string"
            return ""
        }
    }
}
