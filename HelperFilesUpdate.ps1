# Script to update helper files
param (
    [switch]$debug
)
Import-Module $PSScriptRoot/Common.psm1 -Force

function Get-RemoteFileHash {
    param(
        [Parameter(Mandatory)]
        [string]$RemoteFileContent
    )
    $Writer.Write($RemoteFileContent)
    $StringAsStream.Position = 0
    return $(Get-FileHash -InputStream $StringAsStream).Hash
}

$Branch = Get-Branch $debug
$Files = @{
    "CheckUpdate.ps1"     = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/CheckUpdate.ps1"
    "BurpSuiteUpdate.ps1" = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/BurpSuiteUpdate.ps1"
    "BurpSuitePro.vbs"    = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/BurpSuitePro.vbs"
}

$StringAsStream = [System.IO.MemoryStream]::new()
$Writer = [System.IO.StreamWriter]::new($StringAsStream)
$Writer.AutoFlush = $true

$Failed = @()

foreach ($File in $Files.GetEnumerator()) {
    try {
        $FilePath = Join-Path C:\Burp $File.Key
        $LocalFileHash = $(Get-FileHash $FilePath).Hash
        $Response = Invoke-RestMethod -Uri $File.Value -ErrorAction Stop
        $RemoteFileHash = Get-RemoteFileHash -RemoteFileContent $Response
        if ($LocalFileHash -ne $RemoteFileHash) {
            Set-Content -Value $Response -Path $FilePath -NoNewline
            Write-Host "$($File.Key) has been updated." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to update $($File.Key): `n$($_.Exception.Message)" -ForegroundColor Red
        $Failed += $File.Key
    }
    finally {
        $StringAsStream.SetLength(0)
    }
}

$StringAsStream.Dispose()
$Writer.Dispose()

if ($Failed.Count) {
    Write-Host "`nThe following files have failed to update:"
    foreach ($File in $Failed) {
        Write-Host $File -ForegroundColor Red
    }
}
else {
    Write-Host "All files are up to date!" -ForegroundColor Green
}
