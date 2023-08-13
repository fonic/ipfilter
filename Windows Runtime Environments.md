# Windows Runtime Environments

## Cygwin

**Homepage:**<br/>
[https://www.cygwin.com/](https://www.cygwin.com/)

**Package management:**<br/>
Package management is only possible via the GUI (i.e. the _Cygwin_ setup).<br/>
There is no package manager present within the _Cygwin_ environment itself.

**Required packages:**<br/>
bash, gawk, grep, sed, unzip, curl, wget, gzip, bzip2, xz, zip

## MSYS2

**Homepage:**<br/>
[https://www.msys2.org/](https://www.msys2.org/)

**Package management (using `pacman`):**

| Function                   | Command                |
|----------------------------|------------------------|
| Update package information | `pacman -Sy`           |
| Search packages            | `pacman -Ss <keyword>` |
| Install packages           | `pacman -S <package>`  |
| Remove packages            | `pacman -Rs <package>` |
| Upgrade all packages       | `pacman -Syu`          |

**Install required packages:**<br/>
`pacman -S --needed bash gawk grep sed unzip curl wget gzip bzip2 xz zip`

## Git for Windows

**Homepage:**<br/>
[https://gitforwindows.org/](https://gitforwindows.org/)

**Downloads:**<br/>
[https://git-scm.com/download/win](https://git-scm.com/download/win)

**Package management:**<br/>
_Git for Windows_ does not feature a package management system.<br/>
However, all required dependencies are already met out of the box.

## Ubuntu for WSL on Windows 10/11

**Homepage:**<br/>
[https://ubuntu.com/wsl](https://ubuntu.com/wsl)

**Quick setup:**<br/>
Open *PowerShell* or *Windows Command Prompt* and enter this command: `wsl --install`<br/>
Once installation is complete, reboot, then open _Start_, find _Ubuntu_ and run/open it.

**Advanced setup:**<br/>
Refer to [Microsoft Learn](https://learn.microsoft.com/en-us/) articles _[Install Linux on Windows with WSL](https://learn.microsoft.com/en-us/windows/wsl/install)_ and/or _[Manual installation steps for older versions of WSL](https://learn.microsoft.com/en-us/windows/wsl/install-manual)_ for detailed instructions.

**Package management (using `apt`):**

| Function                   | Command                                        |
|----------------------------|------------------------------------------------|
| Update package information | `sudo apt update`                              |
| Search packages            | `apt search <keyword>`                         |
| Install packages           | `sudo apt install <package>`                   |
| Remove packages            | `sudo apt remove <package>`                    |
| Upgrade all packages       | `sudo apt upgrade`<br/>`sudo apt full-upgrade` |

**Package management (using `apt-get`):**

| Function                   | Command                                                |
|----------------------------|--------------------------------------------------------|
| Update package information | `sudo apt-get update`                                  |
| Search packages            | `apt-cache search <keyword>`                           |
| Install packages           | `sudo apt-get install <package>`                       |
| Remove packages            | `sudo apt-get remove <package>`                        |
| Upgrade all packages       | `sudo apt-get upgrade`<br/>`sudo apt-get dist-upgrade` |

**Install required packages:**<br/>
`sudo apt install bash gawk grep sed unzip curl wget gzip bzip2 xz-utils zip`<br/>
-or-<br/>
`sudo apt-get install bash gawk grep sed unzip curl wget gzip bzip2 xz-utils zip`

##

_Last updated: 08/13/23_
