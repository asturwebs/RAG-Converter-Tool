<div align="center">

# RAG Converter Tool

**Convert Office documents to Markdown ready for RAG pipelines.**

[English](README.md) | [Español](README.es.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko-KR.md)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/asturwebs/RAG-Converter-Tool/blob/main/LICENSE)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7+-5391DE.svg)](https://learn.microsoft.com/en-us/powershell/scripting/overview)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)
[![Release v2.0.0](https://img.shields.io/badge/release-v2.0.0-green.svg)

</div>

---

Converts `.doc`, `.docx` and `.pptx` files into structured Markdown optimized for RAG systems, with AI-powered image analysis, quality validation and certification report generation.

Born as an internal tool validated in production. Released as open source for the community to benefit.

---

## What it does

| Capability | Description |
|-----------|-------------|
| **Conversion** | Office to Markdown with hierarchical structure, table of contents and anchors |
| **AI Vision** | Analysis of embedded images: OCR, spatial analysis, pedagogical value |
| **Automatic QA** | Batch validation with `NORM_OK` or `NORM_WITH_ERRORS` status |
| **Reports** | Generation of commercial and technical reports with real metrics |
| **Multi-client** | Independent configuration per client with `.env.<client>.<environment>` |
| **Idempotent** | Skips already processed files; `-Reprocess` forces reprocessing |

## Current limitations

- **Windows** with Microsoft Word and PowerPoint installed (COM automation)
- **PowerShell 7+** required
- Requires an API key from a vision model provider (OpenRouter, OpenAI, etc.)

The [roadmap](./ROADMAP.md) includes plans for cross-platform support (Python, Docker) and more formats (PDF, XLSX, images).

---

## Structure

```
RAG_Converter_Tool/
├── Convert-OfficeToRAG.ps1     # Main conversion and QA engine
├── Run-RAG.ps1                # Launcher with .env support
├── Enable-RagAlias.ps1         # Session aliases (rag, rr, rag-report)
├── Gen-Report.ps1             # Report generator
├── .env.example              # Configuration template
├── DEV_GUIDE.md              # Full technical guide
├── ROADMAP.md                # Project roadmap
├── LICENSE                   # MIT
├── NOTICE.md                  # Attribution for commercial use
├── CITATION.cff              # Academic citation
└── docs/                     # Additional documentation
```

---

## Installation

No installation required. Clone the repository and configure your API key:

```powershell
git clone https://github.com/asturwebs/RAG-Converter-Tool.git
cd RAG_Converter_Tool
Copy-Item ".env.example" ".env"
```

Edit `.env` and add your `OPENROUTER_API_KEY`.

## Quick start

```powershell
# Load aliases in the current session
. ".\Enable-RagAlias.ps1"

# Convert all documents in a folder
rag -Target "C:\Path\Documents"

# Convert a specific file
rag -Target "C:\Path\Report.docx" -Reprocess

# Generate certification report
rag-report -Modo comercial -Cliente "Acme Corp"
rag-report -Modo tecnico -Cliente "Acme Corp"
```

## Multi-client

Manage multiple clients with independent environment files:

```powershell
# Create configuration per client
Copy-Item ".env.example" ".env.acme.prod"
Copy-Item ".env.example" ".env.contoso.staging"

# Run per client
rag -EnvFile ".env.acme.prod" -Target "C:\Path\Documents"
```

## Certification reports

The tool generates automatic reports with real execution metrics:

- **Commercial:** Executive summary for client delivery
- **Technical:** Forensic audit with detailed metrics

Both modes include: processed files, analyzed images, QA status, timings and responsible signature.

## Profiles

Three predefined profiles with tuned model configuration:

| Profile | Use case |
|---------|----------|
| `default` | Development and testing |
| `staging` | Pre-production with conservative parameters |
| `prod` | Production with maximum analysis quality |

## License

MIT. See [LICENSE](./LICENSE).

Commercial use: visible attribution to the author is appreciated. See [NOTICE.md](./NOTICE.md).

## Author

**Pedro Luis Cuevas Villarrubia** — Innovation Practitioner & AI Agent Architect
