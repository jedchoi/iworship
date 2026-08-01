import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.database import init_db
from app.routers import qt, bulletin, admin

app = FastAPI(
    title="아이워십 (iWorship) 백엔드 API 서비스",
    description="모바일 QT 앱 및 교회 관리자 동기화 통합 백엔드 시스템",
    version="1.0.0"
)

# CORS 설정 (개발 단계 및 교단 내부망 자유로운 접근을 위함)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 미디어 파일 및 정적 리소스 경로 동적 마운트
MEDIA_DIR = "media"
os.makedirs(MEDIA_DIR, exist_ok=True)
app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")
app.mount("/static", StaticFiles(directory=MEDIA_DIR), name="static")

# 데이터베이스 자동 초기화 (컨테이너 최초 기동 시 테이블 생성)
@app.on_event("startup")
async def on_startup():
    await init_db()

# 라우터 등록
app.include_router(qt.router)
app.include_router(bulletin.router)
app.include_router(admin.router)

# 관리자 웹 콘솔 정적 마운트
ADMIN_STATIC_DIR = os.path.join("app", "admin_static")
os.makedirs(ADMIN_STATIC_DIR, exist_ok=True)

from fastapi.responses import FileResponse

@app.get("/admin")
@app.get("/admin/")
async def serve_admin_page():
    return FileResponse(os.path.join(ADMIN_STATIC_DIR, "index.html"))

from fastapi.responses import RedirectResponse

@app.get("/app")
async def redirect_app_root():
    return RedirectResponse(url="/app/")

# Flutter 앱 웹 빌드 마운트 (/app 접속 시 실행)
FLUTTER_WEB_DIR = os.path.join("app", "flutter_web")
if os.path.exists(FLUTTER_WEB_DIR):
    app.mount("/app", StaticFiles(directory=FLUTTER_WEB_DIR, html=True), name="flutter_app")

@app.get("/")
def read_root():
    return {
        "project": "iWorship (아이워십) 백엔드 서비스",
        "status": "online",
        "flutter_mobile_app": "/app",
        "admin_console": "/admin",
        "documentation": "/docs"
    }
