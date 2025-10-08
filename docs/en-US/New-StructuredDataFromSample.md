---
external help file: PSTestableData-help.xml
Module Name: PSTestableData
online version:
schema: 2.0.0
---

# New-StructuredDataFromSample

## SYNOPSIS
Analyzes structured data and generates new data following the same patterns and structure.

## SYNTAX

```
New-StructuredDataFromSample [-InputObject] <Object> [[-Count] <Int32>] [[-MaxArrayItems] <Int32>] [-Anonymize]
 [[-PreserveFields] <String[]>] [-UseKubernetesPresets] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function takes structured data (hashtables, arrays, PSCustomObjects) and analyzes their patterns
to generate new data that follows the same structure.
It can create realistic test data by examining
existing data patterns including field types, array sizes, nested structures, and value formats.

## EXAMPLES

### EXAMPLE 1
```
$sample = @{
    name = "John Doe"
    age = 30
    items = @("item1", "item2")
}
New-StructuredDataFromSample -InputObject $sample
```

Generates a new hashtable with the same structure but different values.

### EXAMPLE 2
```
$yamlData = ConvertFrom-Yaml $yamlString
New-StructuredDataFromSample -InputObject $yamlData -Count 3
```

Generates 3 new data structures based on the YAML input pattern.

## PARAMETERS

### -InputObject
The structured data to analyze and use as a template for generating new data.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Count
The number of new data items to generate.
Default is 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxArrayItems
The maximum number of items to generate for arrays.
Default is 5.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymize
Whether to anonymize the generated data values while preserving structure.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreserveFields
Array of field name patterns that should not be anonymized.
Supports wildcards.
Examples: 'apiVersion', 'kind', '*.phase', 'metadata.labels.*'

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseKubernetesPresets
When enabled, automatically preserves common Kubernetes system fields like apiVersion, kind, phase, etc.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [object] - New structured data following the input pattern
## NOTES

## RELATED LINKS
