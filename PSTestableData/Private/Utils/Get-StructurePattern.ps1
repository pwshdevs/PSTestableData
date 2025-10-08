Function Get-StructurePattern {
    <#
    .SYNOPSIS
    Analyzes the structure of complex objects to create a pattern description.

    .DESCRIPTION
    This function recursively analyzes PowerShell objects (hashtables, PSCustomObjects, arrays)
    to create a comprehensive pattern description that can be used to generate similar test data.
    It identifies object types, property structures, array characteristics, and applies
    preservation rules for specified field patterns.

    The function handles infinite recursion prevention through depth limiting and provides
    detailed analysis of nested structures including arrays with item patterns and objects
    with property patterns.

    .PARAMETER Object
    The object to analyze. Can be hashtables, PSCustomObjects, arrays, or simple values.

    .PARAMETER Depth
    Current recursion depth. Used internally for infinite recursion prevention.
    Default value is 0.

    .PARAMETER MaxDepth
    Maximum allowed recursion depth. When exceeded, returns a fallback pattern.
    Default value is 10.

    .PARAMETER FieldPath
    Current field path in dot notation. Used internally for building hierarchical
    field paths and applying preservation patterns.

    .PARAMETER PreservePatterns
    Array of field path patterns that should be marked for preservation.
    Supports wildcard patterns for matching multiple fields.

    .OUTPUTS
    [hashtable]
    Returns a hashtable describing the structure:
    - For objects: Type, ObjectType, Properties (nested patterns)
    - For arrays: Type, ItemCount, SampleSize, ItemPatterns
    - For simple values: Delegates to Get-ValuePattern

    .EXAMPLE
    $obj = @{name = "John"; age = 30}
    Get-StructurePattern -Object $obj -PreservePatterns @()
    Returns pattern describing hashtable with string and integer properties

    .EXAMPLE
    $arr = @("item1", "item2", "item3")
    Get-StructurePattern -Object $arr -PreservePatterns @()
    Returns pattern describing array with string item patterns

    .EXAMPLE
    $obj = @{apiVersion = "v1"; data = "sensitive"}
    Get-StructurePattern -Object $obj -PreservePatterns @("apiVersion")
    Returns pattern with apiVersion marked for preservation

    .NOTES
    This is an internal utility function used by the PSTestableData module for analyzing
    complex data structures. It limits array analysis to the first 3 items for performance
    while maintaining representative patterns.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param(
        [object]$Object,
        [int]$Depth = 0,
        [int]$MaxDepth = 10,
        [string]$FieldPath = "",
        [string[]]$PreservePatterns = @()
    )

    # Prevent infinite recursion
    if ($Depth -gt $MaxDepth) {
        return @{ Type = 'string'; Pattern = 'text'; Length = 10 }
    }

    if ($null -eq $Object) {
        return @{ Type = 'null' }
    }

    $type = $Object.GetType()

    if ($Object -is [hashtable] -or $Object -is [PSCustomObject]) {
        # Object pattern - handle this first before IEnumerable check
        $properties = @{}

        if ($Object -is [hashtable]) {
            foreach ($key in $Object.Keys) {
                $childPath = if ($FieldPath) { "$FieldPath.$key" } else { $key }
                $properties[$key] = Get-StructurePattern -Object $Object[$key] -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath $childPath -PreservePatterns $PreservePatterns
            }
        }
        else {
            foreach ($prop in $Object.PSObject.Properties) {
                $childPath = if ($FieldPath) { "$FieldPath.$($prop.Name)" } else { $prop.Name }
                $properties[$prop.Name] = Get-StructurePattern -Object $prop.Value -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath $childPath -PreservePatterns $PreservePatterns
            }
        }

        return @{
            Type = 'object'
            Properties = $properties
            ObjectType = if ($Object -is [hashtable]) { 'hashtable' } else { 'pscustomobject' }
        }
    }
    elseif ($type.IsArray -or ($Object -is [System.Collections.IEnumerable] -and $Object -isnot [string] -and $Object -isnot [hashtable] -and $Object -isnot [PSCustomObject])) {
        # Array pattern - limit analysis to first 3 items to prevent excessive processing
        $items = @($Object)
        $itemPatterns = @()
        $maxItems = [math]::Min($items.Count, 3)

        for ($i = 0; $i -lt $maxItems; $i++) {
            $item = $items[$i]
            if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                # Use wildcard notation for array items to enable pattern matching like "items.*.apiVersion" or "*.kind"
                $arrayItemPath = if ($FieldPath) { "$FieldPath.*" } else { "*" }
                $itemPatterns += Get-StructurePattern -Object $item -Depth ($Depth + 1) -MaxDepth $MaxDepth -FieldPath $arrayItemPath -PreservePatterns $PreservePatterns
            }
            else {
                $pattern = Get-ValuePattern -Value $item
                # Use wildcard notation for array item values too
                $arrayItemPath = if ($FieldPath) { "$FieldPath.*" } else { "*" }
                $pattern.PreserveField = Test-PreserveField -FieldPath $arrayItemPath -PreservePatterns $PreservePatterns
                # Store original value if field should be preserved
                if ($pattern.PreserveField) {
                    $pattern.OriginalValue = $item
                }
                $itemPatterns += $pattern
            }
        }

        return @{
            Type = 'array'
            ItemCount = $items.Count
            ItemPatterns = $itemPatterns
            SampleSize = $maxItems
        }
    }
    else {
        # Primitive value
        $pattern = Get-ValuePattern -Value $Object
        # Mark if this field should be preserved from anonymization
        $pattern.PreserveField = Test-PreserveField -FieldPath $FieldPath -PreservePatterns $PreservePatterns
        # Store original value if field should be preserved
        if ($pattern.PreserveField) {
            $pattern.OriginalValue = $Object
        }
        return $pattern
    }
}
