Describe 'New-ConfigurationFromSample' {
    BeforeAll {
        # Import the module
        $modulePath = Split-Path -Parent $PSScriptRoot
        Import-Module "$modulePath/PSTestableData/PSTestableData.psd1" -Force
    }

    Context 'Basic functionality' {
        It 'Should generate configuration for a simple hashtable' {
            $sample = @{
                name = "John Doe"
                age = 30
                active = $true
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config | Should -Not -BeNullOrEmpty
            $config.Keys.Count | Should -Be 3
            $config.name.Type | Should -Be 'string'
            $config.age.Type | Should -Be 'int'
            $config.active.Type | Should -Be 'bool'
        }

        It 'Should generate configuration for nested objects' {
            $sample = @{
                user = @{
                    name = "John"
                    profile = @{
                        email = "john@example.com"
                    }
                }
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.user | Should -Not -BeNullOrEmpty
            $config.user.name.Type | Should -Be 'string'
            $config.user.profile.email.Type | Should -Be 'string'
        }

        It 'Should detect GUID type' {
            $sample = @{
                id = "4ffbd194-0705-4794-bc30-7785fd1b88c6"
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.id.Type | Should -Be 'guid'
        }

        It 'Should detect datetime type' {
            $sample = @{
                createdAt = "2025-09-08T04:13:34Z"
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.createdAt.Type | Should -Be 'datetime'
        }

        It 'Should handle null values' {
            $sample = @{
                nullField = $null
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.nullField.Type | Should -Be 'null'
        }
    }

    Context 'Array handling' {
        It 'Should generate configuration for arrays of primitives' {
            $sample = @{
                tags = @("tag1", "tag2", "tag3")
            }

            $config = New-ConfigurationFromSample -SampleObject $sample -DefaultArrayCount 5

            $config.tags.Type | Should -Be 'array'
            $config.tags.ArrayCount | Should -Be 3
            $config.tags.ItemType | Should -Be 'string'
        }

        It 'Should generate configuration for arrays of objects' {
            $sample = @{
                items = @(
                    @{ name = "item1"; value = 100 },
                    @{ name = "item2"; value = 200 }
                )
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.items.Type | Should -Be 'array'
            $config.items.ItemStructure | Should -Not -BeNullOrEmpty
            $config.items.ItemStructure.name.Type | Should -Be 'string'
            $config.items.ItemStructure.value.Type | Should -Be 'int'
        }

        It 'Should use custom DefaultArrayCount' {
            $sample = @{
                items = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            }

            $config = New-ConfigurationFromSample -SampleObject $sample -DefaultArrayCount 7

            # Should use the minimum of actual count and DefaultArrayCount
            $config.items.ArrayCount | Should -Be 7
        }
    }

    Context 'Action options' {
        It 'Should apply default Preserve action' {
            $sample = @{ name = "test" }

            $config = New-ConfigurationFromSample -SampleObject $sample -DefaultAction 'Preserve'

            $config.name.Action | Should -Be 'Preserve'
        }

        It 'Should apply default Anonymize action' {
            $sample = @{ name = "test" }

            $config = New-ConfigurationFromSample -SampleObject $sample -DefaultAction 'Anonymize'

            $config.name.Action | Should -Be 'Anonymize'
        }

        It 'Should apply default Randomize action' {
            $sample = @{ name = "test" }

            $config = New-ConfigurationFromSample -SampleObject $sample -DefaultAction 'Randomize'

            $config.name.Action | Should -Be 'Randomize'
        }

        It 'Should default to Preserve action when not specified' {
            $sample = @{ name = "test" }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.name.Action | Should -Be 'Preserve'
        }
    }

    Context 'AnonymizePatterns' {
        It 'Should anonymize exact field matches' {
            $sample = @{
                password = "secret123"
                email = "user@test.com"
                name = "test"
            }

            $config = New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('password', 'email')

            $config.password.Action | Should -Be 'Anonymize'
            $config.email.Action | Should -Be 'Anonymize'
            $config.name.Action | Should -Be 'Preserve'
        }

        It 'Should support wildcard patterns' {
            $sample = @{
                metadata = @{
                    secrets = @{
                        apiKey = "abc123"
                        token = "xyz789"
                    }
                }
            }

            $config = New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('metadata.secrets.*')

            $config.metadata.secrets.apiKey.Action | Should -Be 'Anonymize'
            $config.metadata.secrets.token.Action | Should -Be 'Anonymize'
        }

        It 'Should support wildcard at any level' {
            $sample = @{
                user = @{
                    password = "secret1"
                }
                admin = @{
                    password = "secret2"
                }
            }

            $config = New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('*.password')

            $config.user.password.Action | Should -Be 'Anonymize'
            $config.admin.password.Action | Should -Be 'Anonymize'
        }
    }

    Context 'Complex Kubernetes-like structures' {
        It 'Should handle complex nested Kubernetes structure' {
            $sample = @{
                kind = "List"
                apiVersion = "v1"
                metadata = @{
                    resourceVersion = "11616458"
                }
                items = @(
                    @{
                        apiVersion = "v1"
                        kind = "Namespace"
                        metadata = @{
                            name = "pwshdevs-com"
                            uid = "4ffbd194-0705-4794-bc30-7785fd1b88c6"
                            labels = @{
                                'kubernetes.io/metadata.name' = "pwshdevs-com"
                            }
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

            $config = New-ConfigurationFromSample -SampleObject $sample `
                -AnonymizePatterns @('*.uid', '*.resourceVersion', '*.creationTimestamp')

            # Check top-level fields default to Preserve
            $config.apiVersion.Action | Should -Be 'Preserve'
            $config.kind.Action | Should -Be 'Preserve'

            # Check array structure
            $config.items.Type | Should -Be 'array'
            $config.items.ItemStructure | Should -Not -BeNullOrEmpty

            # Check anonymized fields
            $config.metadata.resourceVersion.Action | Should -Be 'Anonymize'
            $config.items.ItemStructure.metadata.uid.Action | Should -Be 'Anonymize'

            # Check preserved fields
            $config.items.ItemStructure.apiVersion.Action | Should -Be 'Preserve'
            $config.items.ItemStructure.kind.Action | Should -Be 'Preserve'
            $config.items.ItemStructure.status.phase.Action | Should -Be 'Preserve'

            # Check type detection
            $config.items.ItemStructure.metadata.uid.Type | Should -Be 'guid'
            $config.items.ItemStructure.spec.finalizers.Type | Should -Be 'array'
        }
    }

    Context 'PSCustomObject support' {
        It 'Should handle PSCustomObject inputs' {
            $sample = [PSCustomObject]@{
                Name = "Test"
                Value = 42
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.Name.Type | Should -Be 'string'
            $config.Value.Type | Should -Be 'int'
        }
    }

    Context 'Edge cases' {
        It 'Should handle empty hashtable' {
            $sample = @{}

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config | Should -BeOfType [hashtable]
            $config.Keys.Count | Should -Be 0
        }

        It 'Should handle empty array' {
            $sample = @{
                items = @()
            }

            $config = New-ConfigurationFromSample -SampleObject $sample

            $config.items.Type | Should -Be 'array'
            $config.items.ArrayCount | Should -Be 0
        }

        It 'Should respect MaxDepth parameter' {
            # Create deeply nested object
            $sample = @{ level1 = @{ level2 = @{ level3 = @{ level4 = "value" } } } }

            $config = New-ConfigurationFromSample -SampleObject $sample -MaxDepth 2

            $config.level1 | Should -Not -BeNullOrEmpty
            $config.level1.level2 | Should -Not -BeNullOrEmpty
            # At MaxDepth, should return a basic config
            $config.level1.level2.level3.Type | Should -Be 'string'
        }
    }

    Context 'Pipeline support' {
        It 'Should accept pipeline input' {
            $sample = @{ name = "test" }

            $config = $sample | New-ConfigurationFromSample

            $config | Should -Not -BeNullOrEmpty
            $config.name.Type | Should -Be 'string'
        }
    }

    Context 'File output' {
        AfterEach {
            # Clean up test files
            if (Test-Path '.\TestDrive\test-config.ps1') {
                Remove-Item '.\TestDrive\test-config.ps1' -Force
            }
        }

        It 'Should save configuration to file with OutputPath' {
            $sample = @{
                name = "John"
                age = 30
            }

            $outputPath = Join-Path $TestDrive 'test-config.ps1'
            $result = New-ConfigurationFromSample -SampleObject $sample -OutputPath $outputPath

            # Should return the file path
            $result | Should -Be $outputPath
            # File should exist
            Test-Path $outputPath | Should -Be $true
            # File should contain valid PowerShell
            $content = Get-Content $outputPath -Raw
            $content | Should -Match '@\{'
            $content | Should -Match 'Action'
            $content | Should -Match 'Type'
            # File should assign to $Config variable
            $content | Should -Match '\$Config\s*='
            # File should have return statement
            $content | Should -Match 'return\s+\$Config'
        }

        It 'Should create directory if it does not exist' {
            $sample = @{ name = "test" }
            $outputPath = Join-Path $TestDrive 'subdir\test-config.ps1'

            $result = New-ConfigurationFromSample -SampleObject $sample -OutputPath $outputPath

            Test-Path $outputPath | Should -Be $true
            Test-Path (Split-Path $outputPath -Parent) | Should -Be $true
        }

        It 'Should return config with PassThru switch' {
            $sample = @{
                name = "John"
                password = "secret"
            }

            $outputPath = Join-Path $TestDrive 'test-config.ps1'
            $config = New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('password') -OutputPath $outputPath -PassThru

            # Should return the configuration object
            $config | Should -Not -BeNullOrEmpty
            $config.name.Action | Should -Be 'Preserve'
            $config.password.Action | Should -Be 'Anonymize'
            # File should still be created
            Test-Path $outputPath | Should -Be $true
        }

        It 'Should create dot-sourceable file' {
            $sample = @{
                name = "John"
                email = "john@example.com"
                age = 30
            }

            $outputPath = Join-Path $TestDrive 'test-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -AnonymizePatterns @('email') -OutputPath $outputPath

            # Dot-source the file
            $loadedConfig = . $outputPath

            # Should be able to access the configuration
            $loadedConfig | Should -Not -BeNullOrEmpty
            $loadedConfig.name.Action | Should -Be 'Preserve'
            $loadedConfig.email.Action | Should -Be 'Anonymize'
            $loadedConfig.age.Type | Should -Be 'int'
        }

        It 'Should create $Config variable when dot-sourced without assignment' {
            $sample = @{
                name = "Test"
                value = 42
            }

            $outputPath = Join-Path $TestDrive 'test-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $outputPath

            # Dot-source without assignment - should create $Config variable in current scope
            . $outputPath

            # $Config variable should be available
            $Config | Should -Not -BeNullOrEmpty
            $Config.name.Type | Should -Be 'string'
            $Config.value.Type | Should -Be 'int'
        }

        It 'Should handle complex nested structures in saved file' {
            $sample = @{
                metadata = @{
                    labels = @{
                        app = "web"
                    }
                }
                items = @(
                    @{ name = "item1"; value = 100 }
                )
            }

            $outputPath = Join-Path $TestDrive 'test-config.ps1'
            New-ConfigurationFromSample -SampleObject $sample -OutputPath $outputPath

            # Dot-source and verify structure
            $loadedConfig = . $outputPath
            $loadedConfig.metadata.labels.app.Type | Should -Be 'string'
            $loadedConfig.items.ItemStructure.name.Type | Should -Be 'string'
            $loadedConfig.items.ItemStructure.value.Type | Should -Be 'int'
        }
    }
}
