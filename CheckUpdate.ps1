function Get-LatestBurpInfo {
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
                    return @{
                        version = $release.version
                        url     = $release.url
                    }
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
        Write-Host "Launching Burp..."
        Start-Sleep 3
        Exit
    }
}

function Show-Versions {
    param(
        [Parameter(Mandatory)]
        [Object[]]$files
    )
    Write-Host "`nVersions:"
    foreach ($file in $files) {
        Write-Host $file.SubString($file.IndexOf("v") + 1, $file.LastIndexOf(".") - 1 - $file.IndexOf("v")) -ForegroundColor Yellow
    }
    Write-Host
}

function Get-CurrentBurpVersion {
    $filename = Get-ChildItem -Path C:/Burp -Name "burpsuite*.jar"
    if ($filename) {
        if ($filename.Count -gt 1) {
            Write-Warning "Multiple versions of burp suite detected. Only the latest is selected for comparison."
            Show-Versions -Files $filename
            $filename = $filename[$filename.Count - 1]
        }
        $version = $filename.SubString($filename.IndexOf("v") + 1, $filename.LastIndexOf(".") - 1 - $filename.IndexOf("v"))
        return $version
    }
}

function Get-UpdateAnswer {
    param(
        [Parameter(Mandatory)]
        [string]$url
    )
    Write-Host "Do you want to update?"
    $url = "https://portswigger.net" + $url
    $yes = @("Y", "YES")
    $no = @("N", "NO")
    $view = @("V", "VIEW RELEASE NOTES")
    $exit = @("E", "EXIT")
    do {
        [string]$userInput = Read-Host -Prompt "[Y] Yes [N] No [V] View Release Notes [E] Exit"
        $userInput = $userInput.Trim()
        if ($userInput -in $view) { Start-Process $url }
    } until ($userInput -in ($yes + $no + $exit))
    return $userInput
}

function Main {
    Write-Host "Checking for updates...`n"
    $latestBurpInfo = Get-LatestBurpInfo
    $script:latestBurpVersion = $latestBurpInfo["version"]
    $script:currentBurpVersion = Get-CurrentBurpVersion
    if ($latestBurpVersion -eq $currentBurpVersion) {
        Write-Host "Burp Suite Professional is up to date." -ForegroundColor Green
        Start-Sleep 3
        Exit
    }

    Write-Host "The newest version of BurpSuite is $latestBurpVersion" -ForegroundColor Cyan
    Write-Host "Your current version of BurpSuite is $currentBurpVersion.`n" -ForegroundColor Yellow
    $userInput = Get-UpdateAnswer -Url $latestBurpInfo["url"]
    switch ($userInput) {
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