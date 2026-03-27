# RAG Converter Tool

Infraestructura de conversión **Office → Markdown RAG-Ready** con control QA, análisis multimodal de imágenes y generación de informes certificables.

## ¿Qué resuelve?

- Convierte `.doc`, `.docx` y `.pptx` a Markdown estructurado para RAG.
- Inserta análisis de imagen IA con OCR + análisis espacial + valor pedagógico.
- Valida calidad del lote (`NORM_OK` / `NORM_WITH_ERRORS`) con evidencia auditable.
- Genera informes ejecutivos y técnicos desde métricas reales (`Gen-Report.ps1`).
- Permite operación multi-cliente con `.env.<cliente>.<entorno>`.

## Stack técnico

- PowerShell 7+
- Automatización COM de Microsoft Word y PowerPoint (Windows)
- OpenRouter para análisis multimodal

## Estructura principal

- `Convert-OfficeToRAG.ps1`: motor de conversión y QA.
- `Run-RAG.ps1`: launcher corto con soporte `.env` y `-EnvFile`.
- `Enable-RagAlias.ps1`: alias operativos (`rag`, `rr`, `rag-report`).
- `Gen-Report.ps1`: informe certificable comercial/técnico.
- `DEV_GUIDE.md`: guía técnica detallada.
- `outputs/logs`: logs y resumen de ejecución.
- `outputs/reports`: reportes de certificación generados.

## Arranque rápido

1) Configura entorno:

```powershell
Copy-Item ".env.example" ".env" -Force
```

2) Edita `.env` y rellena `OPENROUTER_API_KEY`.

3) Carga alias:

```powershell
. ".\Enable-RagAlias.ps1"
```

4) Ejecuta:

```powershell
rag
rag -Target "D:\Ruta\Carpeta"
rag -Target "D:\Ruta\Documento.docx" -Reprocess
```

5) Genera informe:

```powershell
rag-report -Modo comercial -Cliente "Cliente Demo"
rag-report -Modo tecnico -Cliente "Cliente Demo"
```

## Multi-cliente

- Usa archivos dedicados como:
  - `.env.acme.dev`
  - `.env.acme.prod`
  - `.env.contoso.staging`

Ejemplo:

```powershell
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Carpeta" -Reprocess
```

## Licencia y atribución

- Licencia: [MIT](./LICENSE)
- Atribución recomendada para uso comercial: [NOTICE.md](./NOTICE.md)
- Citación académica/técnica: [CITATION.cff](./CITATION.cff)

## Documentación

- Guía técnica completa: [DEV_GUIDE.md](./DEV_GUIDE.md)
