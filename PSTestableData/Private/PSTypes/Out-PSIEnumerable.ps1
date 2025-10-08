Function Out-PSIEnumerable {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        $InputObject,
        [Parameter(Mandatory = $false, Position = 1)]
        [int]$IndentLevel = 0,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch]$Anonymize
    )

    Begin {
        Write-Verbose "Processing enumerable"
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        $indent = "    " * $IndentLevel
        if ($InputObject.Count -eq 0) {
            return "@()"
        }
        $items = @()
        foreach ($item in $InputObject) {
            $value = Out-Determinizer -InputObject $item -IndentLevel ($IndentLevel + 1) -Anonymize:$Anonymize
            $items += "${indent}$value"
        }
        return "@(`n$($items -join "`n")`n$("    " * ($IndentLevel - 1)))"
    }

    End { }
}
