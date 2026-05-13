# Reset development status

function Uninstall-Java {
    $SystemPackages = Get-Package
    $JDK21 = $SystemPackages | Where-Object { $_.Name -clike "Java(TM) SE Development Kit 21*" }
    $JRE8 = $SystemPackages | Where-Object { $_.Name -clike "Java 8 Update *" }
    $PackagesToUninstall = @($JDK21, $JRE8)
    $PackagesRemoved = @()
    foreach($Package in $PackagesToUninstall) {
        $PackagesRemoved += Uninstall-Package $Package
    }
    if ($PackagesRemoved.Count -eq $PackagesToUninstall.Count) {
        Write-Host "Removed all java packages."
    }
    else {
        Write-Host "The following packages were not removed:"
        foreach ($Package in $PackagesToUninstall) {
            if ($Package -notcontains $PackagesRemoved) {
                Write-Host $Package.Name
            }
        }
    }
}

function Remove-BurpDirectory {
    $BurpPath = "C:\Burp"
    if (Test-Path $BurpPath) {
        Remove-Item -ItemType Directory -Path $BurpPath -Recurse -Force
    }
    Write-Host "Removed $BurpPath."
}

function Remove-Shortcut {
    $DesktopPath = [System.Environment]::GetFolderPath("Desktop")
    $Shortcut = "$DesktopPath/BSPro Debug.lnk"
    if (Test-Path $Shortcut) {
        Remove-Item -ItemType File -Path $Shortcut -Force
    }
    Write-Host "Shortcut removed."
}

function Main {
    Write-Host "Start uninstallation process.`n" -ForegroundColor Cyan
    Uninstall-Java
    Remove-BurpDirectory
    Remove-Shortcut
    Write-Host "`nUninstallation process finished." -ForegroundColor Magenta
}

Main