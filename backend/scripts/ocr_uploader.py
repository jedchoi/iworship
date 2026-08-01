#!/usr/bin/env python3
import os
import sys
import argparse
import json

try:
    import requests
except ImportError:
    print("이 스크립트를 사용하려면 requests 라이브러리가 필요합니다.")
    print("설치 명령: pip install requests")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="아이워십 (iWorship) 지능형 인쇄물 사진 자동 업로더 CLI 에이전트"
    )
    parser.add_argument(
        "--image", 
        required=True, 
        help="업로드하여 분석할 주간 일정표 또는 매일 묵상 지면 사진 경로 (예: page.jpg)"
    )
    parser.add_argument(
        "--type",
        choices=["weekly", "daily"],
        default="weekly",
        help="업로드 타입: 'weekly' (주간 일정/캘리그라피 지면) 또는 'daily' (매일 성경 본문/해설 독서 지면). 기본값: weekly"
    )
    parser.add_argument(
        "--server", 
        default="http://localhost:8000", 
        help="아이워십 백엔드 서버 주소 (기본값: http://localhost:8000)"
    )
    
    args = parser.parse_args()
    
    image_path = args.image
    if not os.path.exists(image_path):
        print(f"오류: 지정한 이미지 파일을 찾을 수 없습니다: {image_path}")
        sys.exit(1)
        
    print(f"• [1/3] 이미지 파일 로드 중: {image_path} (타입: {args.type.upper()})")
    print(f"• [2/3] 백엔드 서버에 이미지 분석 업로드 요청 중... (서버: {args.server})")
    print("  (Gemini 1.5 Flash API를 활용하여 인쇄 지면을 구조화된 JSON 데이터로 자동 변환합니다.)")
    
    # 2. 업로드 API 엔드포인트 분기
    if args.type == "daily":
        endpoint = "/api/v1/admin/upload-daily-photo"
    else:
        endpoint = "/api/v1/admin/upload-by-photo"
        
    url = f"{args.server.rstrip('/')}{endpoint}"
    
    try:
        with open(image_path, "rb") as f:
            files = {"file": (os.path.basename(image_path), f, "image/jpeg")}
            response = requests.post(url, files=files)
            
        if response.status_code == 200:
            result = response.json()
            data = result.get("data", {})
            print("\n" + "="*60)
            print("🎉 [3/3] 이미지 파싱 및 서버 데이터 저장 성공!")
            print("="*60)
            
            if args.type == "daily":
                print(f"• 묵상 날짜: {data.get('date')}")
                print(f"• 말씀 제목: {data.get('title')} ({data.get('passage')})")
                print(f"• 파싱된 구절 수: {data.get('verses_count')}개 절")
                print("-"*60)
                print("📖 파싱된 성경 본문 절 (Verses):")
                for v in data.get("verses", []):
                    print(f"  {v.get('num')} {v.get('text')}")
                print("-"*60)
                print(f"💡 본문 해설 (Commentary):\n  {data.get('commentary')}")
            else:
                print(f"• 주차 정보: {data.get('week_number')} (주일 시작일: {data.get('start_date')})")
                print(f"• 캘리그라피 요약 말씀: {data.get('calligraphy_scripture')}")
                print(f"• 저장된 캘리그라피 URL: {data.get('calligraphy_image_url')}")
                print("-"*60)
                print(f"🔥 우모하 기도발전소")
                print(f"  • 카테고리: {data.get('weekly_pray_category')}")
                print(f"  • 기도제목: \"{data.get('weekly_prayer')}\"")
                print("-"*60)
                print("📅 주간 성경 공부 / QT 일정 목록 (Daily Scriptures)")
                schedule = data.get("weekly_schedule", [])
                for idx, item in enumerate(schedule):
                    print(f"  [{idx+1}] {item.get('date')} ({item.get('day')}): {item.get('passage')} - {item.get('title')}")
                    
            print("="*60)
            print("• 데이터베이스(PostgreSQL)에 즉시 저장되었습니다.")
            print("• 모바일 앱이 백엔드와 통신 시 최신 말씀 텍스트가 바인딩됩니다.")
        else:
            print(f"\n❌ 서버 업로드 에러 (HTTP {response.status_code})")
            try:
                err_detail = response.json().get("detail", "알 수 없는 에러")
                print(f"상세 에러 내용: {err_detail}")
            except Exception:
                print(response.text)
            sys.exit(1)
            
    except requests.exceptions.ConnectionError:
        print(f"\n❌ 에러: 백엔드 서버({args.server})에 연결할 수 없습니다. 서버가 켜져 있는지 확인하십시오.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 예외 에러 발생: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
