# PSTestableData

[![GitHub Actions Status][github-actions-badge]][github-actions-build] [![GitHub Actions Status][github-actions-badge-publish]][github-actions-build] [![GitHub Open Issues Status][github-open-issues-badge]][github-open-issues] [![GitHub Closed Issues Status][github-closed-issues-badge]][github-closed-issues] [![License][license-badge]][license]

[![PowerShell Gallery][psgallery-badge]][psgallery] [![PSGallery Version][psgallery-version-badge]][psgallery] [![PSGallery Playform][psgallery-platform-badge]][psgallery] [![PSGallery Playform][ps-desktop-badge]][psgallery]

A PowerShell module designed to help convert structured data formats and generate realistic test data for Pester tests. PSTestableData provides utilities for working with JSON, YAML, and PowerShell objects, making it easy to create consistent and maintainable test data for your PowerShell projects.

## Installation

```powershell
Install-PSResource -Name PSTestableData -Scope CurrentUser
```

or

```powershell
Install-Module -Name PSTestableData -Scope CurrentUser
```

## Features

- **Convert** JSON/YAML data to PowerShell objects and export as dot-sourceable .ps1 files
- **Generate** realistic test data by analyzing existing data patterns and structures
- **Configure** data generation behavior with editable configuration templates
- **Preserve** specific fields during anonymization for testing scenarios
- **Support** for complex nested structures, arrays, and mixed data types
- **Anonymize** sensitive data while maintaining structural integrity
- **Fast** pattern recognition and data generation for large datasets

## Public Functions Overview

### `ConvertTo-TestableData`

Converts JSON or YAML data to PowerShell objects and writes them to a .ps1 file for dot-sourcing in tests.

**Key Parameters:**

- `InputObject` - Raw JSON or YAML data as string
- `Name` - Base name for variables in output file
- `Path` - Output file path for the .ps1 file
- `From` - Input format ('json' or 'yaml')
- `Anonymize` - Anonymize sensitive data
- `AsHashtable` / `AsPSCustomObject` - Output format control

### `New-ConfigurationFromSample`

Analyzes a sample object and creates a configuration template that controls how data generation should work for each field.

**Key Parameters:**

- `SampleObject` - The sample data to analyze
- `DefaultAction` - Default action for all fields ('Preserve', 'Anonymize', 'Randomize')
- `DefaultArrayCount` - Default number of items for arrays
- `AnonymizePatterns` - Field patterns that should be anonymized by default
- `OutputPath` - Save configuration to a .ps1 file for editing and reuse
- `PassThru` - Return configuration object when saving to file

### `New-DataFromConfiguration`

Generates new test data using a configuration template created by `New-ConfigurationFromSample`.

**Key Parameters:**

- `ConfigPath` - Path to configuration file (.ps1) created by New-ConfigurationFromSample
- `Config` - Configuration hashtable directly (alternative to ConfigPath)
- `SeedData` - Seed data for preserved/anonymized values (accepts pipeline input)
- `Count` - Number of data items to generate
- `AsJson` / `AsYaml` - Output format options

### `New-StructuredDataFromSample`

Analyzes structured data and generates new data following the same patterns and structure.

**Key Parameters:**

- `InputObject` - Sample data to analyze and replicate
- `Count` - Number of data items to generate
- `MaxArrayItems` - Maximum items in generated arrays
- `PreservePatterns` - Field patterns to preserve during generation
- `Anonymize` - Enable data anonymization

### `ConvertTo-Hashtable`

Converts PowerShell objects to hashtable format, useful for data transformation and serialization.

### `ConvertTo-PSCustomObject`

Converts hashtables and other objects to PSCustomObject format for consistent object handling.

## Examples

### Basic JSON to PowerShell Conversion

```powershell
# Convert JSON data to a PowerShell script file
$jsonData = @'
{
    "apiVersion": "v1",
    "kind": "ConfigMap",
    "metadata": {
        "name": "app-config",
        "namespace": "default"
    },
    "data": {
        "database.url": "postgresql://db:5432/app",
        "cache.ttl": "300"
    }
}
'@

ConvertTo-TestableData -InputObject $jsonData -Name "ConfigMap" -Path "./test-data.ps1" -From "json" -AsHashtable
```

This creates a `test-data.ps1` file that you can dot-source in your tests:

```powershell
# In your test file
. ./test-data.ps1
# Now $ConfigMap contains your converted data
```

### Generate Test Data from Sample

```powershell
# Create sample data structure
$sampleData = @{
    users = @(
        @{
            id = 1
            name = "John Doe"
            email = "john.doe@company.com"
            active = $true
            created = "2023-01-15T10:30:00Z"
        }
    )
    metadata = @{
        version = "1.0.0"
        environment = "production"
    }
}

# Generate 5 similar data structures
$testData = New-StructuredDataFromSample -InputObject $sampleData -Count 5 -MaxArrayItems 3

# Each item in $testData will have the same structure but different values
```

### Create and Use Configuration Templates

```powershell
# Step 1: Analyze sample data and create a configuration template
$sampleData = @{
    apiVersion = "v1"
    kind = "Namespace"
    metadata = @{
        name = "my-namespace"
        labels = @{
            "app.kubernetes.io/name" = "my-app"
        }
    }
    spec = @{
        finalizers = @("kubernetes")
    }
}

# Create configuration with custom defaults
$config = New-ConfigurationFromSample -SampleObject $sampleData -DefaultAction "Randomize" -DefaultArrayCount 4

# Save configuration to file for editing
$configPath = New-ConfigurationFromSample -SampleObject $sampleData -OutputPath ".\namespace-config.ps1" -PassThru

# Edit the config file to customize field behaviors
# For example, change metadata.name to Action = "Preserve" to keep namespace names
```

### Generate Data from Configuration

```powershell
# Step 2: Use the configuration to generate test data
$seedData = @{
    apiVersion = "v1"
    kind = "Namespace"
    metadata = @{
        name = "production-namespace"
        labels = @{
            "app.kubernetes.io/name" = "web-app"
        }
    }
    spec = @{
        finalizers = @("kubernetes")
    }
}

# Generate 3 test namespaces using the configuration and seed data
$testNamespaces = $seedData | New-DataFromConfiguration -ConfigPath ".\namespace-config.ps1" -Count 3

# Or use configuration hashtable directly
$testNamespaces = $seedData | New-DataFromConfiguration -Config $config -Count 3

# Each generated namespace will:
# - Preserve apiVersion and kind from seed
# - Randomize metadata.name (unless you edited config to preserve it)
# - Generate appropriate random values for other fields
# - Use ArrayCount=4 for any arrays in the structure
```

### Anonymize Data with Field Preservation

```powershell
$sensitiveData = @{
    apiVersion = "v1"  # Keep this unchanged
    kind = "Secret"    # Keep this unchanged
    metadata = @{
        name = "db-credentials"  # This will be anonymized
        namespace = "production" # This will be anonymized
    }
    data = @{
        username = "admin"     # This will be anonymized
        password = "secret123" # This will be anonymized
    }
}

# Preserve Kubernetes API fields but anonymize data
$preservePatterns = @("apiVersion", "kind", "metadata.namespace")
$anonymizedData = New-StructuredDataFromSample -InputObject $sensitiveData -Anonymize -PreservePatterns $preservePatterns
```

### YAML to PowerShell with Complex Structures

```powershell
$yamlData = @'
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-server
  template:
    spec:
      containers:
        - name: web
          image: nginx:1.20
          ports:
            - containerPort: 80
          env:
            - name: ENV
              value: "production"
        - name: sidecar
          image: logging:1.0
          ports:
            - containerPort: 8080
'@

ConvertTo-TestableData -InputObject $yamlData -Name "Deployment" -Path "./k8s-test-data.ps1" -From "yaml" -AsPSCustomObject
```

### Generate Multiple Test Scenarios

```powershell
# Generate test data for different scenarios
$baseConfig = @{
    server = @{
        host = "localhost"
        port = 8080
        ssl = $false
    }
    features = @("auth", "logging", "metrics")
    limits = @{
        maxConnections = 100
        timeout = 30
    }
}

# Generate 10 different configurations for testing
$testConfigs = 1..10 | ForEach-Object {
    New-StructuredDataFromSample -InputObject $baseConfig -MaxArrayItems 5
}

# Use in Pester tests
Describe "Server Configuration Tests" {
    It "Should handle configuration <_>" -ForEach (1..10) {
        $config = $testConfigs[$_ - 1]
        # Test your function with different configurations
        Test-ServerConfig -Config $config | Should -Not -Throw
    }
}
```

### Working with Complex Nested Structures

```powershell
$complexData = @{
    application = @{
        name = "MyApp"
        version = "2.1.0"
        components = @(
            @{
                type = "web"
                instances = 3
                config = @{
                    memory = "512Mi"
                    cpu = "200m"
                }
            },
            @{
                type = "database"
                instances = 1
                config = @{
                    memory = "1Gi"
                    cpu = "500m"
                    storage = "10Gi"
                }
            }
        )
        monitoring = @{
            enabled = $true
            endpoints = @("/health", "/metrics", "/ready")
        }
    }
}

# Generate test data maintaining the complex structure
$testApplications = New-StructuredDataFromSample -InputObject $complexData -Count 3 -MaxArrayItems 4
```

## Use Cases

### Pester Test Data Management

- Create consistent test data files that can be version controlled
- Generate multiple test scenarios from a single sample
- Maintain test data structure while anonymizing sensitive information
- Use configuration templates to control data generation behavior

### CI/CD Pipeline Testing

- Generate realistic test datasets for integration tests
- Create reproducible test scenarios across different environments
- Validate application behavior with varied but structured data
- Customize data generation rules for different testing environments

### Development and Debugging

- Create sample data that matches production structures
- Generate edge cases and boundary conditions for testing
- Prototype with realistic data before production deployment
- Edit configuration templates to fine-tune data generation rules

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Reporting bugs and requesting features
- Setting up the development environment
- Running tests and submitting pull requests

## Requirements

- PowerShell 5.1 or later
- PowerShell Core 6.0+ (cross-platform support)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

[github-actions-badge]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSTestableData/CI.yaml?label=build&style=for-the-badge
[github-actions-badge-publish]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSTestableData/publish.yaml?label=publish&style=for-the-badge
[github-actions-build]: https://github.com/pwshdevs/PSTestableData/actions
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/PSTestableData?label=downloads&style=for-the-badge
[psgallery]: https://www.powershellgallery.com/packages/PSTestableData
[psgallery-version-badge]: https://img.shields.io/powershellgallery/v/PSTestableData?label=version&style=for-the-badge
[license-badge]: https://img.shields.io/github/license/pwshdevs/PSTestableData?style=for-the-badge
[license]: https://raw.githubusercontent.com/pwshdevs/PSTestableData/main/LICENSE
[github-open-issues-badge]: https://img.shields.io/github/issues/pwshdevs/PSTestableData?style=for-the-badge
[github-closed-issues-badge]: https://img.shields.io/github/issues-closed/pwshdevs/PSTestableData?style=for-the-badge
[github-closed-issues]: https://github.com/pwshdevs/PSTestableData/issues?q=is%3Aissue%20state%3Aclosed
[github-open-issues]: https://github.com/pwshdevs/PSTestableData/issues
[psgallery-platform-badge]: https://img.shields.io/powershellgallery/p/PSTestableData?style=for-the-badge
[ps-desktop-badge]: https://img.shields.io/badge/edition-Desktop_|_Core-blue?style=for-the-badge
