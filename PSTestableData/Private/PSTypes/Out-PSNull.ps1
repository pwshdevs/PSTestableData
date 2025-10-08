Function Out-PSNull {
    [CmdletBinding()]
    [OutputType([string])]
    Param ()

    Begin {
        Write-Verbose "Processing null value"
    }

    Process {
        return "`$null"
    }

    End { }
}
