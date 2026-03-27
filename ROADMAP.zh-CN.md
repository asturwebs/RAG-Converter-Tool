[English](ROADMAP.md) | [Español](ROADMAP.es.md) | [简体中文](ROADMAP.zh-CN.md) | [한국어](ROADMAP.ko-KR.md)

# 路线图 — RAG Converter Tool

> 面向 RAG 管道的文档转换工具。
> 目标：成为 RAG 系统中文档摄取的开源标准。

---

## 阶段 1 — Python 核心（跨平台基础）

**目标：** 消除对 PowerShell + Windows + Office COM 的依赖。

### 1.1 Python 引擎
- [ ] 使用 Python 3.11+ 重写引擎
- [ ] DOCX 提取：`python-docx`（无 Office 依赖）
- [ ] PPTX 提取：`python-pptx`（无 Office 依赖）
- [ ] DOC 提取（旧版）：`antiword` + `textract` 作为后备方案
- [ ] 通过 `click` 或 `typer` 实现原生 CLI
- [ ] 兼容性：Windows、macOS、Linux

### 1.2 Vision AI 集成
- [ ] 将 OpenRouter 调用迁移至 `httpx`（异步、超时、重试）
- [ ] 多提供商支持：OpenRouter、OpenAI、Anthropic、Ollama（本地）
- [ ] 通过 `.env` 进行提供商配置（如同当前的多客户端系统）

### 1.3 质量保证与规范化
- [ ] 将 OCR 字典和 token 映射移植到 Python
- [ ] 移植 QA 验证系统（`Test-RagOutput` 等效方案）
- [ ] 使用 `pytest` 进行单元测试（覆盖率 >80%）

### 1.4 分发
- [ ] `pip` 包：`pip install rag-converter-tool`
- [ ] Docker 镜像，无需本地安装即可使用
- [ ] `pyproject.toml` 包含元数据、依赖项和入口点

**交付物：** PyPI + Docker Hub 上的 `rag-converter-tool` v3.0.0

---

## 阶段 2 — 多文档支持

**目标：** 支持实际环境中最常见的格式。

| 格式 | 库 | 优先级 |
|------|-----|--------|
| **PDF** | `PyMuPDF` (`fitz`) + `pdfplumber` | 关键 |
| **XLSX / XLS** | `openpyxl` | 高 |
| **CSV / TSV** | 内置 `csv` | 高 |
| **ODT / ODP** | `odfpy` + `ezodf` | 中 |
| **RTF** | `striprtf` | 中 |
| **EPUB** | `ebooklib` | 低 |
| **独立图片**（PNG、JPG、WEBP） | 直接 Vision AI | 高 |
| **HTML** | `beautifulsoup4` | 中 |
| **Markdown** | 直通 + 验证 | 低 |

### 2.1 PDF 提取（优先级 #1）
- [ ] 带结构保留的文本提取
- [ ] 嵌入式表格的检测与提取
- [ ] 嵌入式图片提取 → Vision AI
- [ ] 扫描版 PDF 处理（图片 → OCR → 文本）
- [ ] 受保护 PDF 支持（在法律允许的范围内）

### 2.2 表格提取（XLSX/CSV）
- [ ] 工作表 → Markdown 表格
- [ ] 自动检测表头
- [ ] 按行分块 vs 按块分块的选项

### 2.3 独立图片
- [ ] 图片文件夹输入（PNG、JPG、WEBP）
- [ ] 无文档包装器的直接 Vision AI 分析
- [ ] 生成包含逐图分析块的 Markdown

### 2.4 格式注册表（插件系统）
- [ ] 按格式的提取器架构（注册表模式）
- [ ] 每种格式 = 一个独立的提取器
- [ ] 无需触碰核心即可轻松添加新格式

**交付物：** 支持 PDF + XLSX + 图片的 `rag-converter-tool` v3.1.0

---

## 阶段 3 — API 与 SaaS

**目标：** 通过服务实现商业化。用户为转换付费，而非为安装付费。

### 3.1 REST API
- [ ] FastAPI 异步端点
- [ ] `POST /convert` — 上传文件，返回 Markdown
- [ ] `POST /batch` — 批量文件
- [ ] `GET /status/{job_id}` — 进度查询
- [ ] `GET /report/{job_id}` — 认证报告下载
- [ ] 通过 API 密钥进行身份验证
- [ ] 按计划进行速率限制

### 3.2 Web UI
- [ ] 拖放界面
- [ ] 生成的 Markdown 预览
- [ ] 直接下载或结果链接
- [ ] 转换历史仪表板

### 3.3 订阅模式
- **Free：** 每月 10 次转换，PDF 最大 5MB
- **Pro：** 每月 500 次转换，所有格式，最大 50MB，API 访问
- **Enterprise：** 无限制，SSO，专用 API，SLA

### 3.4 基础设施
- [ ] Docker Compose 用于自托管部署
- [ ] Worker 队列（Celery/Redis）用于异步处理
- [ ] S3 兼容存储用于文件和结果
- [ ] 匿名使用遥测（可选加入）

**交付物：** 可部署于任何 VPS 的 `rag-converter-api` v1.0.0

---

## 阶段 4 — 差异化特性（别人没有的）

### 4.1 智能 RAG 分块
- [ ] 语义分块（非固定 token）
- [ ] 尊重章节、段落和页面边界
- [ ] 可配置的分块重叠
- [ ] 每个分块的源元数据（文件、页面、章节）
- [ ] 导出为 LangChain、LlamaIndex、ChromaDB 即用格式

### 4.2 可认证的质量
- [ ] 每个文档的自动质量评分（0-100）
- [ ] 原始文档指纹（SHA-256 哈希）
- [ ] 完整追溯：原始文件 → 分块 → 嵌入
- [ ] 批量审计报告（现有功能，改进版）

### 4.3 领域配置文件
- [ ] 预定义配置文件：法律、医学、学术、技术、金融
- [ ] 每个配置文件调整：术语、要过滤的噪声、输出结构
- [ ] 用户可自定义配置文件
- [ ] 配置文件市场（社区贡献）

### 4.4 集成
- [ ] LangChain 插件（`RAGConverterLoader`）
- [ ] LlamaIndex 插件
- [ ] ChromaDB、Pinecone、Weaviate 连接器
- [ ] Webhook 在批处理完成时通知外部管道

**交付物：** 带分块 + 集成的 `rag-converter-tool` v4.0.0

---

## 长期愿景

- **自主代理：** 该工具作为代理，通过单一指令即可完成摄取、分块、嵌入和存储到完整的 RAG 系统中。
- **领域配置文件市场**，接受社区贡献。
- **ONNX Runtime** 用于本地执行，无需外部 API（OCR + 视觉）。
- **VS Code 扩展**，支持从编辑器预览和转换。

---

## 预估时间线

| 阶段 | 范围 | 预估工作量 |
|------|------|------------|
| 阶段 1 | Python 核心 + Docker | 2-3 周 |
| 阶段 2 | PDF + XLSX + 图片 | 1-2 周 |
| 阶段 3 | API + Web UI | 3-4 周 |
| 阶段 4 | 分块 + 集成 | 2-3 周 |

---

## 贡献

欢迎贡献。请参阅 [LICENSE](./LICENSE) 和 [NOTICE.zh-CN.md](./NOTICE.zh-CN.md) 了解条款。

**寻求贡献的领域：**
- 新格式提取器
- 领域配置文件
- RAG 框架集成
- 测试和文档

---

## 作者说明

RAG Converter Tool 最初是一个内部工具，用于一个将教育材料转换为 RAG-Ready 格式的真实项目。在验证了其在生产环境中的实用性后，决定以开源方式发布，让社区受益。

如果您觉得这个工具很有用并在商业环境中使用，感谢对原作者进行可见的署名。请参阅 [NOTICE.zh-CN.md](./NOTICE.zh-CN.md)。

---

*Pedro Luis Cuevas Villarrubia — Innovation Practitioner & AI Agent Architect*
*西班牙阿斯图里亚斯 — 2026*
