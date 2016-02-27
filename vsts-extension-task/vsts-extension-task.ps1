[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Itemspec = "$/",
    [Parameter(Mandatory=$true)]
    [ValidateSet("None", "Full", "OneLevel")]
    [string] $Recursion = "None",
    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false")]
    [string] $DeleteAdds = $false
)

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | %{ Write-Verbose "$_ = $($PSBoundParameters[$_])" }

Write-Verbose "Importing modules"
Import-Module -DisableNameChecking "$PSScriptRoot/vsts-extension-shared.psm1"