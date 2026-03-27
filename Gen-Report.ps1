param(
  [string]$SummaryPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot 'outputs') 'logs') 'rag_converter_summary.txt'),
  [string]$LogPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot 'outputs') 'logs') 'rag_converter_log.txt'),
  [string]$QaPath = (Join-Path (Join-Path (Join-Path $PSScriptRoot 'outputs') 'logs') 'rag_converter_qa_log.txt'),
  [string]$OutputPath,
  [string]$Cliente = 'Cliente no especificado',
  [string]$Firmante = 'Innovation Practitioner & AI Agent Architect',
  [string]$Proyecto = 'Conversión de Activos a Inteligencia RAG',
  [ValidateSet('comercial','tecnico')]
  [string]$Modo = 'tecnico'
)

$ErrorActionPreference = 'Stop'

function Parse-KeyValueFile([string]$Path) {
  $map = @{}
  if (-not (Test-Path -LiteralPath $Path)) { return $map }
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.Trim().StartsWith('#')) { continue }
    $idx = $line.IndexOf('=')
    if ($idx -lt 1) { continue }
    $k = $line.Substring(0, $idx).Trim()
    $v = $line.Substring($idx + 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($k)) { $map[$k] = $v }
  }
  return $map
}

function Parse-DurationFromLog([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $timestamps = New-Object System.Collections.Generic.List[datetime]
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
    $m = [regex]::Match($line, '^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\]')
    if ($m.Success) {
      try {
        $dt = [datetime]::ParseExact($m.Groups[1].Value, 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
        $timestamps.Add($dt)
      } catch {}
    }
  }
  if ($timestamps.Count -lt 2) { return $null }
  $min = ($timestamps | Measure-Object -Minimum).Minimum
  $max = ($timestamps | Measure-Object -Maximum).Maximum
  return ($max - $min)
}

function Get-OrDefault($Map, [string]$Key, [string]$DefaultValue = 'N/D') {
  if ($Map.ContainsKey($Key) -and -not [string]::IsNullOrWhiteSpace([string]$Map[$Key])) { return [string]$Map[$Key] }
  return $DefaultValue
}

function To-Int([string]$Text, [int]$DefaultValue = 0) {
  $n = 0
  if ([int]::TryParse($Text, [ref]$n)) { return $n }
  return $DefaultValue
}

function Read-QA([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  $raw = Get-Content -LiteralPath $Path -Encoding UTF8
  return @($raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Ensure-ParentDirectory([string]$FilePath) {
  if ([string]::IsNullOrWhiteSpace($FilePath)) { return }
  $dir = Split-Path -Parent $FilePath
  if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

$summary = Parse-KeyValueFile $SummaryPath
$duration = Parse-DurationFromLog $LogPath
$qaLines = Read-QA $QaPath

$status = Get-OrDefault $summary 'STATUS'
$files = To-Int (Get-OrDefault $summary 'FILES' '0')
$visionItems = To-Int (Get-OrDefault $summary 'VISION_ITEMS' '0')
$visionSuccess = To-Int (Get-OrDefault $summary 'VISION_SUCCESS' '0')
$visionPending = To-Int (Get-OrDefault $summary 'VISION_PENDING' '0')
$visionErrors = To-Int (Get-OrDefault $summary 'VISION_API_ERRORS' '0')
$model = Get-OrDefault $summary 'VISION_MODEL'
$profile = Get-OrDefault $summary 'PROFILE'

$durationText = if ($null -eq $duration) {
  'N/D'
} else {
  ('{0:N0} s ({1:N2} min)' -f $duration.TotalSeconds, $duration.TotalMinutes)
}

$ocrTotalFixes = 0
foreach ($k in $summary.Keys) {
  if ($k -like 'OCR_*') {
    $n = To-Int ([string]$summary[$k]) 0
    $ocrTotalFixes += $n
  }
}

$qaText = ($qaLines -join "`n")
$hasNoToc = $qaText -match 'NO_TOC'
$hasNoAnchor = $qaText -match 'NO_ANCHOR'
$hasResidualOCR = $qaText -match 'RESIDUAL_OCR'
$hasQaIssues = $qaLines.Count -gt 0

$ptsIntegridad = if ($status -eq 'NORM_OK') { 30.0 } elseif ($status -eq 'NORM_WITH_ERRORS') { 15.0 } else { 0.0 }
$esTextoPuro = $false
if ($visionItems -gt 0) {
  $ratioVision = [math]::Min(1.0, [math]::Max(0.0, ($visionSuccess / [double]$visionItems)))
  $ptsSemantica = [math]::Round($ratioVision * 40.0, 2)
} else {
  $ratioVision = $null
  $ptsSemantica = 40.0
  $esTextoPuro = $true
}

if ($hasResidualOCR) {
  $ptsNormalizacion = 5.0
} elseif ($status -eq 'NORM_OK') {
  $ptsNormalizacion = 20.0
} else {
  $ptsNormalizacion = 10.0
}

if ($status -eq 'NORM_OK' -and -not $hasNoToc -and -not $hasNoAnchor) {
  $ptsCitacion = 10.0
} elseif ($status -eq 'NORM_OK') {
  $ptsCitacion = 7.0
} elseif ($status -eq 'NORM_WITH_ERRORS') {
  $ptsCitacion = 5.0
} else {
  $ptsCitacion = 0.0
}

$dhi = [math]::Round($ptsIntegridad + $ptsSemantica + $ptsNormalizacion + $ptsCitacion, 2)
if ($dhi -gt 100) { $dhi = 100.0 }
if ($dhi -lt 0) { $dhi = 0.0 }

if ($dhi -ge 90) {
  $grado = 'WORLD CLASS'
} elseif ($dhi -ge 80) {
  $grado = 'ENTERPRISE READY'
} elseif ($dhi -ge 65) {
  $grado = 'ACCEPTABLE'
} else {
  $grado = 'NEEDS IMPROVEMENT'
}

$hoy = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$modoLabel = if ($Modo -eq 'comercial') { 'Comercial' } else { 'Tecnico' }
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $reportsRoot = Join-Path (Join-Path $PSScriptRoot 'outputs') 'reports'
  $OutputPath = Join-Path $reportsRoot ('RAG_Certificacion_' + $modoLabel + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.md')
}

$md = @()
if ($Modo -eq 'comercial') {
  $md += '# 🏆 Informe Ejecutivo: Activos Digitales RAG-Ready'
  $md += ''
  $md += '- Cliente: ' + $Cliente
  $md += '- Fecha de Proceso: ' + $hoy
  $md += '- Estado del Lote: `STATUS=' + $status + '`'
  $md += '- DHI SCORE: **' + $dhi + ' / 100**'
  $md += '- RATING: **' + $grado + '**'
  $md += '- Motor de Visión: `' + $model + '`'
  $md += ''
  $md += '## 1. Resumen Ejecutivo'
  $md += 'Se certifica la conversión de activos documentales a formato RAG-Ready, con trazabilidad y control operativo.'
  $md += ''
  $md += '- Archivos procesados: **' + $files + '**'
  $md += '- Imágenes analizadas con éxito: **' + $visionSuccess + ' / ' + $visionItems + '**'
  $md += '- Tiempo de procesamiento: **' + $durationText + '**'
  $md += ''
  $md += '## 2. Certificación de Salud del Dato (DHI)'
  $md += '| Pilar | Puntos | Estado |'
  $md += '| :--- | :---: | :--- |'
  $md += '| Integridad estructural | **' + $ptsIntegridad + ' / 30** | ' + $(if ($ptsIntegridad -ge 30) { 'Óptima' } else { 'Revisable' }) + ' |'
  $md += '| Densidad semántica enriquecida | **' + $ptsSemantica + ' / 40** | ' + $(if ($esTextoPuro) { 'Texto puro (sin imágenes)' } else { 'Visión activa' }) + ' |'
  $md += '| Normalización OCR | **' + $ptsNormalizacion + ' / 20** | ' + $(if ($hasResidualOCR) { 'Con residuos detectados' } else { 'Sin residuos reportados' }) + ' |'
  $md += '| Citación RAG-Ready | **' + $ptsCitacion + ' / 10** | ' + $(if ($hasNoToc -or $hasNoAnchor) { 'Anclajes/TOC revisables' } else { 'Trazabilidad activa' }) + ' |'
  $md += ''
  $md += '## 3. Indicadores de Calidad'
  $md += '- Integridad del lote: **' + $status + '**'
  $md += '- Pendientes de visión: **' + $visionPending + '**'
  $md += '- Errores de API de visión: **' + $visionErrors + '**'
  $md += '- Correcciones OCR aplicadas: **' + $ocrTotalFixes + '**'
  $md += '- Incidencias QA reportadas: **' + $qaLines.Count + '**'
  $md += ''
  $md += '## 4. Valor para IA/RAG'
  $md += '- Estructura Markdown jerárquica con índice y anclajes'
  $md += '- Enriquecimiento de imágenes con OCR + análisis espacial + valor pedagógico'
  $md += '- Configuración escalable por cliente mediante `.env.<cliente>.<entorno>`'
  $md += ''
  $md += '## 5. Evidencia y Auditoría'
  $md += '- Evidencia de ejecución: `rag_converter_summary.txt`'
  $md += '- Evidencia técnica: `rag_converter_log.txt`'
  $md += '- Evidencia QA: `rag_converter_qa_log.txt`'
  $md += '- Nota metodológica: el DHI usa métricas observables, sin inferencias de rendimiento no medidas.'
} else {
  $md += '# 🧪 Informe Técnico de Auditoría: Conversión de Activos a RAG'
  $md += ''
  $md += '- Cliente: ' + $Cliente
  $md += '- Fecha de Proceso: ' + $hoy
  $md += '- Estado del Lote: `STATUS=' + $status + '`'
  $md += '- Perfil de Ejecución: `' + $profile + '`'
  $md += ''
  $md += '## 1. Métricas de Ingestión'
  $md += '- FILES=' + [string]$files
  $md += '- VISION_ITEMS=' + [string]$visionItems
  $md += '- VISION_SUCCESS=' + [string]$visionSuccess
  $md += '- VISION_PENDING=' + [string]$visionPending
  $md += '- VISION_API_ERRORS=' + [string]$visionErrors
  $md += '- VISION_MODEL=' + $model
  $md += '- DURATION=' + $durationText
  $md += ''
  $md += '## 2. DHI Forense'
  $md += '- DHI=' + [string]$dhi
  $md += '- DHI_GRADE=' + $grado
  $md += '- DHI_INTEGRIDAD=' + [string]$ptsIntegridad + '/30'
  $md += '- DHI_SEMANTICA=' + [string]$ptsSemantica + '/40'
  $md += '- DHI_NORMALIZACION=' + [string]$ptsNormalizacion + '/20'
  $md += '- DHI_CITACION=' + [string]$ptsCitacion + '/10'
  $md += '- DHI_TEXTO_PURO=' + [string]$esTextoPuro
  $md += ''
  $md += '## 3. Métricas de Calidad'
  $md += '- STATUS=' + $status
  $md += '- OCR_FIXES_TOTAL=' + [string]$ocrTotalFixes
  $md += '- QA_ISSUES=' + [string]$qaLines.Count
  $md += '- QA_HAS_NO_TOC=' + [string]$hasNoToc
  $md += '- QA_HAS_NO_ANCHOR=' + [string]$hasNoAnchor
  $md += '- QA_HAS_RESIDUAL_OCR=' + [string]$hasResidualOCR
  $md += '- SOURCE_SUMMARY=' + $SummaryPath
  $md += '- SOURCE_LOG=' + $LogPath
  $md += '- SOURCE_QA=' + $QaPath
  $md += ''
  $md += '## 4. Validación Operativa'
  $md += '- Recomendación: validar `STATUS=NORM_OK` antes de certificación final.'
  $md += '- Si `VISION_PENDING > 0`, revisar cola de análisis visual.'
  $md += '- Si `VISION_API_ERRORS > 0`, revisar conectividad, cuota y modelo.'
}
$md += ''
$md += '---'
$md += 'Firma: ' + $Firmante
$md += 'Proyecto: ' + $Proyecto
$md += 'Modo de informe: ' + $modoLabel

Ensure-ParentDirectory $OutputPath
[System.IO.File]::WriteAllLines($OutputPath, $md, [System.Text.Encoding]::UTF8)
Write-Host "Informe generado: $OutputPath (DHI=$dhi, GRADE=$grado)" -ForegroundColor Green
