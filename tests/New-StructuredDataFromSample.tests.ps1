# New-StructuredDataFromSample.tests.ps1
# Comprehensive test cases for the enhanced New-StructuredDataFromSample function

Describe 'New-StructuredDataFromSample' {
    BeforeAll {
        # Import the function and dependencies
        . $PSScriptRoot/../PSTestableData/Public/New-StructuredDataFromSample.ps1
        . $PSScriptRoot/../PSTestableData/Private/Generators/Out-AnonymizedString.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/New-DataFromStructure.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/New-ValueFromPattern.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Get-StructurePattern.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Test-PreserveField.ps1
        . $PSScriptRoot/../PSTestableData/Private/Utils/Get-ValuePattern.ps1
    }

    Context 'Basic Structure Preservation' {
        It 'Preserves hashtable structure and types' {
            $sample = @{ name = "John"; age = 30; active = $true }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 3
            $result.Keys | Should -Contain 'name'
            $result.Keys | Should -Contain 'age'
            $result.Keys | Should -Contain 'active'
            $result.name | Should -BeOfType [string]
            $result.age | Should -BeOfType [int]
            $result.active | Should -BeOfType [bool]
        }

        It 'Generates different values while preserving types' {
            $sample = @{ name = "John"; age = 30 }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.name | Should -Not -Be "John"
            $result.age | Should -Not -Be 30
            $result.name | Should -BeOfType [string]
            $result.age | Should -BeOfType [int]
        }

        It 'Handles PSCustomObjects correctly' {
            $sample = [PSCustomObject]@{
                id = 123
                title = "Test Object"
                enabled = $false
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result | Should -BeOfType [PSCustomObject]
            $result.id | Should -BeOfType [int]
            $result.title | Should -BeOfType [string]
            $result.enabled | Should -BeOfType [bool]
        }
    }

    Context 'Array Generation and Randomization' {
        It 'Generates random array sizes within MaxArrayItems range' {
            $sample = @{ items = @("a", "b") }
            $results = @()

            # Run multiple times to test randomization
            for ($i = 0; $i -lt 20; $i++) {
                $result = New-StructuredDataFromSample -InputObject $sample -MaxArrayItems 8
                $results += $result.items.Count
            }

            # Should have variety in array sizes (1-8)
            $uniqueCounts = $results | Sort-Object -Unique
            $uniqueCounts.Count | Should -BeGreaterThan 2
            $results | ForEach-Object { $_ | Should -BeGreaterThan 0 }
            $results | ForEach-Object { $_ | Should -BeLessOrEqual 8 }
        }

        It 'Handles arrays of different types correctly' {
            $sample = @{
                strings = @("hello", "world")
                numbers = @(1, 2, 3)
                booleans = @($true, $false)
            }
            $result = New-StructuredDataFromSample -InputObject $sample
            # Test array types without pipeline to avoid unwrapping
            $result.strings.GetType() | Should -Be ([System.Object[]])
            $result.numbers.GetType() | Should -Be ([System.Object[]])
            $result.booleans.GetType() | Should -Be ([System.Object[]])

            # Verify array contents maintain type
            $result.strings[0] | Should -BeOfType [string]
            $result.numbers[0] | Should -BeOfType [int]
            $result.booleans[0] | Should -BeOfType [bool]
        }

        It 'Preserves arrays with single items as arrays' {
            $sample = @{ singleton = @("only-one") }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.singleton.GetType() | Should -Be ([System.Object[]])
            $result.singleton.Count | Should -BeGreaterOrEqual 1
        }

        It 'Handles arrays of complex objects' {
            $sample = @{
                users = @(
                    @{ name = "Alice"; id = 1 }
                    @{ name = "Bob"; id = 2 }
                )
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.users.GetType() | Should -Be ([System.Object[]])
            $result.users.Count | Should -BeGreaterThan 0
            $result.users[0] | Should -BeOfType [hashtable]
            $result.users[0].Keys | Should -Contain 'name'
            $result.users[0].Keys | Should -Contain 'id'
        }
    }

    Context 'Pattern Recognition and Generation' {
        It 'Recognizes and generates GUID patterns' {
            $sample = @{
                id = "4ffbd194-0705-4794-bc30-7785fd1b88c6"
                correlationId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.id | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            $result.correlationId | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            $result.id | Should -Not -Be $sample.id
            $result.correlationId | Should -Not -Be $sample.correlationId
        }

        It 'Recognizes and generates ISO8601 datetime patterns' {
            $sample = @{
                createdAt = "2025-09-08T04:13:34Z"
                updatedAt = "2024-12-04T14:30:45Z"
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.createdAt | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$'
            $result.updatedAt | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$'
            $result.createdAt | Should -Not -Be $sample.createdAt
        }

        It 'Recognizes and generates kebab-case patterns' {
            $sample = @{
                status = "active-ready"
                phase = "pending-complete"
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.status | Should -Match '^[a-zA-Z]+-[a-zA-Z]+$'
            $result.phase | Should -Match '^[a-zA-Z]+-[a-zA-Z]+$'
            $result.status | Should -Not -Be $sample.status
        }

        It 'Recognizes and generates dotted notation patterns' {
            $sample = @{
                label = "kubernetes.io/metadata.name"
                annotation = "app.kubernetes/service.port"
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.label | Should -Match '^[a-zA-Z0-9]+\.[a-zA-Z0-9]+/[a-zA-Z0-9]+\.[a-zA-Z0-9]+$'
            $result.annotation | Should -Match '^[a-zA-Z0-9]+\.[a-zA-Z0-9]+/[a-zA-Z0-9]+\.[a-zA-Z0-9]+$'
            $result.label | Should -Not -Be $sample.label
        }

        It 'Recognizes and generates numeric string patterns' {
            $sample = @{
                resourceVersion = "11616458"
                port = "8080"
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.resourceVersion | Should -Match '^\d+$'
            $result.port | Should -Match '^\d+$'
            $result.resourceVersion | Should -Not -Be $sample.resourceVersion
        }
    }

    Context 'Multiple Item Generation' {
        It 'Generates specified count of items' {
            $sample = @{ name = "test"; value = 42 }
            $result = New-StructuredDataFromSample -InputObject $sample -Count 5

            $result | Should -HaveCount 5
            foreach ($item in $result) {
                $item | Should -BeOfType [hashtable]
                $item.Keys | Should -Contain 'name'
                $item.Keys | Should -Contain 'value'
            }
        }

        It 'Returns single item when Count is 1' {
            $sample = @{ id = 1 }
            $result = New-StructuredDataFromSample -InputObject $sample -Count 1

            $result | Should -BeOfType [hashtable]
            $result | Should -Not -BeOfType [array]
        }

        It 'Generates variety across multiple items' {
            $sample = @{ name = "test" }
            $result = New-StructuredDataFromSample -InputObject $sample -Count 10

            # All items should have different values due to randomization
            $names = $result | ForEach-Object { $_.name }
            $uniqueNames = $names | Sort-Object -Unique
            $uniqueNames.Count | Should -BeGreaterThan 1
        }
    }

    Context 'Nested and Complex Structures' {
        It 'Handles deeply nested structures' {
            $sample = @{
                level1 = @{
                    level2 = @{
                        level3 = @{
                            data = "deep value"
                            items = @(1, 2, 3)
                        }
                    }
                }
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.level1 | Should -BeOfType [hashtable]
            $result.level1.level2 | Should -BeOfType [hashtable]
            $result.level1.level2.level3 | Should -BeOfType [hashtable]
            $result.level1.level2.level3.data | Should -BeOfType [string]
            $result.level1.level2.level3.items.GetType() | Should -Be ([System.Object[]])
        }

        It 'Handles mixed hashtables and PSCustomObjects' {
            $sample = @{
                hashTable = @{ name = "hash"; value = 100 }
                customObject = [PSCustomObject]@{ name = "custom"; value = 200 }
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.hashTable | Should -BeOfType [hashtable]
            $result.customObject | Should -BeOfType [PSCustomObject]
        }
    }

    Context 'Real-World Kubernetes Examples' {
        It 'Handles Kubernetes List structures with multiple namespaces' {
            $sample = @{
                kind = "List"
                apiVersion = "v1"
                metadata = @{ resourceVersion = "" }
                items = @(
                    @{
                        kind = "Namespace"
                        apiVersion = "v1"
                        metadata = @{
                            name = "test-namespace"
                            uid = "4ffbd194-0705-4794-bc30-7785fd1b88c6"
                            creationTimestamp = "2025-09-08T04:13:34Z"
                            labels = @{
                                "kubernetes.io/metadata.name" = "test-namespace"
                            }
                            resourceVersion = "11616458"
                        }
                        spec = @{
                            finalizers = @("kubernetes")
                        }
                        status = @{
                            phase = "Active"
                        }
                    }
                )
            }

            # Test with different MaxArrayItems values to ensure variety
            $results = @()
            for ($i = 0; $i -lt 10; $i++) {
                $generated = New-StructuredDataFromSample -InputObject $sample -MaxArrayItems 6
                $results += $generated.items.Count
            }

            # Verify structure preservation
            $testResult = New-StructuredDataFromSample -InputObject $sample
            $testResult.kind | Should -BeOfType [string]
            $testResult.apiVersion | Should -BeOfType [string]
            $testResult.metadata | Should -BeOfType [hashtable]
            $testResult.items.GetType() | Should -Be ([System.Object[]])
            $testResult.items[0].metadata.uid | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

            # Verify array size variety
            $uniqueCounts = $results | Sort-Object -Unique
            $uniqueCounts.Count | Should -BeGreaterThan 2
        }

        It 'Handles Pod specifications' {
            $sample = @{
                apiVersion = "v1"
                kind = "Pod"
                metadata = @{
                    name = "web-pod"
                    namespace = "default"
                    uid = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
                }
                spec = @{
                    containers = @(
                        @{
                            name = "nginx"
                            image = "nginx:1.20"
                            ports = @(
                                @{ containerPort = 80; protocol = "TCP" }
                                @{ containerPort = 443; protocol = "TCP" }
                            )
                        }
                    )
                    restartPolicy = "Always"
                }
                status = @{
                    phase = "Running"
                }
            }
            $result = New-StructuredDataFromSample -InputObject $sample

            # Verify overall structure
            $result.apiVersion | Should -BeOfType [string]
            $result.kind | Should -BeOfType [string]
            $result.metadata | Should -BeOfType [hashtable]
            $result.spec | Should -BeOfType [hashtable]
            $result.status | Should -BeOfType [hashtable]

            # Verify nested arrays and objects
            $result.spec.containers.GetType() | Should -Be ([System.Object[]])
            $result.spec.containers[0] | Should -BeOfType [hashtable]
            $result.spec.containers[0].ports.GetType() | Should -Be ([System.Object[]])
            $result.spec.containers[0].ports[0] | Should -BeOfType [hashtable]

            # Verify GUID generation
            $result.metadata.uid | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            $result.metadata.uid | Should -Not -Be $sample.metadata.uid
        }
    }

    Context 'Anonymization Features' {
        It 'Uses word-based generation without Anonymize flag' {
            $sample = @{ description = "This is a test description" }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.description | Should -BeIn @('sample', 'test', 'demo', 'example', 'data', 'value', 'item', 'content')
        }

        It 'Uses scrambled generation with Anonymize flag' {
            $sample = @{ description = "This is a test description" }
            $result = New-StructuredDataFromSample -InputObject $sample -Anonymize

            $result.description | Should -BeOfType [string]
            $result.description | Should -Not -BeIn @('sample', 'test', 'demo', 'example', 'data', 'value', 'item', 'content')
            $result.description.Length | Should -BeGreaterThan 0
        }
    }

    Context 'Edge Cases and Error Handling' {
        It 'Handles null input gracefully' {
            $sample = @{ value = $null }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.value | Should -Be $null
        }

        It 'Handles empty arrays' {
            $sample = @{ items = @() }
            $result = New-StructuredDataFromSample -InputObject $sample

            $result.items.GetType() | Should -Be ([System.Object[]])
        }

        It 'Handles very high MaxArrayItems values' {
            $sample = @{ items = @("test") }
            $result = New-StructuredDataFromSample -InputObject $sample -MaxArrayItems 100

            $result.items.GetType() | Should -Be ([System.Object[]])
            $result.items.Count | Should -BeLessOrEqual 100
            $result.items.Count | Should -BeGreaterThan 0
        }

        It 'Prevents infinite recursion with depth limiting' {
            # Create a very deep structure
            $sample = @{ level1 = @{ level2 = @{ level3 = @{ level4 = @{ level5 = @{ level6 = @{ level7 = @{ level8 = @{ level9 = @{ level10 = @{ level11 = "deep" } } } } } } } } } } }

            { New-StructuredDataFromSample -InputObject $sample } | Should -Not -Throw
        }
    }

    Context 'Performance and Consistency' {
        It 'Generates consistent structure across multiple runs' {
            $sample = @{
                users = @(
                    @{ id = 1; name = "Alice"; active = $true }
                )
                settings = @{
                    theme = "dark"
                    notifications = $false
                }
            }

            # Run multiple times and verify structure consistency
            for ($i = 0; $i -lt 5; $i++) {
                $result = New-StructuredDataFromSample -InputObject $sample

                $result.users.GetType() | Should -Be ([System.Object[]])
                $result.settings | Should -BeOfType [hashtable]
                $result.users[0] | Should -BeOfType [hashtable]
                $result.users[0].Keys.Count | Should -Be 3
                $result.settings.Keys.Count | Should -Be 2
            }
        }

        It 'Handles large datasets efficiently' {
            $largeSample = @{
                items = @()
            }

            # Create a larger sample structure
            for ($i = 0; $i -lt 50; $i++) {
                $largeSample.items += @{
                    id = $i
                    name = "item-$i"
                    metadata = @{
                        created = "2025-01-01T00:00:00Z"
                        tags = @("tag1", "tag2", "tag3")
                    }
                }
            }

            # This should complete without timeout or errors
            $result = New-StructuredDataFromSample -InputObject $largeSample -MaxArrayItems 10

            $result.items.GetType() | Should -Be ([System.Object[]])
            $result.items.Count | Should -BeGreaterThan 0
            $result.items.Count | Should -BeLessOrEqual 10
        }
    }
}
