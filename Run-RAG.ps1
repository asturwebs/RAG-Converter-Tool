param(
  [string]$Target,
  [string]$EnvFile,
  [string]$Model,
  [switch]$Reprocess,
  [switch]$FailFast,
  [switch]$Preflight
)

$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptRoot) -and $PSCommandPath) {
  $ScriptRoot = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) {
  $ScriptRoot = (Get-Location).Path
}

function Normalize-Bool([string]$Text, [bool]$DefaultValue) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return $DefaultValue }
  $v = $Text.Trim().ToLowerInvariant()
  if ($v -in @('1','true','yes','y','on')) { return $true }
  if ($v -in @('0','false','no','n','off')) { return $false }
  return $DefaultValue
}

function Strip-Quotes([string]$Text) {
  if ($null -eq $Text) { return $null }
  $v = $Text.Trim()
  if ($v.Length -ge 2 -and (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'")))) {
    return $v.Substring(1, $v.Length - 2)
  }
  return $v
}

function Load-DotEnv([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.Trim().StartsWith('#')) { continue }
    $m = [regex]::Match($line, '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$')
    if (-not $m.Success) { continue }
    $name = $m.Groups[1].Value
    $value = Strip-Quotes $m.Groups[2].Value
    $existing = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($existing)) {
      [Environment]::SetEnvironmentVariable($name, $value)
    }
  }
}

$envFileFinal = if (-not [string]::IsNullOrWhiteSpace($EnvFile)) {
  $EnvFile
} else {
  $fromEnv = [Environment]::GetEnvironmentVariable('RAG_ENV_FILE')
  if ([string]::IsNullOrWhiteSpace($fromEnv)) { '.env' } else { $fromEnv.Trim() }
}

$dotenvPath = if ([IO.Path]::IsPathRooted($envFileFinal)) {
  $envFileFinal
} else {
  Join-Path $ScriptRoot $envFileFinal
}

if (-not (Test-Path -LiteralPath $dotenvPath)) {
  throw "No existe archivo de entorno: $dotenvPath"
}

Load-DotEnv $dotenvPath

$apiKey = [Environment]::GetEnvironmentVariable('OPENROUTER_API_KEY')
if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw "Falta OPENROUTER_API_KEY. Revisa $dotenvPath"
}

$modelFinal = if (-not [string]::IsNullOrWhiteSpace($Model)) {
  $Model.Trim()
} else {
  $m = [Environment]::GetEnvironmentVariable('RAG_OPENROUTER_MODEL')
  if ([string]::IsNullOrWhiteSpace($m)) { 'google/gemini-3.1-flash-lite-preview' } else { $m.Trim() }
}

$defaultFailFast = Normalize-Bool ([Environment]::GetEnvironmentVariable('RAG_FAIL_FAST') ) $false
$defaultPreflight = Normalize-Bool ([Environment]::GetEnvironmentVariable('RAG_ENABLE_PREFLIGHT') ) $false
$defaultReprocess = Normalize-Bool ([Environment]::GetEnvironmentVariable('RAG_FORCE_REPROCESS') ) $false

$failFastFinal = if ($FailFast.IsPresent) { $true } else { $defaultFailFast }
$preflightFinal = if ($Preflight.IsPresent) { $true } else { $defaultPreflight }
$reprocessFinal = if ($Reprocess.IsPresent) { $true } else { $defaultReprocess }

$converterPath = Join-Path $ScriptRoot 'Convert-OfficeToRAG.ps1'
if (-not (Test-Path -LiteralPath $converterPath)) {
  throw "No existe Convert-OfficeToRAG.ps1 en $ScriptRoot"
}

$invokeArgs = @{
  FailFastOverride = $failFastFinal
  EnablePreflightOverride = $preflightFinal
  ForceReprocessOverride = $reprocessFinal
  OpenRouterModelOverride = $modelFinal
}

if (-not [string]::IsNullOrWhiteSpace($Target)) {
  $resolvedTarget = if ([IO.Path]::IsPathRooted($Target)) { $Target } else { [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Target)) }
  if (Test-Path -LiteralPath $resolvedTarget -PathType Leaf) {
    $invokeArgs.SourceFilesOverride = @($resolvedTarget)
  } elseif (Test-Path -LiteralPath $resolvedTarget -PathType Container) {
    $invokeArgs.SourceFoldersOverride = @($resolvedTarget)
  } else {
    throw "Target no existe: $Target"
  }
}

Write-Host "Modelo: $modelFinal" -ForegroundColor Cyan
Write-Host "EnvFile: $dotenvPath" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($Target)) { Write-Host "Target: $Target" -ForegroundColor Cyan }
Write-Host "FailFast: $failFastFinal | Preflight: $preflightFinal | Reprocess: $reprocessFinal" -ForegroundColor Cyan

& $converterPath @invokeArgs
