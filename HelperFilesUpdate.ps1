# Script to update helper files

$files = @{
    "CheckUpdate.ps1"     = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/CheckUpdate.ps1"
    "BurpSuiteUpdate.ps1" = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuiteUpdate.ps1"
    "BurpSuitePro.vbs"    = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuitePro.vbs"
}

$failed = @()
foreach ($file in $files.GetEnumerator()) {
    try {
        $filePath = Join-Path C:\Burp $file.Key
        Invoke-WebRequest -Uri $file.Value -OutFile $filePath -UseBasicParsing -ErrorAction Stop
        Write-Host "$($file.Key) has been updated." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to update $($file.Key): `n$($_.Exception.Message)" -ForegroundColor Red
        $failed += $file.Key
    }
}

if ($failed.Count) {
    Write-Host "`nThe following files have failed to update:"
    foreach ($file in $failed) {
        Write-Host $file -ForegroundColor Red
    }
}
else {
    Write-Host "`nAll helper files have been updated." -ForegroundColor Green
}
