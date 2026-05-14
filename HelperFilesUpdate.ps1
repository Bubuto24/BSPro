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
$Files = @("CheckUpdate.ps1", "BurpSuiteUpdate.ps1", "BurpSuitePro.vbs", "Common.psm1", "HelperFilesUpdate.ps1", "Uninstall.ps1")

$StringAsStream = [System.IO.MemoryStream]::new()
$Writer = [System.IO.StreamWriter]::new($StringAsStream)
$Writer.AutoFlush = $true

$Failed = [System.Collections.Generic.List[string]]::new()

foreach ($File in $Files) {
    try {
        $FilePath = Join-Path $BurpPath $File
        $LocalFileHash = $(Get-FileHash $FilePath).Hash
        $Url = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/$File"
        $Response = Invoke-RestMethod -Uri $Url -ErrorAction Stop
        $RemoteFileHash = Get-RemoteFileHash -RemoteFileContent $Response
        if ($LocalFileHash -ne $RemoteFileHash) {
            Set-Content -Value $Response -Path $FilePath -NoNewline
            Write-Host "$($File) has been updated." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to update $($File): `n$($_.Exception.Message)" -ForegroundColor Red
        $Failed.Add($File)
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
