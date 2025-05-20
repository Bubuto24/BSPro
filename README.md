# Overview
* **Windows** Installation for BS Pro

* Provides installation and checking of updates

* [Link](https://portswigger.net/burp/pro) to official website 

<br>

# Installation Guide 
* There are two ways to run the installation.
<br>

## One-liner installation (recommended)
* Open `powershell` in Administrator Mode and run the following command

```
irm https://github.com/Bubuto24/BSPro/raw/refs/heads/main/install.ps1 | iex
```

## Run installation locally
* Run this command to download the installation script
```
irm https://github.com/Bubuto24/BSPro/raw/refs/heads/main/install.ps1 > install.ps1
```
* Then use this command to run the installation script you just downloaded
```
./install.ps1
```
<br>

# Installation notes
* A shortcut will be created at your desktop after the installation of BSPro.
* Checking of updates in BSPro will <ins>**not work**</ins>.
<br>

# Update Guide
* Running BSPro with key generator results in the **disablement** of checking of updates

* As a workaround, the installation script will provide a launcher (VBS script) that will provide for both the launching of BSPro and checking of updates.
<br>

# References
[BSPro](https://github.com/xiv3r/Burpsuite-Professional) by xiv3r
