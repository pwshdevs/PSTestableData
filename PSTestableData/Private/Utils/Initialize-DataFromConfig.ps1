function Initialize-DataFromConfig {
    <#
    .SYNOPSIS
        Orchestrates the three-pass generation process for creating test data.

    .DESCRIPTION
        This function coordinates the three-pass approach to generating test data:
        - Pass 1: Create empty structure with all fields set to null
        - Pass 2: Populate all non-linked fields
        - Pass 3: Populate all linked fields after Pass 2 is complete

        This ensures that linked fields can always resolve their dependencies.

    .PARAMETER Config
        The configuration hashtable defining the data structure.

    .PARAMETER SeedObject
        Optional seed data to use for Preserve or Anonymize actions.

    .EXAMPLE
        Initialize-DataFromConfig -Config $config -SeedObject $seed

        Generates test data using the three-pass approach.

    .OUTPUTS
        A hashtable with the fully populated test data.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [object]$SeedObject = $null
    )

    # Pass 1: Create empty structure
    Write-Verbose "Initialize-DataFromConfig: Starting Pass 1 (Empty Structure)"
    $result = New-EmptyStructure -Config $Config

    # Pass 2: Populate non-linked fields
    Write-Verbose "Initialize-DataFromConfig: Starting Pass 2 (Non-Linked Fields)"
    Set-NonLinkedFields -Config $Config -Result $result -SeedObject $SeedObject

    # Pass 3: Populate linked fields
    Write-Verbose "Initialize-DataFromConfig: Starting Pass 3 (Linked Fields)"
    Set-LinkedFields -Config $Config -Result $result -ResultContext $result

    return $result
}
