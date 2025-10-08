Function Out-Determinizer {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
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
        elseif ($InputObject -is [string]) {
            return Out-PSString -InputObject $InputObject
        }
        elseif ($InputObject -is [bool]) {
            return Out-PSBool -InputObject $InputObject
        }
        elseif ($InputObject -is [int] -or $InputObject -is [long] -or $InputObject -is [double] -or $InputObject -is [decimal]) {
            return Out-PSNumber -InputObject $InputObject
        }
        elseif ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.IDictionary]) {
            return Out-PSHashtable -InputObject $InputObject -IndentLevel $IndentLevel -Anonymize:$Anonymize
        }
        elseif ($InputObject -is [System.Collections.IEnumerable]) {
            return Out-PSIEnumerable -InputObject $InputObject -IndentLevel $IndentLevel -Anonymize:$Anonymize
        }
        elseif ($InputObject -is [PSCustomObject]) {
            return Out-PSCustomObject -InputObject $InputObject -IndentLevel $IndentLevel -Anonymize:$Anonymize
        }
        elseif ($InputObject -is [datetime]) {
            return Out-PSDateTime -InputObject $InputObject
        }
        else {
            throw "Unsupported type: $($InputObject.GetType())"
        }
    }

    End { }
}
