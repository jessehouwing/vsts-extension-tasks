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
    [ValidateSet("true", "false", "1", "0")]
    [string] $OverrideExtensionVersion,

    [Parameter(Mandatory=$false)]
    [string] $ExtensionVersion,

    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false", "1", "0")]
    [string] $OverrideInternalVersions = $true,

    [Parameter(Mandatory=$false)]
    [ValidateSet("NoOverride", "Private", "PrivatePreview", "PublicPreview", "Public")]
    [string] $ExtensionVisibility = "NoOverride",

    # Global Options
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
    [string] $ManifestGlobs = "vss-extension.json",

    [Parameter(Mandatory=$false)]
    [string] $ExtensionRoot,

    [Parameter(Mandatory=$false)]
    [string] $PackagingOutputPath,

    # Advanced Options
    [Parameter(Mandatory=$false)]
    [ValidateSet("None", "File", "Json")]
    [string] $OverrideType = "None",

    [Parameter(Mandatory=$false)]
    [string] $OverrideFile = "",

    [Parameter(Mandatory=$false)]
    [string] $OverrideJson = "{}",

    [Parameter(Mandatory=$false)]
    [string] $BypassValidation = $false,

    [Parameter(Mandatory=$false)]
    [string] $EnablePublishing = $false,

    [Parameter(Mandatory=$false)]
    [string] $VsixPath,
    

    # Sgaing options
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

$global:globalOptions = Convert-GlobalOptions $PSBoundParameters
$global:packageOptions = Convert-PackageOptions $PSBoundParameters
$global:publishOptions = Convert-PublishOptions $PSBoundParameters
$global:shareOptions = Convert-ShareOptions $PSBoundParameters

Find-Tfx -TfxInstall:$globalOptions.TfxInstall -TfxLocation $globalOptions.TfxLocation -Detect

if ($packageOptions.Enabled)
{
    $tfxArgs = @(
        "extension",
        "create",
        "--root",
        $packageOptions.ExtensionRoot,
        "--output-path",
        $packageOptions.OutputPath,
        "--extensionid",
        $packageOptions.ExtensionId,
        "--publisher",
        $packageOptions.PublisherId,
        "--override",
        ($globalOptions.OverrideJson | ConvertTo-Json -Depth 255 -Compress)
    )
    
    if ($packageOptions.BypassValidation)
    {
        $tfxArgs += "--bypass-validation"
    }

    if ($packageOptions.OverrideInternalVersions)
    {

    }

    $output = Invoke-Tfx -Arguments $tfxArgs -WorkingFolder $cwd 

    if ($output -ne $null)
    {
        $publishOptions.VsixPath = $output.Path
    }
}

if ($publishOptions.Enabled)
{
    $MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $ServiceEndpoint
    if (-not $serviceEndpoint)
    {
        throw "Could not locate service endpoint $ServiceEndpoint"
    }

    if ($publishOptions.VsixPath -contains "*","?")
    {
        $publishOptions.VsixPath = [string] (Find-Files $publishOptions.VsixPath)
    }

    $tfsArgs = @(
        "extension",
        "publish",
        "--vsix-path",
        $publishOptions.VsixPath,
        "--extensionid",
        $packageOptions.ExtensionId,
        "--publisher",
        $packageOptions.PublisherId,
        "--override",
        ($globalOptions.OverrideJson | ConvertTo-Json -Depth 255 -Compress)
    )

    if ($BypassValidation -eq $true)
    {
        $tfxArgs += "--bypass-validation"
    }

    Invoke-Tfx -Arguments $tfxArgs -WorkingFolder $cwd -ServiceEndpoint $MarketEndpoint
}

if ($shareOptions.Enabled)
{
    foreach ($account in $shareOptions.Accounts)
    {
        $tfxArgs = @(
            "extension",
            "publish",
            "--share-with",
            $account,
            "--extensionid",
            $packageOptions.ExtensionId,
            "--publisher",
            $packageOptions.PublisherId,
            "--override",
            ($globalOptions.OverrideJson | ConvertTo-Json -Depth 255 -Compress)
        )

        if ($publishOptions.VsixPath -ne "")
        {
            $tfxArgs += "--vsix-path"
            $tfxArgs += $publishOptions.VsixPath
        }

        if ($BypassValidation -eq $true)
        {
            $tfxArgs += "--bypass-validation"
        }

        Invoke-Tfx -Arguments $tfxArgs -WorkingFolder $cwd -ServiceEndpoint $MarketEndpoint
    }
}