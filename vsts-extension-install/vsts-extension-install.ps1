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
    [string] $InstallWith = $false,

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
Import-Module -DisableNameChecking "$PSScriptRoot/vsts-extension-Installd.psm1"

$global:globalOptions = Convert-GlobalOptions $PSBoundParameters
$global:InstallOptions = Convert-InstallOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect -TfxUpdate:$globalOptions.TfxUpdate

$command = "Install"
$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

switch ($InstallOptions.InstallUsing)
{
    "VSIX"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--vsix-path",
            $InstallOptions.VsixPath
        )
    }

    "ID"
    {
        $tfxArgs = @(
            "extension",
            $command,
            "--extension-id"
            $InstallOptions.ExtensionId,        
            "--publisher",
            $InstallOptions.PublisherId
        )
    }
}

if ($InstallOptions.BypassValidation)
{
    $tfxArgs += "--bypass-validation"
}

if ($InstallOptions.InstallWith.Length -gt 0)
{
    $tfxArgs += "--Install-with"

    Write-Debug "--Install-with"
    foreach ($account in $InstallOptions.InstallWith)
    {
        Write-Debug "$account"
        $tfxArgs += $account
    }
}
else
{
    throw "Please specify the accounts to Install with"
}
    
$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

Write-Host "##vso[task.complete result=Succeeded;]DONE"