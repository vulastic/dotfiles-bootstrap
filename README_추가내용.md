# dotfiles-bootstrap (Windows)

A minimal and reproducible bootstrap script for setting up a modern Windows terminal environment.

## ✨ Features

* Installs **PowerShell 7**
* Installs **Scoop** package manager
* Installs core tools:

  * `git`
  * `starship`
* Installs selected **Nerd Fonts**
* Configures **Windows Terminal**
* Sets up **PowerShell profile with Starship**

---

## 🚀 Quick Start

Run the following command in PowerShell:

```powershell
irm https://raw.githubusercontent.com/vulastic/dotfiles-bootstrap/refs/heads/main/install.ps1 | iex
```

---

## ⚠️ PowerShell 5.x Execution Policy Issue

If you see an error like:

```
PSSecurityException: running scripts is disabled on this system
```

Run the following command:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then re-run the powershell command.

> This allows locally created scripts to run, while still blocking unsigned remote scripts.

---

## ⚠️ PowerShell 5.x (한국어 안내)

다음과 같은 오류가 발생할 경우:

```
이 시스템에서 스크립트를 실행할 수 없으므로 ...
PSSecurityException
```

아래 명령어를 실행하세요:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

이후 다시 설치 파워쉘을 실행하면 됩니다.

---

## 🧩 What Gets Installed

### Core Tools

* PowerShell 7 (via winget)
* Scoop
* Git
* Starship prompt

### Fonts

* Iosevka Nerd Font
* Iosevka Term Nerd Font Mono
* Sarasa Mono K

Only selected font weights are installed:

* Regular
* Italic
* Bold
* BoldItalic

---

## ⚙️ Configuration

### Windows Terminal

* Tokyo Night color scheme
* Custom font configuration
* Improved cursor & rendering settings

### Starship

* Custom Tokyo Night theme
* Minimal left prompt
* Optional right-side modules

---

## 📁 Project Structure

```
install.ps1         # Entry point (called via irm)
install/windows.ps1 # Main Windows setup script

config/
  starship/
    starship.toml

  windows-terminal/
    settings.json
```

---

## 🧼 Cleanup Behavior

* Temporary files are automatically removed
* Scoop font cache is cleaned after installation

---

## 🛠 Troubleshooting

### Fonts not showing in Windows Terminal

* Restart Windows Terminal
* Ensure font name matches exactly:

  * Example: `IosevkaTerm Nerd Font Mono`

### Starship not loading

Check your PowerShell profile:

```powershell
notepad $PROFILE
```

Make sure it contains:

```powershell
$env:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
Invoke-Expression (& starship init powershell)
```

---

## 🧠 Philosophy

This bootstrap script aims to be:

* Minimal
* Predictable
* Non-invasive

It avoids modifying system-level policies unless explicitly required.

---

## 📌 Notes

* Designed primarily for **fresh Windows environments**
* Safe to run multiple times (idempotent where possible)

---

## 📄 License

MIT
