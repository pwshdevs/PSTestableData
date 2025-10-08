function Out-AnonymizedDouble {
    <#
    .SYNOPSIS
        Anonymizes a double value by applying a random but consistent offset.

    .DESCRIPTION
        This function takes a double value and applies a deterministic random offset,
        making the original number unrecognizable while ensuring identical inputs produce
        identical outputs. This is useful for anonymizing double data in testable datasets.

    .PARAMETER InputNumber
        The double value to anonymize.

    .EXAMPLE
        Out-AnonymizedDouble -InputNumber 123.45
        # Returns a randomized double, consistent for the same input

    .OUTPUTS
        [double]
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$InputNumber
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

        # Get the number of decimal places
        $decimalPlaces = 0
        if ($str.Contains('.')) {
            $decimalPlaces = $str.Split('.')[1].Length
        }

        # Calculate min and max based on digits
        $min = [math]::Pow(10, $digits - 1)
        $max = [math]::Pow(10, $digits) - 1

        # Generate random integer in range
        $randInt = $random.Next([int]$min, [int]$max + 1)

        # Apply decimal places
        if ($decimalPlaces -eq 0) {
            $magnitude = $randInt
        } else {
            $magnitude = $randInt / [math]::Pow(10, $decimalPlaces)
        }

        # Apply sign and cast to double
        $result = $sign * $magnitude
        return [double]$result
    }
}