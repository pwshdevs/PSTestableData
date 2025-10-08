function Out-AnonymizedInt {
    <#
    .SYNOPSIS
        Anonymizes an integer value by applying a random but consistent offset.

    .DESCRIPTION
        This function takes an integer value and applies a deterministic random offset,
        making the original number unrecognizable while ensuring identical inputs produce
        identical outputs. This is useful for anonymizing integer data in testable datasets.

    .PARAMETER InputNumber
        The integer value to anonymize.

    .EXAMPLE
        Out-AnonymizedInt -InputNumber 123
        # Returns a randomized int, consistent for the same input

    .OUTPUTS
        [int]
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int]$InputNumber
    )

    process {
        # Use the string representation's hash code as seed for deterministic randomization
        $seed = $InputNumber.ToString().GetHashCode()
        $random = [System.Random]::new($seed)

        $sign = [math]::Sign($InputNumber)
        $absValue = [math]::Abs($InputNumber)

        # Get the number of digits in the integer part
        $str = $absValue.ToString()
        $intPart = $str.Split('.')[0]
        $digits = $intPart.Length

        # Calculate min and max based on digits
        $min = [math]::Pow(10, $digits - 1)
        $max = [math]::Pow(10, $digits) - 1

        # Generate random integer in range
        $randInt = $random.Next([int]$min, [int]$max + 1)

        # Apply sign and cast to int
        $result = $sign * $randInt
        return [int]$result
    }
}
