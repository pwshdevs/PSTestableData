Describe 'Generators and Out-Determinizer' {
    BeforeAll {
        # Dot source the required private functions
        . $PSScriptRoot/../PSTestableData/Private/Out-Determinizer.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedString.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedNumber.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedInt.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedLong.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedDouble.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedDecimal.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedDateTime.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSNull.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSBool.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSString.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSNumber.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSDateTime.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSIEnumerable.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSHashtable.ps1
        . $PSScriptRoot/../PSTestableData/Private/PSTypes/Out-PSCustomObject.ps1
    }

    Context 'Out-AnonymizedString' {
        It 'Returns a string of same length' {
            $testInput = "Hello World"
            $result = Out-AnonymizedString -InputString $testInput
            $result | Should -BeOfType [string]
            $result.Length | Should -Be $testInput.Length
        }

        It 'Preserves non-alphanumeric characters' {
            $testInput = "Test-123_abc!"
            $result = Out-AnonymizedString -InputString $testInput
            $result | Should -Match '^[\w\-_!]+$'
            $result.Length | Should -Be $testInput.Length
        }

        It 'Is deterministic for same input' {
            $testInput = "Consistent"
            $result1 = Out-AnonymizedString -InputString $testInput
            $result2 = Out-AnonymizedString -InputString $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedNumber' {
        It 'Returns same type as input' {
            $testInput = 123
            $result = Out-AnonymizedNumber -InputNumber $testInput
            $result | Should -BeOfType [int]
        }

        It 'Returns different value' {
            $testInput = 100
            $result = Out-AnonymizedNumber -InputNumber $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = 456.78
            $result1 = Out-AnonymizedNumber -InputNumber $testInput
            $result2 = Out-AnonymizedNumber -InputNumber $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedInt' {
        It 'Returns int' {
            $testInput = 123
            $result = Out-AnonymizedInt -InputNumber $testInput
            $result | Should -BeOfType [int]
        }

        It 'Returns different value' {
            $testInput = 100
            $result = Out-AnonymizedInt -InputNumber $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = 456
            $result1 = Out-AnonymizedInt -InputNumber $testInput
            $result2 = Out-AnonymizedInt -InputNumber $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedLong' {
        It 'Returns long' {
            $testInput = [long]123456789
            $result = Out-AnonymizedLong -InputNumber $testInput
            $result | Should -BeOfType [long]
        }

        It 'Returns different value' {
            $testInput = [long]100000
            $result = Out-AnonymizedLong -InputNumber $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = [long]456789
            $result1 = Out-AnonymizedLong -InputNumber $testInput
            $result2 = Out-AnonymizedLong -InputNumber $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedDouble' {
        It 'Returns double' {
            $testInput = 123.45
            $result = Out-AnonymizedDouble -InputNumber $testInput
            $result | Should -BeOfType [double]
        }

        It 'Returns different value' {
            $testInput = 100.0
            $result = Out-AnonymizedDouble -InputNumber $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = 456.78
            $result1 = Out-AnonymizedDouble -InputNumber $testInput
            $result2 = Out-AnonymizedDouble -InputNumber $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedDecimal' {
        It 'Returns decimal' {
            $testInput = [decimal]123.45
            $result = Out-AnonymizedDecimal -InputNumber $testInput
            $result | Should -BeOfType [decimal]
        }

        It 'Returns different value' {
            $testInput = [decimal]100.0
            $result = Out-AnonymizedDecimal -InputNumber $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = [decimal]456.78
            $result1 = Out-AnonymizedDecimal -InputNumber $testInput
            $result2 = Out-AnonymizedDecimal -InputNumber $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-AnonymizedDateTime' {
        It 'Returns DateTime object' {
            $testInput = Get-Date
            $result = Out-AnonymizedDateTime -InputDateTime $testInput
            $result | Should -BeOfType [DateTime]
        }

        It 'Returns different date' {
            $testInput = Get-Date "2023-01-01"
            $result = Out-AnonymizedDateTime -InputDateTime $testInput
            $result | Should -Not -Be $testInput
        }

        It 'Is deterministic for same input' {
            $testInput = Get-Date "2023-05-15"
            $result1 = Out-AnonymizedDateTime -InputDateTime $testInput
            $result2 = Out-AnonymizedDateTime -InputDateTime $testInput
            $result1 | Should -Be $result2
        }
    }

    Context 'Out-Determinizer' {
        It 'Handles null' {
            $result = Out-Determinizer -InputObject $null
            $result | Should -Be '$null'
        }

        It 'Handles string' {
            $result = Out-Determinizer -InputObject "test"
            $result | Should -Be "'test'"
        }

        It 'Handles bool' {
            $result = Out-Determinizer -InputObject $true
            $result | Should -Be '$true'
        }

        It 'Handles int' {
            $result = Out-Determinizer -InputObject 42
            $result | Should -Be '42'
        }

        It 'Handles hashtable' {
            $ht = @{a = 1; b = "test"}
            $result = Out-Determinizer -InputObject $ht
            $result | Should -Match '^@\{\s*'
            $result | Should -Match 'a = 1'
            $result | Should -Match "b = 'test'"
            $result | Should -Match '\s*\}$'
        }

        It 'Handles array' {
            $arr = @(1, 2, 3)
            $result = Out-Determinizer -InputObject $arr
            $result | Should -Be "@(`n    1`n    2`n    3`n)"
        }

        It 'Handles PSCustomObject' {
            $obj = [PSCustomObject]@{a = 1; b = "test"}
            $result = Out-Determinizer -InputObject $obj
            $result | Should -Be "[PSCustomObject]@{`n    a = 1`n    b = 'test'`n}"
        }

        It 'Handles DateTime' {
            $dt = [datetime]::Parse('2023-10-01T12:00:00')
            $result = Out-Determinizer -InputObject $dt
            $result | Should -Match "'2023-10-01T12:00:00"
        }
    }
}
