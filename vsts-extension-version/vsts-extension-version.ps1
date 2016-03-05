[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)]
    [string] $PublisherID,
    
    [Parameter(Mandatory=$false)]
    [string] $ExtensionID,

    [Parameter(Mandatory=$false)]
    [string] $ExtensionTag,

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
    [string] $Preview = $false
)

$PreviewMode = ($Preview -eq $true)

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | %{ Write-Verbose "$_ = $($PSBoundParameters[$_])" }

Write-Verbose "Importing modules"
Import-Module -DisableNameChecking "$PSScriptRoot/vsts-extension-shared.psm1"

$global:globalOptions = Convert-GlobalOptions $PSBoundParameters
$global:versionOptions = Convert-VersionOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect -TfxUpdate:$globalOptions.TfxUpdate

$command = "view"
$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

$tfxArgs = @(
    "extension",
    $command,
    "--extension-id"
    $versionOptions.ExtensionId,        
    "--publisher",
    $versionOptions.PublisherId

$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

if ($versionOptions.OutputVariable -ne "")
{
    $version = ($json.versions | Select-Object -Last 1)

    Write-Debug "Setting output variable '$($versionOptions.OutputVariable)' to '$($version.version)'"
    Write-Host "##vso[task.setvariable variable=$($packageOptions.OutputVariable);]$($version.version)"
}

Write-Host "##vso[task.complete result=Succeeded;]DONE"