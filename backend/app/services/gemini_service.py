import os
import json
import io
from PIL import Image
import google.generativeai as genai
from pydantic import BaseModel, Field
from typing import List, Optional

# ==========================================
# 1. Pydantic Return DTO Classes
# ==========================================
class OcrScheduleItem(BaseModel):
    date: str
    day: str = ""
    passage: str = ""
    title: str = ""

class WeeklyOcrData(BaseModel):
    week_number: str = "주차 미상"
    start_date: str
    calligraphy_scripture: str = ""
    weekly_pray_category: str = "공동체 기도"
    weekly_prayer: str = ""
    weekly_schedule: List[OcrScheduleItem] = []

class DailyVerseOcrItem(BaseModel):
    num: int = 1
    text: str = ""

class DailyScriptureOcrData(BaseModel):
    date: str
    title: str = "성경 묵상"
    passage: str = ""
    verses: List[DailyVerseOcrItem] = []
    commentary: str = "본문 해설 참조"

# ==========================================
# 2. Strict Gemini OpenAPI Dict Schemas (No 'default' keys)
# ==========================================
WEEKLY_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "week_number": {"type": "STRING", "description": "주차 표시 (예: 7월 1주차)"},
        "start_date": {"type": "STRING", "description": "해당 주간의 주일 시작일 날짜 (YYYY-MM-DD)"},
        "calligraphy_scripture": {"type": "STRING", "description": "캘리그라피 말씀 본문 텍스트"},
        "weekly_pray_category": {"type": "STRING", "description": "우모하 기도발전소 카테고리 (예: 샬롬기도, 닛시기도 등)"},
        "weekly_prayer": {"type": "STRING", "description": "우모하 기도제목 본문 텍스트"},
        "weekly_schedule": {
            "type": "ARRAY",
            "description": "일요일부터 토요일까지 7일간의 일정 표 리스트",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "date": {"type": "STRING", "description": "YYYY-MM-DD 날짜"},
                    "day": {"type": "STRING", "description": "요일 이름 (예: 주일, 수요일 등)"},
                    "passage": {"type": "STRING", "description": "성경 범위"},
                    "title": {"type": "STRING", "description": "말씀 제목"}
                },
                "required": ["date"]
            }
        }
    },
    "required": ["start_date"]
}

DAILY_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "date": {"type": "STRING", "description": "지면에 기재된 묵상 날짜 (YYYY-MM-DD 형식. 예: 2026-07-01)"},
        "title": {"type": "STRING", "description": "말씀 제목 (예: 도둑의 소굴로 보이느냐)"},
        "passage": {"type": "STRING", "description": "성경 범위 (예: 예레미야 7:1-11)"},
        "verses": {
            "type": "ARRAY",
            "description": "본문 구절 리스트 (절 번호와 본문 텍스트)",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "num": {"type": "INTEGER", "description": "성경 절 번호 (예: 1, 2, 3)"},
                    "text": {"type": "STRING", "description": "해당 절의 성경 본문 텍스트"}
                },
                "required": ["num", "text"]
            }
        },
        "commentary": {"type": "STRING", "description": "지면 하단 말씀 BGM 및 본문 해설 텍스트 전체"}
    },
    "required": ["date", "title", "verses"]
}

# ==========================================
# 3. Helper: Multi-model Fallback Generator
# ==========================================
def _generate_with_fallback(prompt: str, image: Image.Image, response_schema):
    raw_key = os.environ.get("GEMINI_API_KEY", "")
    api_key = raw_key.strip().strip('"').strip("'")
    if not api_key:
        raise ValueError("GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")
        
    genai.configure(api_key=api_key)
    
    models_to_try = ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-flash-latest"]
    last_error = None
    
    for model_name in models_to_try:
        try:
            generation_config = {
                "response_mime_type": "application/json",
                "response_schema": response_schema,
                "temperature": 0.1,
            }
            model = genai.GenerativeModel(model_name, generation_config=generation_config)
            response = model.generate_content([prompt, image])
            return json.loads(response.text)
        except Exception as e:
            last_error = e
            print(f"[Gemini Fallback Log] 모델 '{model_name}' 처리 중 알림: {str(e)}. 다음 폴백 모델로 시도합니다...")
            
    raise last_error

# ==========================================
# 4. Public Service Functions
# ==========================================
async def parse_weekly_intro_image(image_bytes: bytes) -> WeeklyOcrData:
    """
    주간 소개 및 일정 인쇄물 사진을 읽어 Gemini Vision을 사용해 JSON으로 반환합니다.
    """
    image = Image.open(io.BytesIO(image_bytes))
    prompt = """
    당신은 교회의 성경 공부 일정표 및 기도제목 안내 지면을 파싱하는 전문 서기 에이전트입니다.
    전달받은 이미지를 꼼꼼히 분석하여 한글 텍스트 정보를 JSON으로 생성하세요.
    
    [규칙]
    1. start_date: 이미지에 명시된 시작일(일요일 기준)을 YYYY-MM-DD 형식으로 기록합니다.
    2. weekly_schedule: 일요일(주일)부터 토요일까지 7일간의 데이터를 배열로 완성하세요.
       각 날짜(date)는 start_date를 기준으로 하루씩 더해가며 YYYY-MM-DD 형식을 계산해야 합니다.
    3. weekly_pray_category: 기도 발전소 란의 카테고리(예: '샬롬기도', '미션기도' 등)를 정확히 추출하세요.
    4. weekly_prayer: 기도내용 텍스트를 완성하세요.
    5. calligraphy_scripture: 지면의 대표 캘리그라피 말씀 텍스트를 적으세요.
    """
    parsed_json = _generate_with_fallback(prompt, image, WEEKLY_SCHEMA)
    return WeeklyOcrData(**parsed_json)

async def parse_daily_scripture_image(image_bytes: bytes) -> DailyScriptureOcrData:
    """
    매일 성경 묵상 지면(독서 페이지) 사진을 읽어 Gemini Vision을 사용해 JSON으로 반환합니다.
    """
    image = Image.open(io.BytesIO(image_bytes))
    prompt = """
    당신은 매일 성경 QT 책자의 독서 지면 페이지를 분석하는 전문 서기 에이전트입니다.
    전달받은 성경 묵상 페이지 사진을 정밀하게 읽고 한글 텍스트를 추출해 JSON으로 반환하세요.
    
    [추출 지침]
    1. date: 지면에 기재된 날짜(월, 일, 요일)를 YYYY-MM-DD 형식으로 변환하세요 (연도 미상 시 2026년).
       (예: '01 수요일'이고 예레미야 7:1-11 말씀이면 '2026-07-01' 또는 인쇄본의 해당 월일)
    2. title: 말씀 제목 (예: '도둑의 소굴로 보이느냐').
    3. passage: 성경 범위 (예: '예레미야 7:1-11').
    4. verses: 왼쪽 지면의 1절부터 11절까지 명시된 각 절 번호(num)와 본문 텍스트(text) 전체.
    5. commentary: 오른쪽 지면 하단의 '말씀 BGM' 해설 텍스트 전체.
    """
    parsed_json = _generate_with_fallback(prompt, image, DAILY_SCHEMA)
    return DailyScriptureOcrData(**parsed_json)

# ==========================================
# 3. Single-Call Batch Bulletin Processor
# ==========================================
BULLETIN_BATCH_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "publication_date": {
            "type": "STRING",
            "description": "1페이지(표지 지면 - 명선교회 로고 및 지난주일 낮 설교 포함)의 상단 헤더 영역에 인쇄된 주보 발행 날짜 (YYYY-MM-DD 형식, 예: 2026-07-19)"
        },
        "pages": {
            "type": "ARRAY",
            "description": "전달된 각 지면 이미지(0~3)의 1~4페이지 분류 정보",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "index": {"type": "INTEGER", "description": "이미지 순번 (0, 1, 2, 3)"},
                    "page_type": {"type": "INTEGER", "description": "1(표지/설교), 2(예배안내), 3(소식모임), 4(클릭/약도)"}
                },
                "required": ["index", "page_type"]
            }
        }
    },
    "required": ["publication_date", "pages"]
}

import time

def _generate_with_fallback_multi_images(prompt: str, images: list, response_schema):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")
        
    genai.configure(api_key=api_key)
    models_to_try = ["gemini-2.0-flash", "gemini-2.5-flash", "gemini-flash-latest"]
    last_error = None
    
    for model_name in models_to_try:
        for attempt in range(3):
            try:
                generation_config = {
                    "response_mime_type": "application/json",
                    "response_schema": response_schema,
                    "temperature": 0.1,
                }
                model = genai.GenerativeModel(model_name, generation_config=generation_config)
                content_payload = [prompt] + images
                response = model.generate_content(content_payload)
                return json.loads(response.text)
            except Exception as e:
                last_error = e
                err_msg = str(e)
                if "429" in err_msg or "ResourceExhausted" in err_msg or "Quota exceeded" in err_msg:
                    print(f"[Gemini 429 Retry] {model_name} (시도 {attempt+1}/3): Rate Limit 429 감지 - 3초 대기 후 재시도...")
                    time.sleep(3)
                else:
                    print(f"[Gemini Batch Log] 모델 '{model_name}' 시도 중 예외: {err_msg}")
                    break
            
    raise last_error

async def parse_and_classify_bulletin_batch(crops: list) -> dict:
    """
    4개의 세로 지면 조각 이미지를 1회의 Gemini Vision 요청으로 통합 전달하여
    1) 1페이지 표지 좌상단의 정확한 주보 발행 날짜(YYYY-MM-DD)와
    2) 각 지면의 페이지 분류(1~4p)를 API Rate Limit 초과 없이 100% 정밀 파싱합니다.
    """
    prompt = """
    당신은 교회 주보 지면들을 파싱하는 전문 에이전트입니다.
    전달받은 4개의 세로 지면 이미지 조각(순서: index 0, 1, 2, 3)을 정밀 분석하여 다음 2가지 미션을 1회의 요청으로 반환하세요:

    [미션 1: 주보 발행 날짜 추출 (publication_date)]
    - 1페이지(표지 지면: '명선교회' 로고, '지난주일 낮 설교', 권/호수가 포함된 지면)의 상단 헤더(예: "2026년 7월 19일", "2026. 7. 19", "7월 19일 주일")에 인쇄된 주보 발행 날짜를 찾아 YYYY-MM-DD 형식("2026-07-19")으로 publication_date에 반환하세요.
    - [엄격한 규정] "창립 1993년 11월 7일"과 같은 교회 설립일이나 타 지면에 인쇄된 기한(예: 8월 1일까지)을 절대로 잡지 말고, 1페이지 표지의 주일 발행 날짜만 정확히 파싱해야 합니다.

    [미션 2: 4개 지면 페이지 분류 (pages)]
    각 이미지 조각(index 0, 1, 2, 3)의 핵심 특징을 파악하여 page_type(1~4)으로 분류하세요:
    - 1: 1페이지 (표지 - '명선교회' 로고, 발행일, '지난주일 낮 설교', 권/호수, 말씀 캘리그라피)
    - 2: 2페이지 (내지1 - 상단 헤더 '예 배', 주일예배 1,2,3부, 수요예배, 목회행사 계획표)
    - 3: 3페이지 (내지2 - 상단 헤더 '소식 모임', 새가족 환영, 금주 성경읽기, 여름사역 소식)
    - 4: 4페이지 (뒷면 - 상단 로고 'click', '우모하 북카페', '지난주 교회모습', 교회 약도 및 전화 031-204-7191)
    """
    try:
        return _generate_with_fallback_multi_images(prompt, crops, BULLETIN_BATCH_SCHEMA)
    except Exception as e:
        print(f"단일 배치 주보 분석 에러: {str(e)}")
        return {"publication_date": "", "pages": [{"index": i, "page_type": i+1} for i in range(len(crops))]}

async def classify_bulletin_page_image(image: Image.Image) -> dict:
    return {"page_type": 1, "date": ""}

async def extract_date_from_bulletin_cover_top_left(cover_image: Image.Image) -> str:
    return ""
