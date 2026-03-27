[English](DEV_GUIDE.md) | [Español](DEV_GUIDE.es.md) | [简体中文](DEV_GUIDE.zh-CN.md) | [한국어](DEV_GUIDE.ko-KR.md)

# Dev Guide - RAG Converter Tool

## 1) Objective

This tool converts Office files (`.doc`, `.docx`, `.pptx`) to Markdown optimized for RAG, maintaining structural fidelity and applying safe linguistic normalization.

Main script:

- `Convert-OfficeToRAG.ps1`

## 2) Requirements

- Windows with Microsoft Word and PowerPoint installed (COM automation).
- PowerShell 7 (`pwsh`) installed.
- Read/write permissions over the source folders.

Quick verification:

```powershell
pwsh -NoProfile -Command "$PSVersionTable.PSVersion"
```

## 3) Configuration

Edit the `$Config` block at the beginning of `Convert-OfficeToRAG.ps1`:

- `SourceFolders`: source folders to process.
- `FileExtensions`: allowed extensions.
- `OcrDictionary`: conservative OCR dictionary.
- `ResidualOcrRegex`: residual validation regex.
- `LogPath`, `QaLogPath`, `SummaryPath`: log output paths.
- `ForceReprocess`: forces reprocessing of files even if `.md` already exists.

Portable behavior:

- If a path is relative, the script resolves it from the folder where `Convert-OfficeToRAG.ps1` lives.
- By default, logs (`rag_converter_log.txt`, `rag_converter_qa_log.txt`, `rag_converter_summary.txt`) are written to `outputs/logs` inside the script folder.
- `SourceFolders` defaults to `..\input` relative to the script folder.

Key environment variables:

- `RAG_SOURCE_FOLDERS`: accepts multiple paths separated by `;` or `,`.
- `RAG_SOURCE_FILES`: accepts one or more specific files separated by `;` or `,`.
- `RAG_FORCE_REPROCESS`: `true/false` to reprocess even if `.md` exists.
- `RAG_FAIL_FAST`: `true/false` to abort or continue on errors.
- `RAG_ENABLE_PREFLIGHT`: `true/false` to enable/disable preflight API.
- `RAG_OPENROUTER_MODEL`: vision model to use.

Direct script parameters (high priority, recommended for automation):

- `-SourceFoldersOverride <string[]>`
- `-SourceFilesOverride <string[]>`
- `-ForceReprocessOverride <bool>`
- `-FailFastOverride <bool>`
- `-EnablePreflightOverride <bool>`
- `-OpenRouterModelOverride <string>`

## 4) Standard Execution

Always run with `pwsh` to maintain UTF-8 stability. Path-agnostic command:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
pwsh -NoProfile -File (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Expected console output:

- `NORM_OK` or `NORM_WITH_ERRORS`.

## 5) Single Command (run + validation)

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"; pwsh -NoProfile -Command "$s=(Join-Path '$toolDir' 'Convert-OfficeToRAG.ps1'); $sum=(Join-Path '$toolDir' 'outputs\logs\rag_converter_summary.txt'); & $s; if($LASTEXITCODE -ne 0){ throw 'Falló la ejecución del convertidor' }; $st=(Get-Content $sum | Select-String '^STATUS=').Line; if($st -ne 'STATUS=NORM_OK'){ throw \"Estado inválido: $st\" }; Write-Host 'OK => STATUS=NORM_OK' -ForegroundColor Green"
```

## 6) Daily Operations

Quick summary audit:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
Get-Content -Path (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt")
```

One-line status:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
(Get-Content (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt") | Select-String '^STATUS=').Line
```

QA incidents:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
$qa = Join-Path $toolDir "outputs\logs\rag_converter_qa_log.txt"
if((Test-Path $qa) -and ((Get-Item $qa).Length -gt 0)){Get-Content $qa}else{"Sin incidencias QA"}
```

## 7) Script Structure (`Convert-OfficeToRAG.ps1`)

The script is designed with a robust and modular approach:

### 1. Domain Injection (Agnostic Prompts)
The script is no longer coupled to a specific topic (such as football). It uses configuration variables to inject context dynamically into the AI model prompt:
- `$Config.DomainContext`: Defines the environment (e.g. "high-performance sports educational environment").
- `$Config.DomainNoiseFilter`: Keywords for the model to ignore (e.g. "clothing colors, landscapes, weather").
- `$Config.DomainTechnicalTerms`: Terminological precision instructions (e.g. avoid replacing specialized terms with ambiguous synonyms).

### 2. Image Extraction and Structured OCR
Image analysis is performed via the OpenRouter API. The new prompt requires a strict Markdown output format that includes:
1. **Literal OCR**: Exact transcription of text in slides.
2. **Spatial Technical Analysis**: Interpretation of diagrams and arrows.
3. **Pedagogical Value**: Extraction of the core concept.

### 3. Verbosity and Logging System
To avoid "flying blind" during massive runs:
- **Console Output (Verbose):** Shows real-time progress (`[1/10] Processing...`, `[Image 3/5] Requesting analysis...`, `Generating final Markdown`).
- **COM Telemetry:** Measures and displays `Word.Open` and `Word.SaveAs(HTML)` timings to detect bottlenecks.
- **Log Files:**
  - `rag_converter_log.txt`: Records events with `INFO` and `ERROR` (including StackTraces).
  - `rag_converter_qa_log.txt`: Records validation errors (e.g. incomplete image analysis).
  - `rag_converter_summary.txt`: Final execution summary.

### 4. Profiles and Automatic Fallback
- Supports profiles like `default` and `staging` to switch models quickly without touching code.
- Includes a preflight check that verifies API connectivity and multimodal support before starting, with automatic fallback from `vision` to `text` if the model does not support images.

## 8) Troubleshooting

- If launching with `powershell.exe` shows broken characters in regex/accents, use `pwsh`.
- If COM fails, verify Word/PowerPoint installation and active user session.
- If status is `NORM_WITH_ERRORS`, check `rag_converter_qa_log.txt` first.
- If you move the `RAG_Converter_Tool` folder, the script still works; just review `SourceFolders` if the sources ended up in another location.
- If a Word extraction runs slow, check the console for `Word.Open`/`Word.SaveAs(HTML)` timings to locate the bottleneck.
- If there are locked temporary files (`~$*.docx`), close them in Office before running the batch.

## 9) Quick Runbook

Full execution (configured folders):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Forced full reprocessing:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Single file execution:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_SOURCE_FILES="D:\Ruta\Input\Documento.docx"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Single file execution (via parameters, recommended):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -SourceFilesOverride "D:\Ruta\Input\Documento.docx" -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

Full execution even if `.md` already exists (via parameters):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

## 10) Simple Workflow with `.env` and Aliases

1) Create `.env` by copying the template:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env") -Force
```

2) Edit `.env` and set your `OPENROUTER_API_KEY`.

3) Load short aliases in the current session:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1")
```

4) Use short commands:

```powershell
rag
rag -Target "D:\Ruta\Input"
rag -Target "D:\Ruta\Input\Documento.docx"
rag -Target "D:\Ruta\Input\Documento.docx" -Reprocess
rr -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

5) Optional: persist aliases in your PowerShell profile:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1") -Persist
```

6) Multi-client scalability with dedicated `.env` files:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

General note:
- Create one `.env` file per client and environment.
- The `.env` parser supports comments on lines starting with `#`.

Usage by client without typing long commands:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

## 11) New Client Onboarding

Quick checklist to onboard a new client without touching code:

1) Create the client environment file:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.<cliente>.<entorno>") -Force
```

2) Edit `.env.<cliente>`:
- `OPENROUTER_API_KEY`: client key.
- `RAG_OPENROUTER_MODEL`: model agreed for that client.
- `RAG_FAIL_FAST`, `RAG_ENABLE_PREFLIGHT`, `RAG_FORCE_REPROCESS`: operational policy.
- Comments are allowed on lines starting with `#`.

3) Run a minimal test on a file:

```powershell
rag -EnvFile ".env.<cliente>" -Target "D:\Ruta\Documento.docx"
```

4) Validate the result:
- Console shows `NORM_OK`.
- Review `rag_converter_summary.txt` and `rag_converter_qa_log.txt`.
- In this version, artifacts are in `outputs/logs`.

5) Daily client operation:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>"
```

6) Full reprocessing when needed:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>" -Reprocess
```

## 12) Naming Convention for `.env` (Enterprise)

To scale without friction, use this convention:

- `.env.<cliente>.<entorno>`
- `<cliente>`: stable identifier (no spaces), e.g. `acme`, `clinicax`, `lexcorp`.
- `<entorno>`: `dev`, `staging`, or `prod`.

Examples:

- `.env.acme.dev`
- `.env.acme.prod`
- `.env.lexcorp.staging`

Recommended workflow:

1) Create a variant per environment from the client base:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

2) Execute per environment:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input" -Reprocess
```

## 13) RAG-Ready Certification Report

Automatic executive report generation from `rag_converter_summary.txt`:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Firmante "Nombre Apellido" -Modo comercial
```

Optionally define the output:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Modo tecnico -OutputPath (Join-Path $toolDir "outputs\reports\Informe_RAG_Auditoria.md")
```

Notes:
- The report uses real metrics from the summary/log; if a data point does not exist, it is shown as `N/D`.
- It avoids inventing KPIs (e.g. OCR percentages or speedups) if they are not measured in the evidence files.
- Available modes: `-Modo comercial` (executive storytelling) and `-Modo tecnico` (forensic audit).
- By default, logs are generated in `outputs/logs` and reports in `outputs/reports` (portable paths, not hardcoded).
- The report incorporates `DHI (Data Health Index)` with a 0-100 scale and grades (`WORLD CLASS`, `ENTERPRISE READY`, `ACCEPTABLE`, `NEEDS IMPROVEMENT`).
- The DHI is calculated with 4 weighted pillars: Integrity (30), Semantics (40), OCR Normalization (20), Citation (10).
- Case without images (`VISION_ITEMS=0`): no penalty; it is marked as `Texto puro` in the semantics pillar.
- The DHI calculation uses `summary + qa log`; you can override QA with `-QaPath`.

Shortcut with aliases (after loading `Enable-RagAlias.ps1`):

```powershell
rag-report -Modo comercial -Cliente "Cliente Demo" -Firmante "Nombre Apellido"
rag-report -Modo tecnico -Cliente "Cliente Demo" -OutputPath "D:\Ruta\RAG_Converter_Tool\outputs\reports\Informe_RAG_Auditoria.md"
```
