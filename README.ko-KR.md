<div align="center">

# RAG Converter Tool

**Office 문서를 RAG 파이프라인에 바로 사용할 수 있는 Markdown으로 변환합니다.**

[English](README.md) | [Español](README.es.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko-KR.md)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/asturwebs/RAG-Converter-Tool/blob/main/LICENSE)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7+-5391DE.svg)](https://learn.microsoft.com/en-us/powershell/scripting/overview)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)
[![Release v2.0.0](https://img.shields.io/badge/release-v2.0.0-green.svg)

</div>

---

`.doc`, `.docx`, `.pptx` 파일을 RAG 시스템에 최적화된 구조화된 Markdown으로 변환합니다. AI 이미지 분석, 품질 검증, 인증 보고서 생성을 지원합니다.

실제 프로덕션 환경에서 검증된 내부 도구로 시작되었습니다. 커뮤니티를 위해 오픈소스로 공개합니다.

---

## 기능

| 기능 | 설명 |
|------|------|
| **문서 변환** | Office를 계층 구조, 목차, 앵커가 포함된 Markdown으로 변환 |
| **AI 비전** | 내장 이미지 분석: OCR, 공간 분석, 교육적 가치 추출 |
| **자동 QA** | 배치 검증, `NORM_OK` 또는 `NORM_WITH_ERRORS` 상태 출력 |
| **보고서** | 실제 메트릭 기반의 상업용 및 기술용 보고서 생성 |
| **다중 클라이언트** | `.env.<client>.<environment>`로 독립적 구성 |
| **멱등성** | 이미 처리된 파일 자동 건너뛰기; `-Reprocess`로 강제 재처리 |

## 현재 제한사항

- **Windows**에 Microsoft Word 및 PowerPoint 설치 필요 (COM 자동화)
- **PowerShell 7+** 필요
- 비전 모델 API 키 필요 (OpenRouter, OpenAI 등)

[로드맵](./ROADMAP.ko-KR.md)에 크로스 플랫폼 지원(Python, Docker) 및 추가 형식(PDF, XLSX, 이미지) 계획이 포함되어 있습니다.

---

## 프로젝트 구조

```
RAG_Converter_Tool/
├── Convert-OfficeToRAG.ps1     # 메인 변환 및 QA 엔진
├── Run-RAG.ps1                # .env 지원 런처
├── Enable-RagAlias.ps1         # 세션 별칭 (rag, rr, rag-report)
├── Gen-Report.ps1             # 보고서 생성기
├── .env.example              # 구성 템플릿
├── DEV_GUIDE.ko-KR.md         # 전체 기술 가이드
├── ROADMAP.ko-KR.md           # 프로젝트 로드맵
├── LICENSE                    # MIT
├── NOTICE.ko-KR.md            # 상업적 사용 시 저작자 표기
├── CITATION.cff               # 학술 인용
└── docs/                      # 추가 문서
```

---

## 설치

설치 불필요. 저장소를 복제하고 API 키를 구성하세요:

```powershell
git clone https://github.com/asturwebs/RAG-Converter-Tool.git
cd RAG_Converter_Tool
Copy-Item ".env.example" ".env"
```

`.env`를 편집하고 `OPENROUTER_API_KEY`를 추가하세요.

## 빠른 시작

```powershell
# 현재 세션에 별칭 로드
. ".\Enable-RagAlias.ps1"

# 폴더의 모든 문서 변환
rag -Target "C:\Path\Documents"

# 특정 파일 변환
rag -Target "C:\Path\Report.docx" -Reprocess

# 인증 보고서 생성
rag-report -Modo comercial -Cliente "Acme Corp"
rag-report -Modo tecnico -Cliente "Acme Corp"
```

## 다중 클라이언트

독립적인 환경 파일로 여러 클라이언트를 관리하세요:

```powershell
# 클라이언트별 구성 생성
Copy-Item ".env.example" ".env.acme.prod"
Copy-Item ".env.example" ".env.contoso.staging"

# 클라이언트별 실행
rag -EnvFile ".env.acme.prod" -Target "C:\Path\Documents"
```

## 인증 보고서

실제 실행 메트릭 기반 자동 보고서 생성:

- **상업용:** 클라이언트 납품용 경영 요약
- **기술용:** 상세 메트릭 포함 포렌식 감사

두 모드 모두 포함: 처리된 파일, 분석된 이미지, QA 상태, 소요 시간, 책임자 서명.

## 프로필

세 가지 사전 정의 프로필, 튜닝된 모델 구성:

| 프로필 | 용도 |
|--------|------|
| `default` | 개발 및 테스트 |
| `staging` | 보수적 파라미터의 사전 프로덕션 |
| `prod` | 최고 분석 품질의 프로덕션 |

## 라이선스

MIT. [LICENSE](./LICENSE) 참조.

상업적 사용: 저작자 표기를 권장합니다. [NOTICE.ko-KR.md](./NOTICE.ko-KR.md) 참조.

## 저자

**Pedro Luis Cuevas Villarrubia** — Innovation Practitioner & AI Agent Architect
