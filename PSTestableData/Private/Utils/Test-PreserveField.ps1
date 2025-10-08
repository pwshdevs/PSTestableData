Function Test-PreserveField {
    <#
    .SYNOPSIS
    Determines whether a field should be preserved based on pattern matching.

    .DESCRIPTION
    This function checks if a given field path matches any of the specified preservation
    patterns. It supports both exact matching and wildcard patterns using PowerShell's
    -like operator. If a wildcard pattern is invalid, it falls back to exact string matching.

    Field paths use dot notation (e.g., "metadata.labels.app") and patterns can include
    wildcards (e.g., "metadata.*", "*.labels.*"). This function is used to determine
    which fields should retain their original values during anonymization.

    .PARAMETER FieldPath
    The field path to test against the preservation patterns. Uses dot notation
    to represent nested object properties (e.g., "spec.containers.0.name").

    .PARAMETER PreservePatterns
    An array of patterns to match against the field path. Supports wildcard patterns
    using PowerShell's -like syntax. If empty, the function returns false.

    .OUTPUTS
    [bool]
    Returns $true if the field path matches any preservation pattern, $false otherwise.

    .EXAMPLE
    Test-PreserveField -FieldPath "apiVersion" -PreservePatterns @("apiVersion", "kind")
    Returns: $true

    .EXAMPLE
    Test-PreserveField -FieldPath "metadata.labels.app" -PreservePatterns @("metadata.labels.*")
    Returns: $true

    .EXAMPLE
    Test-PreserveField -FieldPath "data.secret" -PreservePatterns @("apiVersion", "kind")
    Returns: $false

    .EXAMPLE
    Test-PreserveField -FieldPath "test.field" -PreservePatterns @()
    Returns: $false

    .NOTES
    This is an internal utility function used by the PSTestableData module for determining
    field preservation during anonymization. It gracefully handles invalid wildcard patterns
    by falling back to exact string matching.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [string]$FieldPath,
        [string[]]$PreservePatterns
    )

    foreach ($pattern in $PreservePatterns) {
        try {
            if ($FieldPath -like $pattern) {
                return $true
            }
        }
        catch {
            # If wildcard pattern is invalid, try exact match
            if ($FieldPath -eq $pattern) {
                return $true
            }
        }
    }
    return $false
}
