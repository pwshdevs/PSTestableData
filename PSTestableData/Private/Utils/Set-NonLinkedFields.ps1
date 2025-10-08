function Set-NonLinkedFields {
    <#
    .SYNOPSIS
        Populates all non-linked fields in the result structure (Pass 2).

    .DESCRIPTION
        This function fills in all fields that don't have a Link action. It processes
        leaf fields, nested objects, and arrays recursively. This is Pass 2 of the
        three-pass generation process.

    .PARAMETER Config
        The configuration hashtable defining the fields to populate.

    .PARAMETER Result
        The result hashtable to populate (created by New-EmptyStructure).

    .PARAMETER SeedObject
        Optional seed data to use for Preserve or Anonymize actions.

    .PARAMETER ParentPath
        The parent path for error messages (used for recursion).

    .EXAMPLE
        Set-NonLinkedFields -Config $config -Result $result -SeedObject $seed

        Populates all non-linked fields in the result structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [hashtable]$Result,

        [Parameter(Mandatory = $false)]
        [object]$SeedObject = $null,

        [Parameter(Mandatory = $false)]
        [string]$ParentPath = ""
    )

    foreach ($key in $Config.Keys) {
        $fieldConfig = $Config[$key]
        $currentPath = if ($ParentPath) { "$ParentPath.$key" } else { $key }

        if ($fieldConfig -is [hashtable]) {
            if ($fieldConfig.ContainsKey('Type') -and $fieldConfig.Type -eq 'array') {
                # Array field
                if ($fieldConfig.ContainsKey('ItemStructure')) {
                    # Array of objects - process each item
                    $itemConfig = $fieldConfig.ItemStructure
                    $seedArray = Get-SeedValue -SeedObject $SeedObject -FieldPath $key

                    for ($i = 0; $i -lt $Result[$key].Count; $i++) {
                        # Use seed data as a template - if seed has fewer items than ArrayCount,
                        # cycle through the available seed items (modulo) or use first item as template
                        $itemSeed = if ($null -ne $seedArray -and ($seedArray -is [array] -or $seedArray -is [System.Collections.IList]) -and $seedArray.Count -gt 0) {
                            $seedIndex = $i % $seedArray.Count
                            $seedArray[$seedIndex]
                        }
                        else {
                            $null
                        }

                        Set-NonLinkedFields -Config $itemConfig -Result $Result[$key][$i] -SeedObject $itemSeed -ParentPath "$currentPath[$i]"
                    }
                }
                else {
                    # Simple array - populate as a whole
                    if ($fieldConfig.Action -ne 'Link') {
                        $seedValue = Get-SeedValue -SeedObject $SeedObject -FieldPath $key
                        $returnedValue = New-ValueFromConfig -FieldConfig $fieldConfig -SeedValue $seedValue -FieldPath $currentPath
                        # For arrays, ensure we preserve the array structure (prevent unwrapping)
                        if ($fieldConfig.Type -eq 'array') {
                            $Result[$key] = @($returnedValue)
                        }
                        else {
                            $Result[$key] = $returnedValue
                        }
                        Write-Verbose "Set-NonLinkedFields: Populated '$currentPath' with value='$($Result[$key])'"
                    }
                    else {
                        Write-Verbose "Set-NonLinkedFields: Skipping linked field '$currentPath'"
                    }
                }
            }
            elseif ($fieldConfig.ContainsKey('Type')) {
                # Leaf field - populate if not a Link action
                if ($fieldConfig.Action -ne 'Link') {
                    $seedValue = Get-SeedValue -SeedObject $SeedObject -FieldPath $key
                    $Result[$key] = New-ValueFromConfig -FieldConfig $fieldConfig -SeedValue $seedValue -FieldPath $currentPath
                    Write-Verbose "Set-NonLinkedFields: Populated '$currentPath' with value='$($Result[$key])'"
                }
                else {
                    Write-Verbose "Set-NonLinkedFields: Skipping linked field '$currentPath'"
                }
            }
            else {
                # Nested object - recurse
                $nestedSeed = Get-SeedValue -SeedObject $SeedObject -FieldPath $key
                Set-NonLinkedFields -Config $fieldConfig -Result $Result[$key] -SeedObject $nestedSeed -ParentPath $currentPath
            }
        }
    }
}
