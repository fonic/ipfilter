# Windows Runtime Environments

## Cygwin

**Homepage:**<br/>
[https://www.cygwin.com/](https://www.cygwin.com/)

**Search/install packages:**<br/>
Package search and installation is only possible via GUI (i.e. Cygwin setup).<br/>
There is no package manager present within the _Cygwin_ environment itself.

**Required packages:**<br/>
bash, gawk, grep, sed, unzip, curl, wget, gzip, bzip2, xz, zip

## MSYS2

**Homepage:**<br/>
[https://www.msys2.org/](https://www.msys2.org/)

**Update package databases:**<br/>
`$ pacman -Sy`

**Search packages:**<br/>
`$ pacman -Ss <keyword>`

**Install packages:**<br/>
`$ pacman -S <package>`

**Upgrade everything:**<br/>
`$ pacman -Syu`

**Install required packages:**<br/>
`$ pacman -S --needed bash gawk grep sed unzip curl wget gzip bzip2 xz zip`

## Git for Windows

**Homepage:**<br/>
[https://gitforwindows.org/](https://gitforwindows.org/)

**Package management:**<br/>
_Git for Windows_ does not feature a package management system.<br/>
However, all required dependencies are met out of the box.

## Ubuntu 20.04 LTS for WSL on Windows 10

**Homepage:**<br/>
[https://ubuntu.com/wsl](https://ubuntu.com/wsl)

**Quick setup:**

1. PowerShell (run as Administrator):<br/>
   ```
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. Restart Windows

3. PowerShell (run as Administrator):<br/>
   ```
   cd $HOME\Downloads
   Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile wsl_update_x64.msi -UseBasicParsing
   .\wsl_update_x64.msi
   wsl --set-default-version 2
   Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu_20.04_LTS.appx -UseBasicParsing
   Add-AppxPackage .\Ubuntu_20.04_LTS.appx
   ```

4. In _Start Menu_, find _Ubuntu 20.04 LTS_ and run it

Refer to [Microsoft Docs](https://docs.microsoft.com) articles _[Install WSL on Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)_ and _[Manually download Windows Subsystem for Linux (WSL) Distros](https://docs.microsoft.com/en-us/windows/wsl/install-manual)_ for detailed instructions.

**Update package databases:**<br/>
`$ sudo apt update`<br/>
`$ sudo apt-get update`

**Search packages:**<br/>
`$ apt search <keyword>`<br/>
`$ apt-cache search <keyword>`

**Install packages:**<br/>
`$ sudo apt install <package>`<br/>
`$ sudo apt-get install <package>`

**Upgrade everything:**<br/>
`$ sudo apt upgrade`<br/>
`$ sudo apt-get upgrade`

**Install required packages:**<br/>
`$ sudo apt install bash gawk grep sed unzip curl wget gzip bzip2 xz-utils zip'`<br/>
`$ sudo apt-get install bash gawk grep sed unzip curl wget gzip bzip2 xz-utils zip'`

<br/>_Last updated: 04/28/21_
