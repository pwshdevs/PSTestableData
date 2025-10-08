function Get-SeedValue {
    <#
    .SYNOPSIS
        Gets a value from seed data using a dot-notation field path.

    .DESCRIPTION
        This function traverses seed data (hashtable, PSCustomObject, or array) using a
        dot-notation path to retrieve values for field population. Handles arrays and
        IEnumerable collections properly to prevent unwrapping.

    .PARAMETER SeedObject
        The seed data to search in (hashtable, PSCustomObject, array, etc.).

    .PARAMETER FieldPath
        The dot-notation path to the value (e.g., "items.metadata.name").

    .EXAMPLE
        Get-SeedValue -SeedObject $seedData -FieldPath "items[0].name"

        Returns the name value from the first item in the seed data.

    .OUTPUTS
        The value at the specified path, or $null if not found.
        Arrays and IEnumerable collections are returned with comma operator to prevent unwrapping.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object]$SeedObject,

        [Parameter(Mandatory = $true)]
        [string]$FieldPath
    )

    Write-Verbose "Get-SeedValue: Called with SeedObject type='$(if ($null -ne $SeedObject) { $SeedObject.GetType().Name } else { 'null' })', FieldPath='$FieldPath'"

    if ($null -eq $SeedObject) {
        return $null
    }

    # Split path and traverse
    $segments = $FieldPath -split '\.'
    $current = $SeedObject

    Write-Verbose "Get-SeedValue: Segments count=$($segments.Count)"

    foreach ($segment in $segments) {
        Write-Verbose "Get-SeedValue: Loop iteration - segment='$segment'"

        if ($null -eq $current) {
            Write-Verbose "Get-SeedValue: current is null, returning null"
            return $null
        }

        # Skip empty segments
        if ([string]::IsNullOrEmpty($segment)) {
            Write-Verbose "Get-SeedValue: Skipping empty segment"
            continue
        }

        # Skip wildcard segments
        if ($segment -eq '*') {
            Write-Verbose "Get-SeedValue: Skipping wildcard segment"
            continue
        }

        Write-Verbose "Get-SeedValue: Processing segment='$segment', current type='$($current.GetType().Name)'"

        # Access property
        if ($current -is [hashtable]) {
            $current = $current[$segment]
            Write-Verbose "Get-SeedValue: Accessed hashtable[$segment], current is now type='$(if ($null -ne $current) { $current.GetType().Name } else { 'null' })'"
        }
        elseif ($current -is [PSCustomObject]) {
            $current = $current.$segment
            Write-Verbose "Get-SeedValue: Accessed PSCustomObject.$segment, current is now type='$(if ($null -ne $current) { $current.GetType().Name } else { 'null' })'"
        }
        else {
            Write-Verbose "Get-SeedValue: Current is neither hashtable nor PSCustomObject, returning null"
            return $null
        }
    }

    Write-Verbose "Get-SeedValue: Returning value type='$(if ($current) { $current.GetType().Name } else { "null" })'"
    # Use comma operator to prevent array unwrapping for single-element arrays and IEnumerable collections
    # This ensures that @( @{x=1} ) stays as an array, not unwrapped to just the hashtable
    # Also handles List<T> and other IEnumerable types from ConvertFrom-Yaml
    if ($current -is [array] -or ($current -is [System.Collections.IEnumerable] -and $current -isnot [string])) {
        return ,$current
    }
    return $current
}
