function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $false)]
        $InputObject,

        [Parameter(Mandatory = $false, Position=1)]
        [switch]$Anonymize
    )

    Write-Verbose "Converting object of type $($InputObject.GetType().FullName) to hashtable."
    if ($null -eq $InputObject) {
        return $null
    }

    # Handle primitive types first to avoid PSObject property confusion
    if ($InputObject -is [string] -or $InputObject -is [bool] -or $InputObject -is [int] -or
        $InputObject -is [long] -or $InputObject -is [double] -or $InputObject -is [decimal] -or
        $InputObject -is [DateTime] -or $InputObject -is [ValueType]) {
        return $InputObject
    }
    # Handle arrays/collections (but not strings or dictionaries)
    elseif ($InputObject -is [System.Array] -or
            ($InputObject -is [System.Collections.IEnumerable] -and
            $InputObject -isnot [string] -and
            $InputObject -isnot [System.Collections.IDictionary])) {
        $array = @()
        foreach ($item in $InputObject) {
            $array += ConvertTo-Hashtable -InputObject $item -Anonymize:$Anonymize
        }
        return $array
    }
    # Handle hashtables/dictionaries
    elseif ($InputObject -is [System.Collections.IDictionary]) {
        $hashtable = @{}
        foreach ($key in $InputObject.Keys) {
            $hashtable[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key] -Anonymize:$Anonymize
        }
        return $hashtable
    }
    # Handle PSCustomObjects
    elseif ($InputObject -is [PSCustomObject]) {
        $hashtable = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hashtable[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value -Anonymize:$Anonymize
        }
        return $hashtable
    }
    # Return everything else as-is
    else {
        return $InputObject
    }
}
