function Set-LinkedFields {
    <#
    .SYNOPSIS
        Populates all linked fields in the result structure (Pass 3).

    .DESCRIPTION
        This function fills in all fields that have a Link action. It processes
        leaf fields, nested objects, and arrays recursively. This is Pass 3 of the
        three-pass generation process, which runs after all non-linked fields have
        been populated.

    .PARAMETER Config
        The configuration hashtable defining the fields to populate.

    .PARAMETER Result
        The result hashtable to populate (already has non-linked fields filled).

    .PARAMETER ResultContext
        The result context for resolving linked values (parent scope for arrays).

    .PARAMETER ParentPath
        The parent path for error messages (used for recursion).

    .EXAMPLE
        Set-LinkedFields -Config $config -Result $result -ResultContext $globalResult

        Populates all linked fields in the result structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [hashtable]$Result,

        [Parameter(Mandatory = $true)]
        [hashtable]$ResultContext,

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
                    # Array of objects - process each item with the item itself as context
                    $itemConfig = $fieldConfig.ItemStructure

                    for ($i = 0; $i -lt $Result[$key].Count; $i++) {
                        # Pass the array item as the ResultContext so links are resolved within the item
                        Set-LinkedFields -Config $itemConfig -Result $Result[$key][$i] -ResultContext $Result[$key][$i] -ParentPath "$currentPath[$i]"
                    }
                }
                # Simple arrays don't have linked fields
            }
            elseif ($fieldConfig.ContainsKey('Type')) {
                # Leaf field - populate if it's a Link action
                if ($fieldConfig.Action -eq 'Link') {
                    if ($fieldConfig.ContainsKey('LinkTo') -and -not [string]::IsNullOrEmpty($fieldConfig.LinkTo)) {
                        $linkPath = $fieldConfig.LinkTo

                        # Determine context for link resolution
                        # Try to resolve the link in the ResultContext first (for sibling references)
                        $linkedValue = Get-LinkedValue -Result $ResultContext -LinkPath $linkPath

                        # If not found and we're in a nested context, the link might be to a parent field
                        # This is already handled by passing the correct ResultContext during recursion

                        $Result[$key] = $linkedValue
                        Write-Verbose "Set-LinkedFields: Populated linked field '$currentPath' with value='$linkedValue' from LinkTo='$linkPath'"
                    }
                    else {
                        # Missing LinkTo - generate a random value instead
                        Write-Verbose "Field '$currentPath' has Link action but no LinkTo property. Generating random value."
                        # Create a copy of config with Action changed to Randomize to avoid Link processing
                        $randomizeConfig = $fieldConfig.Clone()
                        $randomizeConfig['Action'] = 'Randomize'
                        $Result[$key] = New-ValueFromConfig -FieldConfig $randomizeConfig -SeedValue $null -FieldPath $currentPath -ResultContext $ResultContext
                    }
                }
            }
            else {
                # Nested object - recurse
                # Determine correct context by analyzing if linked fields reference local or parent properties
                $hasLocalLinks = $false

                foreach ($nestedKey in $fieldConfig.Keys) {
                    $nestedField = $fieldConfig[$nestedKey]
                    if ($nestedField -is [hashtable] -and
                        $nestedField.ContainsKey('Action') -and
                        $nestedField['Action'] -eq 'Link' -and
                        $nestedField.ContainsKey('LinkTo')) {

                        # Check if link target (first segment) exists in nested config
                        $linkTarget = $nestedField['LinkTo'] -split '\.' | Select-Object -First 1
                        if ($fieldConfig.ContainsKey($linkTarget)) {
                            # Link target is defined in the same config object (local link)
                            $hasLocalLinks = $true
                            Write-Verbose "Set-LinkedFields: Found local link in '$currentPath': '$nestedKey' -> '$linkTarget'"
                            break
                        }
                    }
                }

                # If nested config has local links, pass nested result as context
                # Otherwise pass parent result to allow links to parent's siblings
                $contextForNested = if ($hasLocalLinks) { $Result[$key] } else { $Result }

                Write-Verbose "Set-LinkedFields: Nested object '$currentPath', recursing with $(if($hasLocalLinks){'local'}else{'parent'}) context"
                Set-LinkedFields -Config $fieldConfig -Result $Result[$key] -ResultContext $contextForNested -ParentPath $currentPath
            }
        }
    }
}
