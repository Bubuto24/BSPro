function Get-LatestBurpVersion {
    try {
        $response = Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/data?pageSize=5"
        if ($response.StatusCode -eq 200) {
            $stableReleases = ($response.Content | ConvertFrom-Json).ResultSet.Results | `
                Where-Object { $_.releaseChannels -eq "Stable" }
            foreach ($release in $stableReleases) {
                if ($release.categories.Contains("Professional")) {
                    return $release.version
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
        Exit-Program -ExitCode 1
    }
}

# Set Wget Progress to Silent, Becuase it slows down Downloading by 50x
Write-Host "Setting Wget Progress to Silent, Becuase it slows down Downloading by 50x`n"
$ProgressPreference = 'SilentlyContinue'
If (-not (Test-Path "C:/burp")) {
    New-Item -Path "C:" -Name "Burp" -ItemType Directory
}
Set-Location "C:/Burp"
$allPackages = Get-Package

# Check JDK-21 Availability or Download JDK-21
# $jdk21 = Get-WmiObject -Class Win32_Product -filter "Vendor='Oracle Corporation'" | where Caption -clike "Java(TM) SE Development Kit 21*"
$jdk21 = $allPackages | Where-Object {$_.Name -clike "Java(TM) SE Development Kit 21*"}
if (-not ($jdk21)) {
    Write-Host "`t`tDownloading Java JDK-21 ...."
    Invoke-WebRequest "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe" -OutFile jdk-21.exe  
    Write-Host "`n`t`tJDK-21 Downloaded, lets start the installation process"
    Start-Process -Wait jdk-21.exe
    Remove-Item jdk-21.exe
}
else {
    Write-Host "Required JDK-21 is installed"
    # $jdk21
}

# Check JRE-8 Availability or Download JRE-8
# $jre8 = Get-WmiObject -Class Win32_Product -filter "Vendor='Oracle Corporation'" | where Caption -clike "Java 8 Update *"
$jre8 = $allPackages | Where-Object {$_.Name -clike "Java 8 Update *"}
if (-not ($jre8)) {
    Write-Host "`n`t`tDownloading Java JRE ...."
    Invoke-WebRequest "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550" -OutFile jre-8.exe
    Write-Host "`n`t`tJRE-8 Downloaded, lets start the Installation process"
    Start-Process -Wait jre-8.exe
    Remove-Item jre-8.exe
}
else {
    Write-Host "`n`nRequired JRE-8 is installed`n"
    # $jre8
}

# Downloading Burp Suite Professional
Write-Host "`n`t`tDownloading Burp Suite Professional..."
$version = Get-LatestBurpVersion
Invoke-WebRequest -Uri "https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$version" `
    -OutFile "burpsuite_pro_v$version.jar"
Write-Host "`nBurp Suite Professional is downloaded."

# Creating Burp.bat file with command for execution
if (Test-Path burp.bat) { Remove-Item burp.bat }
$path = "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:`"$pwd\loader.jar`" -noverify -jar `"$pwd\burpsuite_pro_v$version.jar`""
$path | Add-Content -Path Burp.bat
Write-Host "`nBurp.bat file is created"

# Download loader if it not exists
if (-not (Test-Path loader.jar)) {
    Write-Host "`nDownloading Loader ...."
    Invoke-WebRequest -Uri "https://github.com/xiv3r/Burpsuite-Professional/raw/refs/heads/main/loader.jar" -OutFile loader.jar
    Write-Host "`nLoader is downloaded"
}
else {
    Write-Host "`nLoader is already downloaded"
}

# Create shortcut in desktop
Write-Host "`nCreating shortcut in Desktop..."
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$desktopPath/Burp Suite Professional.lnk")
$Shortcut.TargetPath = "$pwd/BurpSuitePro.vbs"
$Shortcut.IconLocation = "$pwd/burp_suite_professional.ico"
$Shortcut.WorkingDirectory = $pwd
$Shortcut.Save()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) > $null
Write-Host "`nShortcut has been created."

# Lets Activate Burp Suite Professional with keygenerator and Keyloader
Write-Host "`n`nReloading Environment Variables ...."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 
Write-Host "`n`nStarting Keygenerator ...."
Start-process java.exe -ArgumentList "-jar loader.jar" -WindowStyle Hidden
Write-Host "`n`nStarting Burp Suite Professional"
Start-Process ./Burp.bat -WindowStyle Hidden
