[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $VsixPath,

    # Global Options
    [Parameter(Mandatory=$true)]
    [string] $ServiceEndpoint,

    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $TfxInstall = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $TfxUpdate = $false,

    [Parameter(Mandatory=$false)]
    [string] $TfxLocation = $false,

    #Preview mode for remote call
    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $Preview = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $BypassValidation = $false
)

$PreviewMode = ($Preview -eq $true)

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | %{ Write-Verbose "$_ = $($PSBoundParameters[$_])" }

Write-Verbose "Importing modules"
Import-Module -DisableNameChecking "$PSScriptRoot/vsts-extension-shared.psm1"

$global:globalOptions = Convert-GlobalOptions $PSBoundParameters
$global:publishOptions = Convert-PublishOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect -TfxUpdate:$globalOptions.TfxUpdate

$command = "publish"
$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

$tfxArgs = @(
    "extension",
    $command,
    "--vsix",
    $publishOptions.VsixPath
)

if ($publishOptions.BypassValidation)
{
    $tfxArgs += "--bypass-validation"
}
    
$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

Write-Host "##vso[task.complete result=Succeeded;]"
Write-Output "Done."