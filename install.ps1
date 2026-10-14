# auto-model mod installer for Windows (Windows PowerShell 5.1 or PowerShell 7).
# 1) Downloads the three mod/ files into %USERPROFILE%\.claude\mods\auto-model
# 2) Adds that folder to env.CLAUDE_CODE_PLUGIN_DIRS in %USERPROFILE%\.claude\settings.json
#    (the previous settings.json is kept as settings.json.bak).
# Set $env:AUTO_MODEL_REF to install from another branch or tag (default: main).
# Messages stay ASCII so Windows PowerShell 5.1 reads this file correctly without a BOM.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$claude = Join-Path $env:USERPROFILE '.claude'
$dir = Join-Path $claude 'mods\auto-model'
$settings = Join-Path $claude 'settings.json'
$ref = if ($env:AUTO_MODEL_REF) { $env:AUTO_MODEL_REF } else { 'main' }
$base = "https://raw.githubusercontent.com/yeopjoonhyun/claude-auto-model/$ref/mod"

foreach ($f in '.claude-plugin/plugin.json', 'hooks/hooks.json', 'hooks/register.ts') {
  $out = Join-Path $dir $f
  New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
  Invoke-WebRequest -UseBasicParsing "$base/$f" -OutFile $out
}

$data = [pscustomobject]@{}
if (Test-Path $settings) {
  Copy-Item $settings "$settings.bak" -Force
  $text = [IO.File]::ReadAllText($settings)
  if ($text.Trim()) { $data = $text | ConvertFrom-Json }
}
if (-not $data.PSObject.Properties['env']) { $data | Add-Member env ([pscustomobject]@{}) }

$current = @("$($data.env.CLAUDE_CODE_PLUGIN_DIRS)" -split ';' | Where-Object { $_ })
if ($current -notcontains $dir) { $current += $dir }
$data.env | Add-Member -Force CLAUDE_CODE_PLUGIN_DIRS ($current -join ';')

$json = $data | ConvertTo-Json -Depth 100
[IO.File]::WriteAllText($settings, $json + "`n", (New-Object Text.UTF8Encoding $false))

Write-Host "Installed: $dir"
Write-Host "Auto model switching is on from the next Claude Code session. To turn it off: /auto-model off"
