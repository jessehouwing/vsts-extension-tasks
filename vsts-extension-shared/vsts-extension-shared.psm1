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
        TfxInstallUpdate = ($parameters["TfxUpdate"] -eq $true)
        TfxInstallPath = [string]$parameters["TfxInstallPath"]
        ServiceEndpoint = [string]$parameters["ServiceEndpoint"]
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
        OverrideType =  $parameters["OverrideType"]
        PublishEnabled = ($parameters["EnablePublishing"] -eq $true)
        ShareEnabled = ($parameters["EnableSharing"] -eq $true)
        ShareWith = @( $parameters["ShareWith"] -split ';|\r?\n' )
    }

    if ($packageOptions.OverrideType = "Json")
    {
        $packageOptions.OverrideJson = ($parameters["OverrideJson"] | Convertfrom-Json)
    }
    elseif ($packageOptions.OverrideType = "File")
    {
        $packageOptions.OverrideJson = (Get-Content $parameters["OverrideJsonFile"] -raw | Convertfrom-Json)
    }
    else
    {
        $packageOptions.OverrideJson = ("{}" | ConvertFrom-Json)
    }

    if ($packageOptions.ExtensionTag -ne "")
    {
        $packageOptions.ExtensionId = "$($packageOptions.ExtensionId)-$($packageOptions.ExtensionTag)"
        Add-Member -InputObject $OverrideJson -NotePropertyName "id" -NotePropertyValue $packageOptions.ExtensionId -Force
    }

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

        "PubicPreview"
        {
            $OverridePublic = $true
            $OverrideFlags = @( "Preview", "Public" )
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

    Write-Debug "ShareOptions:"
    Write-Debug ($shareOptions | Out-String)

    $global:shareOptions = $shareOptions

    return $global:shareOptions
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
        $global:tfx = $tfx.Path
    }
    else
    { 
        Write-Debug "Locating tfx in standard locations"
        $options = @()
        if ($TfxLocation -ne "")
        {
            $options += $TfxLocation
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
    
    $workingFolder = $global:packageOptions.OutputPath
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
            }
            "Token"
            {
                $Arguments += "pat"
                $Arguments += "--token"
                $Arguments += $ServiceEndpoint.Authorization.Parameters.apitoken
            }
        }
    }

    $tfxArgs = ($Arguments | %{ Escape-Args $_ } ) -join " "

    Write-Debug "Calling: $($global:tfx)"
    Write-Debug "Arguments: $tfxArgs"
    Write-Debug "Working Directory: $workingFolder"

    if ($preview.IsPresent)
    {
        Write-Warning "Skipped call due to Preview: True"
        Write-Warning "$($global:tfx) $tfxArgs"
        $Output = "{}"
    }
    else
    {
        # Pass -1 as success so we can handle output ourselves.
        $output = Invoke-Tool -Path $global:tfx -Arguments $tfxArgs -ErrorPattern "^Error:" -SuccessfulExitCodes @(0,-1) -WorkingFolder $workingFolder
    }

    $messages = $output -Split "`r?`n" | Skip-While { $_.StartsWith("$global:tfx") } | Take-While { $_ -match "^[^{]" }
    $json = $output -Split "`r?`n" | Skip-While { $_ -match "^[^{]" } | ConvertFrom-Json

    if ($messages -ne $null)
    {
        if ($json -ne $null)
        {
            $messages | %{ Write-Warning $_ }
        }
        else
        {
            $messages | %{ Write-Error $_ }
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

function Take-While() {
    param ( [scriptblock]$pred = $(throw "Need a predicate") )
    begin {
        $continue = $true
    }
    process {
        if ( $continue )
        {
            $continue = & $pred $_
        }

        if ( $continue ) {
            $_
        }
    }
    end {}
}


function Skip-While() {
    param ( [scriptblock]$pred = $(throw "Need a predicate") )
    begin {
        $skip = $true
    }
    process {
        if ( $skip ) {
            $skip = & $pred $_
        }

        if ( -not $skip ) {
            $_
        }
    }
    end {}
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
            $output = $taskjson | ConvertTo-JSON -Depth 255
            
            Write-Output "Setting version for: $file"

            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False) 
            [System.IO.File]::WriteAllText($file, $output, $Utf8NoBomEncoding)
        }
    }
    end{
    }
}


Export-ModuleMember -Function *