# Script for updating burp suite
param (
    [switch]$debug
)
Import-Module $PSScriptRoot/Common.psm1 -Force

function Test-BurpInstanceRunning {
    $BurpInstances = Get-CimInstance Win32_Process | Select-Object ProcessId, Name, CommandLine | `
        Where-Object { $_.Name -eq "java.exe" -and $_.CommandLine -like "java*loader.jar*" }
    $BurpRunning = $false
    if ($BurpInstances) {
        $BurpRunning = $true
    }
    return $BurpRunning
}

function Remove-OldBurp {
    if ($ExistingBurp) {
        Remove-Item $ExistingBurp -Force
        Write-Host "Successfully removed old Burp Suite files."
    }
}

function Add-LatestBurp {
    try {
        Write-Host "Downloading the latest version of Burp Suite Professional..."
        $Url = "https://portswigger-cdn.net/burp/releases/download?product=desktop&type=Jar&version=$Version"
        Invoke-WebRequest -Uri $Url -OutFile "burpsuite_desktop_v$Version.jar" -ErrorAction Stop
        Write-Host "`nBurp Suite Professional download successful." -ForegroundColor Green    
    }
    catch {
        Write-Host "Error occurred in $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        if (Test-Path "burpsuite_desktop_v$Version.jar") {
            Remove-Item "burpsuite_desktop_v$Version.jar"
        }
        # Backwards compatibility
        if (Test-Path "burpsuite_pro_v$Version.jar") {
            Remove-Item "burpsuite_pro_v$Version.jar"
        }
        Pause
        Exit 1
    }
}

function Request-AdminPrivileges {
    Write-Host "Requesting Administrator privileges..."
    try {
        $CmdArgs = @("-Nologo", "-File", $PSCommandPath)
        if ($debug) {
            $CmdArgs = @("-Nologo", "-NoExit", "-File", $PSCommandPath, "-debug")
        }
        Start-Process powershell -Verb runas -ArgumentList $CmdArgs
    }
    catch [System.InvalidOperationException] {
        Write-Host "`nThis script requires you to run in Administrator mode." -ForegroundColor Yellow
        Pause
        Exit 1
    }
}

function Test-AdminPrivileges {
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Edit-BatchFileCommand {
    $BatchFileContent = Get-Content Burp.bat
    $Command = $BatchFileContent.Substring(0, $BatchFileContent.LastIndexOf("`"C")) + `
        "`"C:/burp/burpsuite_desktop_v$Version.jar`""
    Set-Content -Value $Command -Path Burp.bat
}

function Update-HelperFiles {
    if (-not (Test-Path .\HelperFilesUpdate.ps1)) {
        $Branch = Get-Branch $debug
        $Url = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/HelperFilesUpdate.ps1"
        Invoke-RestMethod $Url -OutFile .\HelperFilesUpdate.ps1
    }
    if ($debug) {
        powershell -File $PSScriptRoot\HelperFilesUpdate.ps1 -debug
    }
    else {
        powershell -File $PSScriptRoot\HelperFilesUpdate.ps1
    }
    if ($LASTEXITCODE -eq 1) {
        Write-Warning "There was a problem updating helper files."
    }
}

function Assert-Versions {
    param(
        [Parameter(Mandatory)]
        [object]$OldVersion,
        [string]$NewVersion
    )
    if ($OldVersion -is [Array]) {
        $OldVersion = $OldVersion[$OldVersion.Count - 1]
    }
    if ($NewVersion -eq $OldVersion) {
        Write-Warning "Your version is up to date. There is no need to update."
        Start-Burp
    }
}

function Start-Burp {
    Start-Process $BurpBatchFile -WindowStyle Hidden
    Start-Sleep 3
    Exit
}

function Update-Burp {
    Write-Warning ("PLEASE DO NOT CANCEL/CLOSE THE WINDOW WHEN THE SCRIPT IS RUNNING." +
    "`nIT WILL SCREW UP THE WHOLE PROCESS.`n")
    $ProgressPreference = "SilentlyContinue"

    Set-Location $BurpPath
    $script:ExistingBurp = Get-ChildItem -Path $BurpPath -Name "burpsuite*.jar"
    $script:BurpBatchFile = Join-Path $BurpPath "Burp.bat"
    $script:Version = Get-LatestBurpVersion
    if ($Version -eq 1) {
        Pause
        Exit 1
    }
    Assert-Versions -NewVersion $Version -OldVersion $ExistingBurp
    Add-LatestBurp
    Edit-BatchFileCommand
    Update-HelperFiles
    Remove-OldBurp
    Write-Host "Burp Suite Professional has been updated to $Version." -ForegroundColor Green
    Write-Host "`nThis window will close in 3 seconds." -ForegroundColor Cyan
    Start-Burp
}

function Main {
    if (-not (Test-AdminPrivileges)) {
        Request-AdminPrivileges
    }
    else {
        Clear-Host
        if (Test-BurpInstanceRunning) {
            Write-Warning "Please close all running instances of Burp Suite Professional before you run this script."
            Pause
            Exit 1
        }
        else {
            Update-Burp
        }
    }
}

Main
