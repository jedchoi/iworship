from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import json

from app.database import get_db
from app.models import (
    DailyScripture, DailyScriptureResponse,
    WeeklyIntro, ServerQtNote,
    SyncPushRequest, SyncPullResponse, QtNoteSyncItem
)

router = APIRouter(prefix="/api/v1/qt", tags=["QT"])

@router.get("/bulk", response_model=List[DailyScriptureResponse])
async def get_bulk_qt(db: AsyncSession = Depends(get_db)):
    """
    모바일 앱 구동 시 오프라인 캐시 적재를 위해 전체 성경 말씀 묵상 본문을 반환합니다.
    """
    result = await db.execute(select(DailyScripture))
    scriptures = result.scalars().all()
    
    response = []
    for sc in scriptures:
        try:
            verses_list = json.loads(sc.verses_json)
        except Exception:
            verses_list = []
            
        response.append(DailyScriptureResponse(
            date=sc.date,
            title=sc.title,
            passage=sc.passage,
            verses=verses_list,
            bgm_commentary=sc.bgm_commentary,
            weekly_pray_category=sc.weekly_pray_category,
            weekly_prayer=sc.weekly_prayer,
            calligraphy_text=sc.calligraphy_text,
            calligraphy_ref=sc.calligraphy_ref
        ))
    return response

@router.get("/weekly-intro")
async def get_weekly_intro(
    start_date: str = Query(..., description="해당 주간의 주일 날짜 (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db)
):
    """
    주간 모달창 구성을 위해 특정 주차의 정보(제목, 캘리그라피 이미지, 일정 리스트)를 반환합니다.
    저장된 매일의 DailyScripture DB 데이터와 상호 자동 연동되어 일정을 동적으로 생성 및 보완합니다.
    """
    from datetime import datetime, timedelta

    # 1. 7일간의 날짜 및 요일 명칭 계산 (일요일~토요일)
    try:
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="날짜 포맷이 올바르지 않습니다. YYYY-MM-DD 형식을 사용하세요.")
        
    week_dates = [(start_dt + timedelta(days=i)).strftime("%Y-%m-%d") for i in range(7)]
    day_names = ["주일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]

    # 2. DB에서 7일간의 DailyScripture 레코드 검색
    scriptures_result = await db.execute(
        select(DailyScripture).where(DailyScripture.date.in_(week_dates))
    )
    scriptures_map = {s.date: s for s in scriptures_result.scalars().all()}

    # 3. DB에서 WeeklyIntro 검색
    weekly_result = await db.execute(
        select(WeeklyIntro).where(WeeklyIntro.start_date == start_date)
    )
    weekly = weekly_result.scalars().first()

    # 4. 주간 일정표 동적 연동 구성
    # WeeklyIntro가 존재하면 기본 저장값 사용, 없을 경우 DailyScripture 7일 데이터로 동적 생성
    saved_schedule = {}
    if weekly:
        try:
            for item in json.loads(weekly.weekly_schedule_json):
                if "date" in item:
                    saved_schedule[item["date"]] = item
        except Exception:
            pass

    dynamic_schedule = []
    for idx, d in enumerate(week_dates):
        day_name = day_names[idx]
        sc = scriptures_map.get(d)
        saved_item = saved_schedule.get(d, {})

        passage = sc.passage if sc and sc.passage else saved_item.get("passage", "")
        title = sc.title if sc and sc.title else saved_item.get("title", "")

        dynamic_schedule.append({
            "date": d,
            "day": day_name,
            "passage": passage,
            "title": title
        })

    # WeeklyIntro가 아직 업로드되지 않았더라도 매일 QT 기록이 있으면 가상 프로필 리턴
    if not weekly and not scriptures_map:
        raise HTTPException(status_code=404, detail="해당 주간의 일정 및 QT 데이터를 찾을 수 없습니다.")

    def compute_korean_week_label(d_str: str) -> str:
        d = datetime.strptime(d_str, "%Y-%m-%d")
        sun_offset = (d.weekday() + 1) % 7
        sun_dt = d - timedelta(days=sun_offset)
        wed_dt = sun_dt + timedelta(days=3)
        
        m_owner = wed_dt.month
        y_owner = wed_dt.year
        
        first_day_of_month = datetime(y_owner, m_owner, 1)
        first_sun = first_day_of_month - timedelta(days=(first_day_of_month.weekday() + 1) % 7)
        first_wed = first_sun + timedelta(days=3)
        if first_wed.month != m_owner:
            first_wed += timedelta(days=7)
            
        w_num = ((wed_dt - first_wed).days // 7) + 1
        return f"{m_owner}월 {w_num}주차"

    week_num_str = weekly.week_number if weekly else compute_korean_week_label(start_date)
    calligraphy_url = weekly.calligraphy_image_url if weekly else ""
    calligraphy_scripture = weekly.calligraphy_scripture if weekly else (
        scriptures_map[week_dates[0]].calligraphy_text if week_dates[0] in scriptures_map else ""
    )

    return {
        "week_number": week_num_str,
        "start_date": start_date,
        "calligraphy_image_url": calligraphy_url,
        "calligraphy_scripture": calligraphy_scripture,
        "weekly_schedule": dynamic_schedule
    }

@router.post("/sync")
async def sync_push(payload: SyncPushRequest, db: AsyncSession = Depends(get_db)):
    """
    모바일 기기의 로컬 데이터를 서버로 백업/동기화(Push)합니다.
    Last-Write-Wins 알고리즘을 사용해 더 최신인 데이터만 덮어씁니다.
    """
    device_id = payload.device_id
    for item in payload.notes:
        # DB에 기존 기록이 있는지 확인
        result = await db.execute(
            select(ServerQtNote).where(
                ServerQtNote.device_id == device_id,
                ServerQtNote.date == item.date
            )
        )
        existing = result.scalars().first()
        
        if existing:
            # 타임스탬프 비교 (새로 올라온 데이터가 더 최신인 경우에만 덮어씀)
            if item.updated_at > existing.updated_at:
                existing.gratitude = item.gratitude
                existing.verse_highlight = item.verse_highlight
                existing.application = item.application
                existing.prayer = item.prayer
                existing.sunday_ibs = item.sunday_ibs
                existing.action_completed = item.action_completed
                existing.sermon_notes = item.sermon_notes
                existing.updated_at = item.updated_at
                db.add(existing)
        else:
            # 새로운 레코드 생성
            new_note = ServerQtNote(
                device_id=device_id,
                date=item.date,
                gratitude=item.gratitude,
                verse_highlight=item.verse_highlight,
                application=item.application,
                prayer=item.prayer,
                sunday_ibs=item.sunday_ibs,
                action_completed=item.action_completed,
                sermon_notes=item.sermon_notes,
                updated_at=item.updated_at
            )
            db.add(new_note)
            
    await db.commit()
    return {"status": "success", "message": "동기화 완료"}

@router.get("/sync", response_model=SyncPullResponse)
async def sync_pull(
    device_id: str = Query(..., description="기기 식별자 ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    기기 변경/분실 시 서버에 저장된 사용자의 기록들을 모바일 기기로 내려받습니다(Pull).
    """
    result = await db.execute(
        select(ServerQtNote).where(ServerQtNote.device_id == device_id)
    )
    notes = result.scalars().all()
    
    sync_items = []
    for n in notes:
        sync_items.append(QtNoteSyncItem(
            date=n.date,
            gratitude=n.gratitude,
            verse_highlight=n.verse_highlight,
            application=n.application,
            prayer=n.prayer,
            sunday_ibs=n.sunday_ibs,
            action_completed=n.action_completed,
            sermon_notes=n.sermon_notes,
            updated_at=n.updated_at
        ))
    return SyncPullResponse(notes=sync_items)
