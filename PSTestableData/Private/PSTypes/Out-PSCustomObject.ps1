Function Out-PSCustomObject {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,
        [Parameter(Mandatory = $false, Position = 1)]
        [int]$IndentLevel = 1,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch]$Anonymize
    )

    Begin {
        Write-Verbose "Processing PSCustomObject"
        $indent = "    " * $IndentLevel
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        if ($InputObject.PSObject.Properties.Count -eq 0) {
            return "[PSCustomObject]@{}"
        }
        $items = @()
        foreach ($property in $InputObject.PSObject.Properties) {
            $value = Out-Determinizer -InputObject $property.Value -IndentLevel ($IndentLevel + 1) -Anonymize:$Anonymize
            if($property.Name -match "^[a-zA-Z_][a-zA-Z0-9_]*$") {
                if ($Anonymize) {
                    $items += "${indent}$($property.Name) = '<ANONYMIZED>'"
                } else {
                    $items += "${indent}$($property.Name) = $value"
                }
            } else {
                if ($Anonymize) {
                    $items += "${indent}'$($property.Name)' = '<ANONYMIZED>'"
                } else {
                    $items += "${indent}'$($property.Name)' = $value"
                }
            }
        }
        return "[PSCustomObject]@{`n$($items -join "`n")`n$("    " * ($IndentLevel - 1))}"
    }

    End { }
}
