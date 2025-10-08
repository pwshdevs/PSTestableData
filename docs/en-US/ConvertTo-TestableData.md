---
external help file: PSTestableData-help.xml
Module Name: PSTestableData
online version:
schema: 2.0.0
---

# ConvertTo-TestableData

## SYNOPSIS
Converts JSON or YAML data to PowerShell objects and writes them to a .ps1 file for dot-sourcing.

## SYNTAX

### PSCustomObjectTestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-AsPSCustomObject]
 [-Force] [-Append] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### HashtableTestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-AsHashtable]
 [-Force] [-Append] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AnonymizedPSCustomObjectTestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-Anonymize]
 [-AsPSCustomObject] [-Force] [-Append] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AnonymizedHashtableTestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-Anonymize]
 [-AsHashtable] [-Force] [-Append] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AnonymizedTestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-Anonymize] [-Force]
 [-Append] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### TestableData
```
ConvertTo-TestableData -InputObject <String> -Name <String> -Path <String> -From <String> [-Force] [-Append]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function takes JSON or YAML input as a string, converts it to PowerShell objects
(hashtables/PSCustomObjects), and writes the converted data to a PowerShell script file
that can be dot-sourced.
The output file will contain two variables based on the Name parameter.

## EXAMPLES

### EXAMPLE 1
```
$jsonData = '{"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}]}'
ConvertTo-TestableData -InputObject $jsonData -Name "TestUsers" -Path "C:\temp\TestUsers.ps1" -From json
```

This example converts a JSON string containing an array of user objects into a PowerShell script file.
The output file will contain variables $TestUsers (the original JSON string) and $TestUsersObject
(the converted PowerShell object), which can be dot-sourced for testing purposes.

### EXAMPLE 2
```
$yamlData = @"
database:
  host: localhost
  port: 5432
  name: testdb
"@
ConvertTo-TestableData -InputObject $yamlData -Name "DatabaseConfig" -Path "C:\temp\DatabaseConfig.ps1" -From yaml
```

This example converts a YAML string defining database configuration into a PowerShell script file.
The resulting file will have $DatabaseConfig (original YAML) and $DatabaseConfigObject
(converted PowerShell hashtable), allowing for easy testing of database-related code.

## PARAMETERS

### -InputObject
The raw JSON or YAML data as a string to be converted.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
The base name used to define the variable in the output file.
Creates variable: $Name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
The file path where the .ps1 file will be written.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From
Specifies the input format of the data.
Valid values are 'json' or 'yaml'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymize
When specified, anonymizes sensitive data in the output by replacing strings, numbers, and dates with randomized but consistent values.

```yaml
Type: SwitchParameter
Parameter Sets: AnonymizedPSCustomObjectTestableData, AnonymizedHashtableTestableData, AnonymizedTestableData
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsHashtable
Converts the input data to hashtable format in the output.

```yaml
Type: SwitchParameter
Parameter Sets: HashtableTestableData, AnonymizedHashtableTestableData
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsPSCustomObject
Converts the input data to PSCustomObject format in the output.

```yaml
Type: SwitchParameter
Parameter Sets: PSCustomObjectTestableData, AnonymizedPSCustomObjectTestableData
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrites the output file if it already exists.

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

### -Append
Appends the output to the existing file instead of overwriting it.

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

## NOTES

## RELATED LINKS
