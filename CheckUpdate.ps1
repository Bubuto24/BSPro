# Script to check and prompt for latest updates
Import-Module $PSScriptRoot/Common.psm1 -Force

function Show-Versions {
    param(
        [Parameter(Mandatory)]
        [Object[]]$Files
    )
    Write-Host "Versions:"
    foreach ($File in $Files) {
        Write-Host $(Get-VersionFromFilename -Filename $File) -ForegroundColor Yellow
    }
    Write-Host
}

function Get-LocalBurpVersion {
    $Filename = Get-ChildItem -Path $BurpPath -Name "burpsuite*.jar"
    if ($Filename -and $($Filename.Count -gt 1)) {
        Write-Warning "Multiple versions of BurpSuite detected. Only the latest is selected for comparison."
        Show-Versions -Files $Filename
        $Filename = $Filename[$Filename.Count - 1]
    }
    $Version = Get-VersionFromFilename -Filename $Filename
    return $Version
}

function Get-UpdateAnswer {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )
    Write-Host "Do you want to update?"
    $Url = "https://portswigger.net" + $Url
    $Yes = @("Y", "YES")
    $No = @("N", "NO")
    $View = @("V", "VIEW RELEASE NOTES")
    $Exit = @("E", "EXIT")
    do {
        [string]$UserInput = Read-Host -Prompt "[Y] Yes [N] No [V] View Release Notes [E] Exit"
        $UserInput = $UserInput.Trim()
        if ($UserInput -in $View) { Start-Process $Url }
    } until ($UserInput -in ($Yes + $No + $Exit))
    return $UserInput
}

function Main {
    Write-Host "Checking for updates...`n"
    $LatestBurpInfo = Get-LatestBurpInfo
    if ($LatestBurpInfo -eq 1) {
        Write-Host "Launching Burp..."
        Start-Sleep 3
        Exit
    }
    $script:LatestBurpVersion = $LatestBurpInfo.Version  
    $script:LocalBurpVersion = Get-LocalBurpVersion
    if ($LatestBurpVersion -eq $LocalBurpVersion) {
        Write-Host "Burp Suite Professional is up to date." -ForegroundColor Green
        Start-Sleep 3
        Exit
    }

    Write-Host "The newest version of BurpSuite is $LatestBurpVersion" -ForegroundColor Cyan
    Write-Host "Your version of BurpSuite is $LocalBurpVersion.`n" -ForegroundColor Yellow
    $UserInput = Get-UpdateAnswer -Url $LatestBurpInfo.Url
    switch ($UserInput) {
        { $_ -in @("Y", "YES") } {
            Exit -1
        }
        { $_ -in @("E", "EXIT") } {
            Exit -2
        }
        { $_ -in @("N", "NO") } {
            Exit
        }
    }
}

Main
