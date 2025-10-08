function Out-AnonymizedNumber {
    <#
    .SYNOPSIS
        Anonymizes a numeric value by applying a random but consistent offset.

    .DESCRIPTION
        This function takes a numeric value (int, long, double, or decimal) and applies
        a deterministic random offset based on the input's type, making the original
        number unrecognizable while ensuring identical inputs produce identical outputs.
        This is useful for anonymizing numeric data in testable datasets.

    .PARAMETER InputNumber
        The numeric value to anonymize. Supports int, long, double, and decimal types.

    .EXAMPLE
        Out-AnonymizedNumber -InputNumber 123
        # Returns a randomized int, consistent for the same input

    .EXAMPLE
        Out-AnonymizedNumber -InputNumber 123.45
        # Returns a randomized double, consistent for the same input

    .OUTPUTS
        [int], [long], [double], or [decimal] (same as input type)
    #>
    [CmdletBinding()]
    [OutputType([int], [long], [double], [decimal])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({
            $type = $_.GetType()
            $type -eq [int] -or $type -eq [long] -or $type -eq [double] -or $type -eq [decimal]
        })]
        $InputNumber
    )

    process {
        $type = $InputNumber.GetType()
        switch ($type) {
            ([int]) {
                return Out-AnonymizedInt -InputNumber $InputNumber
            }
            ([long]) {
                return Out-AnonymizedLong -InputNumber $InputNumber
            }
            ([double]) {
                return Out-AnonymizedDouble -InputNumber $InputNumber
            }
            ([decimal]) {
                return Out-AnonymizedDecimal -InputNumber $InputNumber
            }
            default {
                throw "Unsupported numeric type: $type"
            }
        }
    }
}
