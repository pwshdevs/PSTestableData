function Get-LinkedValue {
    <#
    .SYNOPSIS
        Gets a value from a result hashtable using a dot-notation path.

    .DESCRIPTION
        This function traverses a hashtable or PSCustomObject using a dot-notation path
        to retrieve a nested value. Used for resolving linked field values.

    .PARAMETER Result
        The hashtable or PSCustomObject to search in.

    .PARAMETER LinkPath
        The dot-notation path to the value (e.g., "metadata.name").

    .EXAMPLE
        Get-LinkedValue -Result $data -LinkPath "metadata.name"

        Returns the value at $data.metadata.name

    .OUTPUTS
        The value at the specified path, or $null if not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,

        [Parameter(Mandatory = $true)]
        [string]$LinkPath
    )

    Write-Verbose "Get-LinkedValue: Looking up LinkPath='$LinkPath'"

    if ([string]::IsNullOrEmpty($LinkPath)) {
        Write-Verbose "Get-LinkedValue: LinkPath is empty, returning null"
        return $null
    }

    # Split path and traverse
    $segments = $LinkPath -split '\.'
    $current = $Result

    foreach ($segment in $segments) {
        # Skip empty segments
        if ([string]::IsNullOrEmpty($segment)) {
            continue
        }

        Write-Verbose "Get-LinkedValue: Processing segment='$segment', current type='$(if ($null -ne $current) { $current.GetType().Name } else { 'null' })'"

        # Access property
        if ($current -is [hashtable]) {
            if ($current.ContainsKey($segment)) {
                $current = $current[$segment]
                Write-Verbose "Get-LinkedValue: Found segment in hashtable, current is now type='$(if ($null -ne $current) { $current.GetType().Name } else { 'null' })'"
            }
            else {
                Write-Verbose "Get-LinkedValue: Segment '$segment' not found in hashtable, returning null"
                return $null
            }
        }
        elseif ($current -is [PSCustomObject]) {
            if ($current.PSObject.Properties.Name -contains $segment) {
                $current = $current.$segment
                Write-Verbose "Get-LinkedValue: Found segment in PSCustomObject, current is now type='$(if ($null -ne $current) { $current.GetType().Name } else { 'null' })'"
            }
            else {
                Write-Verbose "Get-LinkedValue: Segment '$segment' not found in PSCustomObject, returning null"
                return $null
            }
        }
        else {
            Write-Verbose "Get-LinkedValue: Current is neither hashtable nor PSCustomObject, returning null"
            return $null
        }
    }

    Write-Verbose "Get-LinkedValue: Returning value='$current'"
    return $current
}
