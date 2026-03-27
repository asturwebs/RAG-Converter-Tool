# Roadmap — RAG Converter Tool

> Herramienta de conversión documental para pipelines RAG.
> Objetivo: convertirse en el estándar open-source de ingesta documental para sistemas RAG.

---

## Fase 1 — Core Python (Fundación Multiplataforma)

**Objetivo:** Eliminar la dependencia de PowerShell + Windows + Office COM.

### 1.1 Motor Python
- [ ] Reescritura del motor en Python 3.11+
- [ ] Extracción DOCX: `python-docx` (sin dependencia de Office)
- [ ] Extracción PPTX: `python-pptx` (sin dependencia de Office)
- [ ] Extracción DOC (legado): `antiword` + `textract` como fallback
- [ ] CLI nativa via `click` o `typer`
- [ ] Compatibilidad: Windows, macOS, Linux

### 1.2 Integración Vision AI
- [ ] Migrar llamadas OpenRouter a `httpx` (async, timeout, retry)
- [ ] Soporte multi-proveedor: OpenRouter, OpenAI, Anthropic, Ollama (local)
- [ ] Configuración de proveedor por `.env` (como el sistema multi-cliente actual)

### 1.3 QA y Normalización
- [ ] Portar diccionario OCR y token maps a Python
- [ ] Portar sistema de validación QA (`Test-RagOutput` equivalente)
- [ ] Tests unitarios con `pytest` (cobertura >80%)

### 1.4 Distribución
- [ ] Paquete `pip`: `pip install rag-converter-tool`
- [ ] Imagen Docker para uso sin instalación local
- [ ] `pyproject.toml` con metadata, dependencias y entry points

**Entregable:** `rag-converter-tool` v3.0.0 en PyPI + Docker Hub

---

## Fase 2 — Multi-Documento

**Objetivo:** Soportar los formatos más comunes en entornos reales.

| Formato | Librería | Prioridad |
|---------|----------|-----------|
| **PDF** | `PyMuPDF` (`fitz`) + `pdfplumber` | CRITICA |
| **XLSX / XLS** | `openpyxl` | ALTA |
| **CSV / TSV** | Built-in `csv` | ALTA |
| **ODT / ODP** | `odfpy` + `ezodf` | MEDIA |
| **RTF** | `striprtf` | MEDIA |
| **EPUB** | `ebooklib` | BAJA |
| **Imágenes sueltas** (PNG, JPG, WEBP) | Vision AI directa | ALTA |
| **HTML** | `beautifulsoup4` | MEDIA |
| **Markdown** | Passthrough + validación | BAJA |

### 2.1 Extracción PDF (prioridad #1)
- [ ] Extracción de texto con preservación de estructura
- [ ] Detección y extracción de tablas embebidas
- [ ] Extracción de imágenes embebidas → Vision AI
- [ ] Manejo de PDF escaneados (imagen → OCR → texto)
- [ ] Soporte para PDF protegidos (donde sea legal)

### 2.2 Extracción Tabular (XLSX/CSV)
- [ ] Hojas → tablas Markdown
- [ ] Detección automática de encabezados
- [ ] Opción de chunking por fila vs por bloque

### 2.3 Imágenes sueltas
- [ ] Input de carpetas de imágenes (PNG, JPG, WEBP)
- [ ] Análisis Vision AI directo sin wrapper documental
- [ ] Generación de Markdown con bloques de análisis por imagen

### 2.4 Registro de formatos (plugin system)
- [ ] Arquitectura de extractores por formato (registry pattern)
- [ ] Cada formato = un extractor independiente
- [ ] Fácil añadir nuevos formatos sin tocar el core

**Entregable:** `rag-converter-tool` v3.1.0 con soporte PDF + XLSX + imágenes

---

## Fase 3 — API y SaaS

**Objetivo:** Monetización vía servicio. Los usuarios pagan por conversión, no por instalar.

### 3.1 REST API
- [ ] FastAPI con endpoints async
- [ ] `POST /convert` — subida de archivo, devuelve Markdown
- [ ] `POST /batch` — lote de archivos
- [ ] `GET /status/{job_id}` — consulta de progreso
- [ ] `GET /report/{job_id}` — descarga de informe de certificación
- [ ] Autenticación via API keys
- [ ] Rate limiting por plan

### 3.2 Web UI
- [ ] Interfaz de arrastrar-y-soltar (drag & drop)
- [ ] Vista previa del Markdown generado
- [ ] Descarga directa o enlace al resultado
- [ ] Dashboard de historial de conversiones

### 3.3 Modelos de suscripción
- **Free:** 10 conversiones/mes, PDF hasta 5MB
- **Pro:** 500 conversiones/mes, todos los formatos, hasta 50MB, API access
- **Enterprise:** Ilimitado, SSO, API dedicada, SLA

### 3.4 Infraestructura
- [ ] Docker Compose para despliegue auto-hospedado
- [ ] Worker queue (Celery/Redis) para procesamiento asíncrono
- [ ] Almacenamiento S3-compatible para archivos y resultados
- [ ] Telemetría anónima de uso (opt-in)

**Entregable:** `rag-converter-api` v1.0.0 desplegable en cualquier VPS

---

## Fase 4 — Diferenciadores (Lo que nadie tiene)

### 4.1 Chunking Inteligente para RAG
- [ ] Chunking por semántica (no por tokens fijos)
- [ ] Respeto de fronteras de sección, párrafo y página
- [ ] Overlap configurable entre chunks
- [ ] Metadatos de fuente por chunk (archivo, página, sección)
- [ ] Exportación a formatos listos para LangChain, LlamaIndex, ChromaDB

### 4.2 Calidad Certificable
- [ ] Score de calidad automático por documento (0-100)
- [ ] Fingerprint del documento original (hash SHA-256)
- [ ] Traza completa: archivo original → chunk → embedding
- [ ] Informes de auditoría por lote (feature actual, mejorado)

### 4.3 Perfiles de Dominio
- [ ] Perfiles predefinidos: Legal, Médico, Académico, Técnico, Financiero
- [ ] Cada perfil ajusta: terminología, ruido a filtrar, estructura de salida
- [ ] Perfiles personalizables por el usuario
- [ ] Marketplace de perfiles (contribución comunitaria)

### 4.4 Integraciones
- [ ] Plugin para LangChain (`RAGConverterLoader`)
- [ ] Plugin para LlamaIndex
- [ ] Connector para ChromaDB, Pinecone, Weaviate
- [ ] Webhook para notificar a pipelines externos al terminar un lote

**Entregable:** `rag-converter-tool` v4.0.0 con chunking + integraciones

---

## Visión a largo plazo

- **Agente autónomo:** El tool como agente que ingesta, chunka, embeda y almacena en un RAG completo con una sola instrucción.
- ** marketplace de perfiles de dominio** con contribuciones de la comunidad.
- **ONNX Runtime** para ejecución local sin API externa (OCR + visión).
- **Extensión VS Code** para preview y conversión desde el editor.

---

## Timeline orientativa

| Fase | Scope | Esfuerzo estimado |
|------|-------|-------------------|
| Fase 1 | Python core + Docker | 2-3 semanas |
| Fase 2 | PDF + XLSX + imágenes | 1-2 semanas |
| Fase 3 | API + Web UI | 3-4 semanas |
| Fase 4 | Chunking + integraciones | 2-3 semanas |

---

## Contribuciones

Las contribuciones son bienvenidas. Ver [LICENSE](./LICENSE) y [NOTICE.md](./NOTICE.md) para términos.

**Areas donde se busca contribución:**
- Nuevos extractores de formato
- Perfiles de dominio
- Integraciones con frameworks RAG
- Tests y documentación

---

## Nota del autor

RAG Converter Tool nació como una herramienta interna para un proyecto real de conversión de materiales educativos a formato RAG-Ready. Tras validar su utilidad en producción, se decidió liberar como open source para que la comunidad se beneficie.

Si esta herramienta te es útil y la usas en un entorno comercial, se agradece la atribución visible al autor original. Ver [NOTICE.md](./NOTICE.md).

---

*Pedro Luis Cuevas Villarrubia — Innovation Practitioner & AI Agent Architect*
*Asturias, España — 2026*
