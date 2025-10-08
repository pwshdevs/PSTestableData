function Test-LinkedFieldConfiguration {
    <#
    .SYNOPSIS
        Validates linked field configuration to ensure no circular references or invalid links.

    .DESCRIPTION
        This function validates that all linked fields in a configuration:
        - Do not create circular references
        - Do not create chained links
        - Only link to existing fields
        - Only link upward or to siblings (not downward to children)
        - Array items only link within the same array item

    .PARAMETER Config
        The configuration hashtable to validate.

    .PARAMETER Path
        The current path in the configuration (used for recursion).

    .EXAMPLE
        Test-LinkedFieldConfiguration -Config $configuration

        Validates all linked fields in the configuration.

    .OUTPUTS
        None - throws an exception if validation fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [string]$Path = ""
    )

    $linkedFields = @{}  # Track all linked fields: path -> target path
    $allFields = @{}     # Track all fields and their depths for validation

    function Collect-Fields {
        param(
            [hashtable]$Cfg,
            [string]$CurrentPath = "",
            [int]$Depth = 0,
            [bool]$InArrayItem = $false
        )

        foreach ($key in $Cfg.Keys) {
            $fieldConfig = $Cfg[$key]
            $fieldPath = if ($CurrentPath) { "$CurrentPath.$key" } else { $key }

            if ($fieldConfig -is [hashtable]) {
                if ($fieldConfig.ContainsKey('Action') -and $fieldConfig.Action -eq 'Link') {
                    if ($fieldConfig.ContainsKey('LinkTo')) {
                        $linkedFields[$fieldPath] = @{
                            Target = $fieldConfig.LinkTo
                            InArrayItem = $InArrayItem
                            ParentPath = $CurrentPath
                        }
                        $allFields[$fieldPath] = $Depth
                        Write-Verbose "Test-LinkedFieldConfiguration: Found linked field '$fieldPath' (depth=$Depth, inArray=$InArrayItem) -> '$($fieldConfig.LinkTo)'"
                    }
                }
                elseif ($fieldConfig.ContainsKey('Type')) {
                    # Regular field
                    $allFields[$fieldPath] = $Depth

                    if ($fieldConfig.Type -eq 'array' -and $fieldConfig.ContainsKey('ItemStructure')) {
                        # Array with item structure - recurse with increased depth
                        # Mark that we're inside an array item structure
                        Collect-Fields -Cfg $fieldConfig.ItemStructure -CurrentPath $fieldPath -Depth ($Depth + 1) -InArrayItem $true
                    }
                }
                else {
                    # Nested object - recurse with increased depth
                    Collect-Fields -Cfg $fieldConfig -CurrentPath $fieldPath -Depth ($Depth + 1) -InArrayItem $InArrayItem
                }
            }
        }
    }

    # Collect all fields
    Collect-Fields -Cfg $Config

    # Validate linked fields
    foreach ($sourceField in $linkedFields.Keys) {
        $linkInfo = $linkedFields[$sourceField]
        $targetField = $linkInfo.Target
        $inArrayItem = $linkInfo.InArrayItem
        $parentPath = $linkInfo.ParentPath

        # For array items, resolve the target field relative to the array item structure
        $resolvedTarget = $targetField
        if ($inArrayItem) {
            # Get the array field name (first segment of parentPath)
            $arrayFieldName = ($parentPath -split '\.')[0]

            # Check if target refers to a field outside the array (at root or in other structures)
            if ($allFields.ContainsKey($targetField)) {
                # Target exists at root level - this is linking outside the array
                throw "Invalid link: Field '$sourceField' in array item cannot link to '$targetField' outside the array. Array items can only link to fields within the same item structure."
            }

            # If target doesn't start with the array field name, it's relative to the current context
            if (-not $targetField.StartsWith($arrayFieldName)) {
                # For nested fields, try resolving as sibling first (from parent's parent)
                # e.g., for 'items.metadata.labels.X' linking to 'name', check 'items.metadata.name'
                if ($parentPath) {
                    $parentSegments = $parentPath -split '\.'
                    Write-Verbose "Test-LinkedFieldConfiguration: DEBUG - parentPath='$parentPath', parentSegments=$($parentSegments -join ',')"
                    if ($parentSegments.Count -gt 1) {
                        # Try sibling resolution (parent's parent + target)
                        $siblingPath = ($parentSegments[0..($parentSegments.Count - 2)] -join '.') + ".$targetField"
                        Write-Verbose "Test-LinkedFieldConfiguration: DEBUG - Testing sibling path '$siblingPath'"
                        if ($allFields.ContainsKey($siblingPath)) {
                            $resolvedTarget = $siblingPath
                            Write-Verbose "Test-LinkedFieldConfiguration: Resolved '$targetField' to '$resolvedTarget' (nested sibling) for field '$sourceField'"
                        }
                        else {
                            # Not a sibling, try array item root
                            $resolvedTarget = "$arrayFieldName.$targetField"
                            Write-Verbose "Test-LinkedFieldConfiguration: Resolved '$targetField' to '$resolvedTarget' (array item root) for field '$sourceField'"
                        }
                    }
                    else {
                        # Direct child of array item, resolve from array root
                        $resolvedTarget = "$arrayFieldName.$targetField"
                        Write-Verbose "Test-LinkedFieldConfiguration: Resolved '$targetField' to '$resolvedTarget' (array item root) for field '$sourceField'"
                    }
                }
                else {
                    # No parent path, use array field name
                    $resolvedTarget = "$arrayFieldName.$targetField"
                    Write-Verbose "Test-LinkedFieldConfiguration: Resolved '$targetField' to '$resolvedTarget' (array item root) for field '$sourceField'"
                }
            }

            # Verify the resolved target exists
            if (-not $allFields.ContainsKey($resolvedTarget)) {
                throw "Invalid link: Field '$sourceField' links to '$targetField', but resolved path '$resolvedTarget' does not exist in the configuration."
            }
        }

        # Check if target is also a linked field (prevent chaining/circular)
        if ($linkedFields.ContainsKey($resolvedTarget)) {
            $targetLinkInfo = $linkedFields[$resolvedTarget]
            throw "Circular or chained link detected: Field '$sourceField' links to '$targetField', but '$targetField' also links to '$($targetLinkInfo.Target)'. Linked fields cannot point to other linked fields."
        }

        # Check that target exists (only for non-array items, array items already checked)
        if (-not $inArrayItem -and -not $allFields.ContainsKey($resolvedTarget)) {
            throw "Invalid link: Field '$sourceField' links to '$targetField', but '$targetField' does not exist in the configuration."
        }

        # For array items, validation is complete (already checked scope and existence above)
        if ($inArrayItem) {
            Write-Verbose "Test-LinkedFieldConfiguration: Validated '$sourceField' -> '$resolvedTarget' (array item internal link)"
            continue
        }

        # Check that link is not downward (parent cannot link to child)
        # Source field can only link to fields at same level or ancestor levels
        $sourceParts = $sourceField -split '\.'
        $targetParts = $resolvedTarget -split '\.'

        # If target path is longer than source, it might be a child
        if ($targetParts.Count -gt $sourceParts.Count) {
            # Check if target is a descendant of source
            $isDescendant = $true
            for ($i = 0; $i -lt $sourceParts.Count; $i++) {
                if ($sourceParts[$i] -ne $targetParts[$i]) {
                    $isDescendant = $false
                    break
                }
            }
            if ($isDescendant) {
                throw "Invalid link: Field '$sourceField' cannot link downward to nested field '$resolvedTarget'. Links can only reference fields at the same level or ancestor levels."
            }
        }

        # Check that link is within scope (same parent path or ancestor)
        # For fields at the same depth, they should share the same parent path
        $sourceDepth = $allFields[$sourceField]
        $targetDepth = $allFields[$resolvedTarget]

        if ($sourceDepth -eq $targetDepth) {
            # Same depth - must have same parent
            $sourceParent = if ($sourceParts.Count -gt 1) { ($sourceParts[0..($sourceParts.Count - 2)] -join '.') } else { '' }
            $targetParent = if ($targetParts.Count -gt 1) { ($targetParts[0..($targetParts.Count - 2)] -join '.') } else { '' }

            if ($sourceParent -ne $targetParent) {
                throw "Invalid link: Field '$sourceField' cannot link to '$resolvedTarget' because they are at the same depth but in different scopes. Links must be within the same object or to ancestor fields."
            }
        }
        elseif ($sourceDepth -lt $targetDepth) {
            # Source is higher (less depth) trying to link to lower (more depth) - not allowed
            throw "Invalid link: Field '$sourceField' at depth $sourceDepth cannot link to '$resolvedTarget' at depth $targetDepth. Parent fields cannot link to nested child fields."
        }
        # else: sourceDepth > targetDepth is OK - child linking to ancestor

        Write-Verbose "Test-LinkedFieldConfiguration: Validated '$sourceField' -> '$resolvedTarget' (scope and direction valid)"
    }

    Write-Verbose "Test-LinkedFieldConfiguration: All linked fields validated successfully"
}
