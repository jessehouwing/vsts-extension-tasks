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
    [string] $InstallUsing,

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
    [string] $InstallTo,

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
$global:installOptions = Convert-InstallOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect -TfxUpdate:$globalOptions.TfxUpdate

$command = "install"
$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

switch ($installOptions.InstallUsing)
{
    "VSIX"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--vsix-path",
            $installOptions.VsixPath,
            "--extension-id"
            $installOptions.ExtensionId,     
            "--publisher",
            $installOptions.PublisherId
        )
    }

    "ID"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--extension-id"
            $installOptions.ExtensionId,        
            "--publisher",
            $installOptions.PublisherId
        )
    }
}

if ($installOptions.BypassValidation)
{
    $tfxArgs += "--bypass-validation"
}

if ($installOptions.InstallTo.Length -gt 0)
{
    $tfxArgs += "--accounts"

    Write-Debug "--accounts"
    foreach ($account in $installOptions.InstallTo)
    {
        Write-Debug "$account"
        $tfxArgs += $account
    }
}
else
{
    throw "Please specify the accounts to Install to."
}
    
$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

Write-Host "##vso[task.complete result=Succeeded;]DONE"