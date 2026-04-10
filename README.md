# Overview
* **Windows** Installation for BS Pro

* [Link](https://portswigger.net/burp/pro) to official website 

<br>

# Installation Guide
### Open powershell and run the following commands

1. Change the execution policy
```
Set-ExecutionPolicy Bypass -Scope CurrentUser
```
2. Download the script
```
irm https://github.com/Bubuto24/BSPro/raw/refs/heads/main/install.ps1 > install.ps1
```
3. Run the script
```
./install.ps1
```
<br>

# Features
* Built-in checking of updates upon launching shortcut.
* Shortcut to launcher(vbs) is created at desktop.
<br>

# Update Guide
* Just run the shortcut in your desktop.
* Checking of updates in the software is disabled.
<br>

# Debugging
1. Create a new branch
2. Edit the 2 variables in <u>Common.psm1 and install.ps1</u> to your <b><u>branch name</u></b> and your <b><u>github username</u></b>.
3. Run  with `-debug` flag.

# Debug steps
```
irm https://github.com/<GithubUsername>/BSPro/raw/refs/heads/<branch>/install.ps1 > install.ps1
```
```
./install.ps1
```

# References
[BSPro](https://github.com/xiv3r/Burpsuite-Professional) by xiv3r 
