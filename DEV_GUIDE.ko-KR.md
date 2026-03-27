[English](DEV_GUIDE.md) | [Español](DEV_GUIDE.es.md) | [简体中文](DEV_GUIDE.zh-CN.md) | [한국어](DEV_GUIDE.ko-KR.md)

# 개발 가이드 - RAG Converter Tool

## 1) 목적

이 도구는 Office 파일(`.doc`, `.docx`, `.pptx`)을 RAG에 최적화된 Markdown으로 변환하며, 구조적 충실도를 유지하고 안전한 언어 정규화를 적용합니다.

메인 스크립트:

- `Convert-OfficeToRAG.ps1`

## 2) 요구 사항

- Microsoft Word 및 PowerPoint가 설치된 Windows(COM 자동화).
- PowerShell 7(`pwsh`)이 설치되어 있어야 함.
- 소스 폴더에 대한 읽기/쓰기 권한.

빠른 확인:

```powershell
pwsh -NoProfile -Command "$PSVersionTable.PSVersion"
```

## 3) 구성

`Convert-OfficeToRAG.ps1` 시작 부분의 `$Config` 블록을 편집합니다:

- `SourceFolders`: 처리할 소스 폴더.
- `FileExtensions`: 허용된 확장자.
- `OcrDictionary`: 보수적 OCR 사전.
- `ResidualOcrRegex`: 잔여 검증 정규식.
- `LogPath`, `QaLogPath`, `SummaryPath`: 로그 출력 경로.
- `ForceReprocess`: `.md`가 이미 존재하더라도 파일을 강제로 재처리.

이식 가능한 동작:

- 경로가 상대 경로인 경우, 스크립트는 `Convert-OfficeToRAG.ps1`이 있는 폴더에서 경로를 해석합니다.
- 기본적으로 로그(`rag_converter_log.txt`, `rag_converter_qa_log.txt`, `rag_converter_summary.txt`)는 스크립트 폴더 내의 `outputs/logs`에 기록됩니다.
- `SourceFolders`는 기본적으로 스크립트 폴더 기준 `..\input`을 가리킵니다.

주요 환경 변수:

- `RAG_SOURCE_FOLDERS`: `;` 또는 `,`로 구분된 여러 경로를 허용.
- `RAG_SOURCE_FILES`: `;` 또는 `,`로 구분된 하나 이상의 특정 파일을 허용.
- `RAG_FORCE_REPROCESS`: `.md`가 존재하더라도 재처리할지 여부(`true/false`).
- `RAG_FAIL_FAST`: 오류 발생 시 중단 또는 계속 여부(`true/false`).
- `RAG_ENABLE_PREFLIGHT`: preflight API 활성화/비활성화(`true/false`).
- `RAG_OPENROUTER_MODEL`: 사용할 비전 모델.

스크립트 직접 파라미터(높은 우선순위, 자동화에 권장):

- `-SourceFoldersOverride <string[]>`
- `-SourceFilesOverride <string[]>`
- `-ForceReprocessOverride <bool>`
- `-FailFastOverride <bool>`
- `-EnablePreflightOverride <bool>`
- `-OpenRouterModelOverride <string>`

## 4) 표준 실행

항상 `pwsh`로 실행하여 UTF-8 안정성을 유지합니다. 경로 무관 명령:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
pwsh -NoProfile -File (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

예상 콘솔 출력:

- `NORM_OK` 또는 `NORM_WITH_ERRORS`.

## 5) 단일 명령(실행 + 검증)

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"; pwsh -NoProfile -Command "$s=(Join-Path '$toolDir' 'Convert-OfficeToRAG.ps1'); $sum=(Join-Path '$toolDir' 'outputs\logs\rag_converter_summary.txt'); & $s; if($LASTEXITCODE -ne 0){ throw 'Falló la ejecución del convertidor' }; $st=(Get-Content $sum | Select-String '^STATUS=').Line; if($st -ne 'STATUS=NORM_OK'){ throw \"Estado inválido: $st\" }; Write-Host 'OK => STATUS=NORM_OK' -ForegroundColor Green"
```

## 6) 일상 운영

빠른 요약 감사:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
Get-Content -Path (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt")
```

한 줄 상태 확인:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
(Get-Content (Join-Path $toolDir "outputs\logs\rag_converter_summary.txt") | Select-String '^STATUS=').Line
```

QA 이벤트 확인:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
$qa = Join-Path $toolDir "outputs\logs\rag_converter_qa_log.txt"
if((Test-Path $qa) -and ((Get-Item $qa).Length -gt 0)){Get-Content $qa}else{"Sin incidencias QA"}
```

## 7) 스크립트 구조(`Convert-OfficeToRAG.ps1`)

스크립트는 견고하고 모듈식 설계 방식으로 구성되어 있습니다:

### 1. 도메인 주입(범용 프롬프트)
스크립트는 더 이상 특정 주제(예: 축구)에 결합되지 않습니다. 구성 변수를 사용하여 AI 모델 프롬프트에 컨텍스트를 동적으로 주입합니다:
- `$Config.DomainContext`: 환경을 정의합니다(예: "고성능 스포츠 교육 환경").
- `$Config.DomainNoiseFilter`: 모델이 무시할 키워드(예: "의류 색상, 풍경, 날씨").
- `$Config.DomainTechnicalTerms`: 용어 정밀도 지침(예: 전문 용어를 모호한 동의어로 대체하지 않기).

### 2. 이미지 추출 및 구조화된 OCR
이미지 분석은 OpenRouter API를 통해 수행됩니다. 새 프롬프트는 다음을 포함하는 엄격한 Markdown 출력 형식을 요구합니다:
1. **문자 그대로의 OCR**: 슬라이드의 텍스트 정확한 전사.
2. **공간 기술 분석**: 다이어그램 및 화살표의 해석.
3. **교육적 가치**: 핵심 개념의 추출.

### 3. 상세 수준 및 로깅 시스템
대규모 실행 중 "장님 코끼리 만지기"를 방지하기 위해:
- **콘솔 출력(상세 모드)**: 실시간 진행 상황을 표시합니다(`[1/10] 처리 중...`, `[이미지 3/5] 분석 요청 중...`, `최종 Markdown 생성 중`).
- **COM 원격 측정**: `Word.Open` 및 `Word.SaveAs(HTML)` 시간을 측정하고 표시하여 병목 현상을 감지합니다.
- **로그 파일:**
  - `rag_converter_log.txt`: `INFO` 및 `ERROR`가 포함된 이벤트를 기록합니다(스택 트레이스 포함).
  - `rag_converter_qa_log.txt`: 검증 오류를 기록합니다(예: 불완전한 이미지 분석).
  - `rag_converter_summary.txt`: 최종 실행 요약.

### 4. 프로필 및 자동 폴백
- `default` 및 `staging`과 같은 프로필을 지원하여 코드를 수정하지 않고 빠르게 모델을 전환할 수 있습니다.
- 시작 전 API 연결성 및 멀티모달 지원을 확인하는 preflight 체크가 포함되며, 모델이 이미지를 지원하지 않는 경우 `vision`에서 `text`로 자동 폴백합니다.

## 8) 문제 해결

- `powershell.exe`로 실행 시 정규식/악센트 기호가 깨지면 `pwsh`를 사용하세요.
- COM이 실패하면 Word/PowerPoint 설치 및 활성 사용자 세션을 확인하세요.
- 상태가 `NORM_WITH_ERRORS`인 경우, 먼저 `rag_converter_qa_log.txt`를 확인하세요.
- `RAG_Converter_Tool` 폴더를 이동해도 스크립트는 계속 작동합니다. 소스가 다른 위치에 있는 경우 `SourceFolders`만 확인하세요.
- Word 추출이 느려지면 콘솔에서 `Word.Open`/`Word.SaveAs(HTML)` 시간을 확인하여 병목 현상을 찾으세요.
- 잠긴 임시 파일(`~$*.docx`)이 있는 경우, 배치를 실행하기 전에 Office에서 닫으세요.

## 9) 빠른 런북

전체 실행(구성된 폴더):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

강제 전체 재처리:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

단일 파일 실행:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; $env:RAG_OPENROUTER_MODEL="google/gemini-3.1-flash-lite-preview"; $env:RAG_SOURCE_FILES="D:\Ruta\Input\Documento.docx"; $env:RAG_FORCE_REPROCESS="true"; $env:RAG_FAIL_FAST="false"; $env:RAG_ENABLE_PREFLIGHT="false"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1")
```

단일 파일 실행(파라미터 사용, 권장):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -SourceFilesOverride "D:\Ruta\Input\Documento.docx" -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

`.md`가 이미 존재하더라도 전체 실행(파라미터 사용):

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
$env:OPENROUTER_API_KEY="TU_API_KEY"; & (Join-Path $toolDir "Convert-OfficeToRAG.ps1") -ForceReprocessOverride $true -FailFastOverride $false -EnablePreflightOverride $false -OpenRouterModelOverride "google/gemini-3.1-flash-lite-preview"
```

## 10) `.env` 및 별칭을 사용한 간단한 워크플로우

1) 템플릿을 복사하여 `.env` 생성:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env") -Force
```

2) `.env`를 편집하고 `OPENROUTER_API_KEY`를 설정하세요.

3) 현재 세션에 짧은 별칭 로드:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1")
```

4) 짧은 명령 사용:

```powershell
rag
rag -Target "D:\Ruta\Input"
rag -Target "D:\Ruta\Input\Documento.docx"
rag -Target "D:\Ruta\Input\Documento.docx" -Reprocess
rr -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

5) 선택 사항: PowerShell 프로필에 별칭 영구 저장:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
. (Join-Path $toolDir "Enable-RagAlias.ps1") -Persist
```

6) 전용 `.env` 파일을 사용한 다중 클라이언트 확장:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

일반 참고:
- 클라이언트 및 환경당 하나의 `.env` 파일을 만드세요.
- `.env` 파서는 `#`로 시작하는 행의 주석을 지원합니다.

긴 명령을 입력하지 않고 클라이언트별 사용:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input\Documento.docx" -Reprocess
```

## 11) 신규 클라이언트 온보딩

코드 수정 없이 신규 클라이언트를 온보딩하기 위한 빠른 체크리스트:

1) 클라이언트 환경 파일 생성:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.<cliente>.<entorno>") -Force
```

2) `.env.<cliente>` 편집:
- `OPENROUTER_API_KEY`: 클라이언트 키.
- `RAG_OPENROUTER_MODEL`: 해당 클라이언트에 합의된 모델.
- `RAG_FAIL_FAST`, `RAG_ENABLE_PREFLIGHT`, `RAG_FORCE_REPROCESS`: 운영 정책.
- `#`로 시작하는 행에 주석을 사용할 수 있습니다.

3) 단일 파일에 대해 최소 테스트 실행:

```powershell
rag -EnvFile ".env.<cliente>" -Target "D:\Ruta\Documento.docx"
```

4) 결과 검증:
- 콘솔에 `NORM_OK` 표시.
- `rag_converter_summary.txt` 및 `rag_converter_qa_log.txt` 확인.
- 이 버전에서 산출물은 `outputs/logs`에 있습니다.

5) 클라이언트 일일 운영:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>"
```

6) 필요 시 전체 재처리:

```powershell
rag -EnvFile ".env.<cliente>.<entorno>" -Reprocess
```

## 12) `.env` 명명 규칙(엔터프라이즈)

마찰 없는 확장을 위해 다음 규칙을 사용하세요:

- `.env.<cliente>.<entorno>`
- `<cliente>`: 안정적인 식별자(공백 없음), 예: `acme`, `clinicax`, `lexcorp`.
- `<entorno>`: `dev`, `staging` 또는 `prod`.

예시:

- `.env.acme.dev`
- `.env.acme.prod`
- `.env.lexcorp.staging`

권장 워크플로우:

1) 클라이언트 베이스에서 환경별 변형 생성:

```powershell
$toolDir = "D:\Ruta\RAG_Converter_Tool"
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.dev") -Force
Copy-Item (Join-Path $toolDir ".env.example") (Join-Path $toolDir ".env.acme.prod") -Force
```

2) 환경별 실행:

```powershell
rag -EnvFile ".env.acme.dev"
rag -EnvFile ".env.acme.prod" -Target "D:\Ruta\Input" -Reprocess
```

## 13) RAG-Ready 인증 보고서

`rag_converter_summary.txt`에서 자동으로 경영 보고서 생성:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Firmante "Nombre Apellido" -Modo comercial
```

선택적으로 출력 경로 정의:

```powershell
$toolDir = "D:\Ruta\Donde\Está\RAG_Converter_Tool"
& (Join-Path $toolDir "Gen-Report.ps1") -Cliente "Cliente Demo" -Modo tecnico -OutputPath (Join-Path $toolDir "outputs\reports\Informe_RAG_Auditoria.md")
```

참고:
- 보고서는 요약/로그의 실제 지표를 사용합니다. 데이터가 존재하지 않으면 `N/D`로 표시됩니다.
- 증거 파일에서 측정되지 않은 KPI(예: OCR 백분율 또는 가속 비율)는 만들어내지 않습니다.
- 사용 가능한 모드: `-Modo comercial`(경영 스토리텔링) 및 `-Modo tecnico`(포렌식 감사).
- 기본적으로 로그는 `outputs/logs`에, 보고서는 `outputs/reports`에 생성됩니다(하드코딩되지 않은 이식 가능한 경로).
- 보고서에는 0-100 점수 척도와 등급(`WORLD CLASS`, `ENTERPRISE READY`, `ACCEPTABLE`, `NEEDS IMPROVEMENT`)이 포함된 `DHI (Data Health Index)`가 통합되어 있습니다.
- DHI는 4개의 가중 기둥으로 계산됩니다: 무결성(30), 의미론(40), OCR 정규화(20), 인용(10).
- 이미지가 없는 경우(`VISION_ITEMS=0`): 페널티 없음. 의미론 기둥에 `Texto puro`로 표시됩니다.
- DHI 계산은 `summary + qa log`를 사용합니다. `-QaPath`로 QA를 덮어쓸 수 있습니다.

별칭을 사용한 바로가기(`Enable-RagAlias.ps1` 로드 후):

```powershell
rag-report -Modo comercial -Cliente "Cliente Demo" -Firmante "Nombre Apellido"
rag-report -Modo tecnico -Cliente "Cliente Demo" -OutputPath "D:\Ruta\RAG_Converter_Tool\outputs\reports\Informe_RAG_Auditoria.md"
```
