Function Out-PSNumber {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [double]$InputObject
    )

    Begin {
        Write-Verbose "Processing number"
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        return $InputObject.ToString()
    }

    End { }
}
