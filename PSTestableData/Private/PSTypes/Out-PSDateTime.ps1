Function Out-PSDateTime {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [datetime]$InputObject
    )

    Begin {
        Write-Verbose "Processing DateTime"
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        return "'$($InputObject.ToString("o"))'"
    }

    End { }
}
