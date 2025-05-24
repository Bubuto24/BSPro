# Script for updating BurpSuite Professional
# BS Pro with keygen and loader disables checking for updates, so this script helps to circumvent that
# This means downloading the new version of BurpSuite Pro and replacing the old one
# Which means need to key in license again, and may lose settings

function Get-LatestBurpVersion {
    try {
        $response = Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/data?pageSize=5"
        if ($response.StatusCode -eq 200) {
            $stableReleases = ($response.Content | ConvertFrom-Json).ResultSet.Results | `
                Where-Object { $_.releaseChannels -eq "Stable" }
            foreach ($release in $stableReleases) {
                if ($release.categories.Contains("Professional")) {
                    return $release.version
                }
            }
        }
        else {
            throw [System.Net.HttpWebRequest] "HTTP Error $($response.StatusCode): $($response.StatusDescription)"
        }
    }
    catch [System.Net.WebException], [System.Net.HttpWebRequest] {
        Write-Host "Error occurred in $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Exit-Program -ExitCode 1
    }
}

function Test-BurpSuiteRunning {
    $burpProInstances = Get-CimInstance Win32_Process | Select-Object ProcessId, Name, CommandLine | `
        Where-Object { $_.Name -eq "java.exe" -and $_.CommandLine -like "java*loader.jar*" }
    if ($burpProInstances) {
        return $true
    }
    return $false
}

function Get-CurrentBurpVersion {
    $filename = Get-ChildItem -Path C:/Burp -Name "burpsuite*.jar"
    if ($filename) {
        $version = $filename.SubString($filename.IndexOf("v") + 1, $filename.LastIndexOf(".") - 1 - $filename.IndexOf("v"))
        return $version
    }
    return "Unknown"
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

# Main flow
# Check for administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..."
    try {
        $scriptPath = Join-Path -Path (Get-Location).Path -ChildPath "BurpSuiteUpdate.ps1"
        $cmdArgs = @("-Nologo", "-File", $scriptPath)
        Start-Process powershell -Verb runas -ArgumentList $cmdArgs
    }
    catch [System.InvalidOperationException] {
        Write-Host "`nThis script requires you to run in Administrator mode." -ForegroundColor Yellow
        Exit-Program -ExitCode 1
    }
}

else {
    Clear-Host
    # Check for instances of burp suite running
    if (Test-BurpSuiteRunning) {
        Write-Host "Please close all running instances of Burp Suite Professional before you run this script." `
            -ForegroundColor Yellow
        Exit-Program -ExitCode 1
    }

    Write-Host "NOTE: PLEASE DO NOT CANCEL/CLOSE THE WINDOW WHEN THE SCRIPT IS RUNNING." `
        "`nIT WILL SCREW UP THE WHOLE PROCESS." -ForegroundColor Cyan
    $ProgressPreference = "SilentlyContinue"

    $burpPath = "C:/Burp"
    Set-Location $burpPath
    $latestBurpVersion = Get-LatestBurpVersion
    $currentBurpVersion = Get-CurrentBurpVersion

    # Download Burp Pro
    Write-Host "`nDownloading the latest version of Burp Suite Professional...."
    Invoke-WebRequest "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$latestBurpVersion" `
        -OutFile "burpsuite_pro_v$latestBurpVersion.jar"
    if (Test-Path "burpsuite_pro_v$currentBurpVersion.jar") {
        Remove-Item "burpsuite_pro_v$currentBurpVersion.jar" 
        Write-Host "`nBurp Suite $currentBurpVersion has been removed."
    }
    else {
        Write-Host "Cannot find old version of burp suite." -ForegroundColor Yellow
    }
    
    Write-Host "`nBurp Suite Professional download successful." -ForegroundColor Green

    # Set burp.bat contents
    $burpBatContent = Get-Content Burp.bat
    $burpCommand = $burpBatContent.Substring(0, $burpBatContent.LastIndexOf("`"C")) + `
        "`"C:/burp/burpsuite_pro_v$latestBurpVersion.jar`""
    Set-Content -Value $burpCommand -Path Burp.bat

    Write-Host "Burp Suite Professional has been updated to $latestBurpVersion." -ForegroundColor Green

    Start-Process ./Burp.bat -WindowStyle Hidden
    Exit-Program
}
