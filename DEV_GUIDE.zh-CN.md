[English](DEV_GUIDE.md) | [Español](DEV_GUIDE.es.md) | [简体中文](DEV_GUIDE.zh-CN.md) | [한국어](DEV_GUIDE.ko-KR.md)

# 开发指南 - RAG Converter Tool

## 1) 目标

此工具将 Office 文件（`.doc`、`.docx`、`.pptx`）转换为针对 RAG 优化的 Markdown，保持结构保真度并应用安全的语言规范化。

主脚本：

- `Convert-OfficeToRAG.ps1`

## 2) 系统要求

- 已安装 Microsoft Word 和 PowerPoint 的 Windows 系统（COM 自动化）。
- 已安装 PowerShell 7（`pwsh`）。
- 对源文件夹具有读写权限。

快速验证：

```powershell
pwsh -NoProfile -Command "$PSVersionTable.PSVersion"
```

## 3) 配置

编辑 `Convert-OfficeToRAG.ps1` 开头的 `$Config` 块：

- `SourceFolders`：要处理的源文件夹。
- `FileExtensions`：允许的扩展名。
- `OcrDictionary`：保守的 OCR 字典。
- `ResidualOcrRegex`：残留验证正则表达式。
- `LogPath`、`QaLogPath`、`SummaryPath`：日志输出路径。
- `ForceReprocess`：强制重新处理文件，即使 `.md` 已存在。

可移植行为：

- 如果路径是相对路径，脚本将从 `Convert-OfficeToRAG.ps1` 所在文件夹解析它。
- 默认情况下，日志（`rag_converter_log.txt`、`rag_converter_qa_log.txt`、`rag_converter_summary.txt`）写入脚本文件夹内的 `outputs/logs`。
- `SourceFolders` 默认指向脚本文件夹的 `..\input`。

关键环境变量：

- `RAG_SOURCE_FOLDERS`：接受以 `;` 或 `,` 分隔的多个路径。
- `RAG_SOURCE_FILES`：接受以 `;` 或 `,` 分隔的一个或多个具体文件。
- `RAG_FORCE_REPROCESS`：`true/false`，即使 `.md` 存在也重新处理。
- `RAG_FAIL_FAST`：`true/false`，遇到错误时中止或继续。
- `RAG_ENABLE_PREFLIGHT`：`true/false`，启用/禁用 preflight API。
- `RAG_OPENROUTER_MODEL`：要使用的视觉模型。

脚本直接参数（高优先级，推荐在自动化中使用）：

- `-SourceFoldersOverride <string[]>`
- `-SourceFilesOverride <string[]>`
- `-ForceReprocessOverride <bool>`
- `-FailFastOverride <bool>`
- `-EnablePreflightOverride <bool>`
- `-OpenRouterModelOverride <string>`

## 4) 标准执行

始终使用 `pwsh` 运行以保持 UTF-8 稳定性。路径无关命令：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
pwsh -NoProfile -File (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

预期控制台输出：

- `NORM_OK` 或 `NORM_WITH_ERRORS`。

## 5) 单命令（运行 + 验证）

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"; pwsh -NoProfile -Command "$s=(Join-Path '$toolDir' 'Convert-OfficeToRAG.ps1'); $sum=(Join-Path '$toolDir' 'outputs\logs\rag_converter_summary.txt'); & $s; if($LASTEXITCODE -ne 0){ throw 'Falló la ejecución del convertidor' }; $st=(Get-Content $sum | Select-String '^STATUS=').Line; if($st -ne 'STATUS=NORM_OK'){ throw \"Estado inválido: $st\" }; Write-Host 'OK => STATUS=NORM_OK' -ForegroundColor Green"
```

## 6) 日常操作

快速摘要审计：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
Get-Content -Path (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt")
```

单行状态查看：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
(Get-Content (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt") | Select-String '^STATUS=').Line
```

QA 事件查看：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
$qa = Join-Path $toolDir "outputs\logs\rag_converter_qa_log.txt"
if((Test-Path $qa) -and ((Get-Item $qa).Length -gt 0)){Get-Content $qa}else{"Sin incidencias QA"}
```

## 7) 脚本结构（`Convert-OfficeToRAG.ps1`）

脚本采用稳健和模块化的设计方法：

### 1. 领域注入（通用提示词）
脚本不再耦合到特定主题（如足球）。它使用配置变量动态地将上下文注入到 AI 模型的提示词中：
- `$Config.DomainContext`：定义环境（例如"高性能体育教育环境"）。
- `$Config.DomainNoiseFilter`：模型应忽略的关键词（例如"服装颜色、风景、天气"）。
- `$Config.DomainTechnicalTerms`：术语精确性指令（例如避免将专业术语替换为歧义同义词）。

### 2. 图像提取和结构化 OCR
图像分析通过 OpenRouter API 执行。新提示词要求严格的 Markdown 输出格式，包括：
1. **字面 OCR**：幻灯片中文字的精确转录。
2. **空间技术分析**：图表和箭头的解释。
3. **教学价值**：核心概念的提取。

### 3. 详细程度和日志系统
为避免在大规模运行时"盲目操作"：
- **控制台输出（详细模式）**：显示实时进度（`[1/10] 正在处理...`、`[图像 3/5] 正在请求分析...`、`正在生成最终 Markdown`）。
- **COM 遥测**：测量并显示 `Word.Open` 和 `Word.SaveAs(HTML)` 的时间以检测瓶颈。
- **日志文件：**
  - `rag_converter_log.txt`：记录带有 `INFO` 和 `ERROR` 的事件（包括堆栈跟踪）。
  - `rag_converter_qa_log.txt`：记录验证错误（例如不完整的图像分析）。
  - `rag_converter_summary.txt`：最终执行摘要。

### 4. 配置文件和自动回退
- 支持如 `default` 和 `staging` 等配置文件，无需修改代码即可快速切换模型。
- 包含一个 preflight 检查，在开始前验证 API 连接性和多模态支持，如果模型不支持图像，则自动从 `vision` 回退到 `text`。

## 8) 故障排除

- 如果使用 `powershell.exe` 启动时出现正则表达式/重音符号乱码，请使用 `pwsh`。
- 如果 COM 失败，请验证 Word/PowerPoint 安装和活动用户会话。
- 如果状态为 `NORM_WITH_ERRORS`，请先检查 `rag_converter_qa_log.txt`。
- 如果移动了 `RAG_Converter_Tool` 文件夹，脚本仍然可以工作；只需在源文件位于其他位置时检查 `SourceFolders`。
- 如果 Word 提取速度慢，请在控制台查看 `Word.Open`/`Word.SaveAs(HTML)` 时间以定位瓶颈。
- 如果存在锁定的临时文件（`~$*.docx`），请在运行批处理之前在 Office 中关闭它们。

## 9) 快速操作手册

完整执行（已配置文件夹）：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

强制完整重新处理：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

单文件执行：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_SOURCE_FILES="D:\Ruta\Input\Documento.docx"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

单文件执行（通过参数，推荐）：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -SourceFilesOverride "D:\Ruta\Input\Documento.docx" -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

完整执行即使 `.md` 已存在（通过参数）：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

## 10) 使用 `.env` 和别名的简单工作流

1) 通过复制模板创建 `.env`：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env") -Force
```

2) 编辑 `.env` 并设置你的 `OPENROUTER_API_KEY`。

3) 在当前会话中加载短别名：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1")
```

4) 使用短命令：

```powershell
rag
rag -Target "D:\Ruta\Input"
rag -Target "D:\Ruta\Input\Documento.docx"
rag -Target "D:\Ruta\Input\Documento.docx" -Reprocess
rr -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

5) 可选：在 PowerShell 配置文件中持久化别名：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1") -Persist
```

6) 使用专用 `.env` 文件实现多客户端扩展：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

一般说明：
- 为每个客户端和环境创建一个 `.env` 文件。
- `.env` 解析器支持以 `#` 开头的行中的注释。

按客户端使用而无需输入长命令：

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

## 11) 新客户端入职

无需修改代码即可上线新客户的快速检查清单：

1) 创建客户端环境文件：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.<cliente>.<entorno>") -Force
```

2) 编辑 `.env.<cliente>`：
- `OPENROUTER_API_KEY`：客户端密钥。
- `RAG_OPENROUTER_MODEL`：为该客户端商定的模型。
- `RAG_FAIL_FAST`、`RAG_ENABLE_PREFLIGHT`、`RAG_FORCE_REPROCESS`：运营策略。
- 允许在以 `#` 开头的行中使用注释。

3) 对单个文件运行最小测试：

```powershell
rag -EnvFile ".env.<cliente>" -Target "D:\Ruta\Documento.docx"
```

4) 验证结果：
- 控制台显示 `NORM_OK`。
- 查看 `rag_converter_summary.txt` 和 `rag_converter_qa_log.txt`。
- 在此版本中，产物位于 `outputs/logs`。

5) 客户端日常操作：

```powershell
rag -EnvFile ".env.<cliente>.<entorno>"
```

6) 需要时进行完整重新处理：

```powershell
rag -EnvFile ".env.<cliente>.<entorno>" -Reprocess
```

## 12) `.env` 命名约定（企业级）

为实现无摩擦扩展，请使用以下约定：

- `.env.<cliente>.<entorno>`
- `<cliente>`：稳定标识符（无空格），例如 `acme`、`clinicax`、`lexcorp`。
- `<entorno>`：`dev`、`staging` 或 `prod`。

示例：

- `.env.acme.dev`
- `.env.acme.prod`
- `.env.lexcorp.staging`

推荐工作流：

1) 从客户端基础创建按环境的变体：

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

2) 按环境执行：

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input" -Reprocess
```

## 13) RAG-Ready 认证报告

从 `rag_converter_summary.txt` 自动生成执行报告：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Firmante "Nombre Apellido" -Modo comercial
```

可选定义输出路径：

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Modo tecnico -OutputPath (Join-Path $toolDir "outputs\reports\Informe_RAG_Auditoria.md")
```

说明：
- 报告使用摘要/日志中的真实指标；如果数据点不存在，则显示为 `N/D`。
- 如果 KPI（例如 OCR 百分比或加速比）未在证据文件中测量，则避免编造。
- 可用模式：`-Modo comercial`（执行摘要叙述）和 `-Modo tecnico`（取证审计）。
- 默认情况下，日志生成在 `outputs/logs`，报告生成在 `outputs/reports`（可移植路径，非硬编码）。
- 报告包含 `DHI (Data Health Index)`，采用 0-100 分制和等级（`WORLD CLASS`、`ENTERPRISE READY`、`ACCEPTABLE`、`NEEDS IMPROVEMENT`）。
- DHI 由 4 个加权支柱计算：完整性（30）、语义（40）、OCR 规范化（20）、引用（10）。
- 无图像的情况（`VISION_ITEMS=0`）：不扣分；在语义支柱中标记为 `Texto puro`。
- DHI 计算使用 `summary + qa log`；你可以使用 `-QaPath` 覆盖 QA。

使用别名的快捷方式（加载 `Enable-RagAlias.ps1` 后）：

```powershell
rag-report -Modo comercial -Cliente "Cliente Demo" -Firmante "Nombre Apellido"
rag-report -Modo tecnico -Cliente "Cliente Demo" -OutputPath "D:\Ruta\RAG_Converter_Tool\outputs\reports\Informe_RAG_Auditoria.md"
```
