[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)]
    [string] $PublisherID,
    
    [Parameter(Mandatory=$false)]
    [string] $ExtensionID,

    [Parameter(Mandatory=$false)]
    [string] $ExtensionTag,
    
    [Parameter(Mandatory=$false)]
    [string] $VsixPath,

    [Parameter(Mandatory=$true)]
    [ValidateSet("VSIX", "ID")]
    [string] $ShareUsing,

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

    [Parameter(Mandatory=$true)]
    [string] $ShareWith,

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
$global:shareOptions = Convert-ShareOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect -TfxUpdate:$globalOptions.TfxUpdate

$command = "share"
$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

switch ($shareOptions.ShareUsing)
{
    "VSIX"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--vsix",
            $shareOptions.VsixPath
        )
    }

    "ID"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--extension-id"
            $shareOptions.ExtensionId,        
            "--publisher",
            $shareOptions.PublisherId
        )
    }
}

if ($shareOptions.BypassValidation)
{
    $tfxArgs += "--bypass-validation"
}

if ($shareOptions.ShareWith.Length -gt 0)
{
    $tfxArgs += "--share-with"

    Write-Debug "--share-with"
    foreach ($account in $shareOptions.ShareWith)
    {
        Write-Debug "$account"
        $tfxArgs += $account
    }
}
else
{
    throw "Please specify the accounts to share with"
}
    
$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

if ("$output" -ne "")
{
    Write-Host "##vso[task.complete result=Succeeded;]"
    Write-Output "Done."
}