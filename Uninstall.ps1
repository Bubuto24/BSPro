# Uninstall BurpSuite
# Note that license details are still stored in local machine if Java is not removed

function Remove-BurpDirectory {
    $BurpPath = "C:\Burp"
    if (Test-Path $BurpPath) {
        Remove-Item -ItemType Directory -Path $BurpPath -Recurse -Force
    }
    Write-Host "Removed $BurpPath."
}

function Remove-Shortcut {
    $DesktopPath = [System.Environment]::GetFolderPath("Desktop")
    $Shortcuts = @("BSPro Debug.lnk", "BSPro.lnk")
    foreach ($Shortcut in $Shortcuts) {
        if (Test-Path $(Join-Path -Path $DesktopPath -ChildPath $Shortcut)) {
            Remove-Item -Path $Shortcut -Force
        }
    }
    Write-Host "Shortcuts removed."
}

function Main {
    Write-Host "Start uninstallation process.`n" -ForegroundColor Cyan
    Remove-BurpDirectory
    Remove-Shortcut
    Write-Host "`nUninstallation process finished." -ForegroundColor Magenta
}

Main