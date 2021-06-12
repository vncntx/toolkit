# Copyright 2021 Vincent Fiestada

. (Join-Path 'tools' 'std' 'std.ps1')
. (Join-Path 'tools' 'go' 'mod.ps1')

<#
.SYNOPSIS
Install dependencies

.DESCRIPTION
Ensure all dependencies and tools are installed

.EXAMPLE
Install-Project
#>
function Install-GoProject {
    Write-Info 'checking environment'
    Confirm-Ready

    Write-Info 'checking dependencies'
    Install-Dependencies

    Write-Info 'checking for available git hooks'
    Install-Hooks
    
    Write-Divider
    Write-Ok 'project installed'
}

<#
.SYNOPSIS
Verify the build environment

.DESCRIPTION
Verify the build environment is set up correctly

.EXAMPLE
Confirm-Ready
#>
function Confirm-Ready {
    # required checks (errors)

    # go must be installed
    if (-not (Get-Command -Name go -ErrorAction SilentlyContinue)) {
        Write-Error 'go is required'
        exit [Error]::NoGo
    }
    # golangci-lint must be installed
    if (-not (Get-Command -Name "golangci-lint" -ErrorAction SilentlyContinue)) {
        Write-Error "golangci-lint is not installed"
        exit [Error]::NoGoLinter
    } else {
        Write-Ok "golangci-lint is installed"
    }
    # go modules must be enabled
    if ($env:GO111MODULE -ne 'on') {
        Write-Error 'go modules should be enabled'
        exit [Error]::InvalidGoEnv
    } else {
        Write-Ok 'go modules are enabled'
    }

    # optional checks (warnings)

    # target go version should be installed
    $target = (Get-GoModule).Target
    if (-not (go version | Select-String -SimpleMatch "go$target")) {
        Write-Warning "go v$target should be installed"
    } else {
        Write-Ok "go v$target is installed"
    }
}

<#
.SYNOPSIS
Install and verify dependencies

.DESCRIPTION
Install and verify the project dependencies

.EXAMPLE
Confirm-Environment
#>
function Install-Dependencies {
    if ((go mod verify) -and (Assert-ExitCode 0)) {
        Write-Ok 'module dependencies verified'
    }
    else {
        Write-Fail 'cannot verify dependencies'
        exit [Error]::InvalidGoMod
    }
}

<#
.SYNOPSIS
Install git hooks

.DESCRIPTION
Copy this project's git hooks into the .git directory

.EXAMPLE
Install-Hooks
#>
function Install-Hooks {
    if (-Not (
        (Test-Path '.git' -ErrorAction SilentlyContinue) -And
        (Test-Path 'hooks' -ErrorAction SilentlyContinue)
    )) {
        return
    }

    New-Item -Type Directory -Force (Join-Path ".git" "hooks") > $null
    foreach ($file in (Get-ChildItem (Join-Path "hooks" "*.*"))) {
        $name = $file.BaseName
        $dest = (Join-Path ".git" "hooks" $name)
        Write-Info "installing $name hook"

        Copy-Item $file $dest
        if (Get-Command chmod -ErrorAction SilentlyContinue) {
            chmod +x $dest
        }
    }
    Write-Ok "git hooks installed"
}

enum Error {
    NoGo = 1
    NoGoLinter = 2
    InvalidGoMod = 3
    InvalidGoEnv = 4
}