# New-StructuredDataFromSample Technical Specification

## Overview

The `New-StructuredDataFromSample` function is a sophisticated PowerShell data generation engine that analyzes structured input data and produces realistic synthetic data following the same patterns, structure, and value formats. This function enables generation of test data, mock objects, and anonymized datasets while preserving the integrity and characteristics of the original data structure.

## Architecture

### Core Components

1. **Pattern Analysis Engine**: Recursively analyzes input data to identify structural patterns, value types, and format conventions
2. **Value Pattern Recognition**: Identifies specific data patterns (GUIDs, ISO8601 dates, kebab-case strings, dotted notation, etc.)
3. **Custom Random Generation**: Uses .NET System.Random for consistent, high-quality randomization
4. **Array Preservation System**: Sophisticated handling to maintain PowerShell array integrity across all contexts
5. **Field Preservation Framework**: Supports selective anonymization with pattern-based field preservation
6. **Depth-Limited Recursion**: Prevents infinite loops when processing complex nested structures

## Technical Implementation

### Random Number Generation

**Problem Solved**: PowerShell's native `Get-Random` was consistently returning minimum values, causing poor data variety.

**Solution**: Custom .NET System.Random implementation:
```powershell
$script:customRandom = [System.Random]::new()
```

**Benefits**:
- True randomization across all value ranges
- Consistent behavior across PowerShell sessions
- Better performance for bulk operations
- Reliable array size generation

### Array Handling System

**Challenge**: PowerShell's complex array unwrapping behavior in different contexts:
- Pipeline operations unwrap arrays to individual elements
- Property assignment can lose array type information
- ArrayList conversion requires careful type preservation
- Single-element arrays are particularly prone to unwrapping

**Solution**: Multi-layered array preservation approach:

1. **ArrayList Building**: Use `[System.Collections.ArrayList]` for dynamic array construction
2. **Type-Safe Conversion**: Convert to `[object[]]` to force array type preservation
3. **Context-Aware Wrapping**: Apply `@()` operator in property assignment contexts
4. **Direct Type Handling**: Return arrays without pipeline operations to prevent unwrapping

```powershell
# Array generation with preservation
$newArray = [System.Collections.ArrayList]::new()
# ... populate array ...
return [object[]]$newArray.ToArray()  # Forces array type
```

### Pattern Recognition Engine

The function identifies and replicates specific data patterns:

#### String Patterns
- **GUID**: `^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`
- **ISO8601 DateTime**: `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}`
- **Numeric String**: `^\d+$`
- **Kebab-case**: `^[a-zA-Z]+(-[a-zA-Z]+)+$`
- **Dotted Notation**: `^[a-zA-Z]+\.[a-zA-Z]+` (enhanced for Kubernetes-style patterns)

#### Value Generation Strategies
- **GUIDs**: Generate new GUIDs using `[guid]::NewGuid()`
- **Dates**: Random dates within ±365 days of current date
- **Kebab-case**: Combine words from predefined dictionaries
- **Dotted notation**: Mix-and-match from prefix/suffix arrays (8 prefixes × 8 suffixes = 64 combinations)
- **Numeric strings**: Generate within appropriate ranges based on input analysis

### Depth-Limited Recursion

**Protection Mechanism**: Prevents infinite recursion with nested or self-referential data structures:

```powershell
function Get-StructurePattern {
    param(
        [object]$Object,
        [int]$Depth = 0,
        [int]$MaxDepth = 10  # Configurable depth limit
    )

    if ($Depth -gt $MaxDepth) {
        return @{ Type = 'string'; Pattern = 'text'; Length = 10 }
    }
    # ... continue processing
}
```

**Benefits**:
- Handles circular references gracefully
- Prevents stack overflow errors
- Maintains performance with deeply nested structures
- Provides fallback values at maximum depth

### Field Preservation System

**Purpose**: Allow selective anonymization while preserving critical fields (API versions, system identifiers, etc.)

**Features**:
- Wildcard pattern matching support
- Kubernetes preset patterns
- Hierarchical field path resolution
- Context-aware preservation decisions

**Kubernetes Preset Patterns**:
```powershell
$kubernetesPreservePatterns = @(
    'apiVersion', 'kind', 'type',
    '*.phase', '*.state', '*.status',
    'metadata.labels.*', 'metadata.annotations.*',
    'spec.type', 'spec.protocol'
)
```

### Type System Handling

The function handles PowerShell's complex type system:

#### Primitive Types
- **String**: Pattern analysis and generation
- **Int32/Int64**: Range-based generation with bounds detection
- **Double**: Decimal generation with realistic ranges
- **Boolean**: Random true/false generation
- **Null**: Preserved as-is

#### Complex Types
- **Hashtable**: Key-value pair preservation with recursive value generation
- **PSCustomObject**: Property-based analysis with Add-Member for construction
- **Arrays**: Multi-type array support with size randomization
- **Nested Structures**: Recursive processing with depth limiting

### Performance Optimizations

#### Array Analysis Limiting
```powershell
# Limit analysis to first 3 items to prevent excessive processing
$maxItems = [math]::Min($items.Count, 3)
```

**Rationale**: Large arrays with identical item patterns don't require full analysis. Sampling the first few items provides sufficient pattern information while dramatically improving performance.

#### Efficient Object Construction
- Use ArrayList for dynamic array building (better performance than += operator)
- Pre-allocate hash tables where possible
- Minimize object copying and reconstruction

## Data Generation Strategies

### Structure Preservation
The function maintains exact structural fidelity:
- **Object hierarchy**: Nested objects retain their depth and relationships
- **Array positioning**: Arrays appear in the same structural locations
- **Type consistency**: Generated values match original types
- **Cardinality respect**: Array sizes vary within specified bounds

### Value Variety Generation
Multiple strategies ensure realistic data diversity:

1. **Pattern-Based Generation**: Uses identified patterns to create similar but distinct values
2. **Range-Based Randomization**: Numeric values generated within detected ranges
3. **Dictionary-Based Selection**: Text values selected from contextually appropriate word lists
4. **Temporal Variation**: Dates generated across reasonable time ranges
5. **Format Preservation**: Complex string formats (GUIDs, etc.) maintain their structure

### Anonymization Features
When anonymization is enabled:
- Values are scrambled while preserving format
- Preserved fields remain unchanged based on patterns
- Structure and types are maintained
- Cross-references and relationships can be preserved

## API Reference

### Parameters

#### InputObject [Required]
- **Type**: `[object]`
- **Pipeline**: Accepts pipeline input
- **Description**: The structured data to analyze and use as template

#### Count [Optional]
- **Type**: `[int]`
- **Default**: `1`
- **Description**: Number of new data items to generate

#### MaxArrayItems [Optional]
- **Type**: `[int]`
- **Default**: `5`
- **Description**: Maximum number of items to generate for arrays

#### Anonymize [Optional]
- **Type**: `[switch]`
- **Description**: Enable value anonymization while preserving structure

#### PreserveFields [Optional]
- **Type**: `[string[]]`
- **Description**: Field name patterns that should not be anonymized (supports wildcards)

#### UseKubernetesPresets [Optional]
- **Type**: `[switch]`
- **Description**: Automatically preserve common Kubernetes system fields

### Return Value
- **Single Item**: When `Count = 1`, returns the generated object directly
- **Multiple Items**: When `Count > 1`, returns array of generated objects
- **Type Preservation**: Return type matches input object type (hashtable, PSCustomObject, etc.)

## Usage Examples

### Basic Usage
```powershell
$sample = @{
    name = "John Doe"
    age = 30
    active = $true
    items = @("item1", "item2", "item3")
}

$generated = New-StructuredDataFromSample -InputObject $sample
# Result: Similar structure with different values
```

### Kubernetes Data Generation
```powershell
$podSpec = @{
    apiVersion = "v1"
    kind = "Pod"
    metadata = @{
        name = "example-pod"
        namespace = "default"
        labels = @{
            app = "web-server"
            version = "1.0.0"
        }
    }
    spec = @{
        containers = @(
            @{
                name = "web-container"
                image = "nginx:1.20"
                ports = @(
                    @{ containerPort = 80; protocol = "TCP" }
                )
            }
        )
    }
}

$testPods = New-StructuredDataFromSample -InputObject $podSpec -Count 5 -UseKubernetesPresets
# Generates 5 realistic pod specifications with preserved Kubernetes system fields
```

### Anonymized Data Generation
```powershell
$sensitiveData = @{
    userId = "user123"
    email = "user@company.com"
    apiVersion = "v2"
    settings = @{
        theme = "dark"
        notifications = $true
    }
}

$anonymized = New-StructuredDataFromSample -InputObject $sensitiveData -Anonymize -PreserveFields @('apiVersion')
# Result: userId and email are anonymized, apiVersion preserved, structure maintained
```

## Error Handling and Edge Cases

### Null Handling
- **Input**: Null values are preserved in output
- **Nested**: Null properties maintain their null state
- **Arrays**: Arrays containing nulls preserve null positions

### Empty Collections
- **Empty Arrays**: Return properly typed empty arrays `@()`
- **Empty Objects**: Generate empty hashtables or PSCustomObjects as appropriate
- **Empty Strings**: Handled as zero-length text patterns

### Type Coercion Edge Cases
- **Mixed Arrays**: Arrays with different types maintain type diversity
- **Nested Complexity**: Deep nesting handled with depth limiting
- **Circular References**: Prevented through recursion depth limits

### PowerShell Quirks Handled
- **Array Unwrapping**: Multiple strategies prevent array unwrapping in various contexts
- **Pipeline Behavior**: Direct returns avoid pipeline unwrapping issues
- **Type System**: Proper handling of PowerShell's dynamic typing
- **Property Access**: Safe handling of hashtable vs. PSCustomObject property access patterns

## Performance Characteristics

### Time Complexity
- **Structure Analysis**: O(n) where n = total number of properties/elements
- **Pattern Recognition**: O(1) per value (regex matching)
- **Data Generation**: O(m×n) where m = Count parameter, n = structure complexity

### Space Complexity
- **Memory Usage**: Linear with respect to output size
- **Recursion Stack**: Limited by MaxDepth parameter (default 10 levels)
- **Temporary Objects**: Minimal through efficient ArrayList usage

### Scalability Considerations
- **Large Arrays**: Analysis limited to first 3 items for performance
- **Deep Nesting**: Depth limiting prevents exponential complexity
- **Bulk Generation**: Efficient when generating multiple items from same pattern

## Testing and Validation

The function includes comprehensive test coverage:
- **27 Test Cases**: Cover all major functionality areas
- **Array Handling**: Extensive tests for array preservation across contexts
- **Pattern Recognition**: Validation of all supported pattern types
- **Edge Cases**: Null handling, empty collections, deep nesting
- **Performance**: Tests for large datasets and complex structures
- **PowerShell Behavior**: Tests for pipeline unwrapping and type preservation

### Critical Test Areas
1. **Array Type Preservation**: Ensures arrays remain arrays in all contexts
2. **Pattern Recognition**: Validates all supported string and value patterns
3. **Recursion Safety**: Tests depth limiting with nested structures
4. **Randomization Quality**: Verifies proper variety in generated values
5. **Structure Fidelity**: Confirms exact structural preservation
6. **Anonymization**: Tests selective field preservation during anonymization

## Dependencies

### PowerShell Requirements
- **PowerShell 5.1+**: Core functionality
- **PowerShell 7.x**: Enhanced performance and reliability

### .NET Dependencies
- **System.Random**: Custom random number generation
- **System.Collections.ArrayList**: Efficient dynamic array building
- **System.Guid**: GUID generation
- **System.DateTime**: Date manipulation

### Optional Dependencies
- **Out-AnonymizedString**: Enhanced anonymization (if available)
- **Out-AnonymizedNumber**: Numeric anonymization (if available)
- **Out-AnonymizedDateTime**: Date anonymization (if available)

## Future Enhancement Opportunities

### Pattern Recognition Extensions
- **Email Patterns**: Detect and generate realistic email formats
- **URL Patterns**: Handle HTTP/HTTPS URL generation
- **Phone Numbers**: Support various international phone formats
- **Custom Patterns**: User-defined regex pattern support

### Performance Improvements
- **Parallel Processing**: Multi-threaded generation for large datasets
- **Caching**: Pattern analysis result caching for repeated operations
- **Memory Optimization**: Stream-based processing for very large structures

### Advanced Features
- **Referential Integrity**: Maintain relationships between generated objects
- **Constraint Validation**: Ensure generated values meet business rules
- **Export Integration**: Direct integration with export formats (JSON, YAML, CSV)
- **Schema Validation**: JSON Schema or other schema format support

---

*This specification documents the current implementation of New-StructuredDataFromSample as of October 2025. The function represents a mature, battle-tested solution for structured data generation with comprehensive PowerShell compatibility and robust error handling.*
