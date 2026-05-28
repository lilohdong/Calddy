# Notification FCM 시스템 설계 스펙

> 작성일: 2026-05-28  
> 범위: Notification P1(친구 요청·약속 초대/수락/거절) + P2(좋아요·댓글) 트리거 + send-notification Edge Function  
> 브랜치: `feat/notification-send-fcm` → `feat/notification-triggers`

---

## 1. 목표

Calddy의 notifications 테이블은 이미 구현되어 있으나, 알림을 **생성하는** 서버 로직(DB 트리거 + FCM 발송)이 없다.  
이 스펙은 두 브랜치에 걸쳐 알림 생성·발송 파이프라인 전체를 완성한다.

---

## 2. 아키텍처

```
[DB 이벤트]
friend_requests INSERT
appointment_invites INSERT / UPDATE
post_likes INSERT
comments INSERT
      │
      ▼
[PL/pgSQL 트리거]
  ① notifications INSERT  (동기, 신뢰성 보장)
  ② net.http_post()       (비동기, best-effort)
      │
      ▼
[send-notification Edge Function]
  - fcm_token + push_enabled 조회
  - RS256 JWT → Google OAuth2 access token
  - FCM HTTP v1 API 호출
      │
      ▼
[Firebase FCM → 수신 기기 푸시]
```

**원칙:**
- `notifications` 행은 트리거가 동기 INSERT → FCM 실패와 무관하게 알림 기록 보존
- FCM 발송은 비동기(pg_net) — 실패 시 로그만 남기고 트랜잭션 롤백 없음
- `push_enabled = false` 또는 `fcm_token IS NULL`이면 Edge Function이 FCM skip

---

## 3. 브랜치 1 — `feat/notification-send-fcm`

### 3.1 파일

| 경로 | 설명 |
|------|------|
| `supabase/functions/send-notification/index.ts` | 신규 생성 |

### 3.2 인증

DB 트리거(pg_net) 전용 엔드포인트. `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>` 검증.  
외부에서 직접 호출 불가.

### 3.3 Request Body

```json
{
  "userId":    "uuid",
  "type":      "friend_request | appointment_invite | appointment_accepted | appointment_rejected | suggest_new_date | post_liked | post_commented",
  "title":     "string",
  "body":      "string",
  "relatedId": "uuid (optional)"
}
```

### 3.4 처리 흐름

```
1. Authorization 헤더 == SUPABASE_SERVICE_ROLE_KEY 검증
2. profiles WHERE id = userId → fcm_token, push_enabled 조회
3. push_enabled = false OR fcm_token IS NULL → 200 { skipped: true }
4. FIREBASE_SERVICE_ACCOUNT_JSON 파싱 → private_key, client_email 추출
5. RS256 JWT 서명 → POST https://oauth2.googleapis.com/token
   scope: "https://www.googleapis.com/auth/firebase.messaging"
6. FCM HTTP v1 POST
   URL: https://fcm.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/messages:send
   Body:
   {
     "message": {
       "token": fcm_token,
       "notification": { "title": title, "body": body },
       "data": {
         "type": type,
         "relatedId": relatedId ?? "",
         "title": title,
         "body": body
       }
     }
   }
7. 성공: 200 { success: true }
   실패: 로그 출력 후 500
```

### 3.5 환경변수 (Supabase Vault)

| 키 | 설명 |
|----|------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Service Account JSON 전체 (신규 등록 필요) |
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID (신규 등록 필요) |
| `SUPABASE_SERVICE_ROLE_KEY` | 자동 주입됨 |
| `SUPABASE_URL` | 자동 주입됨 |

### 3.6 Firebase Service Account 발급 절차

1. Firebase Console → 프로젝트 설정 → 서비스 계정
2. "새 비공개 키 생성" → JSON 다운로드
3. Supabase Dashboard → Project Settings → Edge Functions → Secrets
4. `FIREBASE_SERVICE_ACCOUNT_JSON` = JSON 내용 전체
5. `FIREBASE_PROJECT_ID` = Firebase 프로젝트 ID (예: `calddy-abc12`)

---

## 4. 브랜치 2 — `feat/notification-triggers`

### 4.1 파일

| 경로 | 설명 |
|------|------|
| `supabase/migrations/YYYYMMDDHHMMSS_notification_triggers.sql` | 신규 생성 |

### 4.2 사전 설정 (마이그레이션 전 1회)

```sql
-- Supabase 대시보드 SQL Editor 또는 별도 마이그레이션에서 실행
ALTER DATABASE postgres SET app.settings.supabase_url TO 'https://<project-ref>.supabase.co';
ALTER DATABASE postgres SET app.settings.service_role_key TO '<service-role-key>';
```

> ⚠️ service_role_key가 DB에 평문 저장됨. Vault를 이용한 보안 강화는 P3 개선 항목.

### 4.3 트리거 함수 5개 (알림 타입 7종)

| # | 테이블 | 이벤트 | notification_type | 수신자 | related_id | 비고 |
|---|--------|--------|------------------|--------|------------|------|
| 1 | `friend_requests` | INSERT | `friend_request` | `addressee_id` | `friend_request.id` | |
| 2 | `appointment_invites` | INSERT | `appointment_invite` | `invitee_id` | `appointment_id` | |
| 3 | `appointment_invites` | UPDATE (→ accepted) | `appointment_accepted` | `appointments.creator_id` | `appointment_id` | |
| 4 | `appointment_invites` | UPDATE (→ rejected) | `appointment_rejected` | `appointments.creator_id` | `appointment_id` | 하나의 트리거에서 4·5 동시 INSERT |
| 5 | `appointment_invites` | UPDATE (→ rejected) | `suggest_new_date` | `appointments.creator_id` | `appointment_id` | 하나의 트리거에서 4·5 동시 INSERT |
| 6 | `post_likes` | INSERT | `post_liked` | `posts.user_id` | `post_id` | 본인 게시글 본인 좋아요 시 skip |
| 7 | `comments` | INSERT | `post_commented` | `posts.user_id` | `post_id` | 본인 게시글 본인 댓글 시 skip |

**트리거 함수:** `notify_on_friend_request`, `notify_on_appointment_invite`, `notify_on_appointment_status_change`, `notify_on_post_like`, `notify_on_comment`

**자기 자신 알림 제외:** `post_likes.user_id = posts.user_id` 또는 `comments.user_id = posts.user_id`인 경우 INSERT 및 pg_net 호출 생략.

### 4.4 공통 헬퍼 함수

```sql
-- 알림 INSERT + FCM pg_net 호출을 캡슐화
CREATE OR REPLACE FUNCTION private.send_push_notification(
  p_user_id   uuid,
  p_type      notification_type,
  p_title     text,
  p_body      text,
  p_related_id uuid DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, private, net
AS $$
BEGIN
  -- 1. notifications INSERT
  INSERT INTO public.notifications (user_id, type, title, body, related_id)
  VALUES (p_user_id, p_type, p_title, p_body, p_related_id);

  -- 2. FCM 비동기 호출
  PERFORM net.http_post(
    url     := current_setting('app.settings.supabase_url')
               || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer '
                       || current_setting('app.settings.service_role_key')
    ),
    body    := jsonb_build_object(
      'userId',    p_user_id,
      'type',      p_type::text,
      'title',     p_title,
      'body',      p_body,
      'relatedId', p_related_id
    )::text
  );
END;
$$;
```

### 4.5 트리거 알림 메시지 명세

| notification_type | title | body |
|------------------|-------|------|
| `friend_request` | `"친구 요청이 왔어요"` | `"{nickname}님이 친구 요청을 보냈습니다."` |
| `appointment_invite` | `"약속 초대가 왔어요"` | `"{nickname}님이 약속에 초대했습니다."` |
| `appointment_accepted` | `"약속이 수락됐어요"` | `"{nickname}님이 약속을 수락했습니다."` |
| `appointment_rejected` | `"약속이 거절됐어요"` | `"{nickname}님이 약속을 거절했습니다."` |
| `suggest_new_date` | `"다른 날짜를 제안해보세요"` | `"{nickname}님이 다른 시간을 원합니다."` |
| `post_liked` | `"좋아요를 받았어요"` | `"{nickname}님이 회원님의 게시글을 좋아합니다."` |
| `post_commented` | `"댓글이 달렸어요"` | `"{nickname}님이 댓글을 남겼습니다."` |

> nickname은 트리거 내에서 `SELECT nickname FROM profiles WHERE id = actor_id`로 조회.

---

## 5. 종속성 및 작업 순서

```
feat/notification-send-fcm 머지
        │
        ▼
Firebase Service Account Vault 등록
app.settings.supabase_url / service_role_key DB 설정
        │
        ▼
feat/notification-triggers 머지
```

---

## 6. 테스트 계획

### Branch 1 테스트
- `supabase functions serve` 로컬 실행
- `curl POST /send-notification` with valid/invalid JWT 케이스
- `push_enabled = false` 케이스 → skip 확인
- FCM 토큰 없는 케이스 → skip 확인

### Branch 2 테스트
- `friend_requests` INSERT 후 notifications 행 생성 확인
- `appointment_invites` status 변경 후 notifications 행 생성 확인
- `post_likes` INSERT 후 notifications 행 생성 확인
- pg_net HTTP 호출 로그 확인 (`net.http_request_queue` 테이블)

---

## 7. 제외 범위 (이후 작업)

- Flutter Realtime subscription (알림 실시간 수신 UI)
- `app.settings.service_role_key` → Vault 마이그레이션 (보안 강화)
- 카카오톡 / Apple 소셜 로그인 (P3)
- 탈퇴 익명화 스프레드시트 상태 업데이트
