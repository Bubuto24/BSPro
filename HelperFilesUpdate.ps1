# Script to update helper files

function New-RemoteFileHash {
    param(
        [Parameter(Mandatory)]
        [string]$remoteFileContent
    )
    $writer.Write($remoteFileContent)
    $stringAsStream.Position = 0
    return $(Get-FileHash -InputStream $stringAsStream).Hash
}

$files = @{
    "CheckUpdate.ps1"     = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/CheckUpdate.ps1"
    "BurpSuiteUpdate.ps1" = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuiteUpdate.ps1"
    "BurpSuitePro.vbs"    = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuitePro.vbs"
}

$script:stringAsStream = [System.IO.MemoryStream]::new()
$script:writer = [System.IO.StreamWriter]::new($stringAsStream)
$writer.AutoFlush = $true

$failed = @()
$filesUpdated = $false

foreach ($file in $files.GetEnumerator()) {
    try {
        $filePath = Join-Path C:\Burp $file.Key
        $localFileHash = $(Get-FileHash $filePath).Hash
        $response = Invoke-RestMethod -Uri $file.Value -ErrorAction Stop
        $remoteFileHash = New-RemoteFileHash -remoteFileContent $response
        if ($localFileHash -ne $remoteFileHash) {
            Set-Content -Value $response -Path $filePath -NoNewline
            Write-Host "$($file.Key) has been updated." -ForegroundColor Green
            $filesUpdated = $true
        }
    }
    catch {
        Write-Host "Failed to update $($file.Key): `n$($_.Exception.Message)" -ForegroundColor Red
        $failed += $file.Key
    }
    finally {
        $stringAsStream.SetLength(0)
    }
}

$stringAsStream.Dispose()
$writer.Dispose()

if ($failed.Count) {
    Write-Host "`nThe following files have failed to update:"
    foreach ($file in $failed) {
        Write-Host $file -ForegroundColor Red
    }
}
elseif ($filesUpdated) {
    Write-Host "`nAll helper files have been updated." -ForegroundColor Green
}
else {
    Write-Host "All files are up to date!" -ForegroundColor Green
}
