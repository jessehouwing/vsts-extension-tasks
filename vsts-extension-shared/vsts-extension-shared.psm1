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


Export-ModuleMember -Function *