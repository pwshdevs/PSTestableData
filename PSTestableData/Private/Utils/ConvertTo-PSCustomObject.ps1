function ConvertTo-PSCustomObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        $InputObject,

        [Parameter(Mandatory = $false, Position=1)]
        [switch]$Anonymize
    )

    Begin { }
    Process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Handle primitive types first
        if ($InputObject -is [string] -or $InputObject -is [bool] -or $InputObject -is [int] -or
            $InputObject -is [long] -or $InputObject -is [double] -or $InputObject -is [decimal] -or
            $InputObject -is [DateTime] -or $InputObject -is [ValueType]) {
            return $InputObject
        }
        # Handle arrays
        elseif ($InputObject -is [System.Array] -or
                ($InputObject -is [System.Collections.IEnumerable] -and
                $InputObject -isnot [string] -and
                $InputObject -isnot [System.Collections.IDictionary])) {
            $array = @()
            foreach ($item in $InputObject) {
                $array += $item | ConvertTo-PSCustomObject -Anonymize:$Anonymize
            }
            return $array
        }
        # Handle hashtables - convert to PSCustomObject
        elseif ($InputObject -is [System.Collections.IDictionary]) {
            $properties = @{}
            foreach ($key in $InputObject.Keys) {
                $properties[$key] = $InputObject[$key] | ConvertTo-PSCustomObject -Anonymize:$Anonymize
            }
            return [PSCustomObject]$properties
        }
        # Handle PSCustomObjects - process recursively
        elseif ($InputObject -is [PSCustomObject]) {
            $properties = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $properties[$property.Name] = $property.Value | ConvertTo-PSCustomObject -Anonymize:$Anonymize
            }
            return [PSCustomObject]$properties
        }
        else {
            return $InputObject
        }
    }
}
