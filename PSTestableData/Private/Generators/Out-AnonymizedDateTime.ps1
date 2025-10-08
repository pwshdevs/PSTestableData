function Out-AnonymizedDateTime {
    <#
    .SYNOPSIS
        Anonymizes a DateTime object by applying a random but consistent offset.

    .DESCRIPTION
        This function takes a DateTime object and applies a deterministic random offset
        to its components (days, hours, minutes, seconds), making the original date/time
        unrecognizable while ensuring identical inputs produce identical outputs.
        This is useful for anonymizing date/time data in testable datasets.

    .PARAMETER InputDateTime
        The DateTime object to sanitize.

    .EXAMPLE
        Out-AnonymizedDateTime -InputDateTime (Get-Date "2023-10-01 12:00:00")
        # Returns a randomized DateTime, consistent for the same input

    .OUTPUTS
        [DateTime]
    #>
    [CmdletBinding()]
    [OutputType([DateTime])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DateTime]$InputDateTime
    )

    process {
        # Use the Ticks of the input DateTime as seed for deterministic randomization
        $seed = $InputDateTime.Ticks % [int]::MaxValue
        $random = [System.Random]::new($seed)

        # Apply random offsets to various components
        $daysOffset = $random.Next(-365, 366)      # -1 year to +1 year
        $hoursOffset = $random.Next(-12, 13)       # -12 to +12 hours
        $minutesOffset = $random.Next(-30, 31)     # -30 to +30 minutes
        $secondsOffset = $random.Next(-30, 31)     # -30 to +30 seconds

        # Apply the offsets to the input DateTime
        $sanitizedDateTime = $InputDateTime.AddDays($daysOffset).AddHours($hoursOffset).AddMinutes($minutesOffset).AddSeconds($secondsOffset)

        return $sanitizedDateTime
    }
}
