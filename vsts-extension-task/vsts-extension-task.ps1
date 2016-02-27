[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $PublisherID,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ExtensionID,

    [Parameter(Mandatory=$false)]
    [string] $ExtensionTag,

    [Parameter(Mandatory=$false)]
    [string] $ExtensionVersion,

    [Parameter(Mandatory=$false)]
    [ValidateSet("NoOverride", "Private", "PrivatePreview", "PublicPreview", "Public")]
    [string] $ExtensionVisibility = "NoOverride",

    [Parameter(Mandatory=$false)]
    [string] $ServiceEndpoint,

    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $TfxInstall = $false,

    [Parameter(Mandatory=$false)]
    [string] $TfxLocation = $false,

    [Parameter(Mandatory=$true)]
    [string] $EnablePackaging = $false,

    [Parameter(Mandatory=$false)]
    [string] $ManifestGlobs = "extension-manifest.json",

    [Parameter(Mandatory=$false)]
    [string] $ExtensionRoot,

    [Parameter(Mandatory=$false)]
    [string] $PackagingOutputPath,

    [Parameter(Mandatory=$false)]
    [string] $OverrideFile = "",

    [Parameter(Mandatory=$false)]
    [string] $OverrideJson = "",

    [Parameter(Mandatory=$false)]
    [string] $OverrideInternalversions = $true,
    
    [Parameter(Mandatory=$false)]
    [string] $BypassValidation = $false,

    [Parameter(Mandatory=$false)]
    [string] $EnablePublishing = $false,

    [Parameter(Mandatory=$false)]
    [string] $VsixPath,
    

    [Parameter(Mandatory=$false)]
    [string] $EnableSharing = $false,

    [Parameter(Mandatory=$false)]
    [string] $ShareWith = $false
)

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | %{ Write-Verbose "$_ = $($PSBoundParameters[$_])" }

Write-Verbose "Importing modules"
Import-Module -DisableNameChecking "$PSScriptRoot/vsts-extension-shared.psm1"

$globalOptions = Convert-GlobalOptions $PSBoundParameters
$packageOptions = Convert-PackageOptions $PSBoundParameters
$publishOptions = Convert-PublishOptions $PSBoundParameters
$shareOptions = Convert-ShareOptions $PSBoundParameters

$tfx = Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect:$false

if ($packageOptions.Enabled)
{

    
    Invoke-Tool -Path $tfx.Path -Arguments $npmArgs -WorkingFolder $cwd -WarningPattern "^npm WARN"
}

if ($publishOptions.Enabled)
{

    if ($shareOptions.Enabled)
    {

    }
}
