<#
.SYNOPSIS
    Single entry point to set up a fresh Windows machine to match the
    macOS/Linux dotfiles setup: WSL2 (Ubuntu) running the existing Nix/
    home-manager config, plus native Windows apps, preferences, WezTerm,
    and taskbar pins.

.DESCRIPTION
    Safe to run more than once — every step checks current state first and
    skips work that's already done. If WSL2 needs a reboot to finish
    installing, re-run this script afterwards; it will pick up where it
    left off.

.PARAMETER DryRun
    Print what would happen without changing anything.

.PARAMETER Distro
    WSL distro to install/use. Default: Ubuntu.

.PARAMETER DotfilesRepo
    Git URL to clone inside WSL. Default: this repo.

.EXAMPLE
    .\bootstrap.ps1 -DryRun
    .\bootstrap.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Distro = "Ubuntu",
    [string]$DotfilesRepo = "https://github.com/marmos91/dotfiles.git"
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Info($msg) { Write-Host "    $msg" -ForegroundColor Gray }
function Write-Done($msg) { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }
function Write-DryRun($msg) { Write-Host "    [DryRun] $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Elevation
# ---------------------------------------------------------------------------
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not $DryRun -and -not (Test-IsAdmin)) {
    Write-Host "Re-launching elevated (admin rights are required for WSL/winget/registry steps)..." -ForegroundColor Yellow
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-Distro', $Distro, '-DotfilesRepo', $DotfilesRepo)
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

Write-Host "marmos91 dotfiles - Windows bootstrap$(if ($DryRun) { ' (dry run)' })" -ForegroundColor Magenta

# ---------------------------------------------------------------------------
# Step 1: WSL2 + distro
# ---------------------------------------------------------------------------
Write-Step "WSL2 + $Distro"

$wslInstalled = $false
try {
    $existing = (wsl.exe -l -q 2>$null) -join "`n"
    if ($existing -match [regex]::Escape($Distro)) {
        $wslInstalled = $true
    }
} catch {
    # wsl.exe not present or WSL not yet enabled
}

if ($wslInstalled) {
    Write-Done "$Distro is already installed"
} elseif ($DryRun) {
    Write-DryRun "would run: wsl --install -d $Distro"
} else {
    Write-Info "Installing $Distro (this may require a reboot on a fresh machine)..."
    wsl.exe --install -d $Distro
    Write-Warn "If Windows asks you to reboot, do so, then re-run this script to continue."
}

$wslReady = $false
if (-not $DryRun) {
    try {
        wsl.exe -d $Distro -- true 2>$null
        if ($LASTEXITCODE -eq 0) { $wslReady = $true }
    } catch {}
}

if (-not $DryRun -and -not $wslReady) {
    Write-Warn "$Distro isn't responding yet (likely needs first-run setup or a reboot)."
    Write-Warn "Re-run this script once 'wsl -d $Distro' drops you into a shell."
    exit 0
}

# ---------------------------------------------------------------------------
# Step 2: clone dotfiles into WSL and run install.sh
# ---------------------------------------------------------------------------
Write-Step "Dotfiles inside WSL ($Distro)"

if ($DryRun) {
    Write-DryRun "would run inside WSL: git clone $DotfilesRepo ~/.dotfiles (if missing)"
    Write-DryRun "would run inside WSL: ~/.dotfiles/install.sh"
} else {
    wsl.exe -d $Distro -- bash -lc "test -d ~/.dotfiles || git clone $DotfilesRepo ~/.dotfiles"
    wsl.exe -d $Distro -- bash -lc "chmod +x ~/.dotfiles/install.sh && ~/.dotfiles/install.sh"
    Write-Done "install.sh finished inside $Distro"
}

# ---------------------------------------------------------------------------
# Step 3: winget apps
# ---------------------------------------------------------------------------
Write-Step "Windows apps (winget)"

$appsFile = Join-Path $PSScriptRoot "apps.txt"
$appIds = Get-Content $appsFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
} else {
    $failed = @()
    foreach ($id in $appIds) {
        $listed = winget list --id $id -e --accept-source-agreements 2>$null | Out-String
        if ($listed -match [regex]::Escape($id)) {
            Write-Done "$id already installed"
            continue
        }

        if ($DryRun) {
            Write-DryRun "would run: winget install --id $id -e"
            continue
        }

        Write-Info "Installing $id..."
        try {
            winget install --id $id -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
            Write-Done "$id installed"
        } catch {
            Write-Warn "Failed to install $id`: $_"
            $failed += $id
        }
    }
    if ($failed.Count -gt 0) {
        Write-Warn "Some packages failed to install: $($failed -join ', ')"
        Write-Warn "Check the exact ID with 'winget search <name>' and retry manually."
    }
}

# ---------------------------------------------------------------------------
# Step 4: system preferences (mirrors system/preferences.nix)
# ---------------------------------------------------------------------------
Write-Step "System preferences (keyboard speed, dark theme, file extensions)"

$prefsChanged = $false

function Set-PrefValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")

    $current = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ("$current" -eq "$Value") {
        Write-Done "$Path\$Name already $Value"
        return $false
    }

    if ($DryRun) {
        Write-DryRun "would set $Path\$Name = $Value (was $current)"
        return $false
    }

    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    Write-Done "set $Path\$Name = $Value"
    return $true
}

# Keyboard: max repeat speed, shortest delay
$prefsChanged = (Set-PrefValue "HKCU:\Control Panel\Keyboard" "KeyboardSpeed" 31 "String") -or $prefsChanged
$prefsChanged = (Set-PrefValue "HKCU:\Control Panel\Keyboard" "KeyboardDelay" 0 "String") -or $prefsChanged

# Dark theme (apps + system chrome)
$personalize = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$prefsChanged = (Set-PrefValue $personalize "AppsUseLightTheme" 0) -or $prefsChanged
$prefsChanged = (Set-PrefValue $personalize "SystemUsesLightTheme" 0) -or $prefsChanged

# Show file extensions (mirrors Finder's AppleShowAllExtensions)
$advanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$prefsChanged = (Set-PrefValue $advanced "HideFileExt" 0) -or $prefsChanged

if ($prefsChanged -and -not $DryRun) {
    Write-Info "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

# ---------------------------------------------------------------------------
# Step 4b: clean up ads / suggestions / UI clutter
# ---------------------------------------------------------------------------
Write-Step "Clean up UI - disable ads, suggestions, and clutter"

$cleanupChanged = $false

# Start menu / lock screen / Settings suggestion content (per-user, no admin needed)
$cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$cdmSettings = [ordered]@{
    "SubscribedContent-338388Enabled" = 0  # suggested/promoted apps in Start
    "SubscribedContent-338389Enabled" = 0  # tips/ads in Settings and elsewhere
    "SubscribedContent-353698Enabled" = 0  # Start menu "recommended" suggestions
    "SilentInstalledAppsEnabled"      = 0  # MS silently installing "suggested" apps
    "SystemPaneSuggestionsEnabled"    = 0  # suggestions in Settings system pane
    "PreInstalledAppsEnabled"         = 0
    "OemPreInstalledAppsEnabled"      = 0
    "SoftLandingEnabled"              = 0  # "Suggested" popups after updates
    "RotatingLockScreenOverlayEnabled" = 0 # lock screen tips/fun-facts overlay
}
foreach ($key in $cdmSettings.Keys) {
    $cleanupChanged = (Set-PrefValue $cdm $key $cdmSettings[$key]) -or $cleanupChanged
}

# Explorer/taskbar clutter
$advanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$cleanupChanged = (Set-PrefValue $advanced "Start_IrisRecommendations" 0) -or $cleanupChanged  # Start "recommendations"
$cleanupChanged = (Set-PrefValue $advanced "TaskbarDa" 0) -or $cleanupChanged                  # hide Widgets icon
$cleanupChanged = (Set-PrefValue $advanced "TaskbarMn" 0) -or $cleanupChanged                  # hide Chat icon
$cleanupChanged = (Set-PrefValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "ShowSyncProviderNotifications" 0) -or $cleanupChanged  # OneDrive ad banners

# Taskbar search: icon-only, no Bing/web content in the search box
$cleanupChanged = (Set-PrefValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1) -or $cleanupChanged
$cleanupChanged = (Set-PrefValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0) -or $cleanupChanged

# Machine-wide policy switches (we're elevated, so HKLM works too - more effective
# than the HKCU keys alone, which Microsoft has moved around across releases).
# NOTE: DisableWindowsSpotlightFeatures also turns off Spotlight's rotating desktop
# background, not just its tips/ad overlay - an accepted tradeoff for "no more ads".
$cloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$cloudContentSettings = [ordered]@{
    "DisableWindowsSpotlightFeatures"    = 1
    "DisableThirdPartySuggestions"       = 1
    "DisableConsumerAccountStateContent" = 1
    "DisableCloudOptimizedContent"       = 1
}
foreach ($key in $cloudContentSettings.Keys) {
    $cleanupChanged = (Set-PrefValue $cloudContent $key $cloudContentSettings[$key]) -or $cleanupChanged
}

if ($cleanupChanged -and -not $DryRun) {
    Write-Info "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

# ---------------------------------------------------------------------------
# Step 4c: remove bloatware (conservative list - no essential utilities)
# ---------------------------------------------------------------------------
Write-Step "Remove bloatware apps"

# Exact first-party app names, plus wildcard patterns for the preinstalled
# "junk tile" placeholders (Candy Crush, Facebook, etc.) that reappear for
# every new user profile unless the provisioned package is removed too.
$bloatPatterns = @(
    "Microsoft.MicrosoftSolitaireCollection"  # has ads
    "Microsoft.BingWeather"
    "Microsoft.BingNews"
    "Microsoft.MicrosoftOfficeHub"            # Office upsell/ads tile
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"                    # "Tips" - itself ad content
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MixedReality.Portal"
    "Microsoft.SkypeApp"                      # legacy Skype
    "Microsoft.549981C3F5F10"                 # Cortana
    "Clipchamp.Clipchamp"
    "*CandyCrush*"
    "*BubbleWitch*"
    "*king.com*"
    "*Facebook*"
    "*Disney*"
    "*TikTok*"
    "*Spotify*"                               # preinstalled placeholder tile, not the real app (installed separately via winget)
)

foreach ($pattern in $bloatPatterns) {
    # -AllUsers requires admin; DryRun may run unelevated, so fall back to a
    # current-user-only (still useful) preview in that case.
    try {
        if ($DryRun) {
            $installed = Get-AppxPackage -Name $pattern -ErrorAction Stop
        } else {
            $installed = Get-AppxPackage -AllUsers -Name $pattern -ErrorAction Stop
        }
    } catch {
        $installed = @()
    }
    try {
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $_.DisplayName -like $pattern }
    } catch {
        $provisioned = @()
    }

    if (-not $installed -and -not $provisioned) {
        continue
    }

    if ($DryRun) {
        (@($installed) + @($provisioned)) | ForEach-Object {
            $name = if ($_.Name) { $_.Name } else { $_.DisplayName }
            Write-DryRun "would remove $name"
        }
        continue
    }

    foreach ($pkg in $installed) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Done "removed $($pkg.Name)"
        } catch {
            Write-Warn "couldn't remove $($pkg.Name): $_"
        }
    }
    foreach ($pkg in $provisioned) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
            Write-Done "de-provisioned $($pkg.DisplayName) (won't reinstall for new users)"
        } catch {
            Write-Warn "couldn't de-provision $($pkg.DisplayName): $_"
        }
    }
}

# ---------------------------------------------------------------------------
# Step 5: WezTerm config (mirrors home/programs/terminal/wezterm.nix)
# ---------------------------------------------------------------------------
Write-Step "WezTerm config"

$weztermDir = Join-Path $env:USERPROFILE ".config\wezterm"
$weztermConfig = Join-Path $weztermDir "wezterm.lua"

$weztermLua = @"
-- Managed by windows/bootstrap.ps1 in marmos91/dotfiles - re-run the script to refresh.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Theme
config.color_scheme = "Catppuccin Mocha"

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 13

-- Window
config.initial_cols = 140
config.initial_rows = 40
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }
config.window_close_confirmation = "NeverPrompt"
config.hide_tab_bar_if_only_one_tab = true

-- Mouse / cursor
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 10000
config.default_cursor_style = "SteadyBlock"

-- Windows: launch straight into WSL2
config.default_domain = "WSL:$Distro"
config.window_decorations = "TITLE|RESIZE"

-- Keybindings (matching ghostty/kitty)
config.keys = {
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
  { key = "[", mods = "CTRL", action = wezterm.action.SendString("\x1b") },
}

return config
"@

if ($DryRun) {
    Write-DryRun "would write $weztermConfig"
} else {
    if (-not (Test-Path $weztermDir)) { New-Item -Path $weztermDir -ItemType Directory -Force | Out-Null }
    Set-Content -Path $weztermConfig -Value $weztermLua -Encoding UTF8
    Write-Done "wrote $weztermConfig"
}

# ---------------------------------------------------------------------------
# Step 6: taskbar pins (best-effort - mirrors system/preferences.nix Dock persistent-apps)
# ---------------------------------------------------------------------------
Write-Step "Taskbar pins (best-effort - Microsoft doesn't officially support scripting this)"

function Find-StartMenuShortcut([string]$NameLike) {
    $roots = @(
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs"
    )
    foreach ($root in $roots) {
        if (Test-Path $root) {
            $hit = Get-ChildItem -Path $root -Filter "*$NameLike*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }
    return $null
}

# Mirrors macOS Dock's persistent-apps list, mapped to Windows equivalents
$pinNames = @("WezTerm", "1Password", "Slack", "WhatsApp", "Telegram", "Spotify", "Chrome")
$pinPaths = @()
foreach ($name in $pinNames) {
    $path = Find-StartMenuShortcut $name
    if ($path) {
        $pinPaths += $path
        Write-Info "found shortcut for $name"
    } else {
        Write-Warn "no Start Menu shortcut found for $name - skipping pin (install it first, or pin manually)"
    }
}

if ($pinPaths.Count -eq 0) {
    Write-Warn "no shortcuts found - skipping taskbar layout"
} elseif ($DryRun) {
    Write-DryRun "would pin: $($pinPaths -join ', ')"
} else {
    $entries = ($pinPaths | ForEach-Object {
        "        <taskbar:DesktopApp DesktopApplicationLinkPath=`"$_`"/>"
    }) -join "`n"

    $layoutXml = @"
<LayoutModificationTemplate xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
$entries
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@

    $layoutPath = Join-Path $env:TEMP "dotfiles-taskbar-layout.xml"
    Set-Content -Path $layoutPath -Value $layoutXml -Encoding UTF8
    try {
        Import-StartLayout -LayoutPath $layoutPath -MountPath "C:\"
        Write-Done "applied taskbar layout (sign out/in if pins don't show up immediately)"
    } catch {
        Write-Warn "Import-StartLayout failed ($_) - this API is inconsistently supported across Windows 11 builds."
        Write-Warn "Pin manually instead: right-click each app -> Pin to taskbar."
    }
}

# ---------------------------------------------------------------------------
# Final checklist
# ---------------------------------------------------------------------------
Write-Step "Manual steps (can't be scripted - need interactive login)"
Write-Host @"
    1. Open 1Password, sign in.
    2. Settings -> Developer -> enable "Use the SSH agent" and check
       "Integrate with 1Password CLI" / WSL for the '$Distro' distro.
    3. Verify from inside WSL:  wsl -d $Distro -- ssh-add.exe -l
    4. Restart your terminal / sign out and back in.
"@ -ForegroundColor White

Write-Host "`nDone.$(if ($DryRun) { ' (dry run - nothing was changed)' })" -ForegroundColor Magenta
