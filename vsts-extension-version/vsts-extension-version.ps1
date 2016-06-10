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
    [string] $Preview = $false,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Major", "Minor", "Patch", "None")]
    [string] $UpdateVersion = "None",

    [Parameter(Mandatory=$false)]
    [string] $OutputVariable = "",

    [Parameter(Mandatory=$false)]
    [string] $TfxArguments
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

$MarketEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $globalOptions.ServiceEndpoint
if ($MarketEndpoint -eq $null)
{
    throw "Could not locate service endpoint $globalOptions.ServiceEndpoint"
}

$command = "show"

$tfxArgs = @(
    "extension",
    $command,
    "--extension-id"
    $versionOptions.ExtensionId,        
    "--publisher",
    $versionOptions.PublisherId
)

$output = Invoke-Tfx -Arguments $tfxArgs -ServiceEndpoint $MarketEndpoint -Preview:$PreviewMode

if ($versionOptions.OutputVariable -ne "")
{
    $version = ($output.versions | Select-Object -First 1)
    
    Write-Output "Current version '$($version.version)'"

    if ($version -ne $null)
    {
        $parsedVersion =  [System.Version]::Parse($version.version)
        switch ($versionOptions.UpdateVersion)
        {
            "None"{}
            "Major"
            {
                $parsedVersion = New-Object System.Version -ArgumentList ($parsedVersion.Major + 1), 0, 0
            }

            "Minor"
            {
                $parsedVersion = New-Object System.Version -ArgumentList $parsedVersion.Major, ($parsedVersion.Minor + 1), 0
            }

            "Patch"
            {
                $parsedVersion = New-Object System.Version -ArgumentList $parsedVersion.Major, $parsedVersion.Minor, ($parsedVersion.Build + 1)
            }

        }

        $newVersion = $parsedVersion.ToString(3)

        Write-Output "Setting output variable '$($versionOptions.OutputVariable)' to '$($newVersion)'"
        Write-Host "##vso[task.setvariable variable=$($versionOptions.OutputVariable);]$($newVersion)"
    }
    else
    {
        throw "Error reading version from Marketplace"
    }
}

if ("$output" -ne "")
{
    Write-Host "##vso[task.complete result=Succeeded;]"
    Write-Output "Done."
}
else
{
    Write-Host "##vso[task.complete result=Failed;]"
    throw ("Failed.")
}