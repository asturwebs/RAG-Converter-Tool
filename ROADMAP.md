[English](ROADMAP.md) | [Español](ROADMAP.es.md) | [简体中文](ROADMAP.zh-CN.md) | [한국어](ROADMAP.ko-KR.md)

# Roadmap — RAG Converter Tool

> Document conversion tool for RAG pipelines.
> Goal: become the open-source standard for document ingestion in RAG systems.

---

## Phase 1 — Core Python (Cross-Platform Foundation)

**Goal:** Eliminate the dependency on PowerShell + Windows + Office COM.

### 1.1 Python Engine
- [ ] Rewrite the engine in Python 3.11+
- [ ] DOCX extraction: `python-docx` (no Office dependency)
- [ ] PPTX extraction: `python-pptx` (no Office dependency)
- [ ] DOC extraction (legacy): `antiword` + `textract` as fallback
- [ ] Native CLI via `click` or `typer`
- [ ] Compatibility: Windows, macOS, Linux

### 1.2 Vision AI Integration
- [ ] Migrate OpenRouter calls to `httpx` (async, timeout, retry)
- [ ] Multi-provider support: OpenRouter, OpenAI, Anthropic, Ollama (local)
- [ ] Provider configuration via `.env` (like the current multi-client system)

### 1.3 QA and Normalization
- [ ] Port OCR dictionary and token maps to Python
- [ ] Port QA validation system (`Test-RagOutput` equivalent)
- [ ] Unit tests with `pytest` (>80% coverage)

### 1.4 Distribution
- [ ] `pip` package: `pip install rag-converter-tool`
- [ ] Docker image for use without local installation
- [ ] `pyproject.toml` with metadata, dependencies, and entry points

**Deliverable:** `rag-converter-tool` v3.0.0 on PyPI + Docker Hub

---

## Phase 2 — Multi-Document

**Goal:** Support the most common formats in real-world environments.

| Format | Library | Priority |
|--------|---------|----------|
| **PDF** | `PyMuPDF` (`fitz`) + `pdfplumber` | CRITICAL |
| **XLSX / XLS** | `openpyxl` | HIGH |
| **CSV / TSV** | Built-in `csv` | HIGH |
| **ODT / ODP** | `odfpy` + `ezodf` | MEDIUM |
| **RTF** | `striprtf` | MEDIUM |
| **EPUB** | `ebooklib` | LOW |
| **Standalone images** (PNG, JPG, WEBP) | Direct Vision AI | HIGH |
| **HTML** | `beautifulsoup4` | MEDIUM |
| **Markdown** | Passthrough + validation | LOW |

### 2.1 PDF Extraction (priority #1)
- [ ] Text extraction with structure preservation
- [ ] Detection and extraction of embedded tables
- [ ] Embedded image extraction → Vision AI
- [ ] Scanned PDF handling (image → OCR → text)
- [ ] Support for protected PDFs (where legally permitted)

### 2.2 Tabular Extraction (XLSX/CSV)
- [ ] Sheets → Markdown tables
- [ ] Automatic header detection
- [ ] Chunking option: by row vs. by block

### 2.3 Standalone Images
- [ ] Image folder input (PNG, JPG, WEBP)
- [ ] Direct Vision AI analysis without document wrapper
- [ ] Markdown generation with per-image analysis blocks

### 2.4 Format Registry (plugin system)
- [ ] Per-format extractor architecture (registry pattern)
- [ ] Each format = an independent extractor
- [ ] Easy to add new formats without touching the core

**Deliverable:** `rag-converter-tool` v3.1.0 with PDF + XLSX + image support

---

## Phase 3 — API and SaaS

**Goal:** Monetization via service. Users pay for conversion, not for installation.

### 3.1 REST API
- [ ] FastAPI with async endpoints
- [ ] `POST /convert` — file upload, returns Markdown
- [ ] `POST /batch` — batch of files
- [ ] `GET /status/{job_id}` — progress check
- [ ] `GET /report/{job_id}` — certification report download
- [ ] Authentication via API keys
- [ ] Rate limiting per plan

### 3.2 Web UI
- [ ] Drag-and-drop interface
- [ ] Preview of generated Markdown
- [ ] Direct download or link to result
- [ ] Conversion history dashboard

### 3.3 Subscription Models
- **Free:** 10 conversions/month, PDF up to 5MB
- **Pro:** 500 conversions/month, all formats, up to 50MB, API access
- **Enterprise:** Unlimited, SSO, dedicated API, SLA

### 3.4 Infrastructure
- [ ] Docker Compose for self-hosted deployment
- [ ] Worker queue (Celery/Redis) for async processing
- [ ] S3-compatible storage for files and results
- [ ] Anonymous usage telemetry (opt-in)

**Deliverable:** `rag-converter-api` v1.0.0 deployable on any VPS

---

## Phase 4 — Differentiators (What Nobody Else Has)

### 4.1 Intelligent RAG Chunking
- [ ] Semantic chunking (not fixed-token)
- [ ] Respect for section, paragraph, and page boundaries
- [ ] Configurable overlap between chunks
- [ ] Source metadata per chunk (file, page, section)
- [ ] Export to formats ready for LangChain, LlamaIndex, ChromaDB

### 4.2 Certifiable Quality
- [ ] Automatic quality score per document (0-100)
- [ ] Original document fingerprint (SHA-256 hash)
- [ ] Full traceability: original file → chunk → embedding
- [ ] Batch audit reports (current feature, improved)

### 4.3 Domain Profiles
- [ ] Predefined profiles: Legal, Medical, Academic, Technical, Financial
- [ ] Each profile adjusts: terminology, noise to filter, output structure
- [ ] User-customizable profiles
- [ ] Profile marketplace (community contribution)

### 4.4 Integrations
- [ ] LangChain plugin (`RAGConverterLoader`)
- [ ] LlamaIndex plugin
- [ ] Connector for ChromaDB, Pinecone, Weaviate
- [ ] Webhook to notify external pipelines when a batch completes

**Deliverable:** `rag-converter-tool` v4.0.0 with chunking + integrations

---

## Long-Term Vision

- **Autonomous agent:** The tool as an agent that ingests, chunks, embeds, and stores in a complete RAG system with a single instruction.
- **Domain profile marketplace** with community contributions.
- **ONNX Runtime** for local execution without external APIs (OCR + vision).
- **VS Code extension** for preview and conversion from the editor.

---

## Estimated Timeline

| Phase | Scope | Estimated Effort |
|-------|-------|------------------|
| Phase 1 | Python core + Docker | 2-3 weeks |
| Phase 2 | PDF + XLSX + images | 1-2 weeks |
| Phase 3 | API + Web UI | 3-4 weeks |
| Phase 4 | Chunking + integrations | 2-3 weeks |

---

## Contributions

Contributions are welcome. See [LICENSE](./LICENSE) and [NOTICE.md](./NOTICE.md) for terms.

**Areas where contributions are sought:**
- New format extractors
- Domain profiles
- RAG framework integrations
- Tests and documentation

---

## Author's Note

RAG Converter Tool was born as an internal tool for a real project converting educational materials to RAG-Ready format. After validating its usefulness in production, it was decided to release it as open source so the community can benefit.

If you find this tool useful and use it in a commercial environment, visible attribution to the original author is appreciated. See [NOTICE.md](./NOTICE.md).

---

*Pedro Luis Cuevas Villarrubia — Innovation Practitioner & AI Agent Architect*
*Asturias, Spain — 2026*
