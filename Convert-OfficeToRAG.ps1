param(
  [string[]]$SourceFoldersOverride,
  [string[]]$SourceFilesOverride,
  [Nullable[bool]]$ForceReprocessOverride,
  [Nullable[bool]]$FailFastOverride,
  [Nullable[bool]]$EnablePreflightOverride,
  [string]$OpenRouterModelOverride
)

$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptRoot) -and $PSCommandPath) {
  $ScriptRoot = Split-Path -Parent $PSCommandPath
}
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) {
  $ScriptRoot = (Get-Location).Path
}
$ProjectRoot = Split-Path -Parent $ScriptRoot
$OutputsRoot = Join-Path $ScriptRoot 'outputs'
$LogsRoot = Join-Path $OutputsRoot 'logs'

$Config = [ordered]@{
  SourceFolders = @(
    (Join-Path $ProjectRoot 'input')
  )
  SourceFiles = @()
  FileExtensions = @('.doc', '.docx', '.pptx')
  EnableVisionAI = $true
  OpenRouterBaseUrl = 'https://openrouter.ai/api/v1/chat/completions'
  OpenRouterApiKeyEnvVar = 'OPENROUTER_API_KEY'
  OpenRouterModel = 'google/gemini-3.1-flash-lite-preview'
  ClientName = 'default'
  AppProfile = 'default'
  RequireVisionSuccess = $true
  FailFast = $true
  ForceReprocess = $false
  EnablePreflightChecks = $true
  PreflightMode = 'vision'
  PreflightImageUrl = 'https://live.staticflickr.com/3851/14825276609_098cac593d_b.jpg'
  VisionTemperature = 0.1
  VisionMaxTokens = 450
  VisionTimeoutSec = 90
  VisionRetryCount = 2
  VisionRetryDelayMs = 1200
  VisionMaxImageBytes = 7340032
  VisionOutputLanguage = 'es'
  DomainContext = 'el dominio profesional del cliente'
  DomainNoiseFilter = 'detalles visuales irrelevantes, elementos de fondo, decoración, paisaje o descripciones estéticas sin valor técnico'
  DomainTechnicalTerms = 'Mantén precisión terminológica según el contexto documental y evita sustituir términos especializados por sinónimos ambiguos'
  
  VisionPromptSystem = 'Rol: Actúa como un Analista Técnico de Élite y Especialista en Ingestión de Datos para Sistemas RAG. Tu objetivo es convertir esta imagen en conocimiento puro, estructurado y útil para {0}.
Directrices Críticas de Ejecución:
- Prioridad OCR Absoluta: Transcribe cada palabra presente en la imagen. No resumas, no parafrases. Si hay una lista, devuélvela como lista. Si hay una tabla, recréala en formato Markdown.
- Análisis de Diagramas y Esquemas: Si la imagen contiene flechas, números o zonas marcadas, explica su relación técnica. (Ej: "La flecha indica la trayectoria...", "El número 2 señala...").
- Filtro de Ruido Visual (Zero Fluff): Ignora por completo descripciones estéticas o irrelevantes. No menciones {1} a menos que influyan directamente en la materia.
- Precisión Técnica: Sé extremadamente riguroso con la terminología. {2}.'
  VisionPromptUserTemplate = 'Contexto documental: {0}.
Estructura de Salida Obligatoria:
### [NOMBRE_DE_LA_DIAPOSITIVA_O_IMAGEN] (Si aparece texto como título, si no, usa un título descriptivo breve).
**CONTENIDO TEXTUAL (OCR):** [Transcripción literal de todo el texto]. Si no hay texto, pon "Sin texto".
* **ANÁLISIS TÉCNICO ESPACIAL:** [Explicación de la lógica del gráfico, flechas o diagramas].
* **VALOR PEDAGÓGICO:** [Breve nota sobre el concepto central que enseña la imagen].'
  OcrDictionary = [ordered]@{
    'ms'             = 'más'
    'aqu'            = 'aquí'
    'aqui'           = 'aquí'
    'compaero'       = 'compañero'
    'nmero'          = 'número'
    'pblico'         = 'público'
    'caractersticas' = 'características'
    'accin'          = 'acción'
    'est'            = 'está'
  }
  ResidualOcrRegex = '\b(ms|aqu|aqui|compaero|nmero|pblico|caractersticas|accin|est)\b'
  LogPath          = (Join-Path $LogsRoot 'rag_converter_log.txt')
  QaLogPath        = (Join-Path $LogsRoot 'rag_converter_qa_log.txt')
  SummaryPath      = (Join-Path $LogsRoot 'rag_converter_summary.txt')
  Profiles = @{
    'default' = @{
      OpenRouterModel = 'google/gemini-3.1-flash-lite-preview'
      VisionTemperature = 0.1
      VisionMaxTokens = 450
      VisionTimeoutSec = 90
      VisionRetryCount = 2
      VisionRetryDelayMs = 1200
      RequireVisionSuccess = $true
      FailFast = $true
      EnablePreflightChecks = $true
    }
    'staging' = @{
      OpenRouterModel = 'google/gemini-3.1-flash-lite-preview'
      VisionTemperature = 0.0
      VisionMaxTokens = 320
      VisionTimeoutSec = 60
      VisionRetryCount = 1
      VisionRetryDelayMs = 800
      RequireVisionSuccess = $true
      FailFast = $true
      EnablePreflightChecks = $true
    }
    'prod' = @{
      OpenRouterModel = 'google/gemini-3.1-flash-lite-preview'
      VisionTemperature = 0.1
      VisionMaxTokens = 550
      VisionTimeoutSec = 90
      VisionRetryCount = 2
      VisionRetryDelayMs = 1200
      RequireVisionSuccess = $true
      FailFast = $true
      EnablePreflightChecks = $true
    }
  }
}

$ErrorActionPreference = 'Stop'

function Log-Message([string]$Message, [string]$Type = "INFO") {
  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[$timestamp] [$Type] $Message"
  Add-Content -LiteralPath $Script:LogPath -Value $line
}

function Log-Error([string]$Message, [Exception]$Exception = $null) {
  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[$timestamp] [ERROR] $Message"
  if ($Exception) {
    $line += "`n   Exception: $($Exception.Message)`n   StackTrace: $($Exception.StackTrace)"
  }
  Add-Content -LiteralPath $Script:LogPath -Value $line
  Write-Host "  [X] $Message" -ForegroundColor Red
}

function Resolve-PathFlexible([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
  if ([IO.Path]::IsPathRooted($Path)) { return $Path }
  return [IO.Path]::GetFullPath((Join-Path $ScriptRoot $Path))
}

function Ensure-ParentDirectory([string]$FilePath) {
  $parent = [IO.Path]::GetDirectoryName($FilePath)
  if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
}

function Get-SystemAnsiEncoding() {
  return [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage)
}

function Read-TextWithSystemEncoding([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, (Get-SystemAnsiEncoding))
}

function Write-TextUtf8NoBom([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function To-Bool([object]$Value, [bool]$DefaultValue) {
  if ($null -eq $Value) { return $DefaultValue }
  $text = $Value.ToString().Trim()
  if ($text.StartsWith("'") -and $text.EndsWith("'") -and $text.Length -ge 2) { $text = $text.Substring(1, $text.Length - 2).Trim() }
  if ($text.StartsWith('"') -and $text.EndsWith('"') -and $text.Length -ge 2) { $text = $text.Substring(1, $text.Length - 2).Trim() }
  $text = $text.ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
  if ($text -in @('1', 'true', 'yes', 'y', 'on')) { return $true }
  if ($text -in @('0', 'false', 'no', 'n', 'off')) { return $false }
  return $DefaultValue
}

function Get-EnvValue([string]$Name) {
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    $item = Get-Item -Path ('Env:' + $Name) -ErrorAction SilentlyContinue
    if ($item) { $value = [string]$item.Value }
  }
  return $value
}

function Normalize-EnvText([string]$Text) {
  if ($null -eq $Text) { return $null }
  $value = $Text.Trim()
  $changed = $true
  while ($changed -and $value.Length -ge 2) {
    $changed = $false
    if ($value.StartsWith("'") -and $value.EndsWith("'")) {
      $value = $value.Substring(1, $value.Length - 2).Trim()
      $changed = $true
      continue
    }
    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
      $value = $value.Substring(1, $value.Length - 2).Trim()
      $changed = $true
    }
  }
  return $value
}

function Apply-ProfilePreset([hashtable]$Config) {
  $name = if ([string]::IsNullOrWhiteSpace($Config.AppProfile)) { 'default' } else { $Config.AppProfile.Trim().ToLowerInvariant() }
  if (-not $Config.Profiles.ContainsKey($name)) {
    throw 'Perfil no válido: ' + $name + '. Usa: default, staging o prod.'
  }
  $Config.AppProfile = $name
  $profileSettings = $Config.Profiles[$name]
  foreach ($key in $profileSettings.Keys) {
    $isMissing = -not $Config.ContainsKey($key)
    $isNull = -not $isMissing -and ($null -eq $Config[$key])
    $isEmptyString = -not $isMissing -and ($Config[$key] -is [string]) -and [string]::IsNullOrWhiteSpace([string]$Config[$key])
    if ($isMissing -or $isNull -or $isEmptyString) {
      $Config[$key] = $profileSettings[$key]
    }
  }
}

function Apply-EnvironmentOverrides([hashtable]$Config) {
  # 1. First, apply any direct environment variables to override defaults
  $client = Normalize-EnvText (Get-EnvValue 'RAG_CLIENT')
  if (-not [string]::IsNullOrWhiteSpace($client)) { $Config.ClientName = $client.Trim() }

  $enableVision = Normalize-EnvText (Get-EnvValue 'RAG_ENABLE_VISION_AI')
  if (-not [string]::IsNullOrWhiteSpace($enableVision)) { $Config.EnableVisionAI = To-Bool $enableVision $Config.EnableVisionAI }

  $requireVision = Normalize-EnvText (Get-EnvValue 'RAG_REQUIRE_VISION_SUCCESS')
  if (-not [string]::IsNullOrWhiteSpace($requireVision)) { $Config.RequireVisionSuccess = To-Bool $requireVision $Config.RequireVisionSuccess }

  $model = Normalize-EnvText (Get-EnvValue 'RAG_OPENROUTER_MODEL')
  if (-not [string]::IsNullOrWhiteSpace($model)) { $Config.OpenRouterModel = $model.Trim() }

  $failFast = Normalize-EnvText (Get-EnvValue 'RAG_FAIL_FAST')
  if (-not [string]::IsNullOrWhiteSpace($failFast)) { $Config.FailFast = To-Bool $failFast $Config.FailFast }
  
  $forceReprocess = Normalize-EnvText (Get-EnvValue 'RAG_FORCE_REPROCESS')
  if (-not [string]::IsNullOrWhiteSpace($forceReprocess)) { $Config.ForceReprocess = To-Bool $forceReprocess $Config.ForceReprocess }

  $preflight = Normalize-EnvText (Get-EnvValue 'RAG_ENABLE_PREFLIGHT')
  if (-not [string]::IsNullOrWhiteSpace($preflight)) { $Config.EnablePreflightChecks = To-Bool $preflight $Config.EnablePreflightChecks }

  $preflightMode = Normalize-EnvText (Get-EnvValue 'RAG_PREFLIGHT_MODE')
  if (-not [string]::IsNullOrWhiteSpace($preflightMode)) { $Config.PreflightMode = $preflightMode.Trim().ToLowerInvariant() }

  $baseUrl = Normalize-EnvText (Get-EnvValue 'RAG_OPENROUTER_BASE_URL')
  if (-not [string]::IsNullOrWhiteSpace($baseUrl)) { $Config.OpenRouterBaseUrl = $baseUrl.Trim() }

  $apiVar = Normalize-EnvText (Get-EnvValue 'RAG_OPENROUTER_APIKEY_ENV')
  if (-not [string]::IsNullOrWhiteSpace($apiVar)) { $Config.OpenRouterApiKeyEnvVar = $apiVar.Trim() }

  $preflightImage = Normalize-EnvText (Get-EnvValue 'RAG_PREFLIGHT_IMAGE_URL')
  if (-not [string]::IsNullOrWhiteSpace($preflightImage)) { $Config.PreflightImageUrl = $preflightImage.Trim() }

  $sources = Normalize-EnvText (Get-EnvValue 'RAG_SOURCE_FOLDERS')
  if (-not [string]::IsNullOrWhiteSpace($sources)) {
    $parts = [regex]::Split($sources, '[;,]') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($parts.Count -gt 0) { $Config.SourceFolders = @($parts) }
  }

  $sourceFiles = Normalize-EnvText (Get-EnvValue 'RAG_SOURCE_FILES')
  if (-not [string]::IsNullOrWhiteSpace($sourceFiles)) {
    $fileParts = [regex]::Split($sourceFiles, '[;,]') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($fileParts.Count -gt 0) { $Config.SourceFiles = @($fileParts) }
  }

  # 2. Then, apply profile ONLY for things not explicitly overridden by environment variables
  $profile = Normalize-EnvText (Get-EnvValue 'RAG_PROFILE')
  if (-not [string]::IsNullOrWhiteSpace($profile)) { $Config.AppProfile = $profile.Trim() }
  Apply-ProfilePreset $Config
  
  # 3. Final safety re-apply of critical overrides after profile might have messed them up
  if (-not [string]::IsNullOrWhiteSpace($preflight)) { $Config.EnablePreflightChecks = To-Bool $preflight $Config.EnablePreflightChecks }
  if (-not [string]::IsNullOrWhiteSpace($requireVision)) { $Config.RequireVisionSuccess = To-Bool $requireVision $Config.RequireVisionSuccess }
}

function Test-OpenRouterPreflight([hashtable]$Config) {
  if (-not $Config.EnableVisionAI) { return }
  if (-not $Config.RequireVisionSuccess) { return }
  if (-not $Config.EnablePreflightChecks) { return }

  $apiKey = [Environment]::GetEnvironmentVariable($Config.OpenRouterApiKeyEnvVar)
  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'Preflight FALLÓ: falta variable de entorno ' + $Config.OpenRouterApiKeyEnvVar
  }
  if ([string]::IsNullOrWhiteSpace($Config.OpenRouterModel)) {
    throw 'Preflight FALLÓ: OpenRouterModel vacío.'
  }
  if ([string]::IsNullOrWhiteSpace($Config.OpenRouterBaseUrl)) {
    throw 'Preflight FALLÓ: OpenRouterBaseUrl vacío.'
  }
  if ([string]::IsNullOrWhiteSpace($Config.PreflightMode)) { $Config.PreflightMode = 'vision' }
  if ($Config.PreflightMode -notin @('vision', 'text')) {
    throw 'Preflight FALLÓ: PreflightMode inválido (' + $Config.PreflightMode + '). Usa vision o text.'
  }

  $headers = @{
    'Authorization' = 'Bearer ' + $apiKey
    'Content-Type' = 'application/json'
    'HTTP-Referer' = 'https://local-rag-converter'
    'X-Title' = 'RAG Converter Tool'
  }
  $messages = @()
  if ($Config.PreflightMode -eq 'vision') {
    $messages = @(
      @{
        role = 'user'
        content = @(
          @{
            type = 'text'
            text = 'Responde solo OK'
          },
          @{
            type = 'image_url'
            image_url = @{
              url = $Config.PreflightImageUrl
            }
          }
        )
      }
    )
  }
  else {
    $messages = @(
      @{
        role = 'user'
        content = 'Responde solo OK'
      }
    )
  }
  $payload = @{
    model = $Config.OpenRouterModel
    temperature = 0
    max_tokens = 24
    messages = $messages
  } | ConvertTo-Json -Depth 10

  try {
    [void](Invoke-RestMethod -Method Post -Uri $Config.OpenRouterBaseUrl -Headers $headers -Body $payload -TimeoutSec ([Math]::Min([int]$Config.VisionTimeoutSec, 45)))
  }
  catch {
    $msg = ($_.Exception.Message -replace "`r?`n", ' ').Trim()
    $responseBody = ''
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream) {
      try {
        $stream = $_.Exception.Response.GetResponseStream()
        if ($stream) {
          $reader = New-Object System.IO.StreamReader($stream)
          $responseBody = $reader.ReadToEnd()
          $reader.Close()
        }
      }
      catch { }
    }
    if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
      $compactBody = ($responseBody -replace "`r?`n", ' ').Trim()
      if ($Config.PreflightMode -eq 'vision' -and ($msg -match '404' -or $msg -match '400' -or $compactBody -match 'not found' -or $compactBody -match 'does not support')) {
        Write-Host "  [!] Fallo de Preflight Vision detectado. Intentando fallback a text mode..." -ForegroundColor Yellow
        $Config.PreflightMode = 'text'
        Test-OpenRouterPreflight $Config
        return
      }
      throw ('Preflight FALLÓ contra OpenRouter para modelo ' + $Config.OpenRouterModel + ' (mode=' + $Config.PreflightMode + '): ' + $msg + ' | body=' + $compactBody)
    }
    
    if ($Config.PreflightMode -eq 'vision' -and ($msg -match '404' -or $msg -match '400')) {
      Write-Host "  [!] Fallo de Preflight Vision detectado. Intentando fallback a text mode..." -ForegroundColor Yellow
      $Config.PreflightMode = 'text'
      Test-OpenRouterPreflight $Config
      return
    }
    
    throw ('Preflight FALLÓ contra OpenRouter para modelo ' + $Config.OpenRouterModel + ' (mode=' + $Config.PreflightMode + '): ' + $msg)
  }
}

function Get-MimeTypeFromPath([string]$Path) {
  $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
  if ($ext -eq '.png') { return 'image/png' }
  if ($ext -eq '.jpg' -or $ext -eq '.jpeg') { return 'image/jpeg' }
  if ($ext -eq '.gif') { return 'image/gif' }
  if ($ext -eq '.bmp') { return 'image/bmp' }
  if ($ext -eq '.webp') { return 'image/webp' }
  return 'application/octet-stream'
}

function Resolve-HtmlImagePath([string]$HtmlPath, [string]$ImageSrc) {
  if ([string]::IsNullOrWhiteSpace($ImageSrc)) { return $null }
  $src = $ImageSrc.Trim()
  if ($src -match '^(?i)https?://') { return $src }
  if ([IO.Path]::IsPathRooted($src)) { return $src }
  $htmlDir = [IO.Path]::GetDirectoryName($HtmlPath)
  return [IO.Path]::GetFullPath((Join-Path $htmlDir $src))
}

function Convert-ImagePathToDataUrl([string]$ImagePath, [hashtable]$Config) {
  if ([string]::IsNullOrWhiteSpace($ImagePath)) { return $null }
  if ($ImagePath -match '^(?i)https?://') { return $ImagePath }
  if (-not (Test-Path -LiteralPath $ImagePath)) { return $null }
  try {
    $fileInfo = Get-Item -LiteralPath $ImagePath -ErrorAction Stop
    if ($fileInfo.Length -gt [int64]$Config.VisionMaxImageBytes) { return $null }
    $bytes = [System.IO.File]::ReadAllBytes($ImagePath)
    $base64 = [Convert]::ToBase64String($bytes)
    $mime = Get-MimeTypeFromPath $ImagePath
    return 'data:' + $mime + ';base64,' + $base64
  } catch {
    return $null
  }
}

function Extract-AssistantTextFromResponse([object]$Response) {
  if ($null -eq $Response) { return $null }
  if ($null -eq $Response.choices -or $Response.choices.Count -eq 0) { return $null }
  $content = $Response.choices[0].message.content
  if ($null -eq $content) { return $null }
  if ($content -is [string]) { return $content.Trim() }
  $parts = New-Object System.Collections.Generic.List[string]
  foreach ($item in $content) {
    if ($item.type -eq 'text' -and -not [string]::IsNullOrWhiteSpace($item.text)) {
      $parts.Add($item.text.Trim())
    }
  }
  if ($parts.Count -eq 0) { return $null }
  return ($parts -join ' ').Trim()
}

function Analyze-ImageWithVisionAI([string]$ImagePath, [string]$Context, [hashtable]$Config, [hashtable]$RuntimeStats) {
  $fallback = 'ANÁLISIS DE IMAGEN IA_PENDIENTE: No se pudo completar análisis automático.'
  $RuntimeStats.VisionItems++
  if (-not $Config.EnableVisionAI) {
    $RuntimeStats.VisionPending++
    return $fallback
  }
  $apiKey = [Environment]::GetEnvironmentVariable($Config.OpenRouterApiKeyEnvVar)
  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    $RuntimeStats.VisionPending++
    return $fallback + ' Falta variable de entorno ' + $Config.OpenRouterApiKeyEnvVar + '.'
  }
  $dataUrl = Convert-ImagePathToDataUrl $ImagePath $Config
  if ([string]::IsNullOrWhiteSpace($dataUrl)) {
    $RuntimeStats.VisionPending++
    return $fallback + ' Imagen no accesible o excede tamaño máximo.'
  }

  $userPrompt = [string]::Format($Config.VisionPromptUserTemplate, $Context)
  $systemPrompt = [string]::Format($Config.VisionPromptSystem, $Config.DomainContext, $Config.DomainNoiseFilter, $Config.DomainTechnicalTerms)
  $payload = @{
    model = $Config.OpenRouterModel
    temperature = $Config.VisionTemperature
    max_tokens = $Config.VisionMaxTokens
    messages = @(
      @{
        role = 'system'
        content = $systemPrompt
      },
      @{
        role = 'user'
        content = @(
          @{
            type = 'text'
            text = $userPrompt
          },
          @{
            type = 'image_url'
            image_url = @{ url = $dataUrl }
          }
        )
      }
    )
  } | ConvertTo-Json -Depth 10

  $headers = @{
    'Authorization' = 'Bearer ' + $apiKey
    'Content-Type' = 'application/json'
    'HTTP-Referer' = 'https://local-rag-converter'
    'X-Title' = 'RAG Converter Tool'
  }

  $attempt = 0
  while ($attempt -le [int]$Config.VisionRetryCount) {
    try {
      $RuntimeStats.VisionApiCalls++
      $response = Invoke-RestMethod -Method Post -Uri $Config.OpenRouterBaseUrl -Headers $headers -Body $payload -TimeoutSec $Config.VisionTimeoutSec
      $text = Extract-AssistantTextFromResponse $response
      if (-not [string]::IsNullOrWhiteSpace($text)) {
        $RuntimeStats.VisionSuccess++
        return $text
      }
      $RuntimeStats.VisionPending++
      return $fallback + ' Respuesta vacía del modelo.'
    }
    catch {
      if ($attempt -ge [int]$Config.VisionRetryCount) {
        $msg = ($_.Exception.Message -replace "`r?`n", ' ').Trim()
        $RuntimeStats.VisionApiErrors++
        $RuntimeStats.VisionPending++
        return $fallback + ' Error API: ' + $msg
      }
      Start-Sleep -Milliseconds ([int]$Config.VisionRetryDelayMs)
      $attempt++
    }
  }
  $RuntimeStats.VisionPending++
  return $fallback
}

function Build-ImageAnalysisLine([string]$AnalysisText) {
  $lines = $AnalysisText -split "`r?`n"
  $formattedLines = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { "> $_" }
  $result = "> [ANÁLISIS DE IMAGEN IA]:`n" + ($formattedLines -join "`n") + "`n"
  return $result
}

function Clean-Text([string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
  $clean = [regex]::Replace($Text, '(?is)<[^>]+>', ' ')
  $clean = [System.Net.WebUtility]::HtmlDecode($clean)
  $clean = $clean -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ' '
  $clean = $clean -replace '[ \t]+', ' '
  $clean = $clean -replace ' +([,.;:!?])', '$1'
  return $clean.Trim()
}

function Remove-Diacritics([string]$Text) {
  $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
  $builder = New-Object System.Text.StringBuilder
  foreach ($char in $normalized.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$builder.Append($char)
    }
  }
  return $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
}

function Build-TokenMaps([string]$SourceText) {
  $tokens = [regex]::Matches($SourceText, '[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{3,}') | ForEach-Object { $_.Value }
  $frequency = @{}
  foreach ($token in $tokens) {
    if ($frequency.ContainsKey($token)) { $frequency[$token]++ } else { $frequency[$token] = 1 }
  }
  $byNoDiacritics = @{}
  $byDroppedAccentVowels = @{}
  foreach ($token in $frequency.Keys) {
    $k1 = Remove-Diacritics $token
    if (-not $byNoDiacritics.ContainsKey($k1)) { $byNoDiacritics[$k1] = @() }
    $byNoDiacritics[$k1] += $token
    $k2 = ($token -replace '[ÁÉÍÓÚáéíóú]', '')
    if (-not $byDroppedAccentVowels.ContainsKey($k2)) { $byDroppedAccentVowels[$k2] = @() }
    $byDroppedAccentVowels[$k2] += $token
  }
  return @{
    Frequency            = $frequency
    ByNoDiacritics       = $byNoDiacritics
    ByDroppedAccentVowels = $byDroppedAccentVowels
  }
}

function Apply-CaseStyle([string]$SourceWord, [string]$Replacement) {
  if ($SourceWord -cmatch '^[A-ZÁÉÍÓÚÑÜ]+$') { return $Replacement.ToUpper() }
  if ($SourceWord -cmatch '^[A-ZÁÉÍÓÚÑÜ]') { return ($Replacement.Substring(0, 1).ToUpper() + $Replacement.Substring(1)) }
  return $Replacement
}

function Apply-OcrDictionary([string]$Markdown, [hashtable]$Dictionary, [hashtable]$Counters) {
  $result = $Markdown
  foreach ($key in $Dictionary.Keys) {
    $pattern = '\b' + [regex]::Escape($key) + '\b'
    $count = ([regex]::Matches($result, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    if ($count -le 0) { continue }
    if (-not $Counters.ContainsKey($key)) { $Counters[$key] = 0 }
    $Counters[$key] += $count
    $replacement = $Dictionary[$key]
    $result = [regex]::Replace(
      $result,
      $pattern,
      [System.Text.RegularExpressions.MatchEvaluator]{
        param($m)
        Apply-CaseStyle $m.Value $replacement
      },
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }
  return $result
}

function Apply-TokenMapsNormalization([string]$Markdown, [hashtable]$TokenMaps) {
  return [regex]::Replace(
    $Markdown,
    '\b[A-Za-z]{4,}\b',
    [System.Text.RegularExpressions.MatchEvaluator]{
      param($match)
      $word = $match.Value
      if ($word -match '[ÁÉÍÓÚáéíóúÑñ]') { return $word }
      $candidates = @()
      $k1 = Remove-Diacritics $word
      if ($TokenMaps.ByNoDiacritics.ContainsKey($k1)) { $candidates += $TokenMaps.ByNoDiacritics[$k1] }
      if ($TokenMaps.ByDroppedAccentVowels.ContainsKey($word)) { $candidates += $TokenMaps.ByDroppedAccentVowels[$word] }
      $candidates = $candidates | Sort-Object -Unique
      if ($candidates.Count -eq 0) { return $word }
      $best = $candidates | Sort-Object -Descending { $TokenMaps.Frequency[$_] } | Select-Object -First 1
      if (-not $best) { return $word }
      return Apply-CaseStyle $word $best
    }
  )
}

function Convert-HtmlTableToMarkdown([string]$TableHtml) {
  $rows = [regex]::Matches($TableHtml, '(?is)<tr[^>]*>(.*?)</tr>')
  $matrix = @()
  foreach ($row in $rows) {
    $cells = [regex]::Matches($row.Groups[1].Value, '(?is)<t[dh][^>]*>(.*?)</t[dh]>')
    if ($cells.Count -eq 0) { continue }
    $line = @()
    foreach ($cell in $cells) { $line += (Clean-Text $cell.Groups[1].Value) }
    $matrix += ,$line
  }
  if ($matrix.Count -eq 0) { return @() }
  $header = $matrix[0]
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('| ' + ($header -join ' | ') + ' |')
  $lines.Add('| ' + (($header | ForEach-Object { '---' }) -join ' | ') + ' |')
  for ($i = 1; $i -lt $matrix.Count; $i++) {
    $row = $matrix[$i]
    while ($row.Count -lt $header.Count) { $row += ' ' }
    if ($row.Count -gt $header.Count) { $row = $row[0..($header.Count - 1)] }
    $lines.Add('| ' + ($row -join ' | ') + ' |')
  }
  return $lines
}

function Build-TocAndAnchors([string]$Markdown) {
  $md = [regex]::Replace($Markdown, '(?ms)\A# Índice\s.*?(?=^# )', '')
  $md = [regex]::Replace($md, '(?m)^<a id="[^"]+"></a>\s*$', '')
  $lines = $md -split "`r?`n"
  $output = New-Object System.Collections.Generic.List[string]
  $toc = New-Object System.Collections.Generic.List[string]
  $toc.Add('# Índice')
  $toc.Add('')
  $top = 0
  $sub = 0
  foreach ($line in $lines) {
    if ($line -match '^#\s+(.+)$') {
      $top++
      $sub = 0
      $id = 'tema-' + $top
      $title = $Matches[1].Trim()
      $output.Add('<a id="' + $id + '"></a>')
      $output.Add('# ' + $title)
      $toc.Add('- [' + $title + '](#' + $id + ')')
      continue
    }
    if ($line -match '^##\s+(.+)$') {
      $sub++
      $id = 'tema-' + $top + '-ap-' + $sub
      $title = $Matches[1].Trim()
      $output.Add('<a id="' + $id + '"></a>')
      $output.Add('## ' + $title)
      $toc.Add('  - [' + $title + '](#' + $id + ')')
      continue
    }
    $output.Add($line)
  }
  return (($toc -join "`n").TrimEnd() + "`n`n" + ($output -join "`n").Trim() + "`n")
}

function Add-ImageAnalysisBlocks([string]$Markdown, [int]$ImageCount, [string[]]$Contexts, [string]$DocumentName) {
  if ($ImageCount -le 0) { return $Markdown }
  $ctx = $Contexts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  if ($ctx.Count -eq 0) { $ctx = @($DocumentName) }
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('')
  $lines.Add('## Análisis de imágenes y esquemas detectados')
  $lines.Add('')
  for ($i = 1; $i -le $ImageCount; $i++) {
    $reference = $ctx[($i - 1) % $ctx.Count]
    $lines.Add('> [ANÁLISIS DE IMAGEN: Esquema técnico asociado a "' + $reference + '". Debe describir estructura espacial, relaciones entre elementos, flujo de información o proceso, señales visuales clave y secuencia de decisión para resolver la tarea con precisión.]')
    $lines.Add('')
  }
  return ($Markdown.Trim() + "`n`n" + ($lines -join "`n")).Trim() + "`n"
}

function Convert-WordToRagMarkdown([object]$WordApp, [string]$SourcePath, [hashtable]$Config, [hashtable]$Counters, [hashtable]$RuntimeStats) {
  $destination = [IO.Path]::ChangeExtension($SourcePath, '.md')
  $tmpTxt = [IO.Path]::ChangeExtension($destination, '.tmp.utf8.txt')
  $tmpHtml = [IO.Path]::ChangeExtension($destination, '.tmp.html')
  $tmpOpenSource = [IO.Path]::ChangeExtension($destination, '.tmp.open' + [IO.Path]::GetExtension($SourcePath))
  
  # Ensure clean slate for HTML export directory
  $htmlDir = [IO.Path]::ChangeExtension($destination, '.tmp_archivos')
  if (Test-Path -LiteralPath $htmlDir) {
    Remove-Item -LiteralPath $htmlDir -Recurse -Force -ErrorAction SilentlyContinue
  }
  
  try {
    Write-Host "  -> Extrayendo texto e imágenes vía Word COM Object..." -ForegroundColor DarkGray
    Copy-Item -LiteralPath $SourcePath -Destination $tmpOpenSource -Force
    $swOpen = [System.Diagnostics.Stopwatch]::StartNew()
    $doc = $WordApp.Documents.Open($tmpOpenSource, $false, $true, $false)
    $swOpen.Stop()
    Write-Host ("     Word.Open completado en {0:N2}s" -f $swOpen.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    try {
      $sourceText = $doc.Content.Text
      [System.IO.File]::WriteAllText($tmpTxt, $sourceText, (Get-SystemAnsiEncoding))
      $sourceUtf8 = Read-TextWithSystemEncoding $tmpTxt
      $tokenMaps = Build-TokenMaps $sourceUtf8
      $formatHtmlFiltered = 10
      $swSave = [System.Diagnostics.Stopwatch]::StartNew()
      $doc.SaveAs([ref]$tmpHtml, [ref]$formatHtmlFiltered)
      $swSave.Stop()
      Write-Host ("     Word.SaveAs(HTML) completado en {0:N2}s" -f $swSave.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    }
    finally {
      $doc.Close()
    }
  } catch {
    Log-Error "Error procesando DOC/DOCX: $($_.Exception.Message)" $_.Exception
    throw
  }

  Write-Host "  -> Parseando HTML generado..." -ForegroundColor DarkGray
  $htmlRaw = Read-TextWithSystemEncoding $tmpHtml
  $body = [regex]::Match($htmlRaw, '(?is)<body[^>]*>(.*)</body>').Groups[1].Value
  $body = [regex]::Replace($body, '(?is)<(script|style)[^>]*>.*?</\1>', '')
  $imageCount = ([regex]::Matches($body, '(?is)<img\b')).Count
  $nodes = [regex]::Matches($body, '(?is)<table[^>]*>.*?</table>|<h[1-6][^>]*>.*?</h[1-6]>|<p[^>]*>.*?</p>|<li[^>]*>.*?</li>|<img[^>]*>')

  $chunks = New-Object System.Collections.Generic.List[string]
  $contexts = New-Object System.Collections.Generic.List[string]
  $currentParagraph = ""
  $analyzedImageCount = 0

  foreach ($node in $nodes) {
    $tag = $node.Value

    if ($tag -match '(?is)<img\b') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) {
        $chunks.Add($currentParagraph.Trim())
        $currentParagraph = ""
      }
      $ctxName = if ($contexts.Count -gt 0) { $contexts[-1] } else { [IO.Path]::GetFileNameWithoutExtension($SourcePath) }
      $srcMatches = [regex]::Matches($tag, '(?is)\bsrc\s*=\s*["'']([^"'']+)["'']')
      if ($srcMatches.Count -eq 0) {
        $currentImg = $analyzedImageCount + 1
        Write-Host "    [Imagen $currentImg/$imageCount] Solicitando análisis a la IA..." -ForegroundColor DarkGray
        $analysis = Analyze-ImageWithVisionAI $null $ctxName $Config $RuntimeStats
        $chunks.Add('')
        $chunks.Add((Build-ImageAnalysisLine $analysis))
        $chunks.Add('')
        $analyzedImageCount++
      }
      else {
        foreach ($srcMatch in $srcMatches) {
          $imgSrc = $srcMatch.Groups[1].Value.Trim()
          # Fix: Word often encodes spaces in src paths when saving as HTML
          $imgSrc = [System.Uri]::UnescapeDataString($imgSrc)
          $imgPath = Resolve-HtmlImagePath $tmpHtml $imgSrc
          $currentImg = $analyzedImageCount + 1
          Write-Host "    [Imagen $currentImg/$imageCount] Solicitando análisis a la IA..." -ForegroundColor DarkGray
          $analysis = Analyze-ImageWithVisionAI $imgPath $ctxName $Config $RuntimeStats
          $chunks.Add('')
          $chunks.Add((Build-ImageAnalysisLine $analysis))
          $chunks.Add('')
          $analyzedImageCount++
        }
      }
      continue
    }

    if ($tag -match '^(?is)<h([1-6])') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) {
        $chunks.Add($currentParagraph.Trim())
        $currentParagraph = ""
      }
      $level = [int]$Matches[1]
      $text = Clean-Text $tag
      if ([string]::IsNullOrWhiteSpace($text)) { continue }
      $header = ('#' * [Math]::Min(3, $level)) + ' ' + $text
      $chunks.Add($header)
      $chunks.Add('')
      $contexts.Add($text)
      continue
    }

    if ($tag -match '^(?is)<table') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) {
        $chunks.Add($currentParagraph.Trim())
        $currentParagraph = ""
      }
      $tableLines = Convert-HtmlTableToMarkdown $tag
      if ($tableLines.Count -gt 0) {
        foreach ($line in $tableLines) { $chunks.Add($line) }
        $chunks.Add('')
      }
      continue
    }

    $text = Clean-Text $tag
    if ([string]::IsNullOrWhiteSpace($text)) { continue }

    # Detectar Títulos por patrón (TEMA 1, I., 1., etc)
    if ($text -match '^TEMA\s+([IVX]+|\d+)') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) { $chunks.Add($currentParagraph.Trim()); $currentParagraph = "" }
      $chunks.Add('# ' + $text); $chunks.Add(''); $contexts.Add($text); continue
    }
    
    # Líneas cortas en MAYÚSCULAS como subtítulos
    if ($text -cmatch '^[A-ZÁÉÍÓÚÑÜ\s]{3,40}$') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) { $chunks.Add($currentParagraph.Trim()); $currentParagraph = "" }
      $chunks.Add('## ' + $text); $chunks.Add(''); $contexts.Add($text); continue
    }

    if ($text -match '^\d+\.\d+\.\s+') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) { $chunks.Add($currentParagraph.Trim()); $currentParagraph = "" }
      $chunks.Add('### ' + $text); $chunks.Add(''); $contexts.Add($text); continue
    }

    if ($text -match '^\d+\.\s+') {
      if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) { $chunks.Add($currentParagraph.Trim()); $currentParagraph = "" }
      $chunks.Add('## ' + $text); $chunks.Add(''); $contexts.Add($text); continue
    }

    # Si no es nada de lo anterior, es un párrafo. Intentamos unir líneas fragmentadas.
    # Unimos si la línea anterior no termina en signo de puntuación de cierre y no es un encabezado
    $isBullet = $tag -match '^(?is)<li' -or $text -match '^[-•]\s+'
    
    if ($isBullet) {
       if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) { $chunks.Add($currentParagraph.Trim()); $currentParagraph = "" }
       $cleanBullet = $text -replace '^[-•]\s*', ''
       $chunks.Add('- ' + $cleanBullet)
       continue
    }

    if (-not [string]::IsNullOrWhiteSpace($currentParagraph) -and $currentParagraph -notmatch '[\.\?\!:]$') {
       # Probablemente continuación de la anterior si la anterior no termina en puntuación
       $currentParagraph = $currentParagraph.TrimEnd() + " " + $text
    } else {
       if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) {
         $chunks.Add($currentParagraph.Trim())
       }
       $currentParagraph = $text
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($currentParagraph)) {
    $chunks.Add($currentParagraph.Trim())
  }

  $markdown = ($chunks -join "`n")
  if ($markdown -notmatch '^#\s+') {
    $markdown = '# ' + [IO.Path]::GetFileNameWithoutExtension($SourcePath) + "`n`n" + $markdown
  }
  $markdown = Apply-TokenMapsNormalization $markdown $tokenMaps
  $markdown = Apply-OcrDictionary $markdown $Config.OcrDictionary $Counters
  $markdown = Build-TocAndAnchors $markdown
  $markdown = Apply-TokenMapsNormalization $markdown $tokenMaps
  $markdown = Apply-OcrDictionary $markdown $Config.OcrDictionary $Counters
  $markdown = [regex]::Replace($markdown, '\n{3,}', "`n`n")

  Write-Host "  -> Generando Markdown final: $destination" -ForegroundColor DarkGray
  Write-TextUtf8NoBom $destination $markdown
  Remove-Item -LiteralPath $tmpTxt, $tmpHtml, $tmpOpenSource -Force -ErrorAction SilentlyContinue

  return @{
    MarkdownPath = $destination
    ImageCount   = $analyzedImageCount
  }
}

function Convert-PptxToRagMarkdown([object]$PowerPointApp, [string]$SourcePath, [hashtable]$Config, [hashtable]$Counters, [hashtable]$RuntimeStats) {
  $destination = [IO.Path]::ChangeExtension($SourcePath, '.md')
  $chunks = New-Object System.Collections.Generic.List[string]
  $contexts = New-Object System.Collections.Generic.List[string]
  $sourceTextBuffer = New-Object System.Collections.Generic.List[string]
  $tempExportDir = Join-Path ([IO.Path]::GetTempPath()) ('rag_vision_' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tempExportDir -Force | Out-Null
  $imageCount = 0

  try {
    Write-Host "  -> Extrayendo contenido vía PowerPoint COM Object..." -ForegroundColor DarkGray
    $presentation = $PowerPointApp.Presentations.Open($SourcePath, $false, $true, $false)
    try {
      $chunks.Add('# ' + [IO.Path]::GetFileNameWithoutExtension($SourcePath))
      $chunks.Add('')

      $slideCount = $presentation.Slides.Count
      $currentSlide = 0

      foreach ($slide in $presentation.Slides) {
        $currentSlide++
        Write-Host "    [Diapositiva $currentSlide/$slideCount] Procesando formas e imágenes..." -ForegroundColor DarkGray
        $title = ''
        foreach ($shape in $slide.Shapes) {
          if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            $value = $shape.TextFrame.TextRange.Text.Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) {
              if ([string]::IsNullOrWhiteSpace($title)) { $title = $value }
              $sourceTextBuffer.Add($value)
            }
          }
        }
        if ([string]::IsNullOrWhiteSpace($title)) { $title = 'Diapositiva ' + $slide.SlideIndex }
        $section = 'Diapositiva ' + $slide.SlideIndex + ': ' + $title
        $chunks.Add('## ' + $section)
        $chunks.Add('')
        $contexts.Add($section)
        $slideHasVisual = $false

        foreach ($shape in $slide.Shapes) {
          if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            $text = $shape.TextFrame.TextRange.Text.Trim()
            if (-not [string]::IsNullOrWhiteSpace($text) -and $text -ne $title) {
              ($text -split "`r?`n") | ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace($_)) { $chunks.Add('- ' + $_.Trim()) }
              }
            }
          }
          else {
            $slideHasVisual = $true
          }
        }
        if ($slideHasVisual) {
          $exportPath = Join-Path $tempExportDir ('slide_' + $slide.SlideIndex + '.png')
          $slide.Export($exportPath, 'PNG', 1600, 900)
          $analysis = Analyze-ImageWithVisionAI $exportPath $section $Config $RuntimeStats
          $chunks.Add((Build-ImageAnalysisLine $analysis))
          $chunks.Add('')
          $imageCount++
        }
        $chunks.Add('')
      }
    }
    finally {
      $presentation.Close()
    }
  } catch {
    Log-Error "Error procesando PPT/PPTX: $($_.Exception.Message)" $_.Exception
    throw
  }

  Remove-Item -LiteralPath $tempExportDir -Recurse -Force -ErrorAction SilentlyContinue
  $tokenMaps = Build-TokenMaps ($sourceTextBuffer -join "`n")

  $markdown = ($chunks -join "`n")
  $markdown = Apply-TokenMapsNormalization $markdown $tokenMaps
  $markdown = Apply-OcrDictionary $markdown $Config.OcrDictionary $Counters
  $markdown = Build-TocAndAnchors $markdown
  $markdown = Apply-TokenMapsNormalization $markdown $tokenMaps
  $markdown = Apply-OcrDictionary $markdown $Config.OcrDictionary $Counters
  $markdown = [regex]::Replace($markdown, '\n{3,}', "`n`n")
  Write-Host "  -> Generando Markdown final: $destination" -ForegroundColor DarkGray
  Write-TextUtf8NoBom $destination $markdown

  return @{
    MarkdownPath = $destination
    ImageCount   = $imageCount
  }
}

function Test-RagOutput([string]$MarkdownPath, [int]$ImageCount, [string]$ResidualRegex, [bool]$RequireVisionSuccess) {
  $issues = New-Object System.Collections.Generic.List[string]
  if (-not (Test-Path -LiteralPath $MarkdownPath)) {
    $issues.Add('MISSING_MD')
    return $issues
  }
  $text = Get-Content -LiteralPath $MarkdownPath -Raw -Encoding UTF8
  if ($text -notmatch '(?m)^# Índice$') { $issues.Add('NO_TOC') }
  if ($text -notmatch '<a id="tema-1"></a>') { $issues.Add('NO_ANCHOR_TEMA_1') }
  if ($text -match '\n{3,}') { $issues.Add('TRIPLE_NEWLINE') }
  if ($ImageCount -gt 0) {
    $aiMatches = [regex]::Matches($text, '(?m)^> \[ANÁLISIS DE IMAGEN IA\]:')
    if ($aiMatches.Count -lt $ImageCount) { $issues.Add("AI_IMAGE_ANALYSIS_INCOMPLETE (Encontrados: $($aiMatches.Count) / Esperados: $ImageCount)") }
    if ($RequireVisionSuccess -and $text -match 'ANÁLISIS DE IMAGEN IA_PENDIENTE:') { $issues.Add('AI_IMAGE_ANALYSIS_PENDING') }
  }
  if ($text -match $ResidualRegex) { $issues.Add('RESIDUAL_OCR') }
  return $issues
}

$Config.LogPath = Resolve-PathFlexible $Config.LogPath
$Config.QaLogPath = Resolve-PathFlexible $Config.QaLogPath
$Config.SummaryPath = Resolve-PathFlexible $Config.SummaryPath
Apply-EnvironmentOverrides $Config
$bound = $MyInvocation.BoundParameters
if ($bound.ContainsKey('SourceFoldersOverride')) { $Config.SourceFolders = @($SourceFoldersOverride) }
if ($bound.ContainsKey('SourceFilesOverride')) { $Config.SourceFiles = @($SourceFilesOverride) }
if ($bound.ContainsKey('ForceReprocessOverride')) { $Config.ForceReprocess = [bool]$ForceReprocessOverride }
if ($bound.ContainsKey('FailFastOverride')) { $Config.FailFast = [bool]$FailFastOverride }
if ($bound.ContainsKey('EnablePreflightOverride')) { $Config.EnablePreflightChecks = [bool]$EnablePreflightOverride }
if ($bound.ContainsKey('OpenRouterModelOverride') -and -not [string]::IsNullOrWhiteSpace($OpenRouterModelOverride)) { $Config.OpenRouterModel = $OpenRouterModelOverride.Trim() }
$Config.SourceFolders = @($Config.SourceFolders | ForEach-Object { Resolve-PathFlexible $_ })
$Config.SourceFiles = @($Config.SourceFiles | ForEach-Object { Resolve-PathFlexible $_ })

if ($Config.EnablePreflightChecks) {
  Test-OpenRouterPreflight $Config
}

Ensure-ParentDirectory $Config.LogPath
Ensure-ParentDirectory $Config.QaLogPath
Ensure-ParentDirectory $Config.SummaryPath

$Script:LogPath = $Config.LogPath
  $Script:QaLogPath = $Config.QaLogPath
  $Script:SummaryPath = $Config.SummaryPath

  # Limpiar logs anteriores
  if (Test-Path $Script:LogPath) { Remove-Item $Script:LogPath -Force }
  if (Test-Path $Script:QaLogPath) { Remove-Item $Script:QaLogPath -Force }
  if (Test-Path $Script:SummaryPath) { Remove-Item $Script:SummaryPath -Force }

  Write-Host "=======================================================" -ForegroundColor Cyan
  Write-Host " Iniciando RAG Converter Tool v2.0" -ForegroundColor Cyan
  Write-Host "=======================================================" -ForegroundColor Cyan
  Write-Host " [i] Modo: $($Config.AppProfile)" -ForegroundColor DarkGray
  Write-Host " [i] Modelo Vision: $($Config.OpenRouterModel)" -ForegroundColor DarkGray
  Write-Host " [i] Carpetas a procesar: $($Config.SourceFolders -join ', ')" -ForegroundColor DarkGray
  Write-Host " [i] Dominio: $($Config.DomainContext)" -ForegroundColor DarkGray
  Write-Host " [i] Logs: $($Script:LogPath)" -ForegroundColor DarkGray
  Write-Host "-------------------------------------------------------`n" -ForegroundColor Cyan

$files = foreach ($folder in $Config.SourceFolders) {
  if (Test-Path -LiteralPath $folder) {
    Get-ChildItem -LiteralPath $folder -Recurse -File | Where-Object { $Config.FileExtensions -contains $_.Extension.ToLower() }
  } else {
    Write-Host " [!] Carpeta no encontrada: $folder" -ForegroundColor Yellow
  }
}
$files = $files | Sort-Object FullName
if ($Config.SourceFiles.Count -gt 0) {
  $sourceFileSet = @{}
  foreach ($sf in $Config.SourceFiles) { $sourceFileSet[$sf.ToLowerInvariant()] = $true }
  $files = $files | Where-Object { $sourceFileSet.ContainsKey($_.FullName.ToLowerInvariant()) }
}

$wordApp = $null
$powerPointApp = $null
$logLines = New-Object System.Collections.Generic.List[string]
$qaLines = New-Object System.Collections.Generic.List[string]
$ocrCounters = @{}
$globalStatus = 'NORM_OK'
$runtimeStats = @{
  VisionItems = 0
  VisionApiCalls = 0
  VisionSuccess = 0
  VisionPending = 0
  VisionApiErrors = 0
  Skipped = 0
  TotalFiles = 0
}

$filesToProcess = @()
foreach ($file in $files) {
  if ($file.Name -match '^\~\$') { continue }
  $outPath = [IO.Path]::ChangeExtension($file.FullName, '.md')
  if (-not (Test-Path -LiteralPath $outPath) -or $Config.ForceReprocess) {
    $filesToProcess += $file
  } else {
    $runtimeStats.Skipped++
  }
}

$totalFiles = $filesToProcess.Count
Write-Host " Archivos encontrados para procesar: $totalFiles" -ForegroundColor Cyan
Write-Host " Archivos saltados (ya procesados): $($runtimeStats.Skipped)`n" -ForegroundColor DarkGray

$currentFileIndex = 0

try {
  $wordApp = New-Object -ComObject Word.Application
  $wordApp.Visible = $false
  $wordApp.DisplayAlerts = 0
  $powerPointApp = New-Object -ComObject PowerPoint.Application

  foreach ($file in $filesToProcess) {
    $currentFileIndex++
    $runtimeStats.TotalFiles++
    Write-Host "[$currentFileIndex/$totalFiles] Procesando: $($file.Name)" -ForegroundColor Yellow
    try {
      if ($file.Extension.ToLower() -eq '.pptx') {
        $result = Convert-PptxToRagMarkdown $powerPointApp $file.FullName $Config $ocrCounters $runtimeStats
        $sourceKind = 'PPTX'
      }
      else {
        $result = Convert-WordToRagMarkdown $wordApp $file.FullName $Config $ocrCounters $runtimeStats
        $sourceKind = 'WORD'
      }
      $issues = Test-RagOutput $result.MarkdownPath $result.ImageCount $Config.ResidualOcrRegex $Config.RequireVisionSuccess
      if ($issues.Count -eq 0) {
        $logLines.Add('NORM_OK|' + $sourceKind + '|' + $file.FullName + '|IMG=' + $result.ImageCount)
      }
      else {
        Write-Host "  [!] Error QA en $($file.Name): $($issues -join ', ')" -ForegroundColor Yellow
        $globalStatus = 'NORM_WITH_ERRORS'
        $logLines.Add('NORM_ERR|' + $sourceKind + '|' + $file.FullName + '|IMG=' + $result.ImageCount + '|ISSUES=' + ($issues -join ','))
        $qaLines.Add($file.FullName + ' => ' + ($issues -join ','))
        if ($Config.FailFast) { break }
      }
    }
    catch {
      $globalStatus = 'NORM_WITH_ERRORS'
      $message = ($_.Exception.Message -replace "`r?`n", ' ').Trim()
      $logLines.Add('NORM_ERR|FILE|' + $file.FullName + '|ISSUES=EXCEPTION:' + $message)
      $qaLines.Add($file.FullName + ' => EXCEPTION: ' + $message)
      $msg = "Error procesando archivo $($file.Name): $($_.Exception.Message)"
      Log-Error $msg $_.Exception
      $runtimeStats.Errors++
      if ($Config.FailFast) {
        Write-Host "`n[FAIL-FAST] Ejecución abortada debido a un error en el procesamiento." -ForegroundColor Red
        break
      }
    }
  }
}
finally {
  if ($wordApp -ne $null) {
    $wordApp.Quit()
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp)
  }
  if ($powerPointApp -ne $null) {
    $powerPointApp.Quit()
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($powerPointApp)
  }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}

Write-TextUtf8NoBom $Config.LogPath ($logLines -join "`n")
Write-TextUtf8NoBom $Config.QaLogPath ($qaLines -join "`n")

$summary = New-Object System.Collections.Generic.List[string]
$summary.Add('STATUS=' + $globalStatus)
$summary.Add('FILES=' + $files.Count)
$summary.Add('CLIENT=' + $Config.ClientName)
$summary.Add('PROFILE=' + $Config.AppProfile)
$summary.Add('VISION_ENABLED=' + $Config.EnableVisionAI)
$summary.Add('VISION_REQUIRE_SUCCESS=' + $Config.RequireVisionSuccess)
$summary.Add('FAIL_FAST=' + $Config.FailFast)
$summary.Add('FORCE_REPROCESS=' + $Config.ForceReprocess)
$summary.Add('PREFLIGHT=' + $Config.EnablePreflightChecks)
$summary.Add('PREFLIGHT_MODE=' + $Config.PreflightMode)
$summary.Add('VISION_MODEL=' + $Config.OpenRouterModel)
$summary.Add('VISION_ITEMS=' + $runtimeStats.VisionItems)
$summary.Add('VISION_API_CALLS=' + $runtimeStats.VisionApiCalls)
$summary.Add('VISION_SUCCESS=' + $runtimeStats.VisionSuccess)
$summary.Add('VISION_PENDING=' + $runtimeStats.VisionPending)
$summary.Add('VISION_API_ERRORS=' + $runtimeStats.VisionApiErrors)
foreach ($key in $Config.OcrDictionary.Keys) {
  $value = 0
  if ($ocrCounters.ContainsKey($key)) { $value = $ocrCounters[$key] }
  $summary.Add('OCR_' + $key + '=' + $value)
}
Write-TextUtf8NoBom $Config.SummaryPath ($summary -join "`n")

$globalStatus
