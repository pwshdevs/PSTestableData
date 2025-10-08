Function New-DataFromStructure {
    <#
    .SYNOPSIS
    Generates complex data structures based on pattern descriptions.

    .DESCRIPTION
    This function recursively generates PowerShell data structures (hashtables, PSCustomObjects,
    arrays) based on pattern descriptions created by Get-StructurePattern. It handles complex
    nested structures while preventing infinite recursion through depth limiting.

    The function generates arrays with random sizes up to MaxArrayItems, creates objects with
    the same property structure as the original, and ensures proper type preservation including
    array wrapping to prevent PowerShell's array unwrapping behavior.

    .PARAMETER Pattern
    A hashtable describing the structure pattern, typically created by Get-StructurePattern.
    Contains type information and nested patterns for complex structures.

    .PARAMETER Depth
    Current recursion depth. Used internally for infinite recursion prevention.
    Default value is 0.

    .PARAMETER MaxDepth
    Maximum allowed recursion depth. When exceeded, returns "max-depth-reached" string.
    Default value is 10.

    .PARAMETER FieldPath
    Current field path in dot notation. Used internally for tracking location
    within nested structures.

    .PARAMETER MaxArrayItems
    Maximum number of items to generate in arrays. Arrays will have random sizes
    between 1 and this value (inclusive). Default value is 5.

    .PARAMETER RandomGenerator
    A System.Random instance for generating random values and array sizes.
    Using the same seed ensures reproducible results.

    .PARAMETER Anonymize
    Indicates whether to generate anonymized values. Passed through to value
    generation functions.

    .OUTPUTS
    [object]
    Returns generated data structures:
    - Arrays: Object[] with random number of items
    - Hashtables: Hashtable with same property structure
    - PSCustomObjects: PSCustomObject with same property structure
    - Simple values: Delegates to New-ValueFromPattern
    - Max depth reached: "max-depth-reached" string

    .EXAMPLE
    $pattern = @{Type = 'array'; ItemCount = 3; ItemPatterns = @(@{Type = 'string'; Pattern = 'text'})}
    New-DataFromStructure -Pattern $pattern -MaxArrayItems 5
    Returns: Array with 1-5 random text strings

    .EXAMPLE
    $pattern = @{Type = 'object'; ObjectType = 'hashtable'; Properties = @{name = @{Type = 'string'}}}
    New-DataFromStructure -Pattern $pattern
    Returns: Hashtable with 'name' property containing generated string

    .NOTES
    This is an internal utility function used by the PSTestableData module for generating
    complex test data structures. It maintains proper PowerShell type behavior and prevents
    array unwrapping through careful use of array operators and type casting.
    #>
    [CmdletBinding()]
    Param(
        [hashtable]$Pattern,
        [int]$Depth = 0,
        [int]$MaxDepth = 10,
        [string]$FieldPath = "",
        [int]$MaxArrayItems = 5,
        [System.Random]$RandomGenerator = [System.Random]::new(),
        [bool]$Anonymize = $false
    )

    # Prevent infinite recursion
    if ($Depth -gt $MaxDepth) {
        return "max-depth-reached"
    }

    switch ($Pattern.Type) {
        'array' {
            # Handle empty arrays specifically
            if ($Pattern.ItemCount -eq 0) {
                # Return empty array, force as array type with comma operator
                return ,[array]@()
            }

            # Generate a truly random array size from 1 to MaxArrayItems (inclusive)
            # Custom random function handles inclusive/exclusive properly
            $newCount = $RandomGenerator.Next(1, ($MaxArrayItems + 1))
            $newArray = [System.Collections.ArrayList]::new()

            for ($i = 0; $i -lt $newCount; $i++) {
                # Use patterns from sample items, or create default pattern
                if ($Pattern.ItemPatterns -and $Pattern.ItemPatterns.Count -gt 0) {
                    $patternIndex = $i % $Pattern.ItemPatterns.Count
                    $itemPattern = $Pattern.ItemPatterns[$patternIndex]

                    if ($itemPattern.Type -eq 'object' -or $itemPattern.Type -eq 'array') {
                        $null = $newArray.Add((New-DataFromStructure -Pattern $itemPattern -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath "$FieldPath[]" -MaxArrayItems $MaxArrayItems -RandomGenerator $RandomGenerator -Anonymize $Anonymize))
                    }
                    else {
                        $null = $newArray.Add((New-ValueFromPattern -Pattern $itemPattern -RandomGenerator $RandomGenerator -Anonymize $Anonymize))
                    }
                }
                else {
                    # No patterns available, create a default string item
                    $defaultPattern = @{ Type = 'string'; Pattern = 'text'; Length = 10 }
                    $null = $newArray.Add((New-ValueFromPattern -Pattern $defaultPattern -RandomGenerator $RandomGenerator -Anonymize $Anonymize))
                }
            }

            # Convert back to array and ensure it stays as array even if empty or single item
            # Force conversion to Object[] to prevent unwrapping during return
            return [object[]]$newArray.ToArray()
        }
        'object' {
            if ($Pattern.ObjectType -eq 'hashtable') {
                $newObject = @{}
                foreach ($propName in $Pattern.Properties.Keys) {
                    $propPattern = $Pattern.Properties[$propName]
                    $childPath = if ($FieldPath) { "$FieldPath.$propName" } else { $propName }

                    if ($propPattern.Type -eq 'object' -or $propPattern.Type -eq 'array') {
                        $value = New-DataFromStructure -Pattern $propPattern -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath $childPath -MaxArrayItems $MaxArrayItems -RandomGenerator $RandomGenerator -Anonymize $Anonymize
                        # Ensure arrays remain arrays even if they have single items
                        if ($propPattern.Type -eq 'array') {
                            # Force array type preservation - always ensure array context
                            $newObject[$propName] = @($value)
                        } else {
                            $newObject[$propName] = $value
                        }
                    }
                    else {
                        $newObject[$propName] = New-ValueFromPattern -Pattern $propPattern -RandomGenerator $RandomGenerator -Anonymize $Anonymize
                    }
                }
                return $newObject
            }
            else {
                $newObject = [PSCustomObject]@{}
                foreach ($propName in $Pattern.Properties.Keys) {
                    $propPattern = $Pattern.Properties[$propName]
                    $childPath = if ($FieldPath) { "$FieldPath.$propName" } else { $propName }

                    if ($propPattern.Type -eq 'object' -or $propPattern.Type -eq 'array') {
                        $value = New-DataFromStructure -Pattern $propPattern -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath $childPath -MaxArrayItems $MaxArrayItems -RandomGenerator $RandomGenerator -Anonymize $Anonymize
                        # Ensure arrays remain arrays even if they have single items
                        if ($propPattern.Type -eq 'array') {
                            # Force array type preservation for PSCustomObjects - always ensure array context
                            $arrayValue = @($value)
                            $newObject | Add-Member -NotePropertyName $propName -NotePropertyValue $arrayValue
                        } else {
                            $newObject | Add-Member -NotePropertyName $propName -NotePropertyValue $value
                        }
                    }
                    else {
                        $newObject | Add-Member -NotePropertyName $propName -NotePropertyValue (New-ValueFromPattern -Pattern $propPattern -RandomGenerator $RandomGenerator -Anonymize $Anonymize)
                    }
                }
                return $newObject
            }
        }
        default {
            return New-ValueFromPattern -Pattern $Pattern -RandomGenerator $RandomGenerator -Anonymize $Anonymize
        }
    }
}
