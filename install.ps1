param (
    [switch]$debug
)
function Get-LatestBurpVersion {
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
            if ($Release.categories -contains "Desktop") {
                return $Release.Version
            }
        }
    }
    catch {
        Write-Host "Error occurred in $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return 1
    }
}


function Install-JDK21 {
    $JDK21 = $SystemPackages | Where-Object { $_.Name -clike "Java(TM) SE Development Kit 21*" }
    Write-Debug "Checking JDK-21"
    if (-not ($JDK21)) {
        Write-Host "Downloading JDK-21 installer ...."
        $Url = "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe"
        Invoke-WebRequest -Uri $Url -OutFile jdk-21.exe  
        Write-Host "JDK-21 installer is downloaded, please install JDK-21 in the following window."
        Start-Process -Wait jdk-21.exe
        Remove-Item jdk-21.exe
    }
    else {
        Write-Host "JDK-21 is installed."
    }
}

function Install-JRE8 {
    $JRE8 = $SystemPackages | Where-Object { $_.Name -clike "Java 8 Update *" }
    Write-Debug "Checking JRE-8"
    if (-not ($JRE8)) {
        Write-Host "Downloading JRE-8 installer ...."
        $Url = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550"
        Invoke-WebRequest -Uri $Url -OutFile jre-8.exe
        Write-Host "JRE-8 installer is downloaded, please install JRE-8 in the following window."
        Start-Process -Wait jre-8.exe
        Remove-Item jre-8.exe
    }
    else {
        Write-Host "JRE-8 is installed."
    }
}

function Install-JavaComponents {
    Write-Host "Checking necessary Java Components..."
    Install-JRE8
    Install-JDK21
    Write-Host "Necessary Java Components are installed."
}

function Rename-ExistingBurpFolder {
    # Rename folder if detected
    if (Test-Path $BurpPath) {
        Write-Host "$BurpPath exists."
        if (Test-Path $BurpPathTemp) {
            Write-Host "Removing $BurpPathTemp."
            Remove-Item $BurpPathTemp -Recurse -Force
            Write-Host "$BurpPathTemp removed."
        }
        Rename-Item $BurpPath "$BurpPathTemp"
        Write-Host "Temporarily moved $BurpPath to $BurpPathTemp."
    }
    Add-Folder
    Write-Host "$BurpPath created."
}

function Remove-ExistingFiles {
    if (Test-Path $BurpPathTemp) {
        Remove-Item -Path $BurpPathTemp -Recurse -Force
        Write-Host "Old files have been deleted."
    }
}

function Add-Folder {
    New-Item $BurpPath -ItemType Directory > $null
}

function Add-Burp {
    Write-Host "Downloading Burp Suite Professional..."
    $url = "https://portswigger-cdn.net/burp/releases/download?product=desktop&type=Jar&version=$Version"
    Invoke-WebRequest -Uri $url -OutFile "burpsuite_desktop_v$Version.jar"
    Write-Host "Burp Suite Professional $Version is downloaded."
}

function Add-BatchFile {
    $Command = "java " +
    "--add-opens=java.desktop/javax.swing=ALL-UNNAMED " +
    "--add-opens=java.base/java.lang=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED " +
    "-javaagent:`"$BurpPath\loader.jar`" " +
    "-noverify " +
    "-jar `"$BurpPath\burpsuite_desktop_v$Version.jar`""
    
    Set-Content -Path Burp.bat -Value $Command
    Write-Host "Batch file is created."
}

function Add-GithubFiles {
    $Branch = Get-Branch
    $Files = @("loader.jar", "CheckUpdate.ps1", "BurpSuiteUpdate.ps1", "HelperFilesUpdate.ps1", `
            "BurpSuitePro.vbs", "bspro.ico", "Common.psm1")
    if ($debug) {
        $Files += "Uninstall.ps1"
    }
    foreach ($File in $Files) {
        $Url = "https://raw.githubusercontent.com/$GithubUsername/BSPro/$Branch/$File"
        try {
            Invoke-WebRequest -Uri $Url -OutFile $File -UseBasicParsing -ErrorAction Stop
        }
        catch {
            Write-Host $Url
            Write-Error "Failed to download $($File): `n$($_.Exception.Message)"
        }
    }
    Write-Host "Helper files have been added."
}

function Add-Files {
    Add-Burp
    Add-BatchFile
    Add-GithubFiles
}

function Add-RealShortcut {
    $WshShell = New-Object -COMObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath/Burp Suite Professional.lnk")
    $Shortcut.TargetPath = "$BurpPath\BurpSuitePro.vbs"
    $Shortcut.IconLocation = "$BurpPath\bspro.ico"
    $Shortcut.WorkingDirectory = $BurpPath
    $Shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) > $null
    Write-Host "Shortcut has been created in desktop."
}

function Add-DebugShortcut {
    $WshShell = New-Object -COMObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath/BSPro Debug.lnk")
    $Shortcut.TargetPath = "wscript.exe"
    $Shortcut.Arguments = "$BurpPath\BurpSuitePro.vbs -debug"
    $Shortcut.WorkingDirectory = $BurpPath
    $Shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) > $null
    Write-Host "Debug shortcut has been created in desktop."
}

function Add-UninstallBatchScriptToDesktop {
    $UninstallBatchScriptPath = Join-Path $DesktopPath -ChildPath "UninstallBurpSuite.cmd"
    $UninstallPSScriptPath = Join-Path $BurpPath -ChildPath "Uninstall.ps1"
    $FileContent = "@echo off`n" +
    "powershell -File `"$UninstallPSScriptPath`"`n" +
    "IF %ERRORLEVEL% EQU 0 (`n" +
    "   Pause`n" +
    "   (goto) 2>nul & del `"%~f0`"`n" +
    ") ELSE (`n" +
    "   echo Uninstallation process has gone wrong somewhere.`n" +
    "   Pause`n" +
    ")"
    Set-Content -Path $UninstallBatchScriptPath -Value $FileContent
    Write-Host "Uninstall batch script created at `"$DesktopPath`""
}

function Start-BurpInstallation {
    Write-Host "Start key generator"
    Start-process java.exe -ArgumentList "-jar loader.jar" -WindowStyle Hidden
    Write-Host "Start Burp Suite Professional"
    Start-Process ./Burp.bat -WindowStyle Hidden
}

function Get-Branch {
    if ($debug) {
        return $DebugBranch
    }
    return "main"
}

# Edit these 2 variables
$DebugBranch = "dev"
$GithubUsername = "Bubuto24"

# Main flow
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
$BurpPath = "C:\Burp"
$BurpPathTemp = "$BurpPath.old"
$CurrentDirectory = Get-Location
$Version = Get-LatestBurpVersion
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")
$SystemPackages = Get-Package
if ($Version -eq 1) {
    Pause
    Exit 1
}
Rename-ExistingBurpFolder
Set-Location $BurpPath
Install-JavaComponents
Add-Files
if ($debug) {
    Add-DebugShortcut
}
Add-RealShortcut
Add-UninstallBatchScriptToDesktop
Remove-ExistingFiles
Start-BurpInstallation
Set-Location $CurrentDirectory