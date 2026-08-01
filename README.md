# ✝️ 명선아이워십 (Myungsun iWorship)

> **"울림과 떨림으로 드리는 예배, 누림과 살림이 가득한 삶"**  
> 명선교회 청·장년 말씀 묵상(QT) 및 주보 자동 정렬·동기화 통합 플랫폼

---

## 📌 1. 프로젝트 개요 (Project Overview)

**명선아이워십(iWorship)**은 명선교회 성도들의 매일 말씀 묵상(QT) 작성과 매주일 주보 조회를 오프라인 퍼스트(Local-First) 환경에서 원활하게 지원하는 **맞춤형 모바일 웹/앱 및 스마트 백엔드 플랫폼**입니다.

* **교인용 모바일 앱**: 네트워크 연결이 불안정한 환경에서도 **0.01초 만에 로컬 캐시**로 묵상 본문과 주보 이미지를 즉시 렌더링하며, 백그라운드 비동기 통신을 통해 서버 최신 데이터 및 개인 작성 노트를 **LWW (Last-Write-Wins) 방식**으로 안전하게 동기화합니다.
* **스마트 관리자 시스템**: 주보 이미지 업로드 시 **Google Gemini AI Vision 배치 연동 알고리즘**이 표지 날짜를 자동 식별하고 4개 지면(표지, 설교, 공지, 소식)을 자동 분류 및 크롭합니다. 분류 오류 발생 시 관리자 웹 콘솔에서 **`◀ 이전` / `다음 ▶`** 버튼 클릭 한 번으로 지면 순서를 손쉽게 교환(Reorder)할 수 있습니다.

---

## 🏗️ 2. 시스템 아키텍처 (System Architecture)

```mermaid
graph TD
    subgraph Mobile Client [Flutter Mobile & Web App]
        UI[Flutter UI - Material 3]
        Provider[QtProvider / State Management]
        LocalDB[(SQLite & SharedPreferences)]
        Cache[Bulletin Base64 Image Cache]
    end

    subgraph Backend Server [FastAPI & Docker Container]
        API[FastAPI Router /api/v1]
        AdminConsole[Admin Web Console /admin]
        Sync[LWW Note Sync Engine]
        VisionPipeline[Gemini Vision Bulletin Pipeline]
    end

    subgraph Infrastructure [Data & AI Layer]
        PG[(PostgreSQL Database)]
        Redis[(Redis Cache)]
        Gemini[Google Gemini API]
    end

    UI <--> Provider
    Provider <--> LocalDB
    Provider <--> Cache
    Provider <-->|REST API / Json| API
    AdminConsole <--> API
    API <--> PG
    API <--> Redis
    VisionPipeline <--> Gemini
```

---

## 🛠️ 3. 기술 스택 (Tech Stack)

### 📱 Frontend (Mobile & Web)
| 구분 | 기술 스택 | 설명 |
|---|---|---|
| **Framework** | **Flutter 3.22+** | iOS, Android, Web 멀티플랫폼 지원 |
| **State Management** | **Provider** | 반응형 상태 관리 및 중앙 데이터 파이프라인 |
| **Local Storage** | **SQLite (sqflite)**, **SharedPreferences** | 묵상 노트 및 주보 Base64 영구 캐싱 (Local-First) |
| **Network & Sync** | **Dio** | REST API 통신, `Uri.base.origin` 동적 IP 자동 감지 |
| **Design System** | **Material 3 / Custom CSS** | 퍼플 파스텔 컬러 Palette (`#7C6893`, `#645179`), Pretendard 서체 |

### ⚙️ Backend & Infrastructure
| 구분 | 기술 스택 | 설명 |
|---|---|---|
| **Framework** | **Python FastAPI**, **Uvicorn** | 고성능 비동기 REST API 서버 |
| **Database** | **PostgreSQL 15**, **SQLModel / SQLAlchemy** | 비동기 ORM (`asyncpg`) 데이터베이스 |
| **Cache & Queue** | **Redis** | 세션 및 API 요청 캐싱 |
| **AI Integration** | **Google Gemini API (Vision)** | 이미지 1회 배치 파싱 (Single-Call Batch Classification) |
| **Containerization** | **Docker**, **Docker Compose** | 컨테이너 기반 서버 멀티 서비스 오케스트레이션 |

---

## ✨ 4. 주요 기능 (Key Features)

### 1) ⚡ 0.01초 오프라인 퍼스트 (Local-First) 렌더링 & 백그라운드 동기화
* 앱 접속 즉시 인터넷 통신 대기 없이 스마트폰 로컬 저장소에 저장된 QT 본문과 주보 4개 지면을 **0.01초 만에 화면에 렌더링**.
* 앱 구동 후 백그라운드 비동기 루틴이 서버의 신규 업데이트 유무를 자동으로 체크하여 최신 데이터로 로컬 캐시를 갱신.
* 성도가 작성한 묵상 노트는 Device ID 기반 **LWW (Last-Write-Wins) 충돌 해결 알고리즘**을 거쳐 서버 백업 DB와 실시간 동기화.

### 2) 🤖 Gemini AI 주보 3단계 전처리 파이프라인 & 관리자 정렬 (Admin Console)
* **1회 통합 배치 파싱 (Single-Call Batch)**: 4개 주보 지면 업로드 시 API 호출 1회만으로 표지 좌상단 날짜와 1~4p 지면 속성(표지, 설교, 광고, 소식)을 자동 분류하여 처리 속도 400% 향상 및 API 429 Rate Limit 방지.
* **관리자 콘솔 (`/admin`) 데이터 제어**:
  * **`✏️ 날짜 수정`**: AI 오인식 시 주보/QT 날짜를 수동으로 변경 (디스크 파일명 및 DB 자동 동기화).
  * **`🗑️ 삭제`**: 불필요하거나 잘못 등록된 주보/QT 데이터를 원클릭 삭제.
  * **`◀ 이전` / `다음 ▶`**: AI 지면 순서가 뒤섞였을 경우 버튼 클릭 한 번으로 지면 순서를 교환하여 모바일 앱에 즉시 반영.

### 3) 📖 주일 / 평일 맞춤형 QT 묵상 양식
* **평일 묵상 양식**: 본문 묵상, 우모하 기도발전소(주간 공동체 기도), 아로새길 말씀 선택 자동 입력, 오늘의 감사, 적용 및 기도.
* **주일 묵상 양식**: 주일 IBS (3가지 나눔 질문) 양식 제공 및 단일 **주일 설교 NOTE (설교 제목 & 메시지 메모)** 통합 카드 UI 제공.

### 4) 🖼️ 시그니처 수채화 표지 스플래시 로딩 (Splash Screen)
* 실제 **'아이워십 청·장년용'** 교재의 수채화 명선교회 그림과 하단 손글씨 캘리그라피 문구를 화면 크기에 맞게 중앙 정렬(`BoxFit.contain`)하고, 하늘색 톤 배경(`Color(0xFF5C7B9E)`)과 조화롭게 배치한 감성 스플래시 화면 구동.

---

## 📂 5. 프로젝트 디렉토리 구조 (Directory Structure)

```text
iworship/
├── backend/                        # FastAPI 백엔드 프로젝트
│   ├── app/
│   │   ├── admin_static/           # 관리자 웹 콘솔 HTML/JS/CSS (/admin)
│   │   ├── flutter_web/            # 빌드된 Flutter Web 정적 파일 (/app)
│   │   ├── models/                 # SQLModel DB 테이블 데이터 구조
│   │   ├── routers/                # REST API 엔드포인트 (admin, qt, bulletin)
│   │   └── services/               # Gemini AI 파이프라인 서비스
│   ├── docker-compose.yml          # Docker 서버 서비스 구성
│   └── Dockerfile
├── iworship_mobile/                # Flutter 모바일/웹 앱 프로젝트
│   ├── assets/                     # 브랜드 로고 및 스플래시 표지 이미지
│   ├── lib/
│   │   ├── models/                 # Dart 데이터 모델 (DailyScripture, UserNote 등)
│   │   ├── providers/              # QtProvider 상태 관리 및 동적 IP 감지
│   │   ├── screens/                # UI 화면 (HomeScreen, QtViewScreen, BulletinScreen 등)
│   │   └── services/               # ApiService, DatabaseHelper, BulletinCacheService
│   ├── web/                        # Flutter Web PWA 패키징 파일 (index.html, manifest.json)
│   └── pubspec.yaml
└── README.md
```

---

## 🚀 6. 실행 및 배포 가이드 (Getting Started)

### 1) 백엔드 서버 실행 (Docker)
```bash
cd backend
# 환경 변수 설정 (.env 파일에 GEMINI_API_KEY 입력)
echo "GEMINI_API_KEY=your_gemini_api_key" > .env

# Docker 컴포즈 실행
docker compose up -d --build
```
* **관리자 웹 콘솔**: `http://localhost:8000/admin`
* **모바일 웹 앱**: `http://localhost:8000/app/`
* **Swagger API 문서**: `http://localhost:8000/docs`

### 2) 모바일 앱 빌드 & 배포 (Flutter)
```bash
cd iworship_mobile

# 패키지 설치
flutter pub get

# Flutter Web 빌드 및 백엔드 적용
flutter build web --base-href "/app/"
cp -r build/web/* ../backend/app/flutter_web/
cd ../backend && docker compose restart web
```

---

## 📄 7. 라이선스 및 저작권 (License)

* 본 프로젝트의 소스코드는 **명선교회** 말씀 묵상 및 주보 서비스를 위해 제작되었습니다.
* 교재 이미지 및 캘리그라피 문구의 저작권은 명선교회에 있습니다.
