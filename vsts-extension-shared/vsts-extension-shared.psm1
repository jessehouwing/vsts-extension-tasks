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
        TfxInstallPath = ($parameters["TfxInstallPath"])
    }

    if ($globalOptions.OverrideType = "Json")
    {
        $globalOptions.OverrideJson = ($parameters["OverrideJson"] | Convertfrom-Json)
    }
    elseif ($globalOptions.OverrideType = "File")
    {
        $globalOptions.OverrideJson = (Get-Content $parameters["OverrideJsonFile"] -raw | Convertfrom-Json)
    }
    else
    {
        $globalOptions.OverrideJson = ("{}" | convertFrom-Json)
    }

    Write-Debug "GlobalOptions:"
    Write-Debug ($globalOptions | Out-String)

    return $globalOptions
}


function Convert-PackageOptions 
{
    param
    (
        $parameters
    )

    $packageOptions = @{
        Enabled = ($parameters["EnablePackaging"] -eq $true)
        ExtensionRoot = [string]$parameters["ExtensionRoot"]
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        OutputPath = [string]$parameters["PackagingOutputPath"]
        BypassValidation = ($parameters["BypassValidation"] -eq $true)
        OverrideExtensionVersion = ($parameters["OverrideExtensionVersion"] -eq $true)
        OverrideInternalVersions = ($parameters["OverrideInternalVersions"] -eq $true)
        ExtensionVersion = $parameters["ExtensionVersion"]
        ExtensionVisibility = $parameters["ExtensionVisibility"]
    }

    if ($packageOptions.ExtensionTag -ne "")
    {
        $packageOptions.ExtensionId = "$($packageOptions.ExtensionId)-$($packageOptions.ExtensionTag)"
    }

    if ($packageOptions.$OverrideExtensionVersion)
    {
        $version = [System.Version]::Parse($packageOptions.ExtensionVersion)
        Add-Member -InputObject $global:globalOptions.OverrideJson.Version -NotePropertyName "Public" -NotePropertyValue $Version.ToString(3) -Force
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
        Add-Member -InputObject $global:globalOptions.OverrideJson -NotePropertyName "Public" -NotePropertyValue $OverridePublic -Force
    }
    if ($OverrideFlags -ne $null)
    {
        Add-Member -InputObject $global:globalOptions.OverrideJson -NotePropertyName "GalleryFlags" -NotePropertyValue $OverrideFlags -Force
    }

    Write-Debug "PackageOptions:"
    Write-Debug ($packageOptions | Out-String)

    return $packageOptions
}

function Convert-PublishOptions 
{
    param
    (
        $parameters
    )

    $publishOptions = @{
        Enabled = ($parameters["EnablePublishing"] -eq $true)
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        VsixPath = [string]$parameters["VsixPath"]
    }

    if ($publishOptions.ExtensionTag -ne "")
    {
        $publishOptions.ExtensionId = "$($publishOptions.ExtensionId)-$($publishOptions.ExtensionTag)"
    }

    Write-Debug "PublishOptions:"
    Write-Debug ($publishOptions | Out-String)

    return $publishOptions
}

function Convert-ShareOptions 
{
    param
    (
        $parameters
    )

    $shareOptions = @{
        Enabled = $parameters["EnableSharing"] -eq $true
        ExtensionId = [string]$parameters["ExtensionId"]
        ExtensionTag = [string]$parameters["Extensiontag"]
        PublisherId = [string]$parameters["PublisherId"]
        VsixPath = [string]$parameters["VsixPath"]
        ShareWith = @( $parameters["ShareWith"] -split ';|\r?\n' )
    }

    if ($shareOptions.ExtensionTag -ne "")
    {
        $shareOptions.ExtensionId = "$($shareOptions.ExtensionId)-$($shareOptions.ExtensionTag)"
    }

    Write-Debug "ShareOptions:"
    Write-Debug ($shareOptions | Out-String)
    
    return $shareOptions
}

$global::tfx = $null

function Find-Tfx
{
    param
    (
        [switch] $DetectTfx = $false,
        [switch] $TfxInstall = $false,
        [string] $TfxLocation = ""
    )

    Write-Debug "DetectTfx: $DetectTfx"
    Write-Debug "TfxInstall: $TfxInstall"
    Write-Debug "TfxLocation: $TfxLocation"

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
        if ($npm)
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
                $global:tfx = $tfx.Path
            }
        }

        if ($TfxInstall.IsPresent)
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

            if(!$npm)
            {
                throw ("Unable to locate npm")
            }

            $npmargs = "install ""tfx-cli"" --prefix ""$TfxLocation"""
            Write-Verbose "Calling: $($npm.Path) $npmargs"
            Invoke-Tool -Path $npm.Path -Arguments $npmArgs -WorkingFolder $cwd -WarningPattern "^npm WARN"
            
            return Find-Tfx -TfxInstall:$false -TfxLocation $TfxLocation -DetectTfx:$false
        }
        throw ("Unable to locate tfx")
    }
}

function Invoke-Tfx
{
    param
    (
        [array] $args = @(),
        [string] $workingFolder,
        [Microsoft.TeamFoundation.DistributedTask.Agent.Interfaces.ITaskEndpoint] $serviceEndpoint = $null
    )

    if ($args -notcontains "--no-prompt")
    {
        $args += "--no-prompt"
    }
    if ($args -notcontains "--json")
    {
        $args += "--json"
    }

    if ($serviceEndpoint -ne $null)
    {
        Write-Debug $endpoint.Authorization.Scheme
        Write-Debug ($endpoint | Out-String)
        
        $args += "--auth-type"

        switch ($endpoint.Authorization.Scheme)
        {
            "Basic"
            {
                $args += "basic"
                $args += "--username"
                $args += $endpoint.Authorization.Parameters.Username
                $args += "--password"
                $args += $endpoint.Authorization.Parameters.Password
            }
            "Token"
            {
                $args += "pat"
                $args += "--token"
                $args += $endpoint.Authorization.Parameters.AccessToken
            }
        }
    }

    $tfxArgs = ($args | %{ Escape-Args $_ } ) -join " "

    $output = Invoke-Tool -Path $global:tfx -Arguments $tfxArgs -WorkingFolder $workingFolder 

    $messages = $output -Split "`r?`n" | Take-While { $_ -match "^[^{]" }
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

    $output = $_

    if ($output -match '(?s:)^"[^"]*"$')
    {
        $output = $output.Trim('"')
    }

    if ($output -match '"') 
    {
        $output = $output -replace '"', '""'
    }

    if ($output -match "\s")
    {
        $output = "`"$output`""
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
        $extensionRoot,
        $version
    )

    begin{
        $version = [System.Version]::Parse($version.ExtensionVersion)
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
            
            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False) 
            [System.IO.File]::WriteAllText($file.FullName, $output, $Utf8NoBomEncoding)
        }
    }
    end{}
}


Export-ModuleMember -Function *