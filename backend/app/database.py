import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@localhost:5432/iworship")

# Async engine for PostgreSQL asyncpg connection
engine = create_async_engine(DATABASE_URL, echo=True, future=True)

# Session factory
async_session = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

import asyncio

async def init_db():
    retries = 15
    while retries > 0:
        try:
            async with engine.begin() as conn:
                # Create database tables defined in SQLModel metadata
                await conn.run_sync(SQLModel.metadata.create_all)
            print("데이터베이스 연결 성공 및 테이블 초기화 완료!")
            break
        except Exception as e:
            retries -= 1
            if retries == 0:
                print(f"데이터베이스 연결 실패 (최종): {e}")
                raise e
            print(f"데이터베이스 부팅 대기 중... (남은 시도: {retries}회, 원인: {e})")
            await asyncio.sleep(2)

async def get_db():
    async with async_session() as session:
        yield session
