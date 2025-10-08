function Out-AnonymizedString {
    <#
    .SYNOPSIS
        Anonymizes a string by replacing letters and digits with random equivalents.

    .DESCRIPTION
        This function takes an input string and replaces each letter with a randomly chosen
        letter of the same case (upper or lower), and each digit with a random digit.
        Non-alphanumeric characters are left unchanged. The randomization is deterministic
        based on the input string, so identical inputs produce identical outputs.
        This makes the original data unrecognizable while preserving the structure for testing purposes.

    .PARAMETER InputString
        The string to sanitize.

    .EXAMPLE
        Out-AnonymizedString -InputString "Test123"
        # Returns something like: "Doah456" (random but consistent for same input)

    .OUTPUTS
        [string]
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )

    process {
        # Use the hash code of the input as seed for deterministic randomization
        $seed = $InputString.GetHashCode()
        $random = [System.Random]::new($seed)

        $result = ''
        foreach ($char in $InputString.ToCharArray()) {
            if ($char -cmatch '[a-z]') {
                # Lowercase letter: replace with random lowercase
                $newChar = [char]($random.Next(97, 123))  # a-z
                $result += $newChar
            } elseif ($char -cmatch '[A-Z]') {
                # Uppercase letter: replace with random uppercase
                $newChar = [char]($random.Next(65, 91))   # A-Z
                $result += $newChar
            } elseif ($char -match '\d') {
                # Digit: replace with random digit
                $newChar = [char]($random.Next(48, 58))   # 0-9
                $result += $newChar
            } else {
                # Non-alphanumeric: keep as is
                $result += $char
            }
        }

        return $result
    }
}
