Function Out-PSBool {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [bool]$InputObject
    )

    Begin {
        Write-Verbose "Processing boolean"
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        if ($InputObject) {
            return "`$true"
        } else {
            return "`$false"
        }
    }

    End { }
}
