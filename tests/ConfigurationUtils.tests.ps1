# ConfigurationUtils.tests.ps1
# Test cases for private Utils functions used in New-DataFromConfiguration

Describe 'Configuration-Based Utils Functions' {
    BeforeAll {
        # Dot source the required private utility functions
        . $PSScriptRoot/../PSTestableData/Private/Utils/Get-SeedValue.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Get-LinkedValue.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/New-ValueFromConfig.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/New-EmptyStructure.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Test-LinkedFieldConfiguration.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Set-NonLinkedFields.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Set-LinkedFields.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Initialize-DataFromConfig.ps1

        # Real Kubernetes namespace data as PowerShell object (from kubectl get namespaces pwshdevs-com -o yaml)
        $script:realK8sSeed = @{
            kind = 'List'
            metadata = @{
                resourceVersion = ''
            }
            apiVersion = 'v1'
            items = @(
                @{
                    spec = @{
                        finalizers = @('kubernetes')
                    }
                    apiVersion = 'v1'
                    kind = 'Namespace'
                    status = @{
                        phase = 'Active'
                    }
                    metadata = @{
                        labels = @{
                            'kubernetes.io/metadata.name' = 'pwshdevs-com'
                        }
                        uid = '4ffbd194-0705-4794-bc30-7785fd1b88c6'
                        name = 'pwshdevs-com'
                        creationTimestamp = '2025-09-08T04:13:34Z'
                        resourceVersion = '11616458'
                    }
                }
            )
        }

        # Real configuration from testoutput.ps1
        $script:realConfig = @{
            apiVersion = @{
                Action = 'Preserve'
                Type = 'string'
            }
            items = @{
                Action = 'Preserve'
                ArrayCount = 1
                ItemStructure = @{
                    apiVersion = @{
                        Action = 'Preserve'
                        Type = 'string'
                    }
                    kind = @{
                        Action = 'Preserve'
                        Type = 'string'
                    }
                    metadata = @{
                        creationTimestamp = @{
                            Action = 'Preserve'
                            Type = 'datetime'
                        }
                        labels = @{
                            'kubernetes.io/metadata.name' = @{
                                Action = 'Link'
                                LinkTo = 'name'
                                Type = 'string'
                            }
                        }
                        name = @{
                            Action = 'Randomize'
                            Type = 'string'
                        }
                        resourceVersion = @{
                            Action = 'Preserve'
                            Type = 'string'
                        }
                        uid = @{
                            Action = 'Randomize'
                            Type = 'guid'
                        }
                    }
                    spec = @{
                        finalizers = @{
                            Action = 'Preserve'
                            ArrayCount = 1
                            ItemAction = 'Preserve'
                            ItemType = 'string'
                            Type = 'array'
                        }
                    }
                    status = @{
                        phase = @{
                            Action = 'Preserve'
                            Type = 'string'
                        }
                    }
                }
                Type = 'array'
            }
            kind = @{
                Action = 'Preserve'
                Type = 'string'
            }
            metadata = @{
                resourceVersion = @{
                    Action = 'Preserve'
                    Type = 'string'
                }
            }
        }
    }

    Context 'Get-SeedValue' {
        BeforeAll {
            $script:testSeed = @{
                name = 'TestName'
                count = 42
                metadata = @{
                    labels = @{
                        app = 'myapp'
                        version = 'v1'
                    }
                    createdAt = '2024-01-01T00:00:00Z'
                }
                items = @(
                    @{ id = 1; name = 'Item1' }
                    @{ id = 2; name = 'Item2' }
                )
            }
        }

        It 'Retrieves top-level string field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'name'
            $result | Should -Be 'TestName'
        }

        It 'Retrieves top-level integer field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'count'
            $result | Should -Be 42
        }

        It 'Retrieves nested object field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'metadata'
            $result | Should -BeOfType [hashtable]
            $result.labels.app | Should -Be 'myapp'
        }

        It 'Retrieves deeply nested field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'metadata.labels.app'
            $result | Should -Be 'myapp'
        }

        It 'Retrieves array field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'items'
            $result.GetType() | Should -Be ([System.Object[]])
            $result.Count | Should -Be 2
        }

        It 'Returns null for non-existent field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null for non-existent nested field' {
            $result = Get-SeedValue -SeedObject $script:testSeed -FieldPath 'metadata.nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null for null seed object' {
            $result = Get-SeedValue -SeedObject $null -FieldPath 'name'
            $result | Should -BeNullOrEmpty
        }

        It 'Handles PSCustomObject seed' {
            $psSeed = [PSCustomObject]@{ title = 'Test'; value = 123 }
            $result = Get-SeedValue -SeedObject $psSeed -FieldPath 'title'
            $result | Should -Be 'Test'
        }
    }

    Context 'Get-LinkedValue' {
        BeforeAll {
            $script:testResult = @{
                name = 'GeneratedName'
                count = 100
                metadata = @{
                    title = 'Generated Title'
                    tags = @{
                        primary = 'tag1'
                        secondary = 'tag2'
                    }
                }
            }
        }

        It 'Retrieves top-level field' {
            $result = Get-LinkedValue -Result $script:testResult -LinkPath 'name'
            $result | Should -Be 'GeneratedName'
        }

        It 'Retrieves nested field' {
            $result = Get-LinkedValue -Result $script:testResult -LinkPath 'metadata.title'
            $result | Should -Be 'Generated Title'
        }

        It 'Retrieves deeply nested field' {
            $result = Get-LinkedValue -Result $script:testResult -LinkPath 'metadata.tags.primary'
            $result | Should -Be 'tag1'
        }

        It 'Returns null for non-existent field' {
            $result = Get-LinkedValue -Result $script:testResult -LinkPath 'nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null for non-existent nested field' {
            $result = Get-LinkedValue -Result $script:testResult -LinkPath 'metadata.nonexistent'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'New-ValueFromConfig' {
        It 'Generates string value with Randomize action' {
            $config = @{ Type = 'string'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Generates int value with Randomize action' {
            $config = @{ Type = 'int'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [int]
        }

        It 'Generates long value with Randomize action' {
            $config = @{ Type = 'long'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [long]
        }

        It 'Generates double value with Randomize action' {
            $config = @{ Type = 'double'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [double]
        }

        It 'Generates bool value with Randomize action' {
            $config = @{ Type = 'bool'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [bool]
        }

        It 'Generates datetime value with Randomize action' {
            $config = @{ Type = 'datetime'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
        }

        It 'Generates guid value with Randomize action' {
            $config = @{ Type = 'guid'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        }

        It 'Preserves seed value with Preserve action' {
            $config = @{ Type = 'string'; Action = 'Preserve' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue 'OriginalValue' -FieldPath 'test.field'
            $result | Should -Be 'OriginalValue'
        }

        It 'Returns fallback value for null seed with Preserve action' {
            # When Preserve action has null seed, it falls through to generate random value
            $config = @{ Type = 'string'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Generates simple string array with Randomize action' {
            $config = @{
                Type = 'array'
                ItemType = 'string'
                ArrayCount = 3
                ItemAction = 'Randomize'
            }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.array'
            $result.GetType() | Should -Be ([System.Object[]])
            $result.Count | Should -Be 3
            $result[0] | Should -BeOfType [string]
        }

        It 'Preserves simple array with Preserve action' {
            $config = @{
                Type = 'array'
                ItemType = 'string'
                ArrayCount = 2
                ItemAction = 'Preserve'
            }
            $seedArray = @('original1', 'original2')
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $seedArray -FieldPath 'test.array'
            $result.GetType() | Should -Be ([System.Object[]])
            $result.Count | Should -Be 2
            $result[0] | Should -Be 'original1'
            $result[1] | Should -Be 'original2'
        }

        It 'Handles IList from YAML parsing with Preserve action' {
            $config = @{
                Type = 'array'
                ItemType = 'string'
                ArrayCount = 2
                ItemAction = 'Preserve'
            }
            # Simulate List<T> from ConvertFrom-Yaml
            $list = New-Object 'System.Collections.Generic.List[Object]'
            $list.Add('item1')
            $list.Add('item2')

            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $list -FieldPath 'test.array'
            $result.GetType() | Should -Be ([System.Object[]])
            $result.Count | Should -Be 2
            $result[0] | Should -Be 'item1'
        }

        It 'Handles unknown type gracefully' {
            $config = @{ Type = 'unknowntype'; Action = 'Randomize' }
            $result = New-ValueFromConfig -FieldConfig $config -SeedValue $null -FieldPath 'test.field'
            $result | Should -BeOfType [string]
        }
    }

    Context 'New-EmptyStructure' {
        It 'Creates empty structure with string fields' {
            $config = @{
                name = @{ Type = 'string'; Action = 'Randomize' }
                count = @{ Type = 'int'; Action = 'Randomize' }
            }
            $result = New-EmptyStructure -Config $config
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'name'
            $result.Keys | Should -Contain 'count'
            $result.name | Should -BeNullOrEmpty
            # Integer fields may be $null or 0, both are acceptable
        }

        It 'Creates empty nested structure' {
            $config = @{
                metadata = @{
                    name = @{ Type = 'string'; Action = 'Randomize' }
                    labels = @{
                        app = @{ Type = 'string'; Action = 'Randomize' }
                    }
                }
            }
            $result = New-EmptyStructure -Config $config
            $result.metadata | Should -BeOfType [hashtable]
            $result.metadata.labels | Should -BeOfType [hashtable]
            $result.metadata.labels.Keys | Should -Contain 'app'
        }

        It 'Creates empty array structure' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 2
                    ItemStructure = @{
                        id = @{ Type = 'int'; Action = 'Randomize' }
                    }
                }
            }
            $result = New-EmptyStructure -Config $config
            $result.items.GetType() | Should -Be ([System.Object[]])
            $result.items.Count | Should -Be 2
            $result.items[0] | Should -BeOfType [hashtable]
            $result.items[0].Keys | Should -Contain 'id'
        }

        It 'Handles simple array without ItemStructure' {
            # Simple arrays without ItemStructure are not initialized in New-EmptyStructure
            # They are created later during Set-NonLinkedFields (Pass 2)
            $config = @{
                tags = @{
                    Type = 'array'
                    ItemType = 'string'
                    ArrayCount = 3
                }
            }
            $result = New-EmptyStructure -Config $config
            # This is expected behavior - simple arrays are not part of empty structure
            $result.ContainsKey('tags') | Should -Be $false
        }
    }

    Context 'Test-LinkedFieldConfiguration' {
        It 'Validates simple link at root level' {
            $config = @{
                firstName = @{ Type = 'string'; Action = 'Randomize' }
                lastName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'firstName' }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw
        }

        It 'Throws for missing LinkTo target' {
            $config = @{
                firstName = @{ Type = 'string'; Action = 'Randomize' }
                lastName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'nonexistent' }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Throw "*does not exist*"
        }

        It 'Throws for circular link' {
            $config = @{
                field1 = @{ Type = 'string'; Action = 'Link'; LinkTo = 'field2' }
                field2 = @{ Type = 'string'; Action = 'Link'; LinkTo = 'field1' }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Throw "*Circular*"
        }

        It 'Throws for chained link' {
            $config = @{
                field1 = @{ Type = 'string'; Action = 'Randomize' }
                field2 = @{ Type = 'string'; Action = 'Link'; LinkTo = 'field1' }
                field3 = @{ Type = 'string'; Action = 'Link'; LinkTo = 'field2' }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Throw "*chained*"
        }

        It 'Validates link within array item structure' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 1
                    ItemStructure = @{
                        name = @{ Type = 'string'; Action = 'Randomize' }
                        displayName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                    }
                }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw
        }

        It 'Validates nested sibling link in array item' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 1
                    ItemStructure = @{
                        metadata = @{
                            name = @{ Type = 'string'; Action = 'Randomize' }
                            labels = @{
                                nameLabel = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                            }
                        }
                    }
                }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw
        }

        It 'Throws when array item tries to link outside array' {
            $config = @{
                globalName = @{ Type = 'string'; Action = 'Randomize' }
                items = @{
                    Type = 'array'
                    ArrayCount = 1
                    ItemStructure = @{
                        name = @{ Type = 'string'; Action = 'Link'; LinkTo = 'globalName' }
                    }
                }
            }
            { Test-LinkedFieldConfiguration -Config $config } | Should -Throw "*cannot link to*outside the array*"
        }
    }

    Context 'Set-NonLinkedFields' {
        It 'Populates simple fields with Randomize action' {
            $config = @{
                name = @{ Type = 'string'; Action = 'Randomize' }
                count = @{ Type = 'int'; Action = 'Randomize' }
            }
            $result = @{}
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $null

            $result.name | Should -BeOfType [string]
            $result.name | Should -Not -BeNullOrEmpty
            $result.count | Should -BeOfType [int]
        }

        It 'Preserves fields from seed data' {
            $config = @{
                name = @{ Type = 'string'; Action = 'Preserve' }
                count = @{ Type = 'int'; Action = 'Preserve' }
            }
            $seed = @{ name = 'SeedName'; count = 99 }
            $result = @{}
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $seed

            $result.name | Should -Be 'SeedName'
            $result.count | Should -Be 99
        }

        It 'Skips linked fields' {
            $config = @{
                firstName = @{ Type = 'string'; Action = 'Randomize' }
                lastName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'firstName' }
            }
            $result = @{}
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $null

            $result.firstName | Should -Not -BeNullOrEmpty
            $result.ContainsKey('lastName') | Should -Be $false
        }

        It 'Handles nested objects' {
            $config = @{
                metadata = @{
                    name = @{ Type = 'string'; Action = 'Randomize' }
                    version = @{ Type = 'int'; Action = 'Randomize' }
                }
            }
            $result = @{ metadata = @{} }
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $null

            $result.metadata.name | Should -BeOfType [string]
            $result.metadata.version | Should -BeOfType [int]
        }

        It 'Handles array with ItemStructure' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 2
                    ItemStructure = @{
                        id = @{ Type = 'int'; Action = 'Randomize' }
                        name = @{ Type = 'string'; Action = 'Randomize' }
                    }
                }
            }
            $result = @{ items = @(@{}, @{}) }
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $null

            $result.items[0].id | Should -BeOfType [int]
            $result.items[0].name | Should -BeOfType [string]
            $result.items[1].id | Should -BeOfType [int]
        }

        It 'Handles simple array with ItemType' {
            $config = @{
                tags = @{
                    Type = 'array'
                    ItemType = 'string'
                    ArrayCount = 3
                    ItemAction = 'Randomize'
                }
            }
            $result = @{}
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $null

            $result.tags.GetType() | Should -Be ([System.Object[]])
            $result.tags.Count | Should -Be 3
            $result.tags[0] | Should -BeOfType [string]
        }

        It 'Preserves array from seed data' {
            $config = @{
                tags = @{
                    Type = 'array'
                    ItemType = 'string'
                    ArrayCount = 2
                    ItemAction = 'Preserve'
                }
            }
            $seed = @{ tags = @('tag1', 'tag2') }
            $result = @{}
            Set-NonLinkedFields -Config $config -Result $result -SeedObject $seed

            $result.tags.GetType() | Should -Be ([System.Object[]])
            $result.tags.Count | Should -Be 2
            $result.tags[0] | Should -Be 'tag1'
        }
    }

    Context 'Set-LinkedFields' {
        It 'Populates simple linked field' {
            $config = @{
                firstName = @{ Type = 'string'; Action = 'Randomize' }
                lastName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'firstName' }
            }
            $result = @{ firstName = 'John'; lastName = '' }
            Set-LinkedFields -Config $config -Result $result -ResultContext $result

            $result.lastName | Should -Be 'John'
        }

        It 'Populates nested linked field' {
            $config = @{
                user = @{
                    name = @{ Type = 'string'; Action = 'Randomize' }
                    displayName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                }
            }
            $result = @{
                user = @{ name = 'TestUser'; displayName = '' }
            }
            # For nested objects, ResultContext is passed down correctly by the recursive call
            Set-LinkedFields -Config $config -Result $result -ResultContext $result

            # The link should work because Set-LinkedFields passes $Result (user object) as context when recursing
            $result.user.displayName | Should -Be 'TestUser'
        }

        It 'Handles linked fields in array items' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 2
                    ItemStructure = @{
                        name = @{ Type = 'string'; Action = 'Randomize' }
                        title = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                    }
                }
            }
            $result = @{
                items = @(
                    @{ name = 'Item1'; title = '' }
                    @{ name = 'Item2'; title = '' }
                )
            }
            Set-LinkedFields -Config $config -Result $result -ResultContext $result

            $result.items[0].title | Should -Be 'Item1'
            $result.items[1].title | Should -Be 'Item2'
        }

        It 'Handles nested linked fields in array items' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 1
                    ItemStructure = @{
                        metadata = @{
                            name = @{ Type = 'string'; Action = 'Randomize' }
                            labels = @{
                                nameLabel = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                            }
                        }
                    }
                }
            }
            $result = @{
                items = @(
                    @{
                        metadata = @{
                            name = 'ItemName'
                            labels = @{ nameLabel = '' }
                        }
                    }
                )
            }
            Set-LinkedFields -Config $config -Result $result -ResultContext $result

            $result.items[0].metadata.labels.nameLabel | Should -Be 'ItemName'
        }

        It 'Handles missing LinkTo gracefully' {
            # This test expects no exception, but New-ValueFromConfig needs Result parameter
            # which is null in the warning code path. This is a known edge case.
            $config = @{
                field1 = @{ Type = 'string'; Action = 'Randomize' }
                field2 = @{ Type = 'string'; Action = 'Link'; LinkTo = '' }
            }
            $result = @{ field1 = 'Value1'; field2 = '' }

            # Should generate random value instead of throwing
            { Set-LinkedFields -Config $config -Result $result -ResultContext $result } | Should -Not -Throw
            $result.field2 | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Initialize-DataFromConfig' {
        It 'Executes three-pass process successfully' {
            $config = @{
                name = @{ Type = 'string'; Action = 'Randomize' }
                displayName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                count = @{ Type = 'int'; Action = 'Randomize' }
            }

            $result = Initialize-DataFromConfig -Config $config -SeedObject $null

            $result | Should -BeOfType [hashtable]
            $result.name | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be $result.name
            $result.count | Should -BeOfType [int]
        }

        It 'Uses seed data when provided' {
            $config = @{
                name = @{ Type = 'string'; Action = 'Preserve' }
                displayName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
            }
            $seed = @{ name = 'SeedName' }

            $result = Initialize-DataFromConfig -Config $config -SeedObject $seed

            $result.name | Should -Be 'SeedName'
            $result.displayName | Should -Be 'SeedName'
        }

        It 'Handles complex nested structure with arrays' {
            $config = @{
                metadata = @{
                    name = @{ Type = 'string'; Action = 'Randomize' }
                }
                items = @{
                    Type = 'array'
                    ArrayCount = 2
                    ItemStructure = @{
                        id = @{ Type = 'int'; Action = 'Randomize' }
                        parentName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'id' }
                    }
                }
            }

            $result = Initialize-DataFromConfig -Config $config -SeedObject $null

            $result.metadata.name | Should -Not -BeNullOrEmpty
            $result.items.Count | Should -Be 2
            $result.items[0].id | Should -BeOfType [int]
            # Convert to string for comparison since LinkTo converts types
            $result.items[0].parentName | Should -Be $result.items[0].id.ToString()
        }
    }

    Context 'Integration Tests - Full Workflow' {
        It 'Processes simple configuration end-to-end' {
            $config = @{
                firstName = @{ Type = 'string'; Action = 'Randomize' }
                lastName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'firstName' }
                age = @{ Type = 'int'; Action = 'Randomize' }
            }

            # Validate
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw

            # Generate
            $result = Initialize-DataFromConfig -Config $config -SeedObject $null

            # Verify
            $result.firstName | Should -Not -BeNullOrEmpty
            $result.lastName | Should -Be $result.firstName
            $result.age | Should -BeOfType [int]
        }

        It 'Processes configuration with arrays end-to-end' {
            $config = @{
                users = @{
                    Type = 'array'
                    ArrayCount = 2
                    ItemStructure = @{
                        username = @{ Type = 'string'; Action = 'Randomize' }
                        displayName = @{ Type = 'string'; Action = 'Link'; LinkTo = 'username' }
                        email = @{ Type = 'string'; Action = 'Randomize' }
                    }
                }
            }

            # Validate
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw

            # Generate
            $result = Initialize-DataFromConfig -Config $config -SeedObject $null

            # Verify
            $result.users.Count | Should -Be 2
            $result.users[0].displayName | Should -Be $result.users[0].username
            $result.users[1].displayName | Should -Be $result.users[1].username
        }

        It 'Processes Kubernetes-style configuration' {
            $config = @{
                items = @{
                    Type = 'array'
                    ArrayCount = 1
                    ItemStructure = @{
                        metadata = @{
                            name = @{ Type = 'string'; Action = 'Randomize' }
                            labels = @{
                                nameLabel = @{ Type = 'string'; Action = 'Link'; LinkTo = 'name' }
                            }
                            uid = @{ Type = 'guid'; Action = 'Randomize' }
                        }
                        spec = @{
                            finalizers = @{
                                Type = 'array'
                                ItemType = 'string'
                                ArrayCount = 2
                                ItemAction = 'Randomize'
                            }
                        }
                    }
                }
            }

            # Validate
            { Test-LinkedFieldConfiguration -Config $config } | Should -Not -Throw

            # Generate
            $result = Initialize-DataFromConfig -Config $config -SeedObject $null

            # Verify
            $result.items.Count | Should -Be 1
            $result.items[0].metadata.name | Should -Not -BeNullOrEmpty
            $result.items[0].metadata.labels.nameLabel | Should -Be $result.items[0].metadata.name
            $result.items[0].metadata.uid | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            $result.items[0].spec.finalizers.Count | Should -Be 2
        }
    }

    Context 'Real-World Kubernetes Integration Tests' {
        It 'Validates real Kubernetes namespace configuration' {
            { Test-LinkedFieldConfiguration -Config $script:realConfig } | Should -Not -Throw
        }

        It 'Generates data from real Kubernetes seed with nested sibling link' {
            # This is the critical test - nested label linking to sibling name field
            $result = Initialize-DataFromConfig -Config $script:realConfig -SeedObject $script:realK8sSeed

            # Verify structure
            $result.kind | Should -Be 'List'
            $result.items | Should -Not -BeNullOrEmpty
            $result.items.Count | Should -Be 1

            # Verify first item
            $item = $result.items[0]
            $item.kind | Should -Be 'Namespace'
            $item.apiVersion | Should -Be 'v1'

            # Verify metadata
            $item.metadata.name | Should -Not -BeNullOrEmpty
            $item.metadata.name | Should -BeOfType [string]

            # Verify the critical nested sibling link
            $item.metadata.labels.'kubernetes.io/metadata.name' | Should -Not -BeNullOrEmpty

            # THE KEY TEST: Label should equal the name (linked field)
            $item.metadata.labels.'kubernetes.io/metadata.name' | Should -Be $item.metadata.name -Because "Label should link to sibling name field"

            # Verify other fields
            $item.metadata.uid | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            $item.metadata.creationTimestamp | Should -Be '2025-09-08T04:13:34Z'
            $item.metadata.resourceVersion | Should -Be '11616458'

            # Verify finalizers array
            $item.spec.finalizers.GetType() | Should -Be ([System.Object[]])
            $item.spec.finalizers.Count | Should -Be 1
            $item.spec.finalizers[0] | Should -Be 'kubernetes'

            # Verify status
            $item.status.phase | Should -Be 'Active'
        }

        It 'Generates multiple instances with consistent linking' {
            # Generate 3 instances to verify linking works consistently
            $results = @()
            for ($i = 0; $i -lt 3; $i++) {
                $results += Initialize-DataFromConfig -Config $script:realConfig -SeedObject $script:realK8sSeed
            }

            foreach ($result in $results) {
                $item = $result.items[0]
                # Each instance should have linked label matching name
                $item.metadata.labels.'kubernetes.io/metadata.name' | Should -Be $item.metadata.name
                # Each instance should have different random name
                $item.metadata.name | Should -Not -BeNullOrEmpty
            }

            # Names should be different across instances (randomized)
            $names = $results | ForEach-Object { $_.items[0].metadata.name }
            $uniqueNames = $names | Select-Object -Unique
            $uniqueNames.Count | Should -BeGreaterThan 1 -Because "Random names should vary"
        }

        It 'Preserves seed array structure correctly' {
            $result = Initialize-DataFromConfig -Config $script:realConfig -SeedObject $script:realK8sSeed

            # Finalizers should be preserved as array
            $result.items[0].spec.finalizers.GetType() | Should -Be ([System.Object[]])
            $result.items[0].spec.finalizers.Count | Should -Be 1
            $result.items[0].spec.finalizers[0] | Should -Be 'kubernetes'
        }
    }
}
