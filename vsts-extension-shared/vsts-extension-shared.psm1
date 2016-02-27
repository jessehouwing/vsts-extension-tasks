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
        $tfx = Get-Command "tfx" -ErrorAction SilentlyContinue
    }

    if ($tfx -eq $null)
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
                return $path
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

            #$npmargs = @(
            #    "install",
            #    "tfx-cli",
            #    "--prefix",
            #    "$TfxLocation"
            #)
            $npmargs = "install ""tfx-cli"" --prefix ""$TfxLocation"""
            Write-Verbose "Calling: $($npm.Path) $npmargs"
            Invoke-Tool -Path $npm.Path -Arguments $npmArgs -WorkingFolder $cwd -WarningPattern "^npm WARN"
            
            return Find-Tfx -TfxInstall:$false -TfxLocation $TfxLocation -DetectTfx:$false
        }
        throw ("Unable to locate tfx")
    }
    else
    {
        Write-Verbose $tfx.Path
        return $tfx.Path
    }
}

Export-ModuleMember -Function *