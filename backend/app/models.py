from typing import Optional, List, Dict
from sqlmodel import SQLModel, Field, UniqueConstraint
from pydantic import BaseModel

# ==========================================
# 1. DB Table Models (SQLModel)
# ==========================================

class DailyScripture(SQLModel, table=True):
    __tablename__ = "daily_scriptures"
    
    date: str = Field(primary_key=True)  # YYYY-MM-DD
    title: str
    passage: str
    verses_json: str  # JSON list of dicts: [{"num": 1, "text": "..."}]
    bgm_commentary: str
    weekly_pray_category: str
    weekly_prayer: str
    calligraphy_text: str
    calligraphy_ref: str

class WeeklyIntro(SQLModel, table=True):
    __tablename__ = "weekly_intros"
    
    start_date: str = Field(primary_key=True)  # YYYY-MM-DD (Sunday)
    week_number: str  # e.g., "7월 1주차"
    calligraphy_image_url: str
    calligraphy_scripture: str
    weekly_schedule_json: str  # JSON list: [{"date": "YYYY-MM-DD", "day": "주일", "passage": "...", "title": "..."}]

class Bulletin(SQLModel, table=True):
    __tablename__ = "bulletins"
    
    date: str = Field(primary_key=True)  # YYYY-MM-DD
    label: str  # e.g., "2026년 7월 12일 주보"
    pages_json: str  # JSON list of string image URLs: ["/media/bulletins/page1.jpg", ...]

class ServerQtNote(SQLModel, table=True):
    __tablename__ = "server_qt_notes"
    __table_args__ = (
        UniqueConstraint("device_id", "date", name="uix_device_date"),
    )
    
    id: Optional[int] = Field(default=None, primary_key=True)
    device_id: str
    date: str  # YYYY-MM-DD
    gratitude: Optional[str] = None
    verse_highlight: Optional[str] = None
    application: Optional[str] = None
    prayer: Optional[str] = None
    sunday_ibs: Optional[str] = None  # JSON string: {"q1": "...", "q2": "...", "q3": "..."}
    action_completed: bool = False
    sermon_notes: Optional[str] = None
    updated_at: str  # ISO 8601 UTC

# ==========================================
# 2. Pydantic Request/Response Models (Schemas)
# ==========================================

class VerseModel(BaseModel):
    num: int
    text: str

class DailyScriptureResponse(BaseModel):
    date: str
    title: str
    passage: str
    verses: List[Dict]
    bgm_commentary: str
    weekly_pray_category: str
    weekly_prayer: str
    calligraphy_text: str
    calligraphy_ref: str

class QtNoteSyncItem(BaseModel):
    date: str
    gratitude: Optional[str] = None
    verse_highlight: Optional[str] = None
    application: Optional[str] = None
    prayer: Optional[str] = None
    sunday_ibs: Optional[str] = None
    action_completed: bool = False
    sermon_notes: Optional[str] = None
    updated_at: str = ""

    # Aliases for Flutter UserNote compatibility
    today_thanks: Optional[str] = None
    engraved_word: Optional[str] = None
    today_application: Optional[str] = None
    today_prayer: Optional[str] = None
    sunday_answer1: Optional[str] = None
    sunday_answer2: Optional[str] = None
    sunday_answer3: Optional[str] = None
    sermon_note: Optional[str] = None

    def get_gratitude(self) -> str:
        return self.gratitude or self.today_thanks or ""

    def get_verse_highlight(self) -> str:
        return self.verse_highlight or self.engraved_word or ""

    def get_application(self) -> str:
        return self.application or self.today_application or ""

    def get_prayer(self) -> str:
        return self.prayer or self.today_prayer or ""

    def get_sermon_notes(self) -> str:
        return self.sermon_notes or self.sermon_note or ""

    def get_sunday_ibs(self) -> str:
        if self.sunday_ibs:
            return self.sunday_ibs
        ibs_parts = []
        if self.sunday_answer1: ibs_parts.append(f"1. {self.sunday_answer1}")
        if self.sunday_answer2: ibs_parts.append(f"2. {self.sunday_answer2}")
        if self.sunday_answer3: ibs_parts.append(f"3. {self.sunday_answer3}")
        return "\n".join(ibs_parts)

class SyncPushRequest(BaseModel):
    device_id: str
    notes: List[QtNoteSyncItem]

class SyncPullResponse(BaseModel):
    notes: List[QtNoteSyncItem]
