# Install the bim-ai-architect skill for Claude Code.
#   .\install.ps1            -> %USERPROFILE%\.claude\skills\bim-ai-architect   (every project)
#   .\install.ps1 -Project   -> .\.claude\skills\bim-ai-architect               (current directory only)
# Works on Windows PowerShell 5.1 and PowerShell 7.

param([switch]$Project)

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'plugins\bim-ai-architect\skills\bim-ai-architect'

if (-not (Test-Path (Join-Path $src 'SKILL.md'))) {
    Write-Error "Skill not found at $src"
    exit 1
}

if ($Project) {
    $dstRoot = Join-Path (Get-Location).Path '.claude\skills'
}
elseif ($env:CLAUDE_CONFIG_DIR) {
    $dstRoot = Join-Path $env:CLAUDE_CONFIG_DIR 'skills'
}
else {
    $dstRoot = Join-Path $env:USERPROFILE '.claude\skills'
}
$dst = Join-Path $dstRoot 'bim-ai-architect'

foreach ($f in (Get-ChildItem $src -Recurse -File)) {
    $rel = $f.FullName.Substring($src.Length).TrimStart('\')
    $target = Join-Path $dst $rel
    $dir = Split-Path $target -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item $f.FullName $target -Force
}

Write-Host "Installed bim-ai-architect to $dst"
Write-Host "Start a new Claude Code session and type /bim-ai-architect, or just describe the BIM AI app you want to build."
