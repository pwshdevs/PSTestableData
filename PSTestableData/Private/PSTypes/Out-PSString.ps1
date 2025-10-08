Function Out-PSString {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$InputObject
    )

    Begin {
        Write-Verbose "Processing string"
    }

    Process {
        if($null -eq $InputObject) {
            return Out-PSNull
        }
        $escaped = $InputObject -replace "'", "''"
        return "'$escaped'"
    }

    End { }
}
