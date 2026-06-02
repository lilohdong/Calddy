# 프로필·설정 UI 설계 (2026-06-01)

## 범위
`lib/features/user/presentation/` 내 pages/widgets만 수정. data/, domain/ 불변.

## 화면 목록

### 1. ProfilePage (수정)
- 상단: 아바타(원형) + 닉네임 (굵게)
- 소개글 없음
- 메뉴 카드: 프로필(person 아이콘) / 이메일(mail) / 생년월일(cake) / 알림 설정(bell)
- 하단: 로그아웃 버튼(purple 채움) + 회원 탈퇴 버튼(연분홍 채움)
- 배경: 연보라(#F5F0FF)

### 2. EditProfilePage (수정)
- 아바타 + 카메라 오버레이 → image_picker → updateAvatarUseCaseProvider
- 닉네임 TextField: 실시간 유효성(2자 이상 / 특수문자 금지 / 20자 제한 + 카운터)
- 소개 필드 없음
- 저장 → updateNicknameUseCaseProvider → pop (NicknameChangeCooldownFailure / NicknameTakenFailure 처리)

### 3. BirthDateSettingPage (신규)
- ListWheelScrollView 스피너 3열(연/월/일), 기본값 2000.01.01
- 연도 범위: 1950 ~ 현재년도
- 저장 → updateBirthDateUseCaseProvider → pop

### 4. NotificationSettingsPage (신규, 기존 SettingsPage 대체)
- 상단 bell 아이콘
- 푸시 알림 카드(메인 토글) → setPushNotificationUseCaseProvider
- 알림 항목 카드: 댓글/좋아요, 멘션, 친구 일정 요청, 마케팅 → 로컬 상태(기본 ON)
- 저장 → 메인 토글만 백엔드 저장, pop

### 5. LogoutPage (신규)
- 상태 1(확인): 로그아웃 아이콘 + 메시지 + [취소|로그아웃] 버튼
- 상태 2(완료): 체크 아이콘 + "로그아웃 되었어요" + [확인] 버튼
- 완료 확인 버튼: signOutUseCaseProvider 호출 후 context.go(AppRoutes.login)

### 6. WithdrawPage (신규)
- Step 1: 경고 아이콘 + 삭제 항목 목록(4개) + [취소|다음]
- Step 2: 비밀번호 필드(UI전용) + 경고 문구 + [탈퇴하기] (red)
- 탈퇴하기: withdrawUseCaseProvider → GoRouter가 /login으로 리다이렉트

## 라우트 추가 (AppRoutes)
- `/profile/birth-date` → BirthDateSettingPage
- `/profile/notification` → NotificationSettingsPage
- `/profile/logout` → LogoutPage
- `/profile/withdraw` → WithdrawPage

## 컬러 규칙
- primary: Theme.of(context).colorScheme.primary (deepPurple seed)
- scaffold bg: Color(0xFFF5F0FF)
- danger: Colors.redAccent / Color(0xFFFF6B6B)
- 카드: Colors.white
