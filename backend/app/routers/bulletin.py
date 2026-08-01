from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import json

from app.database import get_db
from app.models import Bulletin

router = APIRouter(prefix="/api/v1/church", tags=["Church Bulletin"])

@router.get("/bulletins")
async def get_bulletins(db: AsyncSession = Depends(get_db)):
    """
    모바일 앱 주보 탭에서 조회할 수 있는 최신 및 과거 주보 목록을 반환합니다.
    자체 메모리 캐시 및 로컬 우선 정책을 적용하여, 클라이언트는 이 주소 목록만 캐싱해 페이징 뷰어를 구동합니다.
    """
    result = await db.execute(select(Bulletin).order_by(Bulletin.date.desc()))
    bulletins_list = result.scalars().all()
    
    response = []
    for b in bulletins_list:
        try:
            pages = json.loads(b.pages_json)
        except Exception:
            pages = []
            
        response.append({
            "date": b.date,
            "label": b.label,
            "pages": pages
        })
        
    return response
