function Get-LatestBurpVersion {
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
                    return $release.version
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
        Exit-Program -ExitCode 1
    }
}


function Install-JRE8 {
    $jre8 = $SystemPackages | Where-Object { $_.Name -clike "Java 8 Update *" }
    if (-not ($jre8)) {
        Write-Host "Downloading JRE-8 installer ...."
        $url = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550"
        Invoke-WebRequest -Uri $url -OutFile jre-8.exe
        Write-Host "JRE-8 installer is downloaded, please install JRE-8 in the following window."
        Start-Process -Wait jre-8.exe
        Remove-Item jre-8.exe
    }
}

function Install-JDK21 {
    $jdk21 = $SystemPackages | Where-Object { $_.Name -clike "Java(TM) SE Development Kit 21*" }
    if (-not ($jdk21)) {
        Write-Host "Downloading JDK-21 installer ...."
        $url = "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe"
        Invoke-WebRequest -Uri $url -OutFile jdk-21.exe  
        Write-Host "JDK-21 installer is downloaded, please install JDK-21 in the following window."
        Start-Process -Wait jdk-21.exe
        Remove-Item jdk-21.exe
    }
}

function Install-JavaComponents {
    Write-Host "Checking necessary Java Components..."
    Install-JRE8
    Install-JDK21
    Write-Host "Necessary Java Components are installed."
}

function Remove-OldFiles {
    if (Test-Path $BurpPath) {
        Get-ChildItem $BurpPath | Remove-Item -Force
        Write-Host "Removed old files."
    }
    else {
        Add-Folder
        Write-Host "$BurpPath created."
    }
}

function Add-Folder {
    New-Item -Path "C:\" -Name "Burp" -ItemType Directory > $null
}

function Add-BurpFile {
    Write-Host "Downloading Burp Suite Professional..."
    $url = "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$version"
    Invoke-WebRequest -Uri $url -OutFile "burpsuite_pro_v$version.jar"
    Write-Host "Burp Suite Professional $version is downloaded."
}

function Add-BatchFile {
    $command = "java " +
    "--add-opens=java.desktop/javax.swing=ALL-UNNAMED " +
    "--add-opens=java.base/java.lang=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED " +
    "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED " +
    "-javaagent:`"$BurpPath\loader.jar`" " +
    "-noverify " +
    "-jar `"$BurpPath\burpsuite_pro_v$version.jar`""
    
    Set-Content -Path Burp.bat -Value $command
    Write-Host "Batch file is created."
}

function Add-GithubFiles {
    $files = @{
        "loader.jar"          = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/loader.jar"
        "CheckUpdate.ps1"     = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/CheckUpdate.ps1"
        "BurpSuiteUpdate.ps1" = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuiteUpdate.ps1"
        "BurpSuitePro.vbs"    = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/BurpSuitePro.vbs"
        "bspro.ico"           = "https://github.com/Bubuto24/BSPro/raw/refs/heads/main/bspro.ico"
    }
    foreach ($file in $files.GetEnumerator()) {
        try {
            Invoke-WebRequest -Uri $file.Value -OutFile $file.Key -UseBasicParsing -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to download $($file.Key): $_"
        }
    }
    Write-Host "Neccesary files have been added."
}

function Add-Files {
    Add-BurpFile
    Add-BatchFile
    Add-GithubFiles
}

function Add-Shortcut {
    $DesktopPath = [System.Environment]::GetFolderPath("Desktop")
    $WshShell = New-Object -COMObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath/Burp Suite Professional.lnk")
    $Shortcut.TargetPath = "$BurpPath\BurpSuitePro.vbs"
    $Shortcut.IconLocation = "$BurpPath\bspro.ico"
    $Shortcut.WorkingDirectory = $BurpPath
    $Shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) > $null
    Write-Host "Shortcut has been created in desktop."
}

function Start-BurpInstallation {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 
    Write-Host "Start key generator"
    Start-process java.exe -ArgumentList "-jar loader.jar" -WindowStyle Hidden
    Write-Host "Start Burp Suite Professional"
    Start-Process ./Burp.bat -WindowStyle Hidden
}

function Main {
    $ProgressPreference = "SilentlyContinue"
    $script:SystemPackages = Get-Package
    $script:BurpPath = "C:\Burp"
    $script:version = Get-LatestBurpVersion
    Remove-OldFiles
    Set-Location $BurpPath
    Install-JavaComponents
    Add-Files
    Add-Shortcut
    Start-BurpInstallation
}

Main
