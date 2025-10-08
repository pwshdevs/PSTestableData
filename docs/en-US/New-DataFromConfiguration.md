---
external help file: PSTestableData-help.xml
Module Name: PSTestableData
online version:
schema: 2.0.0
---

# New-DataFromConfiguration

## SYNOPSIS
Generates new data based on a configuration file and optional seed data.

## SYNTAX

### FromPath (Default)
```
New-DataFromConfiguration -ConfigPath <String> -SeedData <Object> [-Count <Int32>] [-AsJson] [-AsYaml]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### FromHashtable
```
New-DataFromConfiguration -Config <Hashtable> -SeedData <Object> [-Count <Int32>] [-AsJson] [-AsYaml]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function uses a configuration file (created by New-ConfigurationFromSample) to generate
test data.
The configuration controls how each field is handled (Preserve, Anonymize, or
Randomize), field types, and array sizes.
Optionally, seed data can be provided to sample
values from when preserving or anonymizing fields.

## EXAMPLES

### EXAMPLE 1
```
# Generate multiple items with seed data from pipeline
$actualData | New-DataFromConfiguration -ConfigPath '.\config.ps1' -Count 5
```

Pipes actual data as seed and generates 5 new items using it as source for preserved/anonymized values.

### EXAMPLE 2
```
# Generate and output as JSON
$seed | New-DataFromConfiguration -ConfigPath '.\config.ps1' -AsJson
```

Pipes seed data and returns generated data as a JSON string.

### EXAMPLE 3
```
# Use configuration hashtable directly
$config = New-ConfigurationFromSample -SampleObject $sample
$data = New-DataFromConfiguration -Config $config -SeedData $sample
```

Generates data using a configuration hashtable without saving to file.

## PARAMETERS

### -ConfigPath
Path to the configuration file (.ps1) created by New-ConfigurationFromSample.
The file will be dot-sourced to load the configuration.

```yaml
Type: String
Parameter Sets: FromPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Config
Configuration hashtable directly (alternative to ConfigPath).
Use this when you want to pass the configuration object directly without saving to a file.

```yaml
Type: Hashtable
Parameter Sets: FromHashtable
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SeedData
Seed data to use as a source for preserved or anonymized values.
This parameter accepts pipeline input, allowing you to pipe actual data directly.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Count
The number of data items to generate.
Default is 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsJson
Return the generated data as JSON string.

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

### -AsYaml
Return the generated data as YAML string (requires powershell-yaml module).

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

### [object] - New data following the configuration pattern
### [string] - JSON or YAML string if AsJson or AsYaml is specified
## NOTES

## RELATED LINKS
