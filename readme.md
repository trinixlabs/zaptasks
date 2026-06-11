# ZapTasks

![ZapTasks Logo](./logo/AppIconsDock/zaptasks_64.png)

**ZapTasks** is a modern, user-friendly command execution tool, designed as an alternative to Cron. It simplifies task configuration, execution, and tracking, all while offering a clean interface and seamless integration into macOS.

ZapTasks is built in **Swift**, delivering a native experience for Mac users, and leverages "Shaas" (Shell as a Service) to execute shell commands.

## Features

* **User-Friendly Interface**: Configure and manage tasks with ease through a Mac application and menu bar interface.
* **Task Execution History**: View and track previously executed tasks.
* **Notifications**: Stay informed with alerts when tasks are executed or completed.
* **Mac Integration**: Operates smoothly as a Mac menu bar app and standalone application.
* **Shell executing**: Executes commands efficiently using the powerful Shaas binary "Shell as a Service."

## Get Started

### 1. Install ZapTasks

Choose one of these installation paths:

#### Option A: Homebrew

```bash
brew tap trinixlabs/tap
brew install --cask zaptasks
```

#### Option B: DMG

1. Open the [GitHub Releases](https://github.com/trinixlabs/zaptasks/releases) page.
2. Download the latest `ZapTasks-<version>.dmg`.
3. Open the DMG and drag `ZapTasks.app` into your `Applications` folder.

#### Option C: ZIP

1. Open the [GitHub Releases](https://github.com/trinixlabs/zaptasks/releases) page.
2. Download the latest `ZapTasks-<version>.zip`.
3. Extract it and move `ZapTasks.app` to your `Applications` folder.

### 2. First Launch on macOS

ZapTasks is an open-source project and release builds are currently distributed unsigned.
On first launch, macOS may show:

- `"ZapTasks" cannot be opened because Apple cannot check it for malicious software.`
- `"ZapTasks" is damaged and can't be opened. You should move it to the Bin.`

To run it anyway:

1. Open `ZapTasks.app` from `Applications`.
2. If macOS blocks it, right-click `ZapTasks.app` and choose `Open`.
3. Click `Open` again in the warning dialog.

If Finder still blocks it, use:

- `System Settings -> Privacy & Security` and click `Open Anyway` for ZapTasks.

Alternative Terminal path:

```bash
xattr -dr com.apple.quarantine /Applications/ZapTasks.app
open /Applications/ZapTasks.app
```

If needed, remove all extended attributes and try again:

```bash
xattr -cr /Applications/ZapTasks.app
open /Applications/ZapTasks.app
```

### 3. Start Shaas

Navigate to the directory containing `shaas` and run:

```bash
./shaas
```

### 4. Launch ZapTasks

Open `ZapTasks.app` and start configuring and managing your tasks.

## How It Works

1. Define tasks directly in the intuitive ZapTasks interface.
2. Use "Shaas" to securely execute shell commands in the background.
3. Get notified when tasks are executed or encounter issues.
4. View the history of your tasks for tracking and analysis.

## Why ZapTasks?

ZapTasks combines the power of command execution with the simplicity of a GUI, making it an ideal solution for developers, system administrators, and everyday users who want a more approachable way to manage their automated tasks.
