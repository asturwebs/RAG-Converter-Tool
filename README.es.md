<div align="center">

# RAG Converter Tool

**Convierte documentos Office en Markdown listo para pipelines RAG.**

[English](README.md) | [Español](README.es.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko-KR.md)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/asturwebs/RAG-Converter-Tool/blob/main/LICENSE)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7+-5391DE.svg)](https://learn.microsoft.com/en-us/powershell/scripting/overview)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)
[![Release v2.0.0](https://img.shields.io/badge/release-v2.0.0-green.svg)

</div>

---

Convierte archivos `.doc`, `.docx` y `.pptx` en Markdown estructurado optimizado para sistemas RAG, con analisis de imagenes mediante IA, validacion de calidad y generacion de informes de certificacion.

Nacio como herramienta interna validada en produccion. Liberado como open source para que la comunidad se beneficie.

---

## Que hace

| Capacidad | Descripcion |
|-----------|-------------|
| **Conversion** | Office a Markdown con estructura jerarquica, indice y anclas |
| **Vision IA** | Analisis de imagenes embebidas: OCR, analisis espacial, valor pedagogico |
| **QA automatico** | Validacion por lote con estado `NORM_OK` o `NORM_WITH_ERRORS` |
| **Informes** | Generacion de informes comerciales y tecnicos con metricas reales |
| **Multi-cliente** | Configuracion independiente por cliente con `.env.<cliente>.<entorno>` |
| **Idempotente** | Omite archivos ya procesados; `-Reprocess` fuerza reproceso |

## Limitaciones actuales

- **Windows** con Microsoft Word y PowerPoint instalados (automatizacion COM)
- **PowerShell 7+** requerido
- Necesita clave API de un proveedor de modelos vision (OpenRouter, OpenAI, etc.)

La [hoja de ruta](./ROADMAP.es.md) incluye planes para soporte multiplataforma (Python, Docker) y mas formatos (PDF, XLSX, imagenes).

---

## Estructura

```
RAG_Converter_Tool/
├── Convert-OfficeToRAG.ps1     # Motor principal de conversion y QA
├── Run-RAG.ps1                # Launcher con soporte .env
├── Enable-RagAlias.ps1         # Alias de sesion (rag, rr, rag-report)
├── Gen-Report.ps1             # Generador de informes
├── .env.example              # Plantilla de configuracion
├── DEV_GUIDE.es.md            # Guia tecnica completa
├── ROADMAP.es.md              # Hoja de ruta del proyecto
├── LICENSE                    # MIT
├── NOTICE.es.md               # Atribucion para uso comercial
├── CITATION.cff               # Citacion academica
└── docs/                      # Documentacion adicional
```

---

## Instalacion

No requiere instalacion. Clona el repositorio y configura tu clave API:

```powershell
git clone https://github.com/asturwebs/RAG-Converter-Tool.git
cd RAG_Converter_Tool
Copy-Item ".env.example" ".env"
```

Edita `.env` y anade tu `OPENROUTER_API_KEY`.

## Uso rapido

```powershell
# Cargar alias en la sesion actual
. ".\Enable-RagAlias.ps1"

# Convertir todos los documentos de una carpeta
rag -Target "C:\Ruta\Documentos"

# Convertir un archivo concreto
rag -Target "C:\Ruta\Informe.docx" -Reprocess

# Generar informe de certificacion
rag-report -Modo comercial -Cliente "Acme Corp"
rag-report -Modo tecnico -Cliente "Acme Corp"
```

## Multi-cliente

Gestiona multiples clientes con archivos de entorno independientes:

```powershell
# Crear configuracion por cliente
Copy-Item ".env.example" ".env.acme.prod"
Copy-Item ".env.example" ".env.contoso.staging"

# Ejecutar por cliente
rag -EnvFile ".env.acme.prod" -Target "C:\Ruta\Documentos"
```

## Informes de certificacion

La herramienta genera informes automaticos con metricas reales de la ejecucion:

- **Comercial:** Resumen ejecutivo para entrega a clientes
- **Tecnico:** Auditoria forense con metricas detalladas

Ambos modos incluyen: archivos procesados, imagenes analizadas, estado QA, tiempos y firma del responsable.

## Perfiles

Tres perfiles predefinidos con configuracion de modelo ajustada:

| Perfil | Uso |
|--------|-----|
| `default` | Desarrollo y pruebas |
| `staging` | Pre-produccion con parametros conservadores |
| `prod` | Produccion con maxima calidad de analisis |

## Licencia

MIT. Ver [LICENSE](./LICENSE).

Uso comercial: se agradece atribucion visible al autor. Ver [NOTICE.es.md](./NOTICE.es.md).

## Autor

**Pedro Luis Cuevas Villarrubia** — Innovation Practitioner & AI Agent Architect
