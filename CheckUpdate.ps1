# Check for updates
# Debug flag (for testing purposes)
param(
    [switch]$DEBUG
)

function Get-LatestBurpInfo {
    try {
        $response = Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/data?pageSize=5"
        if ($response.StatusCode -eq 200) {
            $stableReleases = ($response.Content | ConvertFrom-Json).ResultSet.Results | `
                Where-Object { $_.releaseChannels -eq "Stable" }
            foreach ($release in $stableReleases) {
                if ($release.categories.Contains("Professional")) {
                    return @{
                        version = $release.version
                        url     = $release.url
                    }
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
        Write-Host "Launching Burp..."
        Start-Sleep 3
        Exit
    }
}

function Get-CurrentBurpVersion {
    $filename = Get-ChildItem -Path C:/Burp -Name "burpsuite*.jar"
    if ($filename) {
        $version = $filename.SubString($filename.IndexOf("v") + 1, $filename.LastIndexOf(".") - 1 - $filename.IndexOf("v"))
        return $version
    }
    return "Unknown"
}

function Get-UpdateAnswer {
    param(
        [string]$url
    )
    Write-Host "Do you want to update?"
    $yes = @("Y", "YES")
    $no = @("N", "NO")
    $view = @("V", "VIEW RELEASE NOTES")
    $exit = @("E", "EXIT")
    do {
        [string]$userInput = Read-Host -Prompt "[Y] Yes [N] No [V] View Release Notes [E] Exit"
        $userInput = $userInput.Trim()
        if ($userInput -in $view) { Start-Process $url }
        elseif ($userInput -in $exit) { Exit -2 }
    } until ($userInput -in ($yes + $no))
    return $userInput
}


Write-Host "Checking for updates...`n"

$currentDir = Get-Location
if (!$DEBUG) {
    $latestBurpInfo = Get-LatestBurpInfo
    $latestBurpVersion = $latestBurpInfo["version"]
}
else {
    # Test data
    $latestBurpInfo = @{
        version = "2025.3.1"
        url     = "/burp/releases/professional-community-2025-3-1"
    }
    $latestBurpVersion = $latestBurpInfo["version"]
}

$currentBurpVersion = Get-CurrentBurpVersion
if ($currentBurpVersion -eq $latestBurpVersion) {
    Write-Host "Burp Suite Professional is up to date." -ForegroundColor Green
    Start-Sleep 3
    Exit
}

Write-Host "The newest version of BurpSuite is $latestBurpVersion" -ForegroundColor Cyan
Write-Host "Your current version of BurpSuite is $currentBurpVersion.`n" -ForegroundColor Yellow
$userInput = Get-UpdateAnswer -Url ("https://portswigger.net" + $latestBurpInfo["url"])
if ($userInput -in @("YES", "Y")) {
    Exit -1
}
else {
    if ($DEBUG) { Set-Location $currentDir }
    Exit
}
