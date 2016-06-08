import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Convert-GlobalOptions 
{
    param
    (
        $parameters
    )

    $globalOptions = @{
        TfxInstall = ($parameters["TfxInstall"] -eq $true)
        TfxUpdate = ($parameters["TfxUpdate"] -eq $true)
        TfxLocation = [string]$parameters["TfxLocation"]
        ServiceEndpoint = [string]$parameters["ServiceEndpoint"]
        TfxArguments = [string]$parameters["TfxArguments"]
    }

    Write-Debug "GlobalOptions:"
    Write-Debug ($globalOptions | Out-String)

    $global:globalOptions = $globalOptions

    return $global:globalOptions
}

function Convert-PackageOptions 
{
    param
    (
        $parameters
    )

    $packageOptions = @{
        ExtensionRoot = [string]$parameters["ExtensionRoot"]
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        OutputPath = [string]$parameters["PackagingOutputPath"]
        BypassValidation = ($parameters["BypassValidation"] -eq $true)
        OverrideExtensionVersion = ($parameters["OverrideExtensionVersion"] -eq $true)
        OverrideInternalVersions = ($parameters["OverrideInternalVersions"] -eq $true)
        ExtensionVersion = [string]$parameters["ExtensionVersion"]
        ExtensionVisibility = [string]$parameters["ExtensionVisibility"]
        ManifestGlobs = [string]$parameters["ManifestGlobs"]
        OverrideType = [string]$parameters["OverrideType"]
        PublishEnabled = ($parameters["EnablePublishing"] -eq $true)
        ShareEnabled = ($parameters["EnableSharing"] -eq $true)
        ShareWith = @( $parameters["ShareWith"] -split ';|\r?\n' )
        LocalizationRoot = [string]$parameters["LocalizationRoot"]
        OutputVariable = [string]$parameters["OutputVariable"]
    }

    [PSCustomObject] $OverrideJson = ( "{}" | Convertfrom-Json)

    if ($packageOptions.OverrideType -eq "Json")
    {
        Write-Debug "Initializing Override from specified Json"
        $OverrideJson = ($parameters["OverrideJson"] | Convertfrom-Json)
    }
    elseif ($packageOptions.OverrideType -eq "File")
    {
        Write-Debug "Initializing Override from specified file"
        $OverrideJson = (Get-Content $parameters["OverrideJsonFile"] -raw | Convertfrom-Json)
    }

    if ($packageOptions.ExtensionTag -ne "")
    {
        $packageOptions.ExtensionId = "$($packageOptions.ExtensionId)-$($packageOptions.ExtensionTag)"
    }
    
    Add-Member -InputObject $OverrideJson -NotePropertyName "id" -NotePropertyValue $packageOptions.ExtensionId -Force
    Add-Member -InputObject $OverrideJson -NotePropertyName "publisher" -NotePropertyValue $packageOptions.PublisherId -Force

    if ($packageOptions.OverrideExtensionVersion)
    {
        $version = [System.Version]::Parse($packageOptions.ExtensionVersion)
        Write-Debug "Setting 'Version'"
        Add-Member -InputObject $OverrideJson -NotePropertyName "version" -NotePropertyValue $Version.ToString(3) -Force
    }
    
    $OverridePublic = $null
    $OverrideFlags  = $null

    switch ($packageOptions.ExtensionVisibility)
    {
        "Private"
        {
            $OverridePublic = $false
            $OverrideFlags  = @()
        }

        "PrivatePreview"
        {
            $OverridePublic = $false
            $OverrideFlags = @( "Preview" )
        }

        "PublicPreview"
        {
            $OverridePublic = $true
            $OverrideFlags = @( "Public", "Preview" )
        }

        "Public"
        {
            $OverridePublic = $true
            $OverrideFlags = @( "Public" )
        }
    }
    
    if ($OverridePublic -ne $null)
    {
        Write-Debug "Setting 'Public'"
        Add-Member -InputObject $OverrideJson -NotePropertyName "public" -NotePropertyValue $OverridePublic -Force
    }
    if ($OverrideFlags -ne $null)
    {
        Write-Debug "Setting 'GalleryFlags'"
        Add-Member -InputObject $OverrideJson -NotePropertyName "galleryFlags" -NotePropertyValue $OverrideFlags -Force
    }
    $packageOptions.OverrideJson = $OverrideJson

    Write-Debug "PackageOptions:"
    Write-Debug ($packageOptions | Out-String)

    $global:packageOptions = $packageOptions

    return $global:packageOptions
}

function Convert-ShareOptions 
{
    param
    (
        $parameters
    )

    $shareOptions = @{
        ShareUsing = [string]$parameters["ShareUsing"]
        VsixPath = [string]$parameters["VsixPath"]
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        BypassValidation = ($parameters["BypassValidation"] -eq $true)
        ShareWith = @( $parameters["ShareWith"] -split ';|\r?\n' )
    }

    if ($shareOptions.ExtensionTag -ne "")
    {
        $shareOptions.ExtensionId = "$($shareOptions.ExtensionId)-$($shareOptions.ExtensionTag)"
    }

    if ($shareOptions.VsixPath -match "[?*]")
    {
        $shareOptions.VsixPath = [string](Find-Files $shareOptions.VsixPath)
    }

    Write-Debug "ShareOptions:"
    Write-Debug ($shareOptions | Out-String)

    $global:shareOptions = $shareOptions

    return $global:shareOptions
}

function Convert-InstallOptions 
{
    param
    (
        $parameters
    )

    $installOptions = @{
        InstallUsing = [string]$parameters["InstallUsing"]
        VsixPath = [string]$parameters["VsixPath"]
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        BypassValidation = ($parameters["BypassValidation"] -eq $true)
        InstallTo = @( $parameters["InstallTo"] -split ';|\r?\n' )
    }

    if ($installOptions.ExtensionTag -ne "")
    {
        $installOptions.ExtensionId = "$($installOptions.ExtensionId)-$($installOptions.ExtensionTag)"
    }

    if ($installOptions.VsixPath -match "[?*]")
    {
        $installOptions.VsixPath = [string](Find-Files $installOptions.VsixPath)
    }

    Write-Debug "ShareOptions:"
    Write-Debug ($installOptions | Out-String)

    $global:installOptions = $installOptions

    return $global:installOptions
}

function Convert-VersionOptions 
{
    param
    (
        $parameters
    )

    $versionOptions = @{
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        OutputVariable = [string]$parameters["OutputVariable"]
        UpdateVersion = [string]$parameters["UpdateVersion"]
    }

    if ($versionOptions.ExtensionTag -ne "")
    {
        $versionOptions.ExtensionId = "$($versionOptions.ExtensionId)-$($versionOptions.ExtensionTag)"
    }

    Write-Debug "VersionOptions:"
    Write-Debug ($versionOptions | Out-String)

    $global:versionOptions = $versionOptions

    return $global:versionOptions
}

function Convert-PublishOptions 
{
    param
    (
        $parameters
    )

    $publishOptions = @{
        VsixPath = [string]$parameters["VsixPath"]
        BypassValidation = ($parameters["BypassValidation"] -eq $true)
    }

    if ($shareOptions.VsixPath -match "[?*]")
    {
        $shareOptions.VsixPath = [string](Find-Files $shareOptions.VsixPath)
    }

    Write-Debug "PublishOptions:"
    Write-Debug ($publishOptions | Out-String)

    $global:publishOptions = $publishOptions

    return $global:publishOptions
}

$global:tfx = $null

function Find-Tfx
{
    param
    (
        [switch] $DetectTfx = $false,
        [switch] $TfxInstall = $false,
        [string] $TfxLocation = "",
        [switch] $TfxUpdate = $false
    )

    Write-Debug "DetectTfx: $DetectTfx"
    Write-Debug "TfxInstall: $TfxInstall"
    Write-Debug "TfxLocation: $TfxLocation"
    Write-Debug "TfxUpdate: $TfxUpdate"

    if ($DetectTfx.IsPresent)
    {
        Write-Debug "Trying to detect tfx"
        $tfxCommand = Get-Command "tfx" -ErrorAction SilentlyContinue
    }

    if ($tfxCommand -ne $null)
    {
        Write-Debug "Found: $tfx.Source"
        $global:tfx = $tfxCommand.Source
    }
    else
    { 
        Write-Debug "Locating tfx in standard locations"
        $options = @()
        if ($TfxLocation -ne "")
        {
            $options += $TfxLocation
            $options += "$TfxLocation\node_modules\.bin"
        }
        
        $options += "$PSScriptRoot\Tools\node_modules\.bin"
        $options += "$($env:appdata)\npm"

        $npm = Get-Command -Name npm -ErrorAction Ignore
        if(!$npm)
        {
            throw ("Unable to locate npm")
        }
        else
        {
            $options += (Get-Item $npm.Path).Directory.FullName
        }
      
        foreach ($path in $options)
        {
            $path = Join-Path $path "tfx.cmd"
            Write-Debug "Trying: $path"
            if (Test-Path -PathType Leaf $path)
            {
                Write-Debug "Found: $path"
                $global:tfx = $path
                break
            }
        }

        if ($TfxInstall.IsPresent -and ($global:tfx -eq $null))
        {
            if ($TfxLocation -eq "")
            {
                $TfxLocation = "$PSScriptRoot\Tools"
            }
            # Trim trailing slashes as NPM doesn't seem to like 'm
            $TfxLocation = $TfxLocation.TrimEnd(@("/", "\"))

            Write-Debug "Trying to install tfx to: $TfxLocation"

            if (-not (Test-Path -PathType Container $TfxLocation))
            {
                New-Item -ItemType Directory -Path $TfxLocation
            }
            
            $npmargs = "install ""tfx-cli"" --prefix ""$TfxLocation"""
            Write-Verbose "Calling: $($npm.Path) $npmargs"
            Invoke-Tool -Path $npm.Path -Arguments $npmArgs -WorkingFolder $cwd -WarningPattern "^npm WARN"
            
            Find-Tfx -TfxInstall:$false -TfxLocation $TfxLocation -DetectTfx:$false -TfxUpdate:$false
        }
        
        if ($global:tfx -eq $null)
        {
            throw ("Unable to locate tfx")
        }
    }

    if ($tfxInstall -and $tfxUpdate)
    {
        if ($TfxLocation -eq "")
        {
            $TfxLocation = "$PSScriptRoot\Tools"
        }
        # Trim trailing slashes as NPM doesn't seem to like 'm
        $TfxLocation = $TfxLocation.TrimEnd(@("/", "\"))

        Write-Debug "Trying to update tfx in: $TfxLocation"

        if(!$npm)
        {
            throw ("Unable to locate npm")
        }

        $npmargs = "update ""tfx-cli"" --prefix ""$TfxLocation"""
        Write-Verbose "Calling: $($npm.Path) $npmargs"
        Invoke-Tool -Path $npm.Path -Arguments $npmArgs -WorkingFolder $cwd -WarningPattern "^npm WARN"
    }

}

function Invoke-Tfx
{
    param
    (
        [array] $Arguments = @(),
        $ServiceEndpoint,
        [switch] $Preview = $false
    )
    
    $workingFolder = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    if (-not (Test-Path -PathType Container $workingFolder))
    {
        New-Item -Path $workingfolder -ItemType Directory -force
    }

    if ($Arguments -notcontains "--no-prompt")
    {
        Write-Debug "Adding --no-prompt"
        $Arguments += "--no-prompt"
    }
    if ($Arguments -notcontains "--json")
    {
        Write-Debug "Adding --json"
        $Arguments += "--json"
    }

    if ($ServiceEndpoint -ne $null)
    {
        Write-Debug "Adding --auth-type"
        $Arguments += "--auth-type"

        switch ($ServiceEndpoint.Authorization.Scheme)
        {
            "Basic"
            {
                $Arguments += "basic"
                $Arguments += "--username"
                $Arguments += $ServiceEndpoint.Authorization.Parameters.Username
                $Arguments += "--password"
                $Arguments += $ServiceEndpoint.Authorization.Parameters.Password
                $Arguments += "--service-url"
                $Arguments += $ServiceEndpoint.Authorization.Parameters.serverUri
            }
            "Token"
            {
                $Arguments += "pat"
                $Arguments += "--token"
                $Arguments += $ServiceEndpoint.Authorization.Parameters.apitoken
            }
        }
    }

    if ($Arguments -notcontains "--service-url")
    {
        Write-Debug "Adding --service-url"
        $Arguments += "--service-url"
        $Arguments += "https://marketplace.visualstudio.com/"
    }
     

    $tfxArgs = ($Arguments | %{ Escape-Args $_ } ) -join " "

    if ($global:globalOptions.TfxArguments)
    {
        $tfxArgs += " $($global:globalOptions.TfxArguments)"
    }

    Write-Debug "Calling: $($global:tfx)"
    Write-Debug "Arguments: $tfxArgs"
    Write-Debug "Working Directory: $workingFolder"

    if ($preview.IsPresent)
    {
        Write-Warning "Skipped call due to Preview: True. Review the call below and disable Advanced\Preview on your task definition to publish/share/install."
        Write-Warning "$($global:tfx) $tfxArgs"
        [string[]] $Output = @("{}")
    }
    else
    {
        # Pass -1 as success so we can handle output ourselves.
        $output = Invoke-Tool -Path $global:tfx -Arguments $tfxArgs -SuccessfulExitCodes @(0,-1,255) -WorkingFolder $workingFolder
        
    }

    return Handle-TfxOutput $output
}

function Handle-TfxOutput{
    param(
        [string[]]$output
    )

    $output | %{ Write-Debug $_ }
    if ($output.Count -eq 1)
    {
        $output = $output -split "`r?`n"
    }

    $commandProcessed = $false
    $messagesProcessed = $false
    $jsonStarted = $false
    $messages = @()
    $json = ""
 
    foreach ($line in $output)
    {
        if (-not $commandProcessed -and $line.StartsWith("$global:tfx"))
        {
            $command = $line
            $commandProcessed = $true
        }
        elseif (-not $messagesProcessed -and -not ($line.StartsWith("{") -or $line.StartsWith("[")))
        {
            $messages += $line
        }
        elseif (-not $jsonStarted -and ($line.StartsWith("{") -or $line.StartsWith("[")))
        {
            $messagesProcessed = $true
            $jsonStarted = $true
            $json += $line
        }
        elseif ($jsonStarted -and -not ($line.StartsWith("}") -or $line.StartsWith("]")))
        {
            $json += $line
        }
        elseif ($jsonStarted -and ($line.StartsWith("}") -or $line.StartsWith("]")))
        {
            $json += $line
            $json = $json | ConvertFrom-Json
            break
        }
    }

    if ($messages -ne $null)
    {
        if ($json -ne $null)
        {
            $messages | %{ Write-Warning $_ }
        }
        else
        {
            $messages | %{ Write-Error $_ }
            Write-Host "##vso[task.complete result=Failed;]"
            throw ("Call to tfx failed.")
        }
    }

    return $json
}

function Escape-Args
{
    param()
    $output = $_.Trim()

    if ($output -match '(?s:)^"[^"]*"$')
    {
        $output = $output.Trim('"')
    }

    if ($output -match '"') 
    {
        $output = $output -replace '"', '""'
    }

    if ($output -match '[\s"]')
    {
        $output = '"'+$output+'"'
    }
    
    return $output
}

function Update-InternalVersion
{
    param
    (
        $extensionRoot = $global:packageOptions.ExtensionRoot,
        $version = $global:packageOptions.ExtensionVersion
    )

    begin{
        $version = [System.Version]::Parse($version)
        $files = Find-Files "$extensionRoot\**\task.json"
    }
    process{
        foreach ($file in $files)
        {
            $taskJson = ConvertFrom-Json (Get-Content $file -Raw)
            $taskJson.Version.Major = $version.Major
            $taskJson.Version.Minor = $version.Minor
            $taskJson.Version.Patch = $version.Build
            $output = $taskjson | ConvertTo-JSON -Depth 100
            
            Write-Output "Setting version for: $file"

            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False) 
            [System.IO.File]::WriteAllText($file, $output, $Utf8NoBomEncoding)
        }
    }
    end{
    }
}

Export-ModuleMember -Function *