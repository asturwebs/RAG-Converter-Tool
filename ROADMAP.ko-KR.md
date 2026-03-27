[English](ROADMAP.md) | [Español](ROADMAP.es.md) | [简体中文](ROADMAP.zh-CN.md) | [한국어](ROADMAP.ko-KR.md)

# 로드맵 — RAG Converter Tool

> RAG 파이프라인을 위한 문서 변환 도구.
> 목표: RAG 시스템의 문서 수집을 위한 오픈소스 표준이 되는 것.

---

## 단계 1 — Python 코어 (크로스 플랫폼 기반)

**목표:** PowerShell + Windows + Office COM 의존성 제거.

### 1.1 Python 엔진
- [ ] Python 3.11+로 엔진 재작성
- [ ] DOCX 추출: `python-docx` (Office 의존성 없음)
- [ ] PPTX 추출: `python-pptx` (Office 의존성 없음)
- [ ] DOC 추출 (레거시): `antiword` + `textract` 폴백
- [ ] `click` 또는 `typer`를 통한 네이티브 CLI
- [ ] 호환성: Windows, macOS, Linux

### 1.2 Vision AI 통합
- [ ] OpenRouter 호출을 `httpx`로 마이그레이션 (비동기, 타임아웃, 재시도)
- [ ] 멀티 프로바이더 지원: OpenRouter, OpenAI, Anthropic, Ollama (로컬)
- [ ] `.env`를 통한 프로바이더 설정 (현재 멀티 클라이언트 시스템과 동일)

### 1.3 QA 및 정규화
- [ ] OCR 사전 및 토큰 맵을 Python으로 포팅
- [ ] QA 검증 시스템 포팅 (`Test-RagOutput` 동급)
- [ ] `pytest`를 사용한 단위 테스트 (커버리지 >80%)

### 1.4 배포
- [ ] `pip` 패키지: `pip install rag-converter-tool`
- [ ] 로컬 설치 없이 사용 가능한 Docker 이미지
- [ ] 메타데이터, 의존성 및 엔트리 포인트가 포함된 `pyproject.toml`

**전달물:** PyPI + Docker Hub의 `rag-converter-tool` v3.0.0

---

## 단계 2 — 멀티 문서

**목표:** 실제 환경에서 가장 일반적인 형식 지원.

| 형식 | 라이브러리 | 우선순위 |
|------|-----------|----------|
| **PDF** | `PyMuPDF` (`fitz`) + `pdfplumber` | 매우 높음 |
| **XLSX / XLS** | `openpyxl` | 높음 |
| **CSV / TSV** | 내장 `csv` | 높음 |
| **ODT / ODP** | `odfpy` + `ezodf` | 보통 |
| **RTF** | `striprtf` | 보통 |
| **EPUB** | `ebooklib` | 낮음 |
| **개별 이미지** (PNG, JPG, WEBP) | 직접 Vision AI | 높음 |
| **HTML** | `beautifulsoup4` | 보통 |
| **Markdown** | 패스스루 + 검증 | 낮음 |

### 2.1 PDF 추출 (우선순위 #1)
- [ ] 구조 보존 텍스트 추출
- [ ] 내장 테이블 감지 및 추출
- [ ] 내장 이미지 추출 → Vision AI
- [ ] 스캔 PDF 처리 (이미지 → OCR → 텍스트)
- [ ] 보호된 PDF 지원 (법적으로 허용되는 범위 내)

### 2.2 표 형식 추출 (XLSX/CSV)
- [ ] 시트 → Markdown 테이블
- [ ] 자동 헤더 감지
- [ ] 행별 청킹 vs 블록별 청킹 옵션

### 2.3 개별 이미지
- [ ] 이미지 폴더 입력 (PNG, JPG, WEBP)
- [ ] 문서 래퍼 없이 직접 Vision AI 분석
- [ ] 이미지별 분석 블록이 포함된 Markdown 생성

### 2.4 형식 레지스트리 (플러그인 시스템)
- [ ] 형식별 추출기 아키텍처 (레지스트리 패턴)
- [ ] 각 형식 = 독립적인 추출기
- [ ] 코어 수정 없이 새 형식 추가 용이

**전달물:** PDF + XLSX + 이미지 지원이 포함된 `rag-converter-tool` v3.1.0

---

## 단계 3 — API 및 SaaS

**목표:** 서비스를 통한 수익화. 사용자는 설치가 아닌 변환에 대해 결제.

### 3.1 REST API
- [ ] 비동기 엔드포인트가 포함된 FastAPI
- [ ] `POST /convert` — 파일 업로드, Markdown 반환
- [ ] `POST /batch` — 파일 일괄 처리
- [ ] `GET /status/{job_id}` — 진행 상태 확인
- [ ] `GET /report/{job_id}` — 인증 보고서 다운로드
- [ ] API 키를 통한 인증
- [ ] 플랜별 속도 제한

### 3.2 Web UI
- [ ] 드래그 앤 드롭 인터페이스
- [ ] 생성된 Markdown 미리보기
- [ ] 직접 다운로드 또는 결과 링크
- [ ] 변환 기록 대시보드

### 3.3 구독 모델
- **Free:** 월 10회 변환, PDF 최대 5MB
- **Pro:** 월 500회 변환, 모든 형식, 최대 50MB, API 접근
- **Enterprise:** 무제한, SSO, 전용 API, SLA

### 3.4 인프라
- [ ] 자체 호스팅 배포를 위한 Docker Compose
- [ ] 비동기 처리를 위한 Worker 큐 (Celery/Redis)
- [ ] 파일 및 결과를 위한 S3 호환 스토리지
- [ ] 익명 사용 텔레메트리 (옵트인)

**전달물:** 모든 VPS에 배포 가능한 `rag-converter-api` v1.0.0

---

## 단계 4 — 차별화 요소 (다른 곳에 없는 것)

### 4.1 지능형 RAG 청킹
- [ ] 의미 기반 청킹 (고정 토큰이 아님)
- [ ] 섹션, 단락, 페이지 경계 준수
- [ ] 청크 간 구성 가능한 오버랩
- [ ] 청크별 소스 메타데이터 (파일, 페이지, 섹션)
- [ ] LangChain, LlamaIndex, ChromaDB 즉시 사용 가능 형식으로 내보내기

### 4.2 인증 가능한 품질
- [ ] 문서별 자동 품질 점수 (0-100)
- [ ] 원본 문서 지문 (SHA-256 해시)
- [ ] 전체 추적 가능성: 원본 파일 → 청크 → 임베딩
- [ ] 일괄 감사 보고서 (기존 기능, 개선됨)

### 4.3 도메인 프로필
- [ ] 사전 정의된 프로필: 법률, 의료, 학술, 기술, 금융
- [ ] 각 프로필 조정: 용어, 필터링할 노이즈, 출력 구조
- [ ] 사용자 맞춤형 프로필
- [ ] 프로필 마켓플레이스 (커뮤니티 기여)

### 4.4 통합
- [ ] LangChain 플러그인 (`RAGConverterLoader`)
- [ ] LlamaIndex 플러그인
- [ ] ChromaDB, Pinecone, Weaviate 커넥터
- [ ] 일괄 처리 완료 시 외부 파이프라인에 알리는 Webhook

**전달물:** 청킹 + 통합이 포함된 `rag-converter-tool` v4.0.0

---

## 장기 비전

- **자율 에이전트:** 단일 명령으로 수집, 청킹, 임베딩 및 완전한 RAG 시스템에 저장하는 에이전트로서의 도구.
- **커뮤니티 기여가 포함된 도메인 프로필 마켓플레이스**.
- **ONNX Runtime**을 통한 외부 API 없는 로컬 실행 (OCR + 비전).
- **VS Code 확장 프로그램**을 통한 편집기 내 미리보기 및 변환.

---

## 예상 타임라인

| 단계 | 범위 | 예상 작업량 |
|------|------|-------------|
| 단계 1 | Python 코어 + Docker | 2-3주 |
| 단계 2 | PDF + XLSX + 이미지 | 1-2주 |
| 단계 3 | API + Web UI | 3-4주 |
| 단계 4 | 청킹 + 통합 | 2-3주 |

---

## 기여

기여를 환영합니다. 이용 약관은 [LICENSE](./LICENSE) 및 [NOTICE.ko-KR.md](./NOTICE.ko-KR.md)를 참조하세요.

**기여가 필요한 분야:**
- 새로운 형식 추출기
- 도메인 프로필
- RAG 프레임워크 통합
- 테스트 및 문서화

---

## 작성자 노트

RAG Converter Tool은 교육 자료를 RAG-Ready 형식으로 변환하는 실제 프로젝트의 내부 도구로 탄생했습니다. 프로덕션 환경에서의 유용성을 검증한 후, 커뮤니티가 혜택을 받을 수 있도록 오픈소스로 공개하기로 결정했습니다.

이 도구가 유용하고 상업적 환경에서 사용하신다면, 원작자에 대한 가시적인 저작자 표기를 부탁드립니다. [NOTICE.ko-KR.md](./NOTICE.ko-KR.md)를 참조하세요.

---

*Pedro Luis Cuevas Villarrubia — Innovation Practitioner & AI Agent Architect*
*스페인 아스투리아스 — 2026*
