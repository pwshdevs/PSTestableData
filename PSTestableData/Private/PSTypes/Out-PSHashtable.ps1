Function Out-PSHashtable {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$InputObject,
        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 1,
        [Parameter(Mandatory = $false)]
        [switch]$Anonymize
    )

    Begin { }

    Process {
        if ($null -eq $InputObject) {
            return Out-PSNull
        }
        Write-Verbose "Processing object of type $($InputObject.GetType()) at indent level $IndentLevel."
        $indent = "    " * $IndentLevel

        if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.IDictionary]) {
            if ($InputObject.Count -eq 0) {
                return "@{}"
            }
            $items = @()
            foreach ($key in $InputObject.Keys) {
                $value = Out-Determinizer -InputObject $InputObject[$key] -IndentLevel ($IndentLevel + 1) -Anonymize:$Anonymize
                if($key -match "^[a-zA-Z_][a-zA-Z0-9_]*$") {
                    if ($Anonymize) {
                        $items += "${indent}$key = '<ANONYMIZED>'"
                    } else {
                        $items += "${indent}$key = $value"
                    }
                } else {
                    if ($Anonymize) {
                        $items += "${indent}'$key' = '<ANONYMIZED>'"
                    } else {
                        $items += "${indent}'$key' = $value"
                    }
                }
            }
            return "@{`n$($items -join "`n")`n$("    " * ($IndentLevel - 1))}"
        }
        else {
            throw "Unsupported type: $($InputObject.GetType())"
        }
    }

    End { }
}
