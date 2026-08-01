// ==========================================
// 1. 가상 데이터베이스 (Mock Data) 정의
// ==========================================

// QT 말씀 데이터 (7월 1주차 ~ 2주차)
const mockQtData = [
  // 1주차
  {
    date: "2026-06-28",
    day_of_week: "주일",
    week: "7월 1주차",
    title: "주일 묵상 및 설교",
    passage_range: "예레미야 6:22-30",
    type: "sunday",
    verses: [
      { num: 22, text: "여호와께서 이와 같이 말씀하시되 보라 한 민족이 북방에서 오며 큰 나라가 땅 끝에서부터 떨쳐 일어나나니" },
      { num: 23, text: "그들은 활과 창을 잡았고 잔인하여 사랑이 없으며 그 목소리는 바다처럼 포효하는 소리라 그들이 말을 타고 전사 같이 다 대열을 벌이고 시온의 딸 너를 치려 하느니라" },
      { num: 24, text: "우리가 그 소문을 들었으므로 손이 약하여졌고 고통이 우리를 잡았으므로 그 아픔이 해산하는 여인 같도다" }
    ],
    bgm_commentary: "예레미야 선지자는 북방에서 올 잔인하고 자비 없는 심판의 민족을 경고하며 이스라엘의 슬픔과 위기를 묘사합니다. 이는 형식적인 성전 예배에 안주하며 정의를 잃어버린 유다 백성을 향한 경고입니다.",
    weekly_pray_category: "예배중보기도",
    weekly_prayer: "지난 상반기 동안 우리 교회를 인도하신 하나님께 진정어린 감사와 찬양의 예배를 드리게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-06-29",
    day_of_week: "월요일",
    week: "7월 1주차",
    title: "길과 행위를 바르게 하라",
    passage_range: "예레미야 7:1-7",
    type: "weekday",
    verses: [
      { num: 1, text: "여호와께로부터 예레미야에게 말씀이 임하니라 이르시되" },
      { num: 2, text: "너는 여호와의 집 문에 서서 이 말을 선포하여 이르기를 여호와께 예배하러 이 문으로 들어가는 유다인들아 여호와의 말씀을 들으라" },
      { num: 3, text: "만군의 여호와 이스라엘의 하나님께서 이와 같이 말씀하시되 너희 길과 행위를 바르게 하라 그리하면 내가 너희로 이 곳에 살게 하리라" },
      { num: 4, text: "너희는 이것이 여호와의 성전이라, 여호와의 성전이라, 여호와의 성전이라 하는 거짓말을 믿지 말라" },
      { num: 5, text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며" },
      { num: 6, text: "이방인과 고아와 과부를 압제하지 아니하며 무죄한 자의 피를 이 곳에서 흘리지 아니하며 다른 신들 뒤를 따라 화를 자초하지 아니하면" },
      { num: 7, text: "내가 너희를 이 곳에 살게 하리니 곧 너희 조상에게 영원무궁토록 준 땅이니라" }
    ],
    bgm_commentary: "성전 문앞에서 울려 퍼지는 예레미야의 충격적인 말씀입니다. 백성들은 예배 행위 자체로 구원을 보장받는다고 생각했지만, 하나님은 성전 밖에서 이웃 사이에 정의를 행하고 고아를 압제하지 않는 '길과 행위의 바름'을 요구하십니다.",
    weekly_pray_category: "샬롬기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-06-30",
    day_of_week: "화요일",
    week: "7월 1주차",
    title: "성전을 도둑의 소굴로 만들지 말라",
    passage_range: "예레미야 7:8-15",
    type: "weekday",
    verses: [
      { num: 8, text: "보라 너희가 무익한 거짓말을 의존하는도다" },
      { num: 9, text: "너희가 도둑질하며 살인하며 간음하며 거짓 맹세하며 바알에게 분향하며 너희가 알지 못하는 다른 신들을 따르면서" },
      { num: 10, text: "내 이름으로 일컬음을 받는 이 성전에 들어와서 내 앞에 서서 말하기를 우리가 구원을 얻었나이다 하느냐 이는 이 모든 가증한 일을 행하려 함이로다" },
      { num: 11, text: "내 이름으로 일컬음을 받는 이 성전이 너희 눈에는 도둑의 소굴로 보이느냐 보라 나 곧 내가 이것을 보았노라 여호와의 말씀이니라" }
    ],
    bgm_commentary: "도둑질하고 우상을 숭배하다가 성전에 와서 '구원받았다'고 안도하는 행위는 성전을 도둑들의 은신처(도둑의 소굴)로 만드는 가증한 일입니다. 우리의 신앙이 삶의 불의를 덮어주는 방패가 되어서는 안 됩니다.",
    weekly_pray_category: "미션기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-07-01",
    day_of_week: "수요일",
    week: "7월 1주차",
    title: "도둑의 소굴로 보이느냐",
    passage_range: "예레미야 7:1-11",
    type: "weekday",
    verses: [
      { num: 1, text: "여호와께로부터 예레미야에게 말씀이 임하여 이르시되," },
      { num: 2, text: "너는 여호와의 집 문에 서서 이 말을 선포하여 이르기를 여호께 예배하러 이 문으로 들어가는 유다 사람들아 다 여호와의 말씀을 들으라." },
      { num: 3, text: "만군의 여호와 이스라엘의 하나님께서 이와 같이 말씀하시되 너희 길과 행위를 바르게 하라 그리하면 내가 너희로 이 곳에 살게 하리라." },
      { num: 4, text: "너희는 이것이 여호와의 성전이라, 여호와의 성전이라, 여호와의 성전이라 하는 거짓말을 믿지 말라." },
      { num: 5, text: "너희가 만일 길과 행위를 참으로 바르게 하며 이웃들 사이에 정의를 행하며," },
      { num: 6, text: "이방인과 고아와 과부를 압제하지 아니하며 무죄한 자의 피를 이 곳에서 흘리지 아니하며 다른 신들 뒤를 따라 화를 자초하지 아니하면," },
      { num: 7, text: "내가 너희를 이 곳에 살게 하리니 곧 너희 조상에게 영원무궁토록 준 땅이니라." },
      { num: 8, text: "보라 너희가 무익한 거짓말을 의존하는도다." },
      { num: 9, text: "너희가 도둑질하며 살인하며 간음하며 거짓 맹세하며 바알에게 분향하며 너희가 알지 못하는 다른 신들을 따르면서," },
      { num: 10, text: "내 이름으로 일컬음을 받는 이 성전에 들어와서 내 앞에 서서 말하기를 우리가 구원을 얻었나이다 하느냐 이는 이 모든 가증한 일을 행하려 함이로다." },
      { num: 11, text: "내 이름으로 일컬음을 받는 이 집이 너희 눈에는 도둑의 소굴로 보이느냐 보라 나 곧 내가 이것을 보았노라 여호와의 말씀이니라." }
    ],
    bgm_commentary: "수요일 본문은 1-11절의 전체적인 선포를 담고 있습니다. 하나님은 화려한 예배 의식보다 일터와 가정에서 정의와 정직을 실천하는 정결한 삶의 예배를 찾으십니다.",
    weekly_pray_category: "샬롬기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-07-02",
    day_of_week: "목요일",
    week: "7월 1주차",
    title: "이 백성을 위하여 기도하지 말라",
    passage_range: "예레미야 7:12-20",
    type: "weekday",
    verses: [
      { num: 12, text: "너희는 내가 처음으로 내 이름을 둔 처소 실로에 가서 내 백성 이스라엘의 악에 대하여 내가 어떻게 행하였는지를 보라" },
      { num: 13, text: "여호와의 말씀이니라 이제 너희가 그 모든 일을 행하였으며 내가 너희에게 말하되 새벽부터 부지런히 말하여도 듣지 아니하였고 너희를 불러도 대답하지 아니하였느니라" },
      { num: 14, text: "그러므로 내가 실로에 행함 같이 너희가 의뢰하는 바 내 이름으로 일컬음을 받는 이 집 곧 너희와 너희 조상들에게 준 이 곳에 행하겠고" },
      { num: 16, text: "그런즉 너는 이 백성을 위하여 기도하지 말라 그들을 위하여 부르짖어 구하지 말라 내게 간구하지 말라 내가 네게서 듣지 아니하리라" }
    ],
    bgm_commentary: "하나님은 실로의 성소가 파괴되었던 역사를 상기시키며 예루살렘 성전 역시 무너질 수 있음을 선언하십니다. 더 나아가, 듣지 않는 완악한 백성을 위해 기도하는 것조차 멈추라고 예레미야에게 명하시는 무서운 말씀입니다.",
    weekly_pray_category: "닛시기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-07-03",
    day_of_week: "금요일",
    week: "7월 1주차",
    title: "목을 굳게 하여",
    passage_range: "예레미야 7:21-29",
    type: "weekday",
    verses: [
      { num: 21, text: "만군의 여호와 이스라엘의 하나님께서 이와 같이 말씀하시되 너희 희생제물과 번제물의 고기를 아울러 먹으라" },
      { num: 22, text: "사실은 내가 너희 조상들을 애굽 땅에서 인도하여 낸 날에 번제나 희생제에 대하여 말하지 아니하며 명령하지 아니하고" },
      { num: 23, text: "오직 내가 이것을 그들에게 명령하여 이르기를 너희는 내 목소리를 들으라 그리하면 나는 너희 하나님이 되겠고 너희는 내 백성이 되리라 너희는 내가 명령한 모든 길로 걸어가라 그리하면 복을 받으리라 하였으나" },
      { num: 24, text: "그들이 순종하지 아니하며 귀를 기울이지도 아니하고 자신들의 악한 마음의 꾀와 완악한 대로 행하여 그 뒤를 향하고 그 앞을 향하지 아니하였으며" }
    ],
    bgm_commentary: "출애굽 때 하나님이 원하셨던 본질은 제사가 아니라 '순종과 경청'이었습니다. 백성들은 마음은 먼 채로 제물만 바쳤으며, 경고를 거절하고 목을 곧게 하였습니다.",
    weekly_pray_category: "예배중보기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  {
    date: "2026-07-04",
    day_of_week: "토요일",
    week: "7월 1주차",
    title: "흰놈의 골짜기",
    passage_range: "예레미야 7:30-8:3",
    type: "weekday",
    verses: [
      { num: 30, text: "여호와께서 말씀하시되 유다 자손이 나의 눈 앞에 악을 행하여 내 이름으로 일컬음을 받는 내 집에 가증한 것을 세워 집을 더럽혔으며" },
      { num: 31, text: "흰놈의 아들 골짜기에 도벳 사당을 건축하고 그들의 자녀들을 불에 살랐나니 내가 명령하지 아니하였고 내 마음에 생각지도 아니한 일이니라" },
      { num: 32, text: "그러므로 여호와께서 말씀하시되 날이 이르면 이 곳을 도벳이라 하거나 흰놈의 아들의 골짜기라 부르지 아니하고 죽임의 골짜기라 부르리니" }
    ],
    bgm_commentary: "유다 백성이 흰놈의 골짜기에서 인신 제사를 드리는 우상숭배에 빠졌습니다. 하나님은 그 죄의 결과로 그 골짜기가 심판의 시체 골짜기가 될 것임을 엄히 선언하십니다.",
    weekly_pray_category: "샬롬기도",
    weekly_prayer: "명선의 다음 세대들이 예수님을 뜨겁게 사랑하게 하옵소서.",
    calligraphy_text: "너희가 만일 길과 행위를 참으로 바르게 하여 이웃들 사이에 정의를 행하며",
    calligraphy_ref: "예레미야 7:5"
  },
  
  // 2주차
  {
    date: "2026-07-05",
    day_of_week: "주일",
    week: "7월 2주차",
    title: "주일 묵상 및 설교",
    passage_range: "예레미야 8:4-17",
    type: "sunday",
    verses: [
      { num: 4, text: "너는 또 그들에게 말하기를 여호와의 말씀에 사람이 엎드러지면 어찌 일어나지 아니하겠으며 사람이 떠나갔으면 어찌 돌아오지 아니하겠느냐" },
      { num: 5, text: "이 예루살렘 백성이 항상 나를 떠나 물러감은 어찌함이냐 그들이 거짓을 고집하고 돌아오기를 거절하도다" },
      { num: 6, text: "내가 귀를 기울여 들은즉 그들이 정직을 말하지 아니하며 그들의 악을 뉘우쳐서 내가 행한 것이 무엇인고 말하는 자가 없고 전쟁터로 향하여 달리는 말 같이 각각 그 길로 행하도다" }
    ],
    bgm_commentary: "자연의 법칙도 엎드러지면 일어나는 법인데, 예루살렘 백성들은 하나님을 한 번 떠나면 돌아올 줄을 모릅니다. 양심의 가책도 없이 각자의 이익과 욕망을 향해 달리는 말처럼 질주하는 완악함을 비판하십니다.",
    weekly_pray_category: "미션기도",
    weekly_prayer: "한 주간 우리 가족이 함께 하나님께 드릴 감사 제목들을 모으고 나누게 하소서.",
    calligraphy_text: "자랑하는 자는 이것으로 자랑할지니 곧 명철하여 나를 아는 것과 나 여호와는 사랑과 정의와 공의를 땅에 행하는 자인 줄 깨닫는 것이라",
    calligraphy_ref: "예레미야 9:24"
  },
  {
    date: "2026-07-06",
    day_of_week: "월요일",
    week: "7월 2주차",
    title: "슬프다 나의 근심이여",
    passage_range: "예레미야 8:18-9:1",
    type: "weekday",
    verses: [
      { num: 18, text: "슬프다 나의 근심이여 어떻게 위로를 얻을 수 있을까 내 마음이 병들었도다" },
      { num: 19, text: "딸 내 백성의 심히 먼 땅에서 부르짖는 소리로다 이르되 여호와께서 시온에 계시지 아니한가, 그의 왕이 그 가운데 계시지 아니한가..." }
    ],
    bgm_commentary: "백성들이 심판의 때를 당해 뒤늦게 부르짖으나, 위로를 얻지 못하는 비참한 현실입니다. 예레미야 선지자는 백성들의 상처를 보며 마음이 병들고 눈물 흘리는 애통한 고백을 합니다.",
    weekly_pray_category: "샬롬기도",
    weekly_prayer: "우리 가정이 세상의 것을 자랑하기보다 하나님을 아는 것을 귀하게 여기게 하소서.",
    calligraphy_text: "자랑하는 자는 이것으로 자랑할지니 곧 명철하여 나를 아는 것과 나 여호와는 사랑과 정의와 공의를 땅에 행하는 자인 줄 깨닫는 것이라",
    calligraphy_ref: "예레미야 9:24"
  }
];

// 가상 주보 데이터 (이미지 대신 텍스트 및 SVG 일러스트가 포함된 카드 렌더링)
const mockBulletins = [
  {
    date: "2026-07-12",
    label: "2026년 7월 12일 주보",
    pages: [
      `
      <div class="bulletin-mock-card">
        <svg viewBox="0 0 200 120" style="width: 140px; height: 80px;"><path d="M100 10 L160 50 L145 50 L145 100 L55 100 L55 50 L40 50 Z" fill="none" stroke="#8e7ca2" stroke-width="2"/><rect x="85" y="70" width="30" height="30" fill="none" stroke="#8e7ca2" stroke-width="2"/><path d="M100 10 L100 110" stroke="#8e7ca2" stroke-dasharray="3" stroke-width="1"/><circle cx="100" cy="35" r="10" fill="none" stroke="#8e7ca2" stroke-width="1.5"/></svg>
        <h3>명선교회 주보</h3>
        <h4>2026년 7월 12일 - 주일 1,2,3부 예배</h4>
        <div class="bulletin-order-list">
          <p style="text-align: center; font-weight: 700; color: #8e7ca2; margin-bottom: 10px;">[ 예배 순서 ]</p>
          <ol>
            <li><strong>개회 인도</strong> - 다같이</li>
            <li><strong>신앙 고백</strong> - 사도신경</li>
            <li><strong>대표 기도</strong> - 김영철 장로</li>
            <li><strong>성경 봉독</strong> - 빌립보서 2:5-11</li>
            <li><strong>찬양</strong> - 시온 찬양대</li>
            <li><strong>말씀 선포</strong> - '그리스도의 마음' (담임목사)</li>
            <li><strong>봉헌 및 기도</strong> - 봉헌위원</li>
            <li><strong>교회 소식</strong> - 인도자</li>
            <li><strong>축도</strong> - 담임목사</li>
          </ol>
        </div>
      </div>
      `,
      `
      <div class="bulletin-mock-card">
        <h3>교회 공지사항</h3>
        <h4>알립니다</h4>
        <div style="font-size: 13px; line-height: 1.8; color: #4a4846; width: 100%; margin-top: 15px;">
          <p style="margin-bottom: 12px;"><strong>1. 여름 수련회 선등록 안내</strong><br>• 일시: 7월 24일(금) ~ 26일(주일)<br>• 장소: 가평 은혜수양관<br>• 본당 로비에서 오늘까지 선등록(회비 10% 감면)을 받습니다.</p>
          <p style="margin-bottom: 12px;"><strong>2. 하반기 주말 성경공부 모집</strong><br>• 강좌: 어? 성경이 읽어지네!, 교리대학<br>• 신청: 교회 홈페이지 혹은 로비 신청서 제출</p>
          <p style="margin-bottom: 12px;"><strong>3. 이번 주 교회 청소 봉사</strong><br>• 금주 청소는 <strong>청년 2순</strong> 차례입니다. 토요일 오전 10시에 본당 로비로 모여주시기 바랍니다.</p>
        </div>
      </div>
      `
    ]
  },
  {
    date: "2026-07-05",
    label: "2026년 7월 05일 주보",
    pages: [
      `
      <div class="bulletin-mock-card">
        <svg viewBox="0 0 200 120" style="width: 140px; height: 80px;"><path d="M100 10 L160 50 L145 50 L145 100 L55 100 L55 50 L40 50 Z" fill="none" stroke="#8e7ca2" stroke-width="2"/><rect x="85" y="70" width="30" height="30" fill="none" stroke="#8e7ca2" stroke-width="2"/></svg>
        <h3>명선교회 주보</h3>
        <h4>2026년 7월 5일 - 주일 예배</h4>
        <div class="bulletin-order-list">
          <p style="text-align: center; font-weight: 700; color: #8e7ca2; margin-bottom: 10px;">[ 예배 순서 ]</p>
          <ol>
            <li><strong>개회 인도</strong> - 다같이</li>
            <li><strong>대표 기도</strong> - 이주한 장로</li>
            <li><strong>성경 봉독</strong> - 누가복음 2:1-14</li>
            <li><strong>말씀 선포</strong> - '큰 기쁨의 좋은 소식'</li>
            <li><strong>축도</strong> - 담임목사</li>
          </ol>
        </div>
      </div>
      `,
      `
      <div class="bulletin-mock-card">
        <h3>교회 소식</h3>
        <h4>알립니다</h4>
        <div style="font-size: 13px; line-height: 1.8; color: #4a4846; width: 100%; margin-top: 15px;">
          <p><strong>1. 새가족 환영</strong><br>• 명선교회에 새로 오신 성도님들을 환영합니다. 등록을 원하시면 안내위원에게 문의 바랍니다.</p>
        </div>
      </div>
      `
    ]
  }
];

// ==========================================
// 2. 상태(State) 및 상수 관리
// ==========================================
let state = {
  currentDate: "2026-07-01", // 현재 선택된 QT 날짜
  activeTab: "screen-meditation", // 현재 탭
  notes: {}, // 사용자 입력 기록 로컬 캐시 (localStorage와 동기화)
  bulletinIdx: 0, // 현재 주보 슬라이드 페이지 인덱스
  bulletinDate: "2026-07-12", // 현재 선택된 주보 날짜
  fontSize: 17 // 성경 본문 폰트 크기
};

// 캘리그라피 나뭇잎 모양 SVG 스트링
const leafSvg = `
  <svg viewBox="0 0 100 100" width="80" height="80">
    <path d="M50,90 Q30,60 30,40 Q30,20 50,10 Q70,20 70,40 Q70,60 50,90 Z" fill="none" stroke="#6aa84f" stroke-width="3"/>
    <path d="M50,90 Q50,45 50,12" fill="none" stroke="#6aa84f" stroke-width="2"/>
    <path d="M50,70 Q40,65 35,55" fill="none" stroke="#6aa84f" stroke-width="2"/>
    <path d="M50,55 Q60,50 65,40" fill="none" stroke="#6aa84f" stroke-width="2"/>
    <path d="M50,40 Q40,35 37,25" fill="none" stroke="#6aa84f" stroke-width="2"/>
  </svg>
`;

// ==========================================
// 3. 앱 초기화 (Initialization)
// ==========================================
document.addEventListener("DOMContentLoaded", () => {
  // 로컬스토리지에서 메모 기록 로드
  const savedNotes = localStorage.getItem("iworship_notes");
  if (savedNotes) {
    state.notes = JSON.parse(savedNotes);
  }
  
  // 첫 진입 시 데이터 로딩 및 렌더링
  loadActiveQt(state.currentDate);
  buildWeeklyStrip("7월 1주차");
  buildCalendarGrid();
  renderHistoryFeed();
  buildBulletinSelect();
  loadBulletin(state.bulletinDate);
  
  // 탭바 네비게이션 등록
  const navItems = document.querySelectorAll(".nav-item");
  navItems.forEach(item => {
    item.addEventListener("click", (e) => {
      const targetScreen = e.currentTarget.getAttribute("data-target");
      switchTab(targetScreen, e.currentTarget);
    });
  });

  // 주간 일정 모달 제어
  document.getElementById("week-selector-btn").addEventListener("click", openWeeklyModal);
  document.getElementById("modal-close-btn").addEventListener("click", closeWeeklyModal);
  document.getElementById("modal-start-btn").addEventListener("click", closeWeeklyModal);
  document.getElementById("weekly-modal").addEventListener("click", (e) => {
    if (e.target.id === "weekly-modal") closeWeeklyModal();
  });
  
  // 모달 안 주차 변경 화살표
  document.getElementById("modal-prev-week").addEventListener("click", () => switchModalWeek(-1));
  document.getElementById("modal-next-week").addEventListener("click", () => switchModalWeek(1));

  // 말씀 해설 바텀시트 제어
  document.getElementById("bgm-btn").addEventListener("click", openBgmSheet);
  document.getElementById("sheet-close-btn").addEventListener("click", closeBgmSheet);
  document.getElementById("bgm-sheet").addEventListener("click", (e) => {
    if (e.target.id === "bgm-sheet") closeBgmSheet();
  });

  // 카톡 나눔 버튼 바인딩
  document.getElementById("share-kakao-btn").addEventListener("click", shareToKakao);
  
  // 주보 탭 스와이프 제어
  document.getElementById("bulletin-prev-btn").addEventListener("click", () => changeBulletinPage(-1));
  document.getElementById("bulletin-next-btn").addEventListener("click", () => changeBulletinPage(1));
  document.getElementById("bulletin-select").addEventListener("change", (e) => {
    state.bulletinDate = e.target.value;
    loadBulletin(state.bulletinDate);
  });

  // 설정 탭 폰트 크기 슬라이더 제어
  // 설정 탭 폰트 크기 슬라이더 제어 및 헬퍼 함수 정의
  window.updateFontSize = function(size) {
    // 최소 14px, 최대 30px 제한
    const newSize = Math.max(14, Math.min(30, Math.round(size)));
    state.fontSize = newSize;
    const container = document.getElementById("scripture-container");
    if (container) {
      container.style.fontSize = `${newSize}px`;
    }
    const fontSlider = document.getElementById("font-size-slider");
    if (fontSlider) {
      fontSlider.value = newSize;
    }
  };

  const fontSlider = document.getElementById("font-size-slider");
  fontSlider.addEventListener("input", (e) => {
    window.updateFontSize(e.target.value);
  });

  // 성경 본문 컨테이너 핀치 줌 및 마우스 휠(Ctrl 키 조합) 줌 제어 등록
  initScriptureZoom();

  // 백업/복원 연동 모의
  document.getElementById("btn-sync-push").addEventListener("click", syncPush);
  document.getElementById("btn-sync-pull").addEventListener("click", syncPull);

  // 해시태그 필터 바인딩
  const filterChips = document.querySelectorAll(".filter-chip");
  filterChips.forEach(chip => {
    chip.addEventListener("click", (e) => {
      filterChips.forEach(c => c.classList.remove("active"));
      e.currentTarget.classList.add("active");
      const filter = e.currentTarget.getAttribute("data-filter");
      renderHistoryFeed(filter);
    });
  });
});

// ==========================================
// 4. 화면 전환 및 데이터 로딩 함수
// ==========================================

// 탭 선택 기능
function switchTab(screenId, navElement) {
  // 스크린 전환
  const screens = document.querySelectorAll(".screen");
  screens.forEach(s => s.classList.remove("active"));
  document.getElementById(screenId).classList.add("active");

  // 탭바 선택 시각화 전환
  const navItems = document.querySelectorAll(".nav-item");
  navItems.forEach(n => n.classList.remove("active"));
  navElement.classList.add("active");

  state.activeTab = screenId;
  
  // 탭별 추가 로드
  if (screenId === "screen-journey") {
    buildCalendarGrid();
    renderHistoryFeed();
  }
}

// 특정 날짜의 QT 말씀 데이터 렌더링
function loadActiveQt(dateStr) {
  const qt = mockQtData.find(q => q.date === dateStr);
  if (!qt) return;
  
  state.currentDate = dateStr;

  // 헤더 타이틀 정보 바인딩
  document.getElementById("current-week-label").innerText = qt.week;
  document.getElementById("meditation-title").innerText = qt.title;
  document.getElementById("meditation-ref").innerText = qt.passage_range;

  // 성경 구절 바인딩 (절 번호 및 개행)
  const container = document.getElementById("scripture-container");
  container.innerHTML = "";
  qt.verses.forEach(v => {
    const verseDiv = document.createElement("div");
    verseDiv.className = "verse-item";
    verseDiv.setAttribute("data-num", v.num);
    verseDiv.innerHTML = `
      <span class="verse-num">${v.num}</span>
      <span class="verse-text">${v.text}</span>
    `;
    
    // 특정 절 클릭 시 인라인 말씀 NOTE 개폐
    verseDiv.addEventListener("click", () => toggleVerseNote(v.num));
    
    container.appendChild(verseDiv);

    // 인라인 메모 상자 동적 배치
    const noteBox = document.createElement("div");
    noteBox.className = "verse-note-box";
    noteBox.id = `note-box-${v.num}`;
    const savedVerseNote = (state.notes[dateStr] && state.notes[dateStr].verse_notes && state.notes[dateStr].verse_notes[v.num]) || "";
    noteBox.innerHTML = `
      <textarea placeholder="이 구절에 대한 내 묵상 메모를 적으세요..." id="textarea-${v.num}" oninput="saveVerseNote(${v.num}, this.value)">${savedVerseNote}</textarea>
    `;
    container.appendChild(noteBox);
  });

  // 해설 BGM 텍스트 바인딩
  document.getElementById("bgm-commentary-text").innerText = qt.bgm_commentary;

  // 평일/주일 전용 작성 폼 양식 로드
  renderPage2Form(qt);

  // 스와이프를 무조건 첫 번째 페이지(말씀)로 돌려놓음
  meditationSwipe(0);

  // 주간 달력 상태 변경
  updateWeeklyStripActive();
}

// 묵상 탭 내 말씀(0)/기록(1) 페이지 스와이프
function meditationSwipe(pageIdx) {
  const slider = document.getElementById("meditation-slider");
  const dots = document.querySelectorAll(".page-indicator .dot");
  
  dots.forEach(d => d.classList.remove("active"));
  dots[pageIdx].classList.add("active");
  
  if (pageIdx === 0) {
    slider.style.transform = "translateX(0%)";
  } else {
    slider.style.transform = "translateX(-50%)";
  }
}

// 평일/주일 양식에 맞춘 Page 2 렌더링
function renderPage2Form(qt) {
  const container = document.getElementById("meditation-form-content");
  container.innerHTML = "";
  
  const savedData = state.notes[qt.date] || {};

  const communityPrayerCategory = qt.weekly_pray_category || "공동체 기도";
  const communityPrayer = qt.weekly_prayer || "교회 공동체 전체가 합심하여 기도의 불을 끄지 않도록 인도하옵소서.";

  // 우모하 기도발전소 카드 공통 생성 (서버에서 지정한 단 하나의 카테고리와 기도 내용만 출력)
  const prayerPowerhouseCard = `
    <div class="input-card" style="background-color: #f7f5f0; border: 1.5px solid #8e7ca2; margin-bottom: 16px;">
      <h3 style="color: #6e5c82; display: flex; align-items: center; gap: 6px; font-size: 15px; font-weight: 800; border-bottom: 1px dashed #d0c8da; padding-bottom: 8px; margin-bottom: 8px;">
        <svg class="icon" viewBox="0 0 24 24" style="width:18px; height:18px; fill:#6e5c82;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
        🔥 우모하 기도발전소
      </h3>
      <div style="font-size: 13px; line-height: 1.6; color: #4a4846; padding-top: 4px;">
        <p><strong>• ${communityPrayerCategory}:</strong> "${communityPrayer}"</p>
      </div>
    </div>
  `;

  if (qt.type === "weekday") {
    // 평일 양식: 우모하 기도발전소 + 감사, 말씀, 적용, 기도
    container.innerHTML = `
      ${prayerPowerhouseCard}
      
      <div class="input-card">
        <h3>오늘의 감사</h3>
        <textarea class="input-field" placeholder="오늘 감사한 일을 한 줄 이상 적어봅시다." oninput="saveNoteField('gratitude', this.value)">${savedData.gratitude || ""}</textarea>
      </div>
      <div class="input-card">
        <h3>아로새길 말씀</h3>
        <textarea class="input-field" placeholder="말씀을 읽으며 마음에 남은 구절이나 느낌을 자유롭게 적어보세요." oninput="saveNoteField('verse_highlight', this.value)">${savedData.verse_highlight || ""}</textarea>
      </div>
      <div class="input-card">
        <h3>오늘의 적용</h3>
        <textarea class="input-field" placeholder="오늘 내가 실천해 볼 적용사항을 써보세요." oninput="saveNoteField('application', this.value)">${savedData.application || ""}</textarea>
      </div>
      <div class="input-card">
        <h3>오늘의 기도</h3>
        <textarea class="input-field" placeholder="주신 말씀으로 살아낼 힘을 구하며 기도문을 적어보세요." oninput="saveNoteField('prayer', this.value)">${savedData.prayer || ""}</textarea>
      </div>
    `;
  } else {
    // 주일 양식: 우모하 기도발전소 + 주일 IBS(3개) + 설교노트
    const ibs = savedData.sunday_ibs || {};
    container.innerHTML = `
      ${prayerPowerhouseCard}
      
      <div class="input-card">
        <h3>주일 IBS (귀납적 성경공부)</h3>
        
        <p class="q-text">1. 오늘 말씀을 통해 알게 된 하나님은 어떠한 하나님인가요?</p>
        <textarea class="input-field" placeholder="생각을 여기에 적으세요..." oninput="saveIbsField('q1', this.value)">${ibs.q1 || ""}</textarea>
        
        <p class="q-text" style="margin-top:16px;">2. 오늘 말씀을 통해 깨달은 것과 받은 은혜는 무엇인가요?</p>
        <textarea class="input-field" placeholder="생각을 여기에 적으세요..." oninput="saveIbsField('q2', this.value)">${ibs.q2 || ""}</textarea>
        
        <p class="q-text" style="margin-top:16px;">3. 나는 한 주간 어떤 삶을 살 것인지 다짐하고 함께 나누어 봅시다.</p>
        <textarea class="input-field" placeholder="다짐을 입력해 보세요..." oninput="saveIbsField('q3', this.value)">${ibs.q3 || ""}</textarea>
        
        <div class="ibs-checkbox-group">
          <label class="ibs-check-label">
            <input type="checkbox" id="check-action" ${savedData.action_completed ? 'checked' : ''} onchange="saveNoteField('action_completed', this.checked)">
            <span>실천 후 박스에 체크하세요 (🌱)</span>
          </label>
        </div>
      </div>
      
      <div class="input-card">
        <h3>설교 NOTE</h3>
        <p class="q-text" style="color: #7c7876; font-size:11.5px; margin-bottom: 4px;">예배 중 설교 말씀을 기록하는 빈 공간입니다 (10초 단위 자동 임시저장)</p>
        <textarea class="sermon-notepad" placeholder="설교 본문, 제목, 말씀을 경청하여 필기하세요..." oninput="saveNoteField('sermon_notes', this.value)">${savedData.sermon_notes || ""}</textarea>
      </div>
    `;
  }
}

// ==========================================
// 5. 메모 및 노팅 데이터 핸들러 (로컬 저장)
// ==========================================

// 일반 필드 실시간 임시 저장
function saveNoteField(field, val) {
  const date = state.currentDate;
  if (!state.notes[date]) {
    state.notes[date] = { date: date };
  }
  
  state.notes[date][field] = val;
  state.notes[date].updated_at = new Date().toISOString();
  state.notes[date].is_synced = 0; // 동기화 안 됨
  
  localStorage.setItem("iworship_notes", JSON.stringify(state.notes));
  
  // 잎새 🌱 완료 표시 업데이트
  checkCompletionState(date);
}

// 주일 IBS 개별 질문 임시 저장
function saveIbsField(qKey, val) {
  const date = state.currentDate;
  if (!state.notes[date]) {
    state.notes[date] = { date: date };
  }
  if (!state.notes[date].sunday_ibs) {
    state.notes[date].sunday_ibs = {};
  }
  
  state.notes[date].sunday_ibs[qKey] = val;
  state.notes[date].updated_at = new Date().toISOString();
  state.notes[date].is_synced = 0;
  
  localStorage.setItem("iworship_notes", JSON.stringify(state.notes));
  checkCompletionState(date);
}

// 구절별 말씀 인라인 메모 저장
function saveVerseNote(verseNum, val) {
  const date = state.currentDate;
  if (!state.notes[date]) {
    state.notes[date] = { date: date };
  }
  if (!state.notes[date].verse_notes) {
    state.notes[date].verse_notes = {};
  }
  
  state.notes[date].verse_notes[verseNum] = val;
  state.notes[date].updated_at = new Date().toISOString();
  state.notes[date].is_synced = 0;
  
  localStorage.setItem("iworship_notes", JSON.stringify(state.notes));
  checkCompletionState(date);
}

// 인라인 말씀 NOTE 창 접고 펴기
function toggleVerseNote(verseNum) {
  const box = document.getElementById(`note-box-${verseNum}`);
  box.classList.toggle("active");
  if (box.classList.contains("active")) {
    document.getElementById(`textarea-${verseNum}`).focus();
  }
}

// 완료 상태(새싹 🌱) 갱신 조건 판단 (1개 이상 작성 완료 시 🌱 획득)
function checkCompletionState(dateStr) {
  const note = state.notes[dateStr];
  let isDone = false;
  
  if (note) {
    // 평일 항목 중 하나라도 작성이 되었을 시
    if (note.gratitude || note.verse_highlight || note.application || note.prayer) {
      isDone = true;
    }
    // 주일 IBS 항목 중 하나라도 기입이 되었을 시
    if (note.sunday_ibs && (note.sunday_ibs.q1 || note.sunday_ibs.q2 || note.sunday_ibs.q3)) {
      isDone = true;
    }
    // 설교노트 기입 시
    if (note.sermon_notes) {
      isDone = true;
    }
    // 구절별 말씀노트가 1개라도 적혔을 시
    if (note.verse_notes && Object.values(note.verse_notes).some(v => v)) {
      isDone = true;
    }
  }
  
  // 주간 달력 아이템 갱신
  const stripItem = document.getElementById(`strip-date-${dateStr}`);
  if (stripItem) {
    if (isDone) stripItem.classList.add("completed");
    else stripItem.classList.remove("completed");
  }
}

// ==========================================
// 6. 주간 달력 스트립 빌더 (홈화면 뷰)
// ==========================================
function buildWeeklyStrip(weekStr) {
  const strip = document.getElementById("weekly-strip");
  strip.innerHTML = "";
  
  // 필터링된 주차 데이터 취득
  const weekData = mockQtData.filter(q => q.week === weekStr);
  
  weekData.forEach(qt => {
    const item = document.createElement("div");
    item.className = "weekly-day-item";
    item.id = `strip-date-${qt.date}`;
    if (qt.date === state.currentDate) item.classList.add("active");
    
    // 이 날의 요일명에서 앞 글자만 따옴 (수요일 -> 수)
    const dayLabel = qt.day_of_week.substring(0, 1);
    const dayNum = parseInt(qt.date.substring(8));
    
    item.innerHTML = `
      <span class="day-label">${dayLabel}</span>
      <span class="day-num">${dayNum}</span>
      <span class="sprout-indicator">🌱</span>
    `;
    
    item.addEventListener("click", () => {
      loadActiveQt(qt.date);
    });
    
    strip.appendChild(item);
    
    // 로컬 스토리지 데이터 유무 확인하여 새싹 세팅
    checkCompletionState(qt.date);
  });
}

function updateWeeklyStripActive() {
  const items = document.querySelectorAll(".weekly-day-item");
  items.forEach(item => {
    item.classList.remove("active");
    if (item.id === `strip-date-${state.currentDate}`) {
      item.classList.add("active");
    }
  });
}

// ==========================================
// 7. 주차 안내 모달 팝업 및 주간 일정표 제어
// ==========================================
let modalCurrentWeek = "7월 1주차";

function openWeeklyModal() {
  const modal = document.getElementById("weekly-modal");
  modal.classList.add("active");
  loadModalWeekData(modalCurrentWeek);
}

function closeWeeklyModal() {
  const modal = document.getElementById("weekly-modal");
  modal.classList.remove("active");
}

// 모달 내부 데이터 바인딩
function loadModalWeekData(weekStr) {
  modalCurrentWeek = weekStr;
  document.getElementById("modal-week-title").innerText = weekStr;
  
  const weekData = mockQtData.filter(q => q.week === weekStr);
  if (weekData.length === 0) return;
  
  // 캘리그라피 말씀 및 잎새 렌더링
  const svgContainer = document.getElementById("modal-calligraphy-container");
  svgContainer.innerHTML = leafSvg;
  
  // 말씀 카드 텍스트 로딩
  const firstItem = weekData[0];
  document.getElementById("modal-calligraphy-text").innerText = `"${firstItem.calligraphy_text}"\n(${firstItem.calligraphy_ref})`;
  
  // 주간 일정 테이블 빌드
  const tbody = document.getElementById("modal-schedule-tbody");
  tbody.innerHTML = "";
  
  weekData.forEach(qt => {
    const tr = document.createElement("tr");
    
    // 월/일로 날짜 표기 (예: "07/01")
    const dateFormatted = qt.date.substring(5).replace("-", "/");
    
    tr.innerHTML = `
      <td>${qt.day_of_week.substring(0, 1)} ${dateFormatted}</td>
      <td><strong>${qt.passage_range}</strong></td>
      <td class="weekly-table-title">${qt.title}</td>
    `;
    
    // 행 클릭 시 해당 날짜 QT로 점프하며 모달 닫기
    tr.addEventListener("click", () => {
      // 1주차 / 2주차 스위칭 시 주간 스트립도 교체
      const currentQt = mockQtData.find(q => q.date === qt.date);
      buildWeeklyStrip(currentQt.week);
      loadActiveQt(qt.date);
      closeWeeklyModal();
    });
    
    tbody.appendChild(tr);
  });
}

// 화살표 주차 이동 (<, >)
function switchModalWeek(direction) {
  const currentNum = parseInt(modalCurrentWeek.match(/\d+/)[0]);
  let nextNum = currentNum + direction;
  if (nextNum < 1) nextNum = 2; // 가상 데이터상 1, 2주차만 존재하므로 룹핑
  if (nextNum > 2) nextNum = 1;
  
  const nextWeekStr = `7월 ${nextNum}주차`;
  loadModalWeekData(nextWeekStr);
}

// ==========================================
// 8. 말씀 해설 BGM 바텀 시트 열기/닫기
// ==========================================
function openBgmSheet() {
  document.getElementById("bgm-sheet").classList.add("active");
}

function closeBgmSheet() {
  document.getElementById("bgm-sheet").classList.remove("active");
}

// ==========================================
// 9. 여정 (달력) 탭 구현
// ==========================================
function buildCalendarGrid() {
  const grid = document.getElementById("calendar-days-grid");
  grid.innerHTML = "";
  
  // 7월 가상 시작 요일: 수요일 (수=3일) ➔ 1일부터 시작
  // 빈 셀 생성 (이전 달 7월 이전인 6월의 남은 일수 - 일(0), 월(1), 화(2))
  for (let i = 0; i < 3; i++) {
    const cell = document.createElement("div");
    cell.className = "calendar-day-cell other-month";
    const prevNum = 28 + i; // 6월 28, 29, 30일
    cell.innerHTML = `<span class="cal-num">${prevNum}</span>`;
    grid.appendChild(cell);
  }
  
  // 7월 1일부터 31일까지 그리드 생성
  for (let day = 1; day <= 31; day++) {
    const dayStr = day < 10 ? `0${day}` : `${day}`;
    const fullDate = `2026-07-${dayStr}`;
    
    const cell = document.createElement("div");
    cell.className = "calendar-day-cell";
    if (day === 12) cell.classList.add("today"); // 가상의 오늘 설정
    
    cell.innerHTML = `
      <span class="cal-num">${day}</span>
      <span class="cal-sprout" id="cal-sprout-${fullDate}"></span>
    `;
    
    // 데이터베이스에 등록된 날짜라면 링크 연결
    const qt = mockQtData.find(q => q.date === fullDate);
    if (qt) {
      // 완료 시 연보라색 백그라운드 주기 위해 데이터 확인
      const note = state.notes[fullDate];
      let isDone = false;
      if (note && (note.gratitude || note.verse_highlight || note.application || note.prayer || (note.sunday_ibs && (note.sunday_ibs.q1 || note.sunday_ibs.q2 || note.sunday_ibs.q3)) || note.sermon_notes || (note.verse_notes && Object.values(note.verse_notes).some(v => v)))) {
        isDone = true;
      }
      
      if (isDone) {
        cell.classList.add("completed");
        cell.querySelector(".cal-sprout").innerText = "🌱";
      }
      
      // 달력의 날짜 클릭 시 해당 날짜 묵상으로 이동
      cell.addEventListener("click", () => {
        buildWeeklyStrip(qt.week);
        loadActiveQt(fullDate);
        switchTab("screen-meditation", document.querySelectorAll(".nav-item")[0]);
      });
    }
    
    grid.appendChild(cell);
  }

  // 완료 통계 수치 갱신
  updateStats();
}

function updateStats() {
  const totalDays = mockQtData.length;
  let doneCount = 0;
  
  mockQtData.forEach(qt => {
    const note = state.notes[qt.date];
    if (note && (note.gratitude || note.verse_highlight || note.application || note.prayer || (note.sunday_ibs && (note.sunday_ibs.q1 || note.sunday_ibs.q2 || note.sunday_ibs.q3)) || note.sermon_notes || (note.verse_notes && Object.values(note.verse_notes).some(v => v)))) {
      doneCount++;
    }
  });

  const percentage = totalDays > 0 ? Math.round((doneCount / totalDays) * 100) : 0;
  document.getElementById("stats-percentage").innerText = `${percentage}%`;
  document.getElementById("stats-count").innerText = `${doneCount}일`;
}

// 달력 아래 지난 묵상 내용 피드 렌더링
function renderHistoryFeed(filterType = "all") {
  const container = document.getElementById("feed-list-container");
  container.innerHTML = "";
  
  let matchCount = 0;
  
  // 날짜 역순으로 정렬
  const dates = Object.keys(state.notes).sort((a, b) => new Date(b) - new Date(a));
  
  dates.forEach(date => {
    const note = state.notes[date];
    const qt = mockQtData.find(q => q.date === date);
    if (!qt) return;
    
    let feedItemsHTML = "";
    
    if (qt.type === "weekday") {
      if ((filterType === "all" || filterType === "gratitude") && note.gratitude) {
        feedItemsHTML += `<div class="feed-item-row"><span class="feed-item-tag">#감사</span><span class="feed-item-text">${note.gratitude}</span></div>`;
      }
      if ((filterType === "all" || filterType === "prayer") && note.prayer) {
        feedItemsHTML += `<div class="feed-item-row"><span class="feed-item-tag">#기도</span><span class="feed-item-text">${note.prayer}</span></div>`;
      }
    } else {
      if (note.sunday_ibs) {
        if ((filterType === "all" || filterType === "gratitude") && note.sunday_ibs.q2) {
          feedItemsHTML += `<div class="feed-item-row"><span class="feed-item-tag">#은혜</span><span class="feed-item-text">${note.sunday_ibs.q2}</span></div>`;
        }
      }
      if ((filterType === "all" || filterType === "sermon") && note.sermon_notes) {
        feedItemsHTML += `<div class="feed-item-row"><span class="feed-item-tag">#설교노트</span><span class="feed-item-text" style="white-space: pre-line;">${note.sermon_notes}</span></div>`;
      }
    }
    
    if (feedItemsHTML) {
      matchCount++;
      const card = document.createElement("div");
      card.className = "feed-card";
      card.innerHTML = `
        <div class="feed-card-header">
          <span class="feed-card-date">${date} (${qt.day_of_week})</span>
          <span class="feed-card-title">${qt.title}</span>
        </div>
        ${feedItemsHTML}
      `;
      container.appendChild(card);
    }
  });

  if (matchCount === 0) {
    container.innerHTML = `
      <div style="text-align: center; color: #7c7876; padding: 40px 0; font-size:13.5px;">
        기록된 지난 묵상이 없습니다.<br>오늘의 묵상 탭에서 감사를 적어보세요!
      </div>
    `;
  }
}

// ==========================================
// 10. 교회 주보 탭 스와이프 슬라이더 구현
// ==========================================
function buildBulletinSelect() {
  const select = document.getElementById("bulletin-select");
  select.innerHTML = "";
  
  mockBulletins.forEach(b => {
    const opt = document.createElement("option");
    opt.value = b.date;
    opt.innerText = b.label;
    select.appendChild(opt);
  });
}

function loadBulletin(dateStr) {
  const bulletin = mockBulletins.find(b => b.date === dateStr);
  if (!bulletin) return;
  
  state.bulletinIdx = 0;
  
  const slider = document.getElementById("bulletin-slider");
  slider.innerHTML = "";
  
  bulletin.pages.forEach((pageHTML, idx) => {
    const pageDiv = document.createElement("div");
    pageDiv.className = `bulletin-page ${idx === 0 ? 'active' : ''}`;
    pageDiv.innerHTML = pageHTML;
    slider.appendChild(pageDiv);
  });
  
  updateBulletinNav(bulletin.pages.length);
}

function changeBulletinPage(direction) {
  const bulletin = mockBulletins.find(b => b.date === state.bulletinDate);
  if (!bulletin) return;
  
  const total = bulletin.pages.length;
  let nextIdx = state.bulletinIdx + direction;
  
  if (nextIdx < 0 || nextIdx >= total) return; // 슬라이드 바운더리 체크
  
  state.bulletinIdx = nextIdx;
  
  const pages = document.querySelectorAll(".bulletin-page");
  pages.forEach((p, idx) => {
    p.classList.remove("active");
    if (idx === nextIdx) p.classList.add("active");
  });
  
  updateBulletinNav(total);
}

function updateBulletinNav(total) {
  document.getElementById("bulletin-page-indicator").innerText = `${state.bulletinIdx + 1} / ${total}`;
  document.getElementById("bulletin-prev-btn").disabled = state.bulletinIdx === 0;
  document.getElementById("bulletin-next-btn").disabled = state.bulletinIdx === total - 1;
}

// ==========================================
// 11. 카카오톡 공유 및 텍스트 클립보드 복사
// ==========================================
function shareToKakao() {
  const qt = mockQtData.find(q => q.date === state.currentDate);
  const note = state.notes[state.currentDate] || {};
  
  if (!qt) return;
  
  let shareText = `📖 [아이워십 QT 나눔] ${qt.date} (${qt.day_of_week.substring(0,1)})\n`;
  shareText += `본문: ${qt.passage_range}\n`;
  shareText += `제목: ${qt.title}\n\n`;
  
  if (qt.type === "weekday") {
    if (note.gratitude) shareText += `🌱 오늘의 감사:\n"${note.gratitude}"\n\n`;
    if (note.verse_highlight) shareText += `🌱 아로새길 말씀:\n"${note.verse_highlight}"\n\n`;
    if (note.application) shareText += `🌱 오늘의 적용:\n"${note.application}"\n\n`;
    if (note.prayer) shareText += `🌱 오늘의 기도:\n"${note.prayer}"\n`;
  } else {
    if (note.sunday_ibs) {
      if (note.sunday_ibs.q1) shareText += `🌱 오늘 알게 된 하나님:\n"${note.sunday_ibs.q1}"\n\n`;
      if (note.sunday_ibs.q2) shareText += `🌱 깨달은 것과 받은 은혜:\n"${note.sunday_ibs.q2}"\n\n`;
      if (note.sunday_ibs.q3) shareText += `🌱 나의 다짐:\n"${note.sunday_ibs.q3}"\n`;
    }
  }

  // 클립보드 복사
  navigator.clipboard.writeText(shareText).then(() => {
    alert("묵상 나눔 텍스트가 클립보드에 복사되었습니다! 카톡창에 붙여넣기(Ctrl+V) 하세요.");
  }).catch(err => {
    alert("클립보드 복사에 실패했습니다. 직접 복사해 주세요.");
  });
}

// ==========================================
// 12. PC 서버 백업/동기화(Sync Push & Pull) 모의 구현
// ==========================================
function syncPush() {
  const serverUrl = document.getElementById("server-url-input").value;
  if (!serverUrl) {
    alert("서버 주소를 입력하세요.");
    return;
  }

  // 1초간 백업하는 척 시뮬레이션
  const btn = document.getElementById("btn-sync-push");
  const oldText = btn.innerText;
  btn.innerText = "서버 백업 중...";
  btn.disabled = true;

  setTimeout(() => {
    // 모든 로컬 노트를 동기화 완료 상태로 갱신
    Object.keys(state.notes).forEach(date => {
      state.notes[date].is_synced = 1;
    });
    localStorage.setItem("iworship_notes", JSON.stringify(state.notes));
    localStorage.setItem("server_backup_data", JSON.stringify(state.notes)); // 모의 서버 DB 저장

    btn.innerText = oldText;
    btn.disabled = false;
    alert(`성공: [${serverUrl}] 서버로 작성한 묵상 데이터 백업이 완료되었습니다!`);
  }, 1000);
}

function syncPull() {
  const serverUrl = document.getElementById("server-url-input").value;
  
  const btn = document.getElementById("btn-sync-pull");
  const oldText = btn.innerText;
  btn.innerText = "서버에서 불러오는 중...";
  btn.disabled = true;

  setTimeout(() => {
    const backup = localStorage.getItem("server_backup_data");
    if (backup) {
      state.notes = JSON.parse(backup);
      localStorage.setItem("iworship_notes", backup);
      
      // 현재 화면 갱신
      loadActiveQt(state.currentDate);
      buildCalendarGrid();
      renderHistoryFeed();
      
      alert("성공: 서버의 백업 데이터를 기기에 복원했습니다!");
    } else {
      alert("알림: 서버에 저장된 백업 데이터가 없습니다. 먼저 백업을 실행하세요.");
    }
    
    btn.innerText = oldText;
    btn.disabled = false;
  }, 1000);
}

// 성경 본문 핀치 줌 및 마우스 휠 줌 기능 등록
function initScriptureZoom() {
  const container = document.getElementById("scripture-container");
  if (!container) return;

  let startDist = 0;
  let startFontSize = 17;

  // 1. 모바일용 핀치 제스처 처리 (두 손가락 터치)
  container.addEventListener("touchstart", (e) => {
    if (e.touches.length === 2) {
      // 두 손가락 사이의 피타고라스 거리 계산
      startDist = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      startFontSize = state.fontSize;
    }
  }, { passive: true });

  container.addEventListener("touchmove", (e) => {
    if (e.touches.length === 2 && startDist > 0) {
      // 브라우저 자체의 전체 화면 줌 차단
      e.preventDefault();
      
      const currentDist = Math.hypot(
        e.touches[0].clientX - e.touches[1].clientX,
        e.touches[0].clientY - e.touches[1].clientY
      );
      
      // 스케일 비율 계산
      const scale = currentDist / startDist;
      const targetSize = startFontSize * scale;
      
      // 폰트 크기 업데이트
      window.updateFontSize(targetSize);
    }
  }, { passive: false });

  container.addEventListener("touchend", () => {
    startDist = 0;
  });

  // 2. 데스크톱용 마우스 휠 줌 처리 (Ctrl 키를 누른 상태에서 휠 회전)
  container.addEventListener("wheel", (e) => {
    if (e.ctrlKey) {
      e.preventDefault(); // 브라우저 자체 화면 돋보기 줌 방지
      const direction = e.deltaY < 0 ? 1 : -1; // 휠 올리면 +, 내리면 -
      const targetSize = state.fontSize + direction;
      window.updateFontSize(targetSize);
    }
  }, { passive: false });
}
