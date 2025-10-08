Function New-ValueFromPattern {
    <#
    .SYNOPSIS
    Generates new values based on pattern descriptions.

    .DESCRIPTION
    This function creates new values that match the characteristics described in a pattern
    hashtable. It supports various data types including null, strings with specific patterns
    (ISO8601 dates, GUIDs, numeric, kebab-case, dotted notation, text), numeric types
    with ranges, booleans, and provides fallback generation for unknown types.

    The function uses a provided random generator for consistent and reproducible results
    across test runs, and supports anonymization mode for generating test-appropriate values.

    .PARAMETER Pattern
    A hashtable describing the pattern to generate, typically created by Get-ValuePattern.
    Must contain 'Type' key and may include 'Pattern', 'Length', 'Range' depending on type.

    .PARAMETER RandomGenerator
    A System.Random instance for generating random values. Using the same seed ensures
    reproducible results. Default creates a new random generator.

    .PARAMETER Anonymize
    Indicates whether to generate anonymized values. Currently used for context but
    doesn't change generation behavior in this implementation.

    .OUTPUTS
    [object]
    Returns a newly generated value matching the pattern specification:
    - null for null patterns
    - ISO8601 datetime strings for datetime patterns
    - GUID strings for guid patterns
    - Various string formats based on pattern type
    - Numeric values within specified ranges
    - Boolean values
    - Fallback string for unknown patterns

    .EXAMPLE
    $pattern = @{Type = 'string'; Pattern = 'kebab-case'}
    New-ValueFromPattern -Pattern $pattern
    Returns: "test-data" (or similar kebab-case string)

    .EXAMPLE
    $pattern = @{Type = 'int'; Range = @(1, 100)}
    New-ValueFromPattern -Pattern $pattern
    Returns: Random integer between 1 and 99

    .EXAMPLE
    $pattern = @{Type = 'datetime'; Pattern = 'iso8601'}
    New-ValueFromPattern -Pattern $pattern
    Returns: "2023-08-15T14:30:22Z" (or similar ISO8601 string)

    .NOTES
    This is an internal utility function used by the PSTestableData module for generating
    individual values during test data creation. It provides consistent, reproducible
    value generation when used with seeded random generators.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    Param(
        [hashtable]$Pattern,
        [System.Random]$RandomGenerator = [System.Random]::new(),
        [bool]$Anonymize = $false
    )

    # If field should be preserved and we have the original value, return it
    if ($Pattern.PreserveField -and $Pattern.ContainsKey('OriginalValue')) {
        return $Pattern.OriginalValue
    }

    switch ($Pattern.Type) {
        'null' { return $null }
        'datetime' {
            if ($Pattern.Pattern -eq 'iso8601') {
                return (Get-Date).AddDays(($RandomGenerator.Next(-365, 366))).ToString('yyyy-MM-ddTHH:mm:ssZ')
            }
        }
        'guid' { return [guid]::NewGuid().ToString() }
        'string' {
            switch ($Pattern.Pattern) {
                'numeric' { return ($RandomGenerator.Next(1000000, 99999999)).ToString() }
                'kebab-case' {
                    $words = @('active', 'ready', 'pending', 'complete', 'failed', 'running', 'stopped')
                    $word1 = $words[($RandomGenerator.Next(0, $words.Count))]
                    $word2 = $words[($RandomGenerator.Next(0, $words.Count))]
                    return "$word1-$word2"
                }
                'dotted' {
                    $prefixes = @('kubernetes.io', 'app.kubernetes', 'service.mesh', 'metadata.k8s', 'config.example', 'system.core', 'runtime.api', 'network.fabric')
                    $suffixes = @('metadata.name', 'metadata.labels', 'config.data', 'service.port', 'resource.type', 'status.phase', 'spec.selector', 'policy.rules')
                    $prefix = $prefixes[($RandomGenerator.Next(0, $prefixes.Count))]
                    $suffix = $suffixes[($RandomGenerator.Next(0, $suffixes.Count))]
                    return "$prefix/$suffix"
                }
                'text' {
                    # Don't anonymize if this field should be preserved
                    if ($Anonymize -and -not $Pattern.PreserveField -and (Get-Command Out-AnonymizedString -ErrorAction SilentlyContinue)) {
                        $sampleString = ("sample" * [math]::Ceiling($Pattern.Length / 6)).Substring(0, $Pattern.Length)
                        return Out-AnonymizedString -InputString $sampleString
                    }
                    else {
                        $words = @('sample', 'test', 'demo', 'example', 'data', 'value', 'item', 'content')
                        $selectedWord = $words[($RandomGenerator.Next(0, $words.Count))]
                        return $selectedWord
                    }
                }
                default {
                    # Fallback for any unhandled string patterns
                    $words = @('sample', 'test', 'demo', 'example', 'data', 'value', 'item', 'content')
                    $selectedWord = $words[($RandomGenerator.Next(0, $words.Count))]
                    return $selectedWord
                }
            }
        }
        'int' {
            if ($Pattern.Range) {
                return $RandomGenerator.Next($Pattern.Range[0], $Pattern.Range[1])
            }
            else {
                return $RandomGenerator.Next(1, 1000)
            }
        }
        'long' {
            if ($Pattern.Range) {
                return [long]($RandomGenerator.Next($Pattern.Range[0], $Pattern.Range[1]))
            }
            else {
                return [long]($RandomGenerator.Next(1000, 999999))
            }
        }
        'double' { return [double]($RandomGenerator.NextDouble() * 99.9 + 0.1) }
        'bool' { return ($RandomGenerator.Next(0, 2)) -eq 1 }
        default { return "generated-value" }
    }
}
