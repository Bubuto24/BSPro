function Get-LatestBurpInfo {
    <#
    .OUTPUTS
    System.PSCustomObject: An object with information related to the stable version.
    System.Int32: Returns 1 if there is an error.
    #>
    try {
        $Url = "https://portswigger.net/burp/releases/data?pageSize=5"
        $Response = Invoke-RestMethod -Uri $Url -ErrorAction Stop
        $StableReleases = $Response.ResultSet.Results | Where-Object {
            $_.releaseChannels -eq "Stable"
        }
        foreach ($Release in $StableReleases) {
            if ($Release.categories -contains "Professional") {
                return $Release
            }
        }
        # $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        # if ($Response.StatusCode -eq 200) {
        #     $Json = $Response.Content | ConvertFrom-Json
        #     $StableReleases = $Json.ResultSet.Results | Where-Object {
        #         $_.releaseChannels -eq "Stable"
        #     }
        #     foreach ($Release in $StableReleases) {
        #         if ($Release.categories -contains "Professional") {
        #             return $Release
        #         }
        #     }
        # }
        # For non error status codes that aren't 200
        # else {
        #     throw "HTTP $($Response.StatusCode): $($Response.StatusDescription)"
        # }
    }
    catch {
        Write-Host "Error occurred in $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return 1
    }
}

function Get-LatestBurpVersion {
    $BurpInfo = Get-LatestBurpInfo
    if ($BurpInfo -eq 1) {
        return $BurpInfo
    }
    return $BurpInfo.Version
}

function Get-VersionFromFilename {
    param(
        [Parameter(Mandatory)]
        [string]$Filename
    )
    return $Filename.SubString($Filename.IndexOf("v") + 1, $Filename.LastIndexOf(".") - 1 - $Filename.IndexOf("v"))
}

function Get-Branch {
    param(
        [Parameter(Mandatory)]
        [bool]$DebugState
    )
    if ($DebugState) {
        return $DebugBranch
    }
    return "main"
}

$BurpPath = "C:\Burp"
$BurpPathTemp = "$BurpPath.old"
# Rename these 2 variables
$GithubUsername = "Bubuto24"
$DebugBranch = "refactor"
$ErrorActionPreference = "Stop"
Export-ModuleMember -Function * -Variable *