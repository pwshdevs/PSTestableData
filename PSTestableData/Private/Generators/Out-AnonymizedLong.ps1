function Out-AnonymizedLong {
    <#
    .SYNOPSIS
        Anonymizes a long integer value by applying a random but consistent offset.

    .DESCRIPTION
        This function takes a long integer value and applies a deterministic random offset,
        making the original number unrecognizable while ensuring identical inputs produce
        identical outputs. This is useful for anonymizing long integer data in testable datasets.

    .PARAMETER InputNumber
        The long integer value to anonymize.

    .EXAMPLE
        Out-AnonymizedLong -InputNumber 123456789
        # Returns a randomized long, consistent for the same input

    .OUTPUTS
        [long]
    #>
    [CmdletBinding()]
    [OutputType([long])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [long]$InputNumber
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

        # Apply sign and cast to long
        $result = $sign * $randInt
        return [long]$result
    }
}