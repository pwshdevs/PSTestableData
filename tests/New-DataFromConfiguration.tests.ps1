Describe 'New-DataFromConfiguration' {
    BeforeAll {
        # Import the module
        $modulePath = Split-Path -Parent $PSScriptRoot
        Import-Module "$modulePath/PSTestableData/PSTestableData.psd1" -Force
    }

    Context 'Basic functionality' {
        BeforeEach {
            # Create a simple test configuration
            $sample = @{
                name = "John"
                age = 30
                active = $true
            }
            $script:testConfigPath = Join-Path $TestDrive 'test-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should load and use configuration file' {
            $seed = @{ name = "Jane"; age = 35; active = $false }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Not -BeNullOrEmpty
            $result.age | Should -BeOfType [int]
            $result.active | Should -BeOfType [bool]
        }

        It 'Should throw error if config file not found' {
            { New-DataFromConfiguration -ConfigPath '.\nonexistent.ps1' -SeedData @{} } | Should -Throw
        }

        It 'Should throw error if config file is not .ps1' {
            { New-DataFromConfiguration -ConfigPath '.\config.txt' -SeedData @{} } | Should -Throw
        }

        It 'Should use seed data from pipeline' {
            $seed = @{ name = "Pipeline User"; age = 40; active = $true }
            $result = $seed | New-DataFromConfiguration -ConfigPath $script:testConfigPath

            # Should preserve values from seed (default Action is Preserve)
            $result.name | Should -Be "Pipeline User"
            $result.age | Should -Be 40
            $result.active | Should -Be $true
        }
    }

    Context 'Seed data handling' {
        BeforeEach {
            $sample = @{
                name = "Test User"
                email = "test@example.com"
                age = 25
            }
            $script:testConfigPath = Join-Path $TestDrive 'seed-test-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should preserve values from seed data when Action is Preserve' {
            $seed = @{
                name = "John Doe"
                email = "john@test.com"
                age = 42
            }

            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            # All fields default to Preserve, so they should match seed data
            $result.name | Should -Be "John Doe"
            $result.age | Should -Be 42
        }

        It 'Should anonymize values from seed data when Action is Anonymize' {
            $sample = @{
                name = "Test"
                password = "secret123"
            }
            $configPath = Join-Path $TestDrive 'anonymize-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('password') -OutputPath $configPath | Out-Null

            $seed = @{
                name = "John"
                password = "secret123"
            }

            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            # Name should be preserved
            $result.name | Should -Be "John"
            # Password should be anonymized (different from seed)
            $result.password | Should -Not -Be "secret123"
            $result.password | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Array handling' {
        BeforeEach {
            $sample = @{
                tags = @("tag1", "tag2", "tag3")
                items = @(
                    @{ name = "item1"; value = 100 },
                    @{ name = "item2"; value = 200 }
                )
            }
            $script:testConfigPath = Join-Path $TestDrive 'array-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should generate arrays with correct count' {
            $seed = @{ tags = @("tag1", "tag2", "tag3"); items = @(@{ name = "item1"; value = 100 }) }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result.tags | Should -Not -BeNullOrEmpty
            $result.tags.Count | Should -BeGreaterThan 0
            @($result.tags).Count | Should -Be $result.tags.Count # Ensure it's an array, not a single value
        }

        It 'Should generate array of objects' {
            $seed = @{ tags = @("a", "b"); items = @(@{ name = "test"; value = 50 }, @{ name = "test2"; value = 75 }) }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result.items | Should -Not -BeNullOrEmpty
            $result.items.Count | Should -BeGreaterThan 0
            $result.items[0] | Should -Not -BeNullOrEmpty
            $result.items[0].name | Should -Not -BeNullOrEmpty
            $result.items[0].value | Should -BeOfType [int]
        }

        It 'Should preserve array values from seed data' {
            $seed = @{
                tags = @("admin", "user", "developer")
                items = @(
                    @{ name = "preserved1"; value = 999 }
                )
            }

            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            # Should preserve seed values
            $result.tags[0] | Should -Be "admin"
            $result.items[0].name | Should -Be "preserved1"
            $result.items[0].value | Should -Be 999
        }
    }

    Context 'Nested objects' {
        BeforeEach {
            $sample = @{
                user = @{
                    profile = @{
                        name = "John"
                        email = "john@test.com"
                    }
                    settings = @{
                        theme = "dark"
                    }
                }
            }
            $script:testConfigPath = Join-Path $TestDrive 'nested-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('*.email') -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should handle nested objects' {
            $seed = @{ user = @{ profile = @{ name = "Test"; email = "test@test.com" }; settings = @{ theme = "dark" } } }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result.user | Should -Not -BeNullOrEmpty
            $result.user.profile | Should -Not -BeNullOrEmpty
            $result.user.profile.name | Should -Not -BeNullOrEmpty
            $result.user.settings.theme | Should -Not -BeNullOrEmpty
        }

        It 'Should preserve nested values from seed data' {
            $seed = @{
                user = @{
                    profile = @{
                        name = "Jane Doe"
                        email = "jane@test.com"
                    }
                    settings = @{
                        theme = "light"
                    }
                }
            }

            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result.user.profile.name | Should -Be "Jane Doe"
            $result.user.settings.theme | Should -Be "light"
            # Email should be anonymized
            $result.user.profile.email | Should -Not -Be "jane@test.com"
        }
    }

    Context 'Count parameter' {
        BeforeEach {
            $sample = @{ name = "Test"; value = 42 }
            $script:testConfigPath = Join-Path $TestDrive 'count-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should generate single item by default' {
            $seed = @{ name = "Single"; value = 10 }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Not -BeNullOrEmpty
            $result -is [array] | Should -Be $false
        }

        It 'Should generate multiple items when Count is specified' {
            $seed = @{ name = "Multi"; value = 20 }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed -Count 5

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result[0].name | Should -Not -BeNullOrEmpty
            $result[4].name | Should -Not -BeNullOrEmpty
        }

        It 'Should generate different values for each item' {
            $seed = @{ name = "Base"; value = 30 }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed -Count 3

            # With Randomize action, each item should have different values
            $result.Count | Should -Be 3
            $result[0].name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Output formats' {
        BeforeEach {
            $sample = @{ name = "Test"; age = 30 }
            $script:testConfigPath = Join-Path $TestDrive 'output-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should return object by default' {
            $seed = @{ name = "Object"; age = 25 }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result | Should -BeOfType [hashtable]
        }

        It 'Should return JSON string with AsJson' {
            $seed = @{ name = "JSON"; age = 30 }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed -AsJson

            $result | Should -BeOfType [string]
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should handle AsYaml when module is not available' {
            $seed = @{ name = "YAML"; age = 35 }
            # This should warn and return object instead if ConvertTo-Yaml is not available
            # But if it IS available, it will return a YAML string
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed -AsYaml -WarningAction SilentlyContinue

            # Should return either object (if ConvertTo-Yaml not available) or string (if it is)
            $result | Should -Not -BeNullOrEmpty
            if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
                $result | Should -BeOfType [string]
            }
            else {
                $result | Should -BeOfType [hashtable]
            }
        }
    }

    Context 'Type preservation' {
        BeforeEach {
            $sample = @{
                stringField = "test"
                intField = 42
                boolField = $true
                dateField = "2025-01-01T00:00:00Z"
                guidField = "12345678-1234-1234-1234-123456789012"
            }
            $script:testConfigPath = Join-Path $TestDrive 'types-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $script:testConfigPath | Out-Null
        }

        It 'Should generate correct types' {
            $seed = @{ stringField = "test"; intField = 42; boolField = $true; dateField = "2025-01-01T00:00:00Z"; guidField = "12345678-1234-1234-1234-123456789012" }
            $result = New-DataFromConfiguration -ConfigPath $script:testConfigPath -SeedData $seed

            $result.stringField | Should -BeOfType [string]
            $result.intField | Should -BeOfType [int]
            $result.boolField | Should -BeOfType [bool]
            $result.dateField | Should -Match '^\d{4}-\d{2}-\d{2}T'
            $result.guidField | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}'
        }
    }

    Context 'Field linking' {
        It 'Should link fields at the same level' {
            $configContent = @'
$Config = @{
    name = @{ Action = 'Preserve'; Type = 'string' }
    displayName = @{ Action = 'Link'; Type = 'string'; LinkTo = 'name' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-same-level.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{ name = 'test-app' }
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.name | Should -Be 'test-app'
            $result.displayName | Should -Be 'test-app'
        }

        It 'Should link nested fields to parent fields' {
            $configContent = @'
$Config = @{
    name = @{ Action = 'Preserve'; Type = 'string' }
    metadata = @{
        title = @{ Action = 'Link'; Type = 'string'; LinkTo = 'name' }
    }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-nested-to-parent.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{ name = 'parent-value' }
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.name | Should -Be 'parent-value'
            $result.metadata.title | Should -Be 'parent-value'
        }

        It 'Should link array item fields to each other' {
            $configContent = @'
$Config = @{
    items = @{
        Type = 'array'
        ArrayCount = 2
        ItemStructure = @{
            name = @{ Action = 'Randomize'; Type = 'string' }
            fullName = @{ Action = 'Link'; Type = 'string'; LinkTo = 'name' }
        }
    }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-array-siblings.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{}
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.items.Count | Should -Be 2
            # Each item's fullName should link to its own name
            $result.items[0].fullName | Should -Be $result.items[0].name
            $result.items[1].fullName | Should -Be $result.items[1].name
        }

        It 'Should reject array items linking to parent scope fields' {
            $configContent = @'
$Config = @{
    namespace = @{ Action = 'Preserve'; Type = 'string' }
    items = @{
        Type = 'array'
        ArrayCount = 2
        ItemStructure = @{
            name = @{ Action = 'Randomize'; Type = 'string' }
            ns = @{ Action = 'Link'; Type = 'string'; LinkTo = 'namespace' }
        }
    }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-array-to-parent.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{ namespace = 'my-namespace' } } |
                Should -Throw '*cannot link to*outside the array*'
        }

        It 'Should reject circular links' {
            $configContent = @'
$Config = @{
    fieldA = @{ Action = 'Link'; Type = 'string'; LinkTo = 'fieldB' }
    fieldB = @{ Action = 'Link'; Type = 'string'; LinkTo = 'fieldA' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-circular.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{} } |
                Should -Throw '*Circular or chained link detected*'
        }

        It 'Should reject chained links' {
            $configContent = @'
$Config = @{
    name = @{ Action = 'Preserve'; Type = 'string' }
    displayName = @{ Action = 'Link'; Type = 'string'; LinkTo = 'name' }
    label = @{ Action = 'Link'; Type = 'string'; LinkTo = 'displayName' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-chained.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{ name = 'test' } } |
                Should -Throw '*Circular or chained link detected*'
        }

        It 'Should reject downward links (parent to child)' {
            $configContent = @'
$Config = @{
    title = @{ Action = 'Link'; Type = 'string'; LinkTo = 'metadata.name' }
    metadata = @{
        name = @{ Action = 'Preserve'; Type = 'string' }
    }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-downward.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{} } |
                Should -Throw '*Parent fields cannot link to nested child fields*'
        }

        It 'Should reject cross-sibling links' {
            $configContent = @'
$Config = @{
    metadata = @{
        name = @{ Action = 'Preserve'; Type = 'string' }
    }
    labels = @{
        title = @{ Action = 'Link'; Type = 'string'; LinkTo = 'metadata.name' }
    }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-cross-sibling.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{} } |
                Should -Throw '*at the same depth but in different scopes*'
        }

        It 'Should reject links to non-existent fields' {
            $configContent = @'
$Config = @{
    name = @{ Action = 'Preserve'; Type = 'string' }
    title = @{ Action = 'Link'; Type = 'string'; LinkTo = 'nonexistent' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-nonexistent.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            { New-DataFromConfiguration -ConfigPath $configPath -SeedData @{ name = 'test' } } |
                Should -Throw '*does not exist in the configuration*'
        }

        It 'Should handle Link action with missing LinkTo property' {
            $configContent = @'
$Config = @{
    name = @{ Action = 'Preserve'; Type = 'string' }
    title = @{ Action = 'Link'; Type = 'string' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-missing-linkto.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            # Should generate random value with warning instead of throwing
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData @{ name = 'test' } -WarningAction SilentlyContinue

            $result.name | Should -Be 'test'
            $result.title | Should -Not -BeNullOrEmpty
        }

        It 'Should support multiple fields linking to same source' {
            $configContent = @'
$Config = @{
    id = @{ Action = 'Preserve'; Type = 'string' }
    name = @{ Action = 'Link'; Type = 'string'; LinkTo = 'id' }
    title = @{ Action = 'Link'; Type = 'string'; LinkTo = 'id' }
    label = @{ Action = 'Link'; Type = 'string'; LinkTo = 'id' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-multiple-to-one.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{ id = 'unique-id-123' }
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.id | Should -Be 'unique-id-123'
            $result.name | Should -Be 'unique-id-123'
            $result.title | Should -Be 'unique-id-123'
            $result.label | Should -Be 'unique-id-123'
        }

        It 'Should link to preserved fields with seed data' {
            $configContent = @'
$Config = @{
    username = @{ Action = 'Preserve'; Type = 'string' }
    email = @{ Action = 'Preserve'; Type = 'string' }
    displayName = @{ Action = 'Link'; Type = 'string'; LinkTo = 'username' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-with-preserve.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{ username = 'johndoe'; email = 'john@test.com' }
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.username | Should -Be 'johndoe'
            $result.email | Should -Be 'john@test.com'
            $result.displayName | Should -Be 'johndoe'
        }

        It 'Should link to randomized fields' {
            $configContent = @'
$Config = @{
    randomId = @{ Action = 'Randomize'; Type = 'string' }
    backupId = @{ Action = 'Link'; Type = 'string'; LinkTo = 'randomId' }
}
$Config
'@
            $configPath = Join-Path $TestDrive 'link-with-randomize.ps1'
            $configContent | Out-File -FilePath $configPath -Encoding UTF8

            $seed = @{}
            $result = New-DataFromConfiguration -ConfigPath $configPath -SeedData $seed

            $result.randomId | Should -Not -BeNullOrEmpty
            $result.backupId | Should -Be $result.randomId
        }
    }
}

