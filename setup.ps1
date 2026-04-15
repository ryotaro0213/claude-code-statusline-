# Claude Code Status Line - Setup Script (Windows PowerShell)
# Displays token usage, context window, and rate limit info in the status bar.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SettingsFile = Join-Path $ClaudeDir "settings.json"

Write-Host "=== Claude Code Status Line Setup ===" -ForegroundColor Cyan
Write-Host ""

# Detect runtime
$Runtime = $null
$Command = $null

if (Get-Command node -ErrorAction SilentlyContinue) {
    $Runtime = "node"
    $Command = "node ~/.claude/statusline.mjs"
    $ver = & node --version
    Write-Host "[OK] Node.js detected: $ver" -ForegroundColor Green
}
elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $Runtime = "python"
    $Command = "python ~/.claude/statusline.py"
    $ver = & python --version 2>&1
    Write-Host "[OK] Python detected: $ver" -ForegroundColor Green
}
elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $Runtime = "python3"
    $Command = "python3 ~/.claude/statusline.py"
    $ver = & python3 --version 2>&1
    Write-Host "[OK] Python3 detected: $ver" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Node.js or Python3 required." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Ensure ~/.claude exists
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# Copy scripts
Copy-Item (Join-Path $ScriptDir "statusline.mjs") (Join-Path $ClaudeDir "statusline.mjs") -Force
Copy-Item (Join-Path $ScriptDir "statusline.py")  (Join-Path $ClaudeDir "statusline.py") -Force
Copy-Item (Join-Path $ScriptDir "statusline.bat") (Join-Path $ClaudeDir "statusline.bat") -Force
Write-Host "[OK] Scripts copied to $ClaudeDir" -ForegroundColor Green

# Update settings.json
if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    $statusLineValue = [PSCustomObject]@{
        type    = "command"
        command = $Command
    }
    if ($settings.PSObject.Properties.Name -contains "statusLine") {
        $settings.statusLine = $statusLineValue
    }
    else {
        $settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $statusLineValue -Force
    }
    $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
    Write-Host "[OK] settings.json updated" -ForegroundColor Green
}
else {
    $newSettings = @{
        statusLine = @{
            type    = "command"
            command = $Command
        }
    }
    $newSettings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
    Write-Host "[OK] settings.json created" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Restart Claude Code to see token usage in the status line."
Write-Host "Runtime: $Runtime ($Command)"
