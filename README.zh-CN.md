<div align="center">

# RAG Converter Tool

**将 Office 文档转换为适用于 RAG 管道的 Markdown。**

[English](README.md) | [Español](README.es.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko-KR.md)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/asturwebs/RAG-Converter-Tool/blob/main/LICENSE)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7+-5391DE.svg)](https://learn.microsoft.com/en-us/powershell/scripting/overview)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)
[![Release v2.0.0](https://img.shields.io/badge/release-v2.0.0-green.svg)

</div>

---

将 `.doc`、`.docx` 和 `.pptx` 文件转换为结构化 Markdown，专为 RAG 系统优化，支持 AI 图像分析、质量验证和认证报告生成。

源于生产环境验证的内部工具。作为开源项目发布，造福社区。

---

## 功能特性

| 功能 | 说明 |
|------|------|
| **文档转换** | Office 转 Markdown，保留层级结构、目录和锚点 |
| **AI 视觉** | 嵌入图像分析：OCR、空间分析、教学价值提取 |
| **自动质检** | 批量验证，输出 `NORM_OK` 或 `NORM_WITH_ERRORS` 状态 |
| **报告生成** | 基于真实指标生成商业和技术报告 |
| **多客户端** | 通过 `.env.<client>.<environment>` 实现独立配置 |
| **幂等操作** | 自动跳过已处理文件；`-Reprocess` 强制重新处理 |

## 当前限制

- **Windows** 系统，需安装 Microsoft Word 和 PowerPoint（COM 自动化）
- 需要 **PowerShell 7+**
- 需要视觉模型 API 密钥（OpenRouter、OpenAI 等）

[路线图](./ROADMAP.zh-CN.md) 包含跨平台支持（Python、Docker）和更多格式（PDF、XLSX、图像）的计划。

---

## 项目结构

```
RAG_Converter_Tool/
├── Convert-OfficeToRAG.ps1     # 主转换和质检引擎
├── Run-RAG.ps1                # 启动器，支持 .env
├── Enable-RagAlias.ps1         # 会话别名（rag、rr、rag-report）
├── Gen-Report.ps1             # 报告生成器
├── .env.example              # 配置模板
├── DEV_GUIDE.zh-CN.md         # 完整技术指南
├── ROADMAP.zh-CN.md           # 项目路线图
├── LICENSE                    # MIT
├── NOTICE.zh-CN.md            # 商业使用署名
├── CITATION.cff               # 学术引用
└── docs/                      # 附加文档
```

---

## 安装

无需安装。克隆仓库并配置 API 密钥：

```powershell
git clone https://github.com/asturwebs/RAG-Converter-Tool.git
cd RAG_Converter_Tool
Copy-Item ".env.example" ".env"
```

编辑 `.env` 并添加你的 `OPENROUTER_API_KEY`。

## 快速开始

```powershell
# 在当前会话中加载别名
. ".\Enable-RagAlias.ps1"

# 转换文件夹中的所有文档
rag -Target "C:\Path\Documents"

# 转换指定文件
rag -Target "C:\Path\Report.docx" -Reprocess

# 生成认证报告
rag-report -Modo comercial -Cliente "Acme Corp"
rag-report -Modo tecnico -Cliente "Acme Corp"
```

## 多客户端管理

通过独立环境文件管理多个客户端：

```powershell
# 创建每个客户端的配置
Copy-Item ".env.example" ".env.acme.prod"
Copy-Item ".env.example" ".env.contoso.staging"

# 按客户端运行
rag -EnvFile ".env.acme.prod" -Target "C:\Path\Documents"
```

## 认证报告

工具基于真实执行指标自动生成报告：

- **商业版：** 面向客户交付的执行摘要
- **技术版：** 包含详细指标的前瞻审计

两种模式均包含：已处理文件、已分析图像、质检状态、耗时和负责人签名。

## 配置档案

三个预定义配置档案，内置调优的模型配置：

| 档案 | 用途 |
|------|------|
| `default` | 开发和测试 |
| `staging` | 预生产环境，使用保守参数 |
| `prod` | 生产环境，最高分析质量 |

## 许可证

MIT。详见 [LICENSE](./LICENSE)。

商业使用：建议对原作者进行署名。详见 [NOTICE.zh-CN.md](./NOTICE.zh-CN.md)。

## 作者

**Pedro Luis Cuevas Villarrubia** — Innovation Practitioner & AI Agent Architect
