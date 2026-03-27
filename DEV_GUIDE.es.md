[English](DEV_GUIDE.md) | [Español](DEV_GUIDE.es.md) | [简体中文](DEV_GUIDE.zh-CN.md) | [한국어](DEV_GUIDE.ko-KR.md)

# Guía Dev - RAG Converter Tool

## 1) Objetivo

Esta herramienta convierte archivos Office (`.doc`, `.docx`, `.pptx`) a Markdown optimizado para RAG, manteniendo fidelidad estructural y aplicando normalización lingüística segura.

Script principal:

- `Convert-OfficeToRAG.ps1`

## 2) Requisitos

- Windows con Microsoft Word y PowerPoint instalados (automatización COM).
- PowerShell 7 (`pwsh`) instalado.
- Permisos de lectura/escritura sobre las carpetas fuente.

Verificación rápida:

```powershell
pwsh -NoProfile -Command "$PSVersionTable.PSVersion"
```

## 3) Configuración

Editar el bloque `$Config` al inicio de `Convert-OfficeToRAG.ps1`:

- `SourceFolders`: carpetas origen a procesar.
- `FileExtensions`: extensiones permitidas.
- `OcrDictionary`: diccionario conservador OCR.
- `ResidualOcrRegex`: regex de validación de residuos.
- `LogPath`, `QaLogPath`, `SummaryPath`: rutas de salida de logs.
- `ForceReprocess`: fuerza reprocesado de archivos aunque ya exista `.md`.

Comportamiento portable:

- Si una ruta es relativa, el script la resuelve desde la carpeta donde vive `Convert-OfficeToRAG.ps1`.
- Por defecto, los logs (`rag_converter_log.txt`, `rag_converter_qa_log.txt`, `rag_converter_summary.txt`) se escriben en `outputs/logs` dentro de la carpeta del script.
- `SourceFolders` por defecto apunta a `..\input` respecto a la carpeta del script.

Variables de entorno clave:

- `RAG_SOURCE_FOLDERS`: acepta múltiples rutas separadas por `;` o `,`.
- `RAG_SOURCE_FILES`: acepta uno o varios archivos concretos separados por `;` o `,`.
- `RAG_FORCE_REPROCESS`: `true/false` para reprocesar aunque exista `.md`.
- `RAG_FAIL_FAST`: `true/false` para abortar o continuar ante errores.
- `RAG_ENABLE_PREFLIGHT`: `true/false` para activar/desactivar preflight API.
- `RAG_OPENROUTER_MODEL`: modelo de visión a usar.

Parámetros directos del script (prioridad alta, recomendados en automatización):

- `-SourceFoldersOverride <string[]>`
- `-SourceFilesOverride <string[]>`
- `-ForceReprocessOverride <bool>`
- `-FailFastOverride <bool>`
- `-EnablePreflightOverride <bool>`
- `-OpenRouterModelOverride <string>`

## 4) Ejecución estándar

Ejecutar siempre con `pwsh` para mantener estabilidad UTF-8. Comando agnóstico a ruta:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
pwsh -NoProfile -File (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Salida esperada en consola:

- `NORM_OK` o `NORM_WITH_ERRORS`.

## 5) Comando único (run + validación)

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"; pwsh -NoProfile -Command "$s=(Join-Path '$toolDir' 'Convert-OfficeToRAG.ps1'); $sum=(Join-Path '$toolDir' 'outputs\logs\rag_converter_summary.txt'); & $s; if($LASTEXITCODE -ne 0){ throw 'Falló la ejecución del convertidor' }; $st=(Get-Content $sum | Select-String '^STATUS=').Line; if($st -ne 'STATUS=NORM_OK'){ throw \"Estado inválido: $st\" }; Write-Host 'OK => STATUS=NORM_OK' -ForegroundColor Green"
```

## 6) Operación diaria

Auditoría rápida de resumen:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
Get-Content -Path (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt")
```

Estado en una línea:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
(Get-Content (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt") | Select-String '^STATUS=').Line
```

Incidencias QA:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
$qa = Join-Path $toolDir "outputs\logs\rag_converter_qa_log.txt"
if((Test-Path $qa) -and ((Get-Item $qa).Length -gt 0)){Get-Content $qa}else{"Sin incidencias QA"}
```

## 7) Estructura del Script (`Convert-OfficeToRAG.ps1`)

El script está diseñado con un enfoque robusto y modular:

### 1. Inyección de Dominio (Prompts Agnósticos)
El script ya no está acoplado a una temática específica (como el fútbol). Utiliza variables de configuración para inyectar el contexto dinámicamente en el prompt del modelo de IA:
- `$Config.DomainContext`: Define el entorno (ej. "entorno educativo de alto rendimiento deportivo").
- `$Config.DomainNoiseFilter`: Palabras clave a ignorar por el modelo (ej. "colores de ropa, paisajes, clima").
- `$Config.DomainTechnicalTerms`: Instrucciones de precisión terminológica (ej. evitar sustituir términos especializados por sinónimos ambiguos).

### 2. Extracción de Imágenes y OCR Estructurado
El análisis de imágenes se realiza mediante la API de OpenRouter. El nuevo prompt exige un formato de salida estricto en Markdown que incluye:
1. **OCR Literal**: Transcripción exacta de texto en diapositivas.
2. **Análisis Técnico Espacial**: Interpretación de diagramas y flechas.
3. **Valor Pedagógico**: Extracción del concepto central.

### 3. Verbosidad y Sistema de Logs
Para evitar "dar palos de ciego" durante ejecuciones masivas:
- **Salida de Consola (Verbose):** Muestra el progreso en tiempo real (`[1/10] Procesando...`, `[Imagen 3/5] Solicitando análisis...`, `Generando Markdown final`).
- **Telemetría COM:** Mide y muestra tiempos de `Word.Open` y `Word.SaveAs(HTML)` para detectar cuellos de botella.
- **Archivos de Log:**
  - `rag_converter_log.txt`: Registra eventos con `INFO` y `ERROR` (incluyendo StackTraces).
  - `rag_converter_qa_log.txt`: Registra errores de validación (ej. análisis de imagen incompleto).
  - `rag_converter_summary.txt`: Resumen final de la ejecución.

### 4. Perfiles y Fallback Automático
- Soporta perfiles como `default` y `staging` para cambiar modelos rápidamente sin tocar el código.
- Incluye un preflight check que verifica la conectividad y soporte multimodal de la API antes de empezar, con fallback automático de `vision` a `text` si el modelo no soporta imágenes.

## 8) Troubleshooting

- Si al lanzar con `powershell.exe` aparecen caracteres rotos en regex/tildes, usar `pwsh`.
- Si COM falla, verificar instalación de Word/PowerPoint y sesión de usuario activa.
- Si el estado es `NORM_WITH_ERRORS`, revisar primero `rag_converter_qa_log.txt`.
- Si mueves la carpeta `RAG_Converter_Tool`, el script sigue funcionando; solo revisa `SourceFolders` si las fuentes quedaron en otra ubicación.
- Si una extracción Word se queda lenta, revisar en consola los tiempos `Word.Open`/`Word.SaveAs(HTML)` para ubicar el cuello de botella.
- Si hay archivos temporales bloqueados (`~$*.docx`), cerrarlos en Office antes de ejecutar el lote.

## 9) Runbook rápido

Ejecución completa (carpetas configuradas):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Reprocesado completo forzado:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Ejecución de un solo archivo:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_SOURCE_FILES="D:\Ruta\Input\Documento.docx"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

Ejecución de un solo archivo (vía parámetros, recomendado):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -SourceFilesOverride "D:\Ruta\Input\Documento.docx" -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

Ejecución total aunque ya existan `.md` (vía parámetros):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

## 10) Flujo simple con `.env` y alias

1) Crear `.env` copiando la plantilla:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env") -Force
```

2) Editar `.env` y poner tu `OPENROUTER_API_KEY`.

3) Cargar alias cortos en la sesión actual:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1")
```

4) Usar comandos cortos:

```powershell
rag
rag -Target "D:\Ruta\Input"
rag -Target "D:\Ruta\Input\Documento.docx"
rag -Target "D:\Ruta\Input\Documento.docx" -Reprocess
rr -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

5) Opcional: persistir alias en el perfil de PowerShell:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1") -Persist
```

6) Escalabilidad multi-cliente con archivos `.env` dedicados:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

Nota general:
- Crea un archivo `.env` por cliente y entorno.
- El parser de `.env` soporta comentarios en líneas que empiezan por `#`.

Uso por cliente sin tocar comandos largos:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

## 11) Onboarding de nuevo cliente

Checklist rápido para dar de alta un cliente nuevo sin tocar código:

1) Crear archivo de entorno del cliente:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.<cliente>.<entorno>") -Force
```

2) Editar `.env.<cliente>`:
- `OPENROUTER_API_KEY`: clave del cliente.
- `RAG_OPENROUTER_MODEL`: modelo acordado para ese cliente.
- `RAG_FAIL_FAST`, `RAG_ENABLE_PREFLIGHT`, `RAG_FORCE_REPROCESS`: política operativa.
- Se permiten comentarios en líneas que empiezan por `#`.

3) Ejecutar una prueba mínima sobre un archivo:

```powershell
rag -EnvFile ".env.<cliente>" -Target "D:\Ruta\Documento.docx"
```

4) Validar resultado:
- Consola con `NORM_OK`.
- Revisar `rag_converter_summary.txt` y `rag_converter_qa_log.txt`.
- En esta versión los artefactos están en `outputs/logs`.

5) Operación diaria del cliente:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>"
```

6) Reproceso total cuando sea necesario:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>" -Reprocess
```

## 12) Convención de naming para `.env` (Enterprise)

Para escalar sin fricción, usar esta convención:

- `.env.<cliente>.<entorno>`
- `<cliente>`: identificador estable (sin espacios), por ejemplo `acme`, `clinicax`, `lexcorp`.
- `<entorno>`: `dev`, `staging` o `prod`.

Ejemplos:

- `.env.acme.dev`
- `.env.acme.prod`
- `.env.lexcorp.staging`

Flujo recomendado:

1) Crear variante por entorno desde la base del cliente:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

2) Ejecutar por entorno:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input" -Reprocess
```

## 13) Informe de Certificación RAG-Ready

Generación automática de informe ejecutivo desde `rag_converter_summary.txt`:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Firmante "Nombre Apellido" -Modo comercial
```

Opcionalmente puedes definir salida:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Modo tecnico -OutputPath (Join-Path $toolDir "outputs\reports\Informe_RAG_Auditoria.md")
```

Notas:
- El informe usa métricas reales del summary/log; si un dato no existe, se muestra como `N/D`.
- Se evita inventar KPIs (por ejemplo porcentajes de OCR o aceleraciones) si no están medidos en los archivos de evidencia.
- Modos disponibles: `-Modo comercial` (storytelling ejecutivo) y `-Modo tecnico` (auditoría forense).
- Por defecto, los logs se generan en `outputs/logs` y los reportes en `outputs/reports` (rutas portables, no hardcodeadas).
- El informe incorpora `DHI (Data Health Index)` con escala 0-100 y grados (`WORLD CLASS`, `ENTERPRISE READY`, `ACCEPTABLE`, `NEEDS IMPROVEMENT`).
- El DHI se calcula con 4 pilares ponderados: Integridad (30), Semántica (40), Normalización OCR (20), Citación (10).
- Caso sin imágenes (`VISION_ITEMS=0`): no penaliza; se marca como `Texto puro` en el pilar semántico.
- El cálculo de DHI usa `summary + qa log`; puedes sobreescribir QA con `-QaPath`.

Atajo con alias (tras cargar `Enable-RagAlias.ps1`):

```powershell
rag-report -Modo comercial -Cliente "Cliente Demo" -Firmante "Nombre Apellido"
rag-report -Modo tecnico -Cliente "Cliente Demo" -OutputPath "D:\Ruta\RAG_Converter_Tool\outputs\reports\Informe_RAG_Auditoria.md"
```
