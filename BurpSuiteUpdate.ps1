# Script for updating burp suite

function Get-LatestBurpVersion {
    try {
        $url = "https://portswigger.net/burp/releases/data?pageSize=5"
        $response = Invoke-WebRequest -Uri $url -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            $json = $response.Content | ConvertFrom-Json
            $stableReleases = $json.ResultSet.Results | Where-Object {
                $_.releaseChannels -eq "Stable"
            }

            foreach ($release in $stableReleases) {
                if ($release.categories -contains "Professional") {
                    return $release.version
                }
            }
        }
        else {
            throw "HTTP Error $($response.StatusCode): $($response.StatusDescription)"
        }
    }
    catch {
        Write-Host "Error occurred in $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Exit-Program -ExitCode 1
    }
}

function Test-BurpRunning {
    $burpInstances = Get-CimInstance Win32_Process | Select-Object ProcessId, Name, CommandLine | `
        Where-Object { $_.Name -eq "java.exe" -and $_.CommandLine -like "java*loader.jar*" }
    $burpRunning = $false
    if ($burpInstances) {
        $burpRunning = $true
    }
    return $burpRunning
}

function Remove-OldBurp {
    $files = Get-ChildItem -Path C:/Burp -Name "burpsuite*.jar"
    if ($files) {
        Remove-Item $files -Force
    }
    Write-Host "Successfully removed old Burp Suite files."
}

function Add-LatestBurp {
    Write-Host "Downloading the latest version of Burp Suite Professional..."
    $url = "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$latestBurpVersion"
    Invoke-WebRequest -Uri $url -OutFile "burpsuite_pro_v$latestBurpVersion.jar"
    Write-Host "`nBurp Suite Professional download successful." -ForegroundColor Green
}

function Request-AdminPrivileges {
    Write-Host "Requesting Administrator privileges..."
    try {
        $cmdArgs = @("-Nologo", "-File", $PSCommandPath)
        Start-Process powershell -Verb runas -ArgumentList $cmdArgs
    }
    catch [System.InvalidOperationException] {
        Write-Host "`nThis script requires you to run in Administrator mode." -ForegroundColor Yellow
        Exit-Program -ExitCode 1
    }
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Exit-Program {
    param(
        [Int32]$ExitCode = 0
    )
    Write-Host "`nPress Enter to exit..."
    do {
        $userKey = ([System.Console]::ReadKey()).Key
    } until ($userKey -eq "Enter")
    Exit $ExitCode
}

function Edit-BatchFileCommand {
    $burpBatContent = Get-Content Burp.bat
    $burpCommand = $burpBatContent.Substring(0, $burpBatContent.LastIndexOf("`"C")) + `
        "`"C:/burp/burpsuite_pro_v$latestBurpVersion.jar`""
    Set-Content -Value $burpCommand -Path Burp.bat
}

function Update-Burp {
    Write-Host "NOTE: PLEASE DO NOT CANCEL/CLOSE THE WINDOW WHEN THE SCRIPT IS RUNNING." `
        "`nIT WILL SCREW UP THE WHOLE PROCESS.`n" -ForegroundColor Cyan
    $ProgressPreference = "SilentlyContinue"

    Set-Location C:\Burp
    $script:latestBurpVersion = Get-LatestBurpVersion

    Remove-OldBurp
    Add-LatestBurp
    Edit-BatchFileCommand

    Write-Host "Burp Suite Professional has been updated to $latestBurpVersion." -ForegroundColor Green
    Start-Process ./Burp.bat -WindowStyle Hidden
    Exit-Program
}

function Main {
    if (-not (Test-AdminPrivileges)) {
        Request-AdminPrivileges
    }
    else {
        Clear-Host
        if (Test-BurpRunning) {
            Write-Host "Please close all running instances of Burp Suite Professional before you run this script." `
                -ForegroundColor Yellow
            Exit-Program -ExitCode 1
        }
        else {
            Update-Burp
        }
    }
}

Main
