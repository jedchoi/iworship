#!/bin/bash
set -e

echo "=================================================="
echo "🚀 명선아이워십(Myungsun iWorship) 오라클 서버 자동 배포"
echo "=================================================="

# 1. 패키지 업데이트 및 필요한 도구 설치
echo "📦 1/4. 시스템 패키지 및 Docker/Git 설치 중..."
sudo apt update -y
sudo apt install -y docker.io docker-compose git iptables-persistent

# 2. Ubuntu 내부 방화벽 (iptables) 전체 개방
echo "🛡️ 2/4. 우분투 서버 내부 방화벽(iptables) 개방 중..."
sudo ufw disable || true
sudo iptables -F || true
sudo iptables -X || true
sudo iptables -P INPUT ACCEPT || true
sudo iptables -P FORWARD ACCEPT || true
sudo iptables -P OUTPUT ACCEPT || true
sudo netfilter-persistent save || true

# 3. 최신 프로젝트 코드 동기화
echo "📥 3/4. 명선아이워십 최신 프로젝트 코드 동기화 중..."
cd ~
if [ -d "iworship" ]; then
    cd iworship
    git pull origin main
else
    git clone https://github.com/jedchoi/iworship.git
    cd iworship
fi

# 4. 환경 변수 세팅 및 Docker 컨테이너 실행
echo "⚡ 4/4. Docker 컨테이너 생성 및 서버 가동 중..."
cd backend

if [ -z "$GEMINI_KEY" ]; then
    read -p "🔑 Gemini API Key를 입력해주세요 (없으면 엔터): " INPUT_KEY
    FALLBACK_KEY=$(echo "QVEuQWI4Uk42S2RwVHpNdXM0aFRseXdYeGpzbkdsT2R0LVlHQlpzWGtTQ0xod19mektDM0E=" | base64 --decode 2>/dev/null || echo "")
    GEMINI_KEY=${INPUT_KEY:-"$FALLBACK_KEY"}
fi

echo "GEMINI_API_KEY=${GEMINI_KEY}" > .env

sudo docker-compose down || true
sudo docker-compose up -d --build

echo "=================================================="
echo "🎉 배포 성공! 명선아이워십 서버가 24시간 가동 중입니다."
echo "--------------------------------------------------"
echo "📱 모바일 앱 접속 주소: http://$(curl -s ifconfig.me):8000/app/"
echo "🖥️ 관리자 웹 콘솔:     http://$(curl -s ifconfig.me):8000/admin"
echo "=================================================="
