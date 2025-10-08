# PSTypes.tests.ps1
# Test cases for private PSTypes functions

Describe 'PSTypes Functions' {
    BeforeAll {
        # Dot source the required private functions
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSNull.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSBool.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSString.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSNumber.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSDateTime.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSIEnumerable.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSHashtable.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSCustomObject.ps1
        . $PSScriptRoot/../PSTestableData/Private/Out-Determinizer.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedString.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedNumber.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedDateTime.ps1
    }

    Context 'Out-PSNull' {
        It 'Returns $null' {
            Out-PSNull | Should -Be '$null'
        }
    }

    Context 'Out-PSBool' {
        It 'Returns $true for $true' {
            Out-PSBool -InputObject $true | Should -Be '$true'
        }
        It 'Returns $false for $false' {
            Out-PSBool -InputObject $false | Should -Be '$false'
        }
    }

    Context 'Out-PSString' {
        It 'Returns quoted string' {
            Out-PSString -InputObject 'hello' | Should -Be "'hello'"
        }
        It 'Escapes single quotes' {
            Out-PSString -InputObject "it's" | Should -Be "'it''s'"
        }
        It 'Returns empty string for null' {
            Out-PSString -InputObject $null | Should -Be "''"
        }
    }

    Context 'Out-PSNumber' {
        It 'Returns string for int' {
            Out-PSNumber -InputObject 42 | Should -Be '42'
        }
        It 'Returns string for double' {
            Out-PSNumber -InputObject 3.14 | Should -Be '3.14'
        }
        It 'Returns 0 for null' {
            Out-PSNumber -InputObject $null | Should -Be '0'
        }
    }

    Context 'Out-PSDateTime' {
        It 'Returns ISO string for DateTime' {
            $dt = [datetime]::Parse('2023-10-01T12:00:00')
            Out-PSDateTime -InputObject $dt | Should -Be "'2023-10-01T12:00:00.0000000'"
        }
    }

    Context 'Out-PSIEnumerable' {
        It 'Returns @() for empty array' {
            Out-PSIEnumerable -InputObject @() -IndentLevel 1 | Should -Be '@()'
        }
        It 'Returns array for simple array' {
            Out-PSIEnumerable -InputObject @(1, 2, 3) -IndentLevel 1 | Should -Be "@(`n    1`n    2`n    3`n)"
        }
        It 'Handles anonymize' {
            Out-PSIEnumerable -InputObject @('a', 'b') -Anonymize -IndentLevel 1 | Should -Be "@(`n    'a'`n    'b'`n)"
        }
    }

    Context 'Out-PSHashtable' {
        It 'Returns @{} for empty hashtable' {
            Out-PSHashtable -InputObject @{} -IndentLevel 1 | Should -Be '@{}'
        }
        It 'Returns hashtable string' {
            $ht = @{a = 1; b = 'test'}
            $result = Out-PSHashtable -InputObject $ht -IndentLevel 1
            $result | Should -Match '^@\{\s*'
            $result | Should -Match 'a = 1'
            $result | Should -Match "b = 'test'"
            $result | Should -Match '\s*\}$'
        }
        It 'Handles quoted keys' {
            $ht = @{'key with spaces' = 'value'}
            $result = Out-PSHashtable -InputObject $ht -IndentLevel 1
            $result | Should -Be "@{`n    'key with spaces' = 'value'`n}"
        }
        It 'Handles anonymize' {
            $ht = @{a = 1; b = 'test'}
            $result = Out-PSHashtable -InputObject $ht -Anonymize -IndentLevel 1
            $result | Should -Match '^@\{\s*'
            $result | Should -Match "a = '<ANONYMIZED>'"
            $result | Should -Match "b = '<ANONYMIZED>'"
            $result | Should -Match '\s*\}$'
        }
    }

    Context 'Out-PSCustomObject' {
        It 'Returns [PSCustomObject]@{} for empty object' {
            $obj = [PSCustomObject]@{}
            Out-PSCustomObject -InputObject $obj -IndentLevel 1 | Should -Be "[PSCustomObject]@{`n`n}"
        }
        It 'Returns custom object string' {
            $obj = [PSCustomObject]@{a = 1; b = 'test'}
            $result = Out-PSCustomObject -InputObject $obj -IndentLevel 1
            $result | Should -Match '^\[PSCustomObject\]@\{\s*'
            $result | Should -Match 'a = 1'
            $result | Should -Match "b = 'test'"
            $result | Should -Match '\s*\}$'
        }
        It 'Handles quoted property names' {
            $obj = [PSCustomObject]@{'prop with spaces' = 'value'}
            $result = Out-PSCustomObject -InputObject $obj -IndentLevel 1
            $result | Should -Be "[PSCustomObject]@{`n    'prop with spaces' = 'value'`n}"
        }
        It 'Handles anonymize' {
            $obj = [PSCustomObject]@{a = 1; b = 'test'}
            $result = Out-PSCustomObject -InputObject $obj -Anonymize -IndentLevel 1
            $result | Should -Match '^\[PSCustomObject\]@\{\s*'
            $result | Should -Match "a = '<ANONYMIZED>'"
            $result | Should -Match "b = '<ANONYMIZED>'"
            $result | Should -Match '\s*\}$'
        }
    }
}
