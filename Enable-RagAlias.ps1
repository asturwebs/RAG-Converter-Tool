param(
  [switch]$Persist
)

$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptRoot) -and $PSCommandPath) {
  $ScriptRoot = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) {
  $ScriptRoot = (Get-Location).Path
}

$runner = Join-Path $ScriptRoot 'Run-RAG.ps1'
if (-not (Test-Path -LiteralPath $runner)) {
  throw "No existe Run-RAG.ps1 en $ScriptRoot"
}

function global:rag-report {
  param(
    [ValidateSet('comercial','tecnico')]
    [string]$Modo = 'comercial',
    [string]$Cliente = 'Cliente no especificado',
    [string]$Firmante = 'Innovation Practitioner & AI Agent Architect',
    [string]$OutputPath
  )
  $gen = Join-Path $ScriptRoot 'Gen-Report.ps1'
  if (-not (Test-Path -LiteralPath $gen)) { throw "No existe Gen-Report.ps1 en $ScriptRoot" }
  if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    & $gen -Cliente $Cliente -Firmante $Firmante -Modo $Modo
  } else {
    & $gen -Cliente $Cliente -Firmante $Firmante -Modo $Modo -OutputPath $OutputPath
  }
}

Set-Alias -Name rag -Value $runner -Scope Global
Set-Alias -Name rr -Value $runner -Scope Global

Write-Host 'Alias cargados en esta sesión:' -ForegroundColor Green
Write-Host '  rag  -> Run-RAG.ps1' -ForegroundColor Green
Write-Host '  rr   -> Run-RAG.ps1' -ForegroundColor Green
Write-Host '  rag-report -> Gen-Report.ps1' -ForegroundColor Green

if ($Persist) {
  if (-not (Test-Path -LiteralPath $PROFILE)) {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -LiteralPath $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
  }
  $line = ". '" + (Join-Path $ScriptRoot 'Enable-RagAlias.ps1') + "'"
  $existing = Get-Content -LiteralPath $PROFILE -ErrorAction SilentlyContinue
  if ($existing -notcontains $line) {
    Add-Content -LiteralPath $PROFILE -Value $line
    Write-Host "Persistido en perfil: $PROFILE" -ForegroundColor Cyan
  } else {
    Write-Host "Ya estaba persistido en: $PROFILE" -ForegroundColor Cyan
  }
}
