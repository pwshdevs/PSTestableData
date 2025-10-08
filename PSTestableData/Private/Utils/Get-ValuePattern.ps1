Function Get-ValuePattern {
    <#
    .SYNOPSIS
    Analyzes a value to determine its data type and pattern characteristics.

    .DESCRIPTION
    This function examines a single value and returns a hashtable describing its type,
    pattern, and other characteristics. It identifies various data types including nulls,
    strings with specific patterns (ISO8601 dates, GUIDs, numeric, kebab-case, dotted notation),
    numeric types with ranges, booleans, and complex objects.

    The function is used internally by Get-StructurePattern to analyze individual values
    within data structures for pattern recognition and subsequent test data generation.

    .PARAMETER Value
    The value to analyze. Can be any PowerShell object including null, strings, numbers,
    booleans, dates, or complex objects.

    .OUTPUTS
    [hashtable]
    Returns a hashtable containing:
    - Type: The identified data type (null, string, int, long, double, bool, datetime, guid, object)
    - Pattern: The specific pattern identified (text, numeric, kebab-case, dotted, iso8601, guid, boolean, number, decimal, complex)
    - Length: For strings, the length of the value
    - Range: For numeric types, an array containing [min, max] values
    - PreserveField: Boolean indicating whether this field should be preserved (set by caller)

    .EXAMPLE
    Get-ValuePattern -Value "hello-world"
    Returns: @{ Type = 'string'; Pattern = 'kebab-case' }

    .EXAMPLE
    Get-ValuePattern -Value "2023-10-01T12:00:00Z"
    Returns: @{ Type = 'datetime'; Pattern = 'iso8601' }

    .EXAMPLE
    Get-ValuePattern -Value 42
    Returns: @{ Type = 'int'; Pattern = 'number'; Range = @(42, 42) }

    .EXAMPLE
    Get-ValuePattern -Value $null
    Returns: @{ Type = 'null'; Pattern = 'null' }

    .NOTES
    This is an internal utility function used by the PSTestableData module for analyzing
    data patterns. It supports the anonymization and test data generation workflow by
    identifying how values should be categorized and regenerated.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return @{ Type = 'null'; Pattern = 'null' }
    }

    $type = $Value.GetType()

    switch ($type.Name) {
        'String' {
            # Analyze string patterns
            if ($Value -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}') {
                return @{ Type = 'datetime'; Pattern = 'iso8601' }
            }
            elseif ($Value -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
                return @{ Type = 'guid'; Pattern = 'guid' }
            }
            elseif ($Value -match '^\d+$') {
                return @{ Type = 'string'; Pattern = 'numeric' }
            }
            elseif ($Value -match '^[a-zA-Z]+(-[a-zA-Z]+)+$') {
                return @{ Type = 'string'; Pattern = 'kebab-case' }
            }
            elseif ($Value -match '^[a-zA-Z]+\.[a-zA-Z]+') {
                return @{ Type = 'string'; Pattern = 'dotted' }
            }
            else {
                return @{ Type = 'string'; Pattern = 'text'; Length = $Value.Length }
            }
        }
        'Int32' {
            try {
                $intValue = if ($Value -is [array]) { [int]$Value[0] } else { [int]$Value }
                return @{ Type = 'int'; Pattern = 'number'; Range = @($intValue - 100, $intValue + 100) }
            } catch {
                return @{ Type = 'int'; Pattern = 'number'; Range = @(1, 1000) }
            }
        }
        'Int64' {
            try {
                $longValue = if ($Value -is [array]) { [long]$Value[0] } else { [long]$Value }
                return @{ Type = 'long'; Pattern = 'number'; Range = @($longValue - 1000, $longValue + 1000) }
            } catch {
                return @{ Type = 'long'; Pattern = 'number'; Range = @(1000, 999999) }
            }
        }
        'Double' { return @{ Type = 'double'; Pattern = 'decimal' } }
        'Boolean' { return @{ Type = 'bool'; Pattern = 'boolean' } }
        default { return @{ Type = 'object'; Pattern = 'complex' } }
    }
}
