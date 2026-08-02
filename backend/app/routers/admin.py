import os
import shutil
import json
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import WeeklyIntro, DailyScripture, Bulletin
from app.services.gemini_service import parse_weekly_intro_image, parse_daily_scripture_image

from datetime import datetime

router = APIRouter(prefix="/api/v1/admin", tags=["Admin Operations"])

MEDIA_DIR = "media"
CALLIGRAPHY_DIR = os.path.join(MEDIA_DIR, "calligraphy")
BULLETINS_DIR = os.path.join(MEDIA_DIR, "bulletins")

# 필요한 로컬 디렉토리 동적 생성
os.makedirs(CALLIGRAPHY_DIR, exist_ok=True)
os.makedirs(BULLETINS_DIR, exist_ok=True)

def post_process_scripture_title(date_str: str, parsed_title: str) -> str:
    """
    [도메인 후처리 규칙]
    주일(일요일) 게시물은 성도들이 예배 시간에 설교 제목과 설교 노트를 직접 작성하므로
    제목을 반드시 빈 문자열("")로 보정합니다.
    """
    try:
        dt = datetime.strptime(date_str, "%Y-%m-%d")
        if dt.weekday() == 6:  # 6 is Sunday
            return ""
    except Exception:
        pass
    return parsed_title or ""

@router.post("/upload-by-photo")
async def upload_weekly_by_photo(
    file: UploadFile = File(..., description="분석할 주간 말씀/일정 인쇄물 사진 이미지"),
    db: AsyncSession = Depends(get_db)
):
    """
    [지능형 자동화] 교역자가 주간 일정이나 말씀 지면 사진을 업로드하면,
    Gemini 1.5 Flash Vision API가 분석하여 요일 일정, 기도제목, 캘리그라피 문구를
    구조화된 데이터로 자동 추출해 데이터베이스에 적재합니다.
    """
    # 1. 파일 데이터 읽기
    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"파일을 읽는 중 에러가 발생했습니다: {str(e)}")
        
    # 2. Gemini Vision 모델 호출하여 이미지 데이터 구조화 파싱
    try:
        ocr_result = await parse_weekly_intro_image(contents)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Gemini API 분석 및 구조화 변환 실패: {str(e)}"
        )
        
    start_date = ocr_result.start_date
    
    # 3. 업로드된 이미지를 캘리그라피 말씀 카드로 로컬 볼륨에 저장
    saved_filename = f"calligraphy_{start_date}.jpg"
    saved_path = os.path.join(CALLIGRAPHY_DIR, saved_filename)
    try:
        with open(saved_path, "wb") as buffer:
            buffer.write(contents)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"이미지 임시 저장 실패: {str(e)}"
        )
        
    calligraphy_url = f"/media/calligraphy/{saved_filename}"
    
    # 4. WeeklyIntro 레코드 저장/업데이트
    result = await db.execute(
        select(WeeklyIntro).where(WeeklyIntro.start_date == start_date)
    )
    existing_weekly = result.scalars().first()
    
    # schedule 리스트를 JSON 문자열로 직렬화
    schedule_data = [
        {"date": item.date, "day": item.day, "passage": item.passage, "title": item.title}
        for item in ocr_result.weekly_schedule
    ]
    schedule_json = json.dumps(schedule_data, ensure_ascii=False)
    
    if existing_weekly:
        existing_weekly.week_number = ocr_result.week_number
        existing_weekly.calligraphy_image_url = calligraphy_url
        existing_weekly.calligraphy_scripture = ocr_result.calligraphy_scripture
        existing_weekly.weekly_schedule_json = schedule_json
        db.add(existing_weekly)
    else:
        new_weekly = WeeklyIntro(
            start_date=start_date,
            week_number=ocr_result.week_number,
            calligraphy_image_url=calligraphy_url,
            calligraphy_scripture=ocr_result.calligraphy_scripture,
            weekly_schedule_json=schedule_json
        )
        db.add(new_weekly)
        
    # 5. 각 요일별 DailyScripture 스텁(Stub) 자동 생성/업데이트
    # 오프라인 데이터 동기화를 위해 일정표에 있는 요일별 레코드를 기본 삽입합니다.
    for item in ocr_result.weekly_schedule:
        scripture_result = await db.execute(
            select(DailyScripture).where(DailyScripture.date == item.date)
        )
        existing_scripture = scripture_result.scalars().first()
        
        final_title = post_process_scripture_title(item.date, item.title)
        if existing_scripture:
            existing_scripture.title = final_title
            existing_scripture.passage = item.passage
            existing_scripture.weekly_pray_category = ocr_result.weekly_pray_category
            existing_scripture.weekly_prayer = ocr_result.weekly_prayer
            existing_scripture.calligraphy_text = ocr_result.calligraphy_scripture
            db.add(existing_scripture)
        else:
            new_scripture = DailyScripture(
                date=item.date,
                title=final_title,
                passage=item.passage,
                verses_json="[]",  # 말씀 본문 구절은 초기값 빈 배열
                bgm_commentary="말씀 BGM 해설 준비중",
                weekly_pray_category=ocr_result.weekly_pray_category,
                weekly_prayer=ocr_result.weekly_prayer,
                calligraphy_text=ocr_result.calligraphy_scripture,
                calligraphy_ref=""
            )
            db.add(new_scripture)
            
    await db.commit()
    
    return {
        "status": "success",
        "message": f"성공: [{ocr_result.week_number}] 데이터가 이미지로부터 자동 파싱되어 등록되었습니다.",
        "data": {
            "week_number": ocr_result.week_number,
            "start_date": ocr_result.start_date,
            "calligraphy_image_url": calligraphy_url,
            "calligraphy_scripture": ocr_result.calligraphy_scripture,
            "weekly_pray_category": ocr_result.weekly_pray_category,
            "weekly_prayer": ocr_result.weekly_prayer,
            "weekly_schedule": schedule_data
        }
    }

@router.post("/upload-bulletin")
async def upload_bulletin(
    date: str = Form(..., description="주보 발행 날짜 (YYYY-MM-DD)"),
    label: str = Form(..., description="주보 타이틀 라벨 (예: 2026년 7월 12일 주보)"),
    files: list[UploadFile] = File(..., description="주보 이미지 파일 리스트 (다중 파일 업로드)"),
    db: AsyncSession = Depends(get_db)
):
    """
    주보 이미지를 일괄 업로드하여 저장합니다.
    """
    date_bulletin_dir = os.path.join(BULLETINS_DIR, date)
    os.makedirs(date_bulletin_dir, exist_ok=True)
    
    saved_urls = []
    for idx, file in enumerate(files):
        filename = f"page_{idx + 1}_{file.filename}"
        filepath = os.path.join(date_bulletin_dir, filename)
        
        try:
            with open(filepath, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            saved_urls.append(f"/media/bulletins/{date}/{filename}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"주보 페이지 저장 실패: {str(e)}")
            
    # DB에 주보 레코드 적재
    result = await db.execute(
        select(Bulletin).where(Bulletin.date == date)
    )
    existing_bulletin = result.scalars().first()
    
    pages_json_str = json.dumps(saved_urls, ensure_ascii=False)
    if existing_bulletin:
        existing_bulletin.label = label
        existing_bulletin.pages_json = pages_json_str
        db.add(existing_bulletin)
    else:
        new_bulletin = Bulletin(
            date=date,
            label=label,
            pages_json=pages_json_str
        )
        db.add(new_bulletin)
        
    await db.commit()
    return {
        "status": "success",
        "message": "주보 일괄 등록 완료",
        "data": {
            "date": date,
            "label": label,
            "pages": saved_urls
        }
    }

@router.post("/upload-daily-photo")
async def upload_daily_by_photo(
    file: UploadFile = File(..., description="매일 묵상/독서 지면 인쇄물 사진 이미지"),
    db: AsyncSession = Depends(get_db)
):
    """
    [지능형 자동화] 매일 묵상 책자 지면 사진을 업로드하면,
    Gemini 1.5 Flash Vision API가 성경 본문 구절들(절 번호/텍스트) 및 해설 텍스트를 파싱하여 DB에 등록합니다.
    """
    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"파일 읽기 실패: {str(e)}")
        
    try:
        ocr_result = await parse_daily_scripture_image(contents)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini API 매일 말씀 지면 파싱 실패: {str(e)}")
        
    verses_data = [
        {"num": item.num, "text": item.text}
        for item in ocr_result.verses
    ]
    verses_json_str = json.dumps(verses_data, ensure_ascii=False)
    
    # DB 조회 및 업데이트 (주일일 경우 제목은 빈 문자열 "" 로 보정)
    final_title = post_process_scripture_title(ocr_result.date, ocr_result.title)
    
    result = await db.execute(
        select(DailyScripture).where(DailyScripture.date == ocr_result.date)
    )
    existing = result.scalars().first()
    
    if existing:
        existing.title = final_title
        existing.passage = ocr_result.passage
        existing.verses_json = verses_json_str
        existing.bgm_commentary = ocr_result.commentary
        db.add(existing)
    else:
        new_scripture = DailyScripture(
            date=ocr_result.date,
            title=final_title,
            passage=ocr_result.passage,
            verses_json=verses_json_str,
            bgm_commentary=ocr_result.commentary,
            weekly_pray_category="공동체 기도",
            weekly_prayer="우리 가정이 말씀 안에 바로 서도록 인도하소서.",
            calligraphy_text=final_title,
            calligraphy_ref=ocr_result.passage
        )
        db.add(new_scripture)
        
    await db.commit()
    
    return {
        "status": "success",
        "message": f"성공: [{ocr_result.date}] 매일 성경 묵상 본문({len(verses_data)}개 구절)이 성공적으로 파싱 등록되었습니다.",
        "data": {
            "date": ocr_result.date,
            "title": final_title,
            "passage": ocr_result.passage,
            "verses_count": len(verses_data),
            "verses": verses_data,
            "commentary": ocr_result.commentary
        }
    }

@router.post("/upload-daily-photos-batch")
async def upload_daily_by_photos_batch(
    files: List[UploadFile] = File(..., description="매일 묵상 지면 인쇄물 사진들 다중 배치 업로드"),
    db: AsyncSession = Depends(get_db)
):
    """
    [다중 배치 파싱] 여러 장의 매일 묵상 책자 지면 사진을 한번에 전송받아,
    오류가 나는 사진이 있더라도 중단하지 않고 마지막 사진까지 계속 처리하여 통합 결과를 반환합니다.
    """
    results = []
    success_count = 0
    failed_count = 0
    
    for idx, file in enumerate(files):
        filename = file.filename
        try:
            contents = await file.read()
            ocr_result = await parse_daily_scripture_image(contents)
            
            verses_data = [
                {"num": item.num, "text": item.text}
                for item in ocr_result.verses
            ]
            verses_json_str = json.dumps(verses_data, ensure_ascii=False)
            
            final_title = post_process_scripture_title(ocr_result.date, ocr_result.title)
            
            res = await db.execute(
                select(DailyScripture).where(DailyScripture.date == ocr_result.date)
            )
            existing = res.scalars().first()
            
            if existing:
                existing.title = final_title
                existing.passage = ocr_result.passage
                existing.verses_json = verses_json_str
                existing.bgm_commentary = ocr_result.commentary
                db.add(existing)
            else:
                new_scripture = DailyScripture(
                    date=ocr_result.date,
                    title=final_title,
                    passage=ocr_result.passage,
                    verses_json=verses_json_str,
                    bgm_commentary=ocr_result.commentary,
                    weekly_pray_category="공동체 기도",
                    weekly_prayer="우리 가정이 말씀 안에 바로 서도록 인도하소서.",
                    calligraphy_text=final_title,
                    calligraphy_ref=ocr_result.passage
                )
                db.add(new_scripture)
                
            await db.commit()
            success_count += 1
            results.append({
                "index": idx + 1,
                "filename": filename,
                "status": "success",
                "date": ocr_result.date,
                "title": final_title,
                "passage": ocr_result.passage,
                "verses_count": len(verses_data)
            })
        except Exception as e:
            failed_count += 1
            results.append({
                "index": idx + 1,
                "filename": filename,
                "status": "error",
                "error": str(e)
            })
            
    return {
        "status": "completed",
        "message": f"총 {len(files)}개 파일 처리 완료 (성공: {success_count}개, 실패: {failed_count}개)",
        "total_files": len(files),
        "success_count": success_count,
        "failed_count": failed_count,
        "results": results
    }

@router.post("/upload-bulletin-photos-batch")
async def upload_bulletin_photos_batch(
    files: List[UploadFile] = File(..., description="업로드할 주보 사진들 (2장 가로 펼침 또는 4장 세로 사진)"),
    bulletin_date: Optional[str] = Form(None, description="주보 날짜 (YYYY-MM-DD, 미지정 시 AI가 파싱)"),
    db: AsyncSession = Depends(get_db)
):
    """
    [지능형 주보 자동 분할 및 1-4페이지 순서 정렬 업로드]
    교역자가 2장의 가로 펼침 사진이나 4장의 세로 사진을 임의의 순서로 업로드하더라도
    1) 가로 펼침 사진은 반으로 자동 절단(Left/Right Split)하고
    2) Gemini AI가 지면 내용(표지/예배/소식/클릭약도)을 정밀 파싱하여
    3) [1페이지, 2페이지, 3페이지, 4페이지] 순서로 자동 정렬해 데이터베이스에 저장합니다.
    """
    import io
    from PIL import Image
    from app.services.gemini_service import parse_and_classify_bulletin_batch

    crops = []

    # Stage 1: 이미지 업로드 수령 및 가로 펼침 수직 절단 (Left/Right Split)
    for file in files:
        try:
            content = await file.read()
            img = Image.open(io.BytesIO(content)).convert("RGB")
            
            if img.width > img.height * 1.1:
                mid = img.width // 2
                left_crop = img.crop((0, 0, mid, img.height))
                right_crop = img.crop((mid, 0, img.width, img.height))
                crops.extend([left_crop, right_crop])
            else:
                crops.append(img)
        except Exception as e:
            print(f"주보 이미지 자르기 에러: {str(e)}")

    if not crops:
        raise HTTPException(status_code=400, detail="유효한 주보 이미지를 처리하지 못했습니다.")

    # Stage 2: 단 1회의 통합 Gemini Vision 요청으로 1p 표지 좌상단 발행일 파싱 + 4개 지면 시그니처 1~4페이지 정렬
    batch_res = await parse_and_classify_bulletin_batch(crops)
    cover_date = batch_res.get("publication_date", "")
    page_classifications = batch_res.get("pages", [])

    # 각 지면 조각에 page_type 매핑
    processed_items = []
    for idx, crop in enumerate(crops):
        p_type = 1
        for p_info in page_classifications:
            if p_info.get("index") == idx:
                p_type = p_info.get("page_type", 1)
                break
        processed_items.append({"image": crop, "page_type": p_type})

    # Stage 3: 1페이지 ~ 4페이지 순서 정렬 확정
    processed_items.sort(key=lambda x: x["page_type"])

    # 최종 주보 날짜 결정 (전달값 > 1페이지 표지 상단 AI 파싱값 > 오늘 날짜 임시)
    if bulletin_date:
        target_date = bulletin_date
    elif cover_date:
        target_date = cover_date
    else:
        target_date = datetime.now().strftime("%Y-%m-%d")
        print(f"[주보 처리 경고] AI 날짜 파싱 실패 (API Quota 제한 등) - 임시 날짜 {target_date}로 저장됨. 필요 시 관리자 콘솔에서 '✏️ 날짜 수정' 버튼을 눌러 지정하세요.")

    # 동일한 날짜로 등록된 주보가 있을 경우 기존 이미지 파일들 실체 삭제 처리
    res = await db.execute(select(Bulletin).where(Bulletin.date == target_date))
    existing_b = res.scalars().first()
    if existing_b:
        try:
            old_pages = json.loads(existing_b.pages_json)
            for old_url in old_pages:
                old_fname = os.path.basename(old_url)
                old_fpath = os.path.join(BULLETINS_DIR, old_fname)
                if os.path.exists(old_fpath):
                    os.remove(old_fpath)
        except Exception as e:
            print(f"기존 주보 이미지 삭제 중 예외 발생: {str(e)}")

    page_urls = []
    for idx, item in enumerate(processed_items):
        page_num = idx + 1
        out_filename = f"bulletin_{target_date}_p{page_num}.jpg"
        out_path = os.path.join(BULLETINS_DIR, out_filename)
        item["image"].save(out_path, "JPEG", quality=92)
        page_urls.append(f"/static/bulletins/{out_filename}")

    # DB의 Bulletin 테이블 레코드 Upsert (라벨 고정 포맷: "XXXX년 XX월 XX일 주보")
    try:
        dt_obj = datetime.strptime(target_date, "%Y-%m-%d")
        bulletin_label = f"{dt_obj.year}년 {dt_obj.month:02d}월 {dt_obj.day:02d}일 주보"
    except Exception:
        bulletin_label = f"{target_date} 주보"

    pages_json_str = json.dumps(page_urls, ensure_ascii=False)

    if existing_b:
        existing_b.pages_json = pages_json_str
        existing_b.label = bulletin_label
        db.add(existing_b)
    else:
        new_b = Bulletin(
            date=target_date,
            label=bulletin_label,
            pages_json=pages_json_str
        )
        db.add(new_b)

    await db.commit()

    return {
        "status": "success",
        "date": target_date,
        "total_pages": len(page_urls),
        "page_urls": page_urls,
        "message": f"🎉 주보 사진이 4개 세로 지면으로 자동 분할 및 [{bulletin_label}] 자동 등록 완료되었습니다!"
    }


# ==========================================
# DB 적재 데이터 삭제 및 날짜 수정 엔드포인트
# ==========================================

@router.delete("/qt/{date_str}")
async def delete_qt_record(date_str: str, db: AsyncSession = Depends(get_db)):
    """
    특정 날짜의 QT 말씀 데이터 삭제
    """
    res = await db.execute(select(DailyScripture).where(DailyScripture.date == date_str))
    scripture = res.scalars().first()
    if not scripture:
        raise HTTPException(status_code=404, detail="해당 날짜의 QT 데이터를 찾을 수 없습니다.")

    await db.delete(scripture)
    await db.commit()
    return {"status": "success", "message": f"[{date_str}] QT 데이터가 삭제되었습니다."}


@router.delete("/bulletin/{date_str}")
async def delete_bulletin_record(date_str: str, db: AsyncSession = Depends(get_db)):
    """
    특정 날짜의 주보 데이터 및 디스크 내 이미지 파일 삭제
    """
    res = await db.execute(select(Bulletin).where(Bulletin.date == date_str))
    bulletin = res.scalars().first()
    if not bulletin:
        raise HTTPException(status_code=404, detail="해당 날짜의 주보 데이터를 찾을 수 없습니다.")

    try:
        pages = json.loads(bulletin.pages_json)
        for page_url in pages:
            fname = os.path.basename(page_url)
            fpath = os.path.join(BULLETINS_DIR, fname)
            if os.path.exists(fpath):
                os.remove(fpath)
    except Exception as e:
        print(f"주보 이미지 삭제 중 예외: {str(e)}")

    await db.delete(bulletin)
    await db.commit()
    return {"status": "success", "message": f"[{date_str}] 주보 데이터 및 4개 사진들이 삭제되었습니다."}


class UpdateBulletinDateRequest(BaseModel):
    new_date: Optional[str] = None
    new_label: Optional[str] = None

@router.patch("/bulletin/{old_date}")
async def update_bulletin_date(old_date: str, req: UpdateBulletinDateRequest, db: AsyncSession = Depends(get_db)):
    """
    주보의 발행 날짜 및 제목 라벨 수정 (날짜 변경 시 이미지 파일명도 새 날짜로 자동 변경)
    """
    res = await db.execute(select(Bulletin).where(Bulletin.date == old_date))
    bulletin = res.scalars().first()
    if not bulletin:
        raise HTTPException(status_code=404, detail="수정할 기존 주보 데이터를 찾을 수 없습니다.")

    new_date = req.new_date.strip() if req.new_date else old_date
    if req.new_label and req.new_label.strip():
        new_label = req.new_label.strip()
    else:
        try:
            dt_obj = datetime.strptime(new_date, "%Y-%m-%d")
            new_label = f"{dt_obj.year}년 {dt_obj.month:02d}월 {dt_obj.day:02d}일 주보"
        except Exception:
            new_label = bulletin.label

    # 이미지 파일명을 새 날짜 파일명으로 변경
    try:
        old_pages = json.loads(bulletin.pages_json)
        new_pages = []
        for idx, old_url in enumerate(old_pages):
            old_fname = os.path.basename(old_url)
            old_fpath = os.path.join(BULLETINS_DIR, old_fname)
            
            new_fname = f"bulletin_{new_date}_p{idx+1}.jpg"
            new_fpath = os.path.join(BULLETINS_DIR, new_fname)

            if os.path.exists(old_fpath):
                os.rename(old_fpath, new_fpath)
            new_pages.append(f"/static/bulletins/{new_fname}")
    except Exception as e:
        print(f"주보 파일명 변경 에러: {str(e)}")
        new_pages = [f"/static/bulletins/bulletin_{new_date}_p{i+1}.jpg" for i in range(4)]

    if old_date != new_date:
        await db.delete(bulletin)
        await db.flush()

        new_b = Bulletin(
            date=new_date,
            label=new_label,
            pages_json=json.dumps(new_pages, ensure_ascii=False)
        )
        db.add(new_b)
    else:
        bulletin.label = new_label
        bulletin.pages_json = json.dumps(new_pages, ensure_ascii=False)
        db.add(bulletin)

    await db.commit()
    return {
        "status": "success",
        "old_date": old_date,
        "new_date": new_date,
        "new_label": new_label,
        "pages": new_pages
    }


class ReorderBulletinPagesRequest(BaseModel):
    pages: List[str]

@router.post("/bulletin/{date_str}/reorder")
async def reorder_bulletin_pages(date_str: str, req: ReorderBulletinPagesRequest, db: AsyncSession = Depends(get_db)):
    """
    주보의 4개 지면 순서를 사용자가 지정한 새로운 순서로 변경합니다.
    """
    res = await db.execute(select(Bulletin).where(Bulletin.date == date_str))
    bulletin = res.scalars().first()
    if not bulletin:
        raise HTTPException(status_code=404, detail="순서를 변경할 주보 데이터를 찾을 수 없습니다.")

    bulletin.pages_json = json.dumps(req.pages, ensure_ascii=False)
    db.add(bulletin)
    await db.commit()

    return {
        "status": "success",
        "date": date_str,
        "pages": req.pages,
        "message": f"[{date_str}] 주보의 지면 순서가 변경되었습니다."
    }


# ==========================================
# JSON 직접 일괄 등록 & 주보 수동 직접 등록 엔드포인트
# ==========================================

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request

@router.post("/qt/json-import")
async def import_qt_json(request: Request, db: AsyncSession = Depends(get_db)):
    """
    QT 말씀 컨텐츠를 JSON 데이터(단일 객체 또는 배열)로 직접 DB에 일괄 등록/수정합니다.
    """
    try:
        payload = await request.json()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"JSON 파싱 실패: {str(e)}")
    items = []
    if isinstance(payload, list):
        items = payload
    elif isinstance(payload, dict):
        if "items" in payload and isinstance(payload["items"], list):
            items = payload["items"]
        else:
            items = [payload]
    else:
        raise HTTPException(status_code=400, detail="올바른 JSON 객체 또는 배열 형식이 아닙니다.")

    success_count = 0
    updated_dates = []

    for item in items:
        date_str = item.get("date")
        if not date_str:
            continue

        title = item.get("title", "")
        passage = item.get("passage", "")
        verses = item.get("verses_json", item.get("verses", []))
        if isinstance(verses, list):
            verses_json = json.dumps(verses, ensure_ascii=False)
        else:
            verses_json = str(verses)

        commentary = item.get("bgm_commentary", item.get("commentary", ""))
        weekly_pray_category = item.get("weekly_pray_category", "공동체 기도")
        weekly_prayer = item.get("weekly_prayer", "")
        calligraphy_text = item.get("calligraphy_text", "")
        calligraphy_ref = item.get("calligraphy_ref", "")

        # 주일(일요일)은 제목을 빈 문자열로 보정
        title = post_process_scripture_title(date_str, title)

        res = await db.execute(select(DailyScripture).where(DailyScripture.date == date_str))
        existing = res.scalars().first()

        if existing:
            existing.title = title
            existing.passage = passage
            existing.verses_json = verses_json
            existing.bgm_commentary = commentary
            existing.weekly_pray_category = weekly_pray_category
            existing.weekly_prayer = weekly_prayer
            existing.calligraphy_text = calligraphy_text
            existing.calligraphy_ref = calligraphy_ref
            db.add(existing)
        else:
            new_scripture = DailyScripture(
                date=date_str,
                title=title,
                passage=passage,
                verses_json=verses_json,
                bgm_commentary=commentary,
                weekly_pray_category=weekly_pray_category,
                weekly_prayer=weekly_prayer,
                calligraphy_text=calligraphy_text,
                calligraphy_ref=calligraphy_ref
            )
            db.add(new_scripture)
        
        success_count += 1
        updated_dates.append(date_str)

    await db.commit()
    return {
        "status": "success",
        "count": success_count,
        "updated_dates": updated_dates,
        "message": f"총 {success_count}건의 QT 말씀 데이터가 성공적으로 적재/갱신되었습니다."
    }


@router.post("/bulletin/manual")
async def create_bulletin_manual(
    date_str: str = Form(..., description="주보 날짜 (YYYY-MM-DD)"),
    label: Optional[str] = Form(None, description="주보 제목 라벨 (선택입력)"),
    page1: Optional[UploadFile] = File(None, description="1페이지 표지 이미지 파일"),
    page2: Optional[UploadFile] = File(None, description="2페이지 설교 이미지 파일"),
    page3: Optional[UploadFile] = File(None, description="3페이지 광고 이미지 파일"),
    page4: Optional[UploadFile] = File(None, description="4페이지 소식 이미지 파일"),
    db: AsyncSession = Depends(get_db)
):
    """
    AI 파싱 없이 교역자가 주보 이미지 파일들을 순서대로 지정하여 수동으로 직접 등록합니다.
    (1~4페이지 지원, 빈 지면 자동 제외)
    """
    if not date_str:
        raise HTTPException(status_code=400, detail="주보 날짜는 필수 입력값입니다.")

    bulletin_label = (label and label.strip()) or f"{date_str[:4]}년 {date_str[5:7]}월 {date_str[8:10]}일 주보"
    upload_files = [page1, page2, page3, page4]
    pages_urls = []

    for up_file in upload_files:
        if up_file and hasattr(up_file, "filename") and up_file.filename:
            content = await up_file.read()
            if content and len(content) > 0:
                page_num = len(pages_urls) + 1
                filename = f"bulletin_{date_str}_p{page_num}.jpg"
                filepath = os.path.join(BULLETINS_DIR, filename)
                with open(filepath, "wb") as f:
                    f.write(content)
                pages_urls.append(f"/static/bulletins/{filename}")

    if not pages_urls:
        raise HTTPException(status_code=400, detail="최소 1개 이상의 주보 이미지 파일을 첨부해야 합니다.")

    res = await db.execute(select(Bulletin).where(Bulletin.date == date_str))
    existing = res.scalars().first()

    if existing:
        existing.label = bulletin_label
        existing.pages_json = json.dumps(pages_urls, ensure_ascii=False)
        db.add(existing)
    else:
        new_bulletin = Bulletin(
            date=date_str,
            label=bulletin_label,
            pages_json=json.dumps(pages_urls, ensure_ascii=False)
        )
        db.add(new_bulletin)

    await db.commit()

    return {
        "status": "success",
        "date": date_str,
        "label": bulletin_label,
        "pages": pages_urls,
        "message": f"[{date_str}] 주보 {len(pages_urls)}개 지면(파일/URL 포함)이 성공적으로 수동 등록되었습니다."
    }

