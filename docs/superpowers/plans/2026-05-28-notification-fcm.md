# Notification FCM 시스템 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DB 이벤트(친구 요청·약속 초대/수락/거절·좋아요·댓글)에서 FCM 푸시 알림을 발송하는 서버 파이프라인을 완성한다.

**Architecture:** DB 트리거가 `notifications` 테이블에 동기 INSERT 후 `pg_net`으로 `send-notification` Edge Function을 비동기 호출. Edge Function이 Deno SubtleCrypto로 RS256 JWT를 서명해 Google OAuth2 토큰을 발급하고 Firebase FCM HTTP v1 API로 푸시를 발송한다.

**Tech Stack:** Supabase Edge Functions (Deno 2), PL/pgSQL, pg_net, Firebase FCM HTTP v1 API, Deno SubtleCrypto

---

## 파일 구조

```
supabase/
  functions/
    send-notification/
      index.ts          ← [신규] Branch 1: FCM 발송 Edge Function
  functions/.env        ← [수정] Branch 1: 로컬 테스트용 Firebase 키 추가
  migrations/
    20260528000001_notification_triggers.sql  ← [신규] Branch 2: 트리거 마이그레이션
```

---

## ── BRANCH 1: feat/notification-send-fcm ──────────────────

---

### Task 1: Firebase Service Account 발급 및 Supabase Vault 등록 (수동)

**Files:** 없음 (대시보드 작업)

- [ ] **Step 1: Firebase Service Account JSON 발급**

  1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 선택
  2. 톱니바퀴 → **프로젝트 설정** → **서비스 계정** 탭
  3. **"새 비공개 키 생성"** 클릭 → JSON 파일 다운로드
  4. JSON 내용 메모장에 열어두기 (다음 Step에서 사용)

- [ ] **Step 2: Firebase 프로젝트 ID 확인**

  Firebase Console → 프로젝트 설정 → 일반 탭 → **프로젝트 ID** 확인 (예: `calddy-a1b2c`)

- [ ] **Step 3: Supabase Vault에 시크릿 등록**

  [Supabase Dashboard](https://supabase.com/dashboard) → 프로젝트 선택 → **Project Settings → Edge Functions → Secrets**

  | 이름 | 값 |
  |------|----|
  | `FIREBASE_SERVICE_ACCOUNT_JSON` | 다운받은 JSON 파일 내용 전체 (한 줄로) |
  | `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID (예: `calddy-a1b2c`) |

- [ ] **Step 4: 로컬 .env에도 추가 (로컬 테스트용)**

  `supabase/functions/.env` 파일에 아래 두 줄 추가:
  ```
  FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...전체JSON..."}
  FIREBASE_PROJECT_ID=calddy-a1b2c
  ```
  > ⚠️ 이 파일은 `.gitignore`에 포함되어 있어 커밋되지 않음. 안전.

---

### Task 2: feat/notification-send-fcm 브랜치 생성

**Files:** 없음

- [ ] **Step 1: 브랜치 생성 후 이동**

  ```bash
  git checkout main
  git pull origin main
  git checkout -b feat/notification-send-fcm
  ```

  Expected: `Switched to a new branch 'feat/notification-send-fcm'`

---

### Task 3: send-notification Edge Function 작성

**Files:**
- Create: `supabase/functions/send-notification/index.ts`

- [ ] **Step 1: 디렉토리 생성 확인**

  ```bash
  ls supabase/functions/
  ```

  Expected: `_shared/`, `calculate-midpoint/`, `delete-account/`, `delete-post/`, `recommend-place/`, `search-places/` 등 기존 함수 디렉토리 존재 확인

- [ ] **Step 2: index.ts 작성**

  `supabase/functions/send-notification/index.ts` 생성:

  ```typescript
  // send-notification Edge Function
  //
  // DB 트리거(pg_net) 전용 엔드포인트 — Firebase FCM 푸시 발송
  // Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY> 검증
  //
  // Request : POST { userId, type, title, body, relatedId? }
  // Response: { success: true } | { skipped: true } | { error: string }

  import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
  import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';

  interface RequestBody {
    userId: string;
    type: string;
    title: string;
    body: string;
    relatedId?: string;
  }

  // Google Service Account → OAuth2 access token (RS256 JWT)
  async function getGoogleAccessToken(serviceAccountJson: string): Promise<string> {
    const sa = JSON.parse(serviceAccountJson) as {
      client_email: string;
      private_key: string;
    };

    const b64url = (obj: unknown) =>
      btoa(JSON.stringify(obj))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');

    const now = Math.floor(Date.now() / 1000);
    const signingInput = `${b64url({ alg: 'RS256', typ: 'JWT' })}.${b64url({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    })}`;

    const pemBody = sa.private_key
      .replace(/-----[^-]+-----/g, '')
      .replace(/\s/g, '');
    const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      keyBytes,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign'],
    );

    const sigBytes = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      new TextEncoder().encode(signingInput),
    );
    const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: `${signingInput}.${sig}`,
      }),
    });

    if (!tokenRes.ok) {
      throw new Error(`OAuth2 token exchange failed: ${await tokenRes.text()}`);
    }
    const data = await tokenRes.json() as { access_token: string };
    return data.access_token;
  }

  Deno.serve(async (req: Request) => {
    const corsResult = handleCors(req);
    if (corsResult) return corsResult;

    // 1. SERVICE_ROLE_KEY 검증 — DB 트리거 전용
    const authHeader = req.headers.get('Authorization') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    if (authHeader !== `Bearer ${serviceRoleKey}`) {
      return errorResponse('Forbidden', 403);
    }

    // 2. Body 파싱
    let body: RequestBody;
    try {
      body = await req.json() as RequestBody;
    } catch {
      return errorResponse('Invalid JSON body');
    }

    const { userId, type, title, body: msgBody, relatedId } = body;
    if (!userId || !type || !title || !msgBody) {
      return errorResponse('Missing required fields: userId, type, title, body');
    }

    // 3. profiles에서 fcm_token + push_enabled 조회
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('fcm_token, push_enabled')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      console.error('[send-notification] profile fetch failed:', profileError?.message);
      return errorResponse('Profile not found', 404);
    }

    // 4. push_enabled=false 또는 fcm_token 없으면 skip
    if (!profile.push_enabled || !profile.fcm_token) {
      return jsonResponse({ skipped: true });
    }

    // 5. Firebase OAuth2 access token 생성
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
    if (!serviceAccountJson || !projectId) {
      console.error('[send-notification] FIREBASE_* env vars not set');
      return errorResponse('Firebase not configured', 500);
    }

    let accessToken: string;
    try {
      accessToken = await getGoogleAccessToken(serviceAccountJson);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error('[send-notification] JWT signing failed:', msg);
      return errorResponse(`FCM auth failed: ${msg}`, 500);
    }

    // 6. FCM HTTP v1 발송
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmRes = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: profile.fcm_token,
          notification: { title, body: msgBody },
          data: {
            type,
            relatedId: relatedId ?? '',
            title,
            body: msgBody,
          },
        },
      }),
    });

    if (!fcmRes.ok) {
      const errText = await fcmRes.text();
      console.error('[send-notification] FCM error:', fcmRes.status, errText);
      return errorResponse(`FCM send failed: ${errText}`, 500);
    }

    return jsonResponse({ success: true });
  });
  ```

---

### Task 4: 로컬에서 Edge Function 테스트

**Files:** 없음 (실행 테스트)

- [ ] **Step 1: Supabase 로컬 스택 기동**

  ```bash
  supabase start
  ```

  Expected: 각 서비스 URL 출력 (API, Studio 등)
  > ⚠️ Docker Desktop이 실행 중이어야 함

- [ ] **Step 2: Edge Function 로컬 서빙**

  새 터미널에서:
  ```bash
  supabase functions serve send-notification --env-file supabase/functions/.env
  ```

  Expected: `Serving functions on http://127.0.0.1:54321/functions/v1/`

- [ ] **Step 3: 인증 실패 케이스 테스트**

  ```bash
  curl -s -X POST http://127.0.0.1:54321/functions/v1/send-notification \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer wrong-key" \
    -d '{"userId":"test","type":"friend_request","title":"테스트","body":"내용"}'
  ```

  Expected:
  ```json
  {"error":"Forbidden"}
  ```

- [ ] **Step 4: 필수 필드 누락 케이스 테스트**

  로컬 Supabase service_role_key 확인:
  ```bash
  supabase status | grep service_role
  ```

  ```bash
  SERVICE_ROLE_KEY="<위에서 확인한 값>"
  
  curl -s -X POST http://127.0.0.1:54321/functions/v1/send-notification \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -d '{"userId":"test","type":"friend_request"}'
  ```

  Expected:
  ```json
  {"error":"Missing required fields: userId, type, title, body"}
  ```

- [ ] **Step 5: push_enabled=false skip 케이스 테스트**

  로컬 DB에 테스트 유저 생성 후 `push_enabled=false`로 설정:
  ```bash
  # Supabase Studio (http://127.0.0.1:54323) → Table Editor → profiles
  # 테스트 유저 INSERT: id='00000000-0000-0000-0000-000000000001', push_enabled=false
  
  curl -s -X POST http://127.0.0.1:54321/functions/v1/send-notification \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -d '{
      "userId": "00000000-0000-0000-0000-000000000001",
      "type": "friend_request",
      "title": "친구 요청이 왔어요",
      "body": "테스트님이 친구 요청을 보냈습니다."
    }'
  ```

  Expected:
  ```json
  {"skipped":true}
  ```

- [ ] **Step 6: 실제 FCM 전송 테스트 (Firebase 키 설정 후)**

  실제 기기의 FCM 토큰을 profiles 테이블에 설정하고:
  ```bash
  curl -s -X POST http://127.0.0.1:54321/functions/v1/send-notification \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -d '{
      "userId": "<실제-유저-uuid>",
      "type": "friend_request",
      "title": "친구 요청이 왔어요",
      "body": "테스트님이 친구 요청을 보냈습니다.",
      "relatedId": "00000000-0000-0000-0000-000000000001"
    }'
  ```

  Expected:
  ```json
  {"success":true}
  ```
  기기에 푸시 알림 도착 확인.

---

### Task 5: commit + push + PR

**Files:** `supabase/functions/send-notification/index.ts`

- [ ] **Step 1: 파일 스테이징**

  ```bash
  git add supabase/functions/send-notification/index.ts
  git status
  ```

  Expected: `new file: supabase/functions/send-notification/index.ts`
  > ⚠️ `supabase/functions/.env`는 절대 스테이징하지 말 것 (gitignore 대상)

- [ ] **Step 2: 커밋**

  ```bash
  git commit -m "feat: send-notification Edge Function — FCM HTTP v1 + RS256 JWT"
  ```

- [ ] **Step 3: 푸시 + PR 생성**

  ```bash
  git push -u origin feat/notification-send-fcm
  
  gh pr create \
    --title "feat: send-notification Edge Function (FCM HTTP v1)" \
    --body "$(cat <<'EOF'
  ## Summary
  - DB 트리거 전용 FCM 발송 Edge Function 추가
  - Deno SubtleCrypto로 RS256 JWT 서명 → Google OAuth2 access token 발급
  - FCM HTTP v1 API로 notification + data payload 동시 발송
  - push_enabled=false 또는 fcm_token 없으면 200 skip
  
  ## 사전 설정 필요
  - Supabase Vault: FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_PROJECT_ID 등록
  
  ## Test plan
  - [ ] Authorization 실패 → 403
  - [ ] 필드 누락 → 400
  - [ ] push_enabled=false → { skipped: true }
  - [ ] fcm_token=null → { skipped: true }
  - [ ] 정상 케이스 → { success: true } + 기기 푸시 수신
  
  🤖 Generated with [Claude Code](https://claude.ai/claude-code)
  EOF
  )"
  ```

---

## ── BRANCH 2: feat/notification-triggers ──────────────────

> ⚠️ **선행 조건:** `feat/notification-send-fcm`이 main에 머지된 후 진행할 것

---

### Task 6: app.settings DB 파라미터 설정 (수동, 1회)

**Files:** 없음 (Supabase 대시보드 SQL Editor)

이 설정은 pg_net 트리거가 Edge Function URL과 인증 키를 알 수 있게 한다.

- [ ] **Step 1: Supabase 대시보드 → SQL Editor에서 실행**

  아래 SQL을 Supabase Dashboard → SQL Editor에서 직접 실행 (프로덕션 DB):

  ```sql
  -- Supabase 프로젝트 URL (대시보드 Settings → API에서 확인)
  ALTER DATABASE postgres
    SET app.settings.supabase_url TO 'https://<project-ref>.supabase.co';

  -- service_role key (대시보드 Settings → API에서 확인)
  ALTER DATABASE postgres
    SET app.settings.service_role_key TO '<service-role-key>';
  ```

  > ⚠️ `<project-ref>`와 `<service-role-key>`를 실제 값으로 대체할 것  
  > Supabase Dashboard → Project Settings → API → Project URL / service_role key

- [ ] **Step 2: 로컬 DB에도 동일하게 설정**

  ```bash
  supabase start  # 로컬 스택 기동
  ```

  ```bash
  # 로컬 DB에 접속
  psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
  ```

  ```sql
  ALTER DATABASE postgres
    SET app.settings.supabase_url TO 'http://127.0.0.1:54321';
  ALTER DATABASE postgres
    SET app.settings.service_role_key TO '<로컬-service-role-key>';
  -- 로컬 키: supabase status 명령에서 service_role key 확인
  \q
  ```

---

### Task 7: feat/notification-triggers 브랜치로 이동

**Files:** 없음

- [ ] **Step 1: 브랜치 이동 (이미 존재함)**

  ```bash
  git checkout feat/notification-triggers
  git rebase main   # send-fcm 브랜치 머지 후 최신 main 반영
  ```

  Expected: `Successfully rebased and updated refs/heads/feat/notification-triggers`

---

### Task 8: 마이그레이션 SQL 작성

**Files:**
- Create: `supabase/migrations/20260528000001_notification_triggers.sql`

- [ ] **Step 1: 파일 생성**

  `supabase/migrations/20260528000001_notification_triggers.sql`:

  ```sql
  -- ============================================================
  -- Notification 트리거 마이그레이션
  --
  -- 사전 요건:
  --   pg_net 활성화 (Supabase 기본 포함)
  --   app.settings.supabase_url, app.settings.service_role_key 설정
  --   (Task 6에서 수동 설정)
  -- ============================================================

  -- pg_net 확장 활성화 (이미 있으면 무시, Supabase는 기본 포함)
  create extension if not exists pg_net;

  -- private 스키마 (헬퍼 함수 격리용)
  create schema if not exists private;


  -- ── 공통 헬퍼: notifications INSERT + FCM pg_net 호출 ────────

  create or replace function private.send_push_notification(
    p_user_id    uuid,
    p_type       public.notification_type,
    p_title      text,
    p_body       text,
    p_related_id uuid default null
  )
  returns void
  language plpgsql
  security definer
  set search_path = public, net
  as $$
  begin
    -- 1. notifications 테이블에 동기 INSERT
    insert into public.notifications (user_id, type, title, body, related_id)
    values (p_user_id, p_type, p_title, p_body, p_related_id);

    -- 2. FCM Edge Function 비동기 호출 (best-effort)
    perform net.http_post(
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
      )
    );
  exception when others then
    -- FCM 호출 실패해도 트랜잭션 롤백 방지 (알림 기록은 보존됨)
    raise warning '[send_push_notification] pg_net call failed: %', sqlerrm;
  end;
  $$;


  -- ── 트리거 1: 친구 요청 ──────────────────────────────────────

  create or replace function public.notify_on_friend_request()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, private
  as $$
  declare
    v_nickname text;
  begin
    select nickname into v_nickname
    from public.profiles
    where id = new.requester_id;

    perform private.send_push_notification(
      p_user_id    := new.addressee_id,
      p_type       := 'friend_request'::public.notification_type,
      p_title      := '친구 요청이 왔어요',
      p_body       := coalesce(v_nickname, '누군가') || '님이 친구 요청을 보냈습니다.',
      p_related_id := new.id
    );
    return new;
  end;
  $$;

  create trigger trg_notify_friend_request
    after insert on public.friend_requests
    for each row
    execute function public.notify_on_friend_request();


  -- ── 트리거 2: 약속 초대 요청 ─────────────────────────────────

  create or replace function public.notify_on_appointment_invite()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, private
  as $$
  declare
    v_creator_nickname text;
    v_creator_id       uuid;
  begin
    select a.creator_id, p.nickname
    into   v_creator_id, v_creator_nickname
    from   public.appointments a
    join   public.profiles     p on p.id = a.creator_id
    where  a.id = new.appointment_id;

    perform private.send_push_notification(
      p_user_id    := new.invitee_id,
      p_type       := 'appointment_invite'::public.notification_type,
      p_title      := '약속 초대가 왔어요',
      p_body       := coalesce(v_creator_nickname, '누군가') || '님이 약속에 초대했습니다.',
      p_related_id := new.appointment_id
    );
    return new;
  end;
  $$;

  create trigger trg_notify_appointment_invite
    after insert on public.appointment_invites
    for each row
    execute function public.notify_on_appointment_invite();


  -- ── 트리거 3: 약속 수락 / 거절 알림 ─────────────────────────

  create or replace function public.notify_on_appointment_status_change()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, private
  as $$
  declare
    v_creator_id       uuid;
    v_invitee_nickname text;
  begin
    -- 상태 변경이 없으면 무시
    if new.status = old.status then
      return new;
    end if;

    select a.creator_id, p.nickname
    into   v_creator_id, v_invitee_nickname
    from   public.appointments a
    join   public.profiles     p on p.id = new.invitee_id
    where  a.id = new.appointment_id;

    if new.status = 'accepted' then
      perform private.send_push_notification(
        p_user_id    := v_creator_id,
        p_type       := 'appointment_accepted'::public.notification_type,
        p_title      := '약속이 수락됐어요',
        p_body       := coalesce(v_invitee_nickname, '누군가') || '님이 약속을 수락했습니다.',
        p_related_id := new.appointment_id
      );

    elsif new.status = 'rejected' then
      -- 거절 알림
      perform private.send_push_notification(
        p_user_id    := v_creator_id,
        p_type       := 'appointment_rejected'::public.notification_type,
        p_title      := '약속이 거절됐어요',
        p_body       := coalesce(v_invitee_nickname, '누군가') || '님이 약속을 거절했습니다.',
        p_related_id := new.appointment_id
      );
      -- 다른 날짜 제안 알림
      perform private.send_push_notification(
        p_user_id    := v_creator_id,
        p_type       := 'suggest_new_date'::public.notification_type,
        p_title      := '다른 날짜를 제안해보세요',
        p_body       := coalesce(v_invitee_nickname, '누군가') || '님이 다른 시간을 원합니다.',
        p_related_id := new.appointment_id
      );
    end if;

    return new;
  end;
  $$;

  create trigger trg_notify_appointment_status
    after update of status on public.appointment_invites
    for each row
    execute function public.notify_on_appointment_status_change();


  -- ── 트리거 4: 게시글 좋아요 알림 ────────────────────────────

  create or replace function public.notify_on_post_like()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, private
  as $$
  declare
    v_post_owner_id uuid;
    v_liker_nickname text;
  begin
    select p.user_id into v_post_owner_id
    from public.posts p
    where p.id = new.post_id;

    -- 본인 게시글 본인 좋아요 → skip
    if v_post_owner_id = new.user_id then
      return new;
    end if;

    select nickname into v_liker_nickname
    from public.profiles
    where id = new.user_id;

    perform private.send_push_notification(
      p_user_id    := v_post_owner_id,
      p_type       := 'post_liked'::public.notification_type,
      p_title      := '좋아요를 받았어요',
      p_body       := coalesce(v_liker_nickname, '누군가') || '님이 회원님의 게시글을 좋아합니다.',
      p_related_id := new.post_id
    );
    return new;
  end;
  $$;

  create trigger trg_notify_post_like
    after insert on public.post_likes
    for each row
    execute function public.notify_on_post_like();


  -- ── 트리거 5: 댓글 알림 ──────────────────────────────────────

  create or replace function public.notify_on_comment()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, private
  as $$
  declare
    v_post_owner_id    uuid;
    v_commenter_nickname text;
  begin
    select p.user_id into v_post_owner_id
    from public.posts p
    where p.id = new.post_id;

    -- 본인 게시글 본인 댓글 → skip
    if v_post_owner_id = new.user_id then
      return new;
    end if;

    select nickname into v_commenter_nickname
    from public.profiles
    where id = new.user_id;

    perform private.send_push_notification(
      p_user_id    := v_post_owner_id,
      p_type       := 'post_commented'::public.notification_type,
      p_title      := '댓글이 달렸어요',
      p_body       := coalesce(v_commenter_nickname, '누군가') || '님이 댓글을 남겼습니다.',
      p_related_id := new.post_id
    );
    return new;
  end;
  $$;

  create trigger trg_notify_comment
    after insert on public.comments
    for each row
    execute function public.notify_on_comment();


  -- ── 권한: private.send_push_notification → postgres 실행 가능 ─

  grant usage on schema private to postgres;
  grant execute on function private.send_push_notification(
    uuid, public.notification_type, text, text, uuid
  ) to postgres;
  ```

---

### Task 9: 로컬 DB에서 트리거 테스트

**Files:** 없음 (SQL 실행)

- [ ] **Step 1: 로컬 마이그레이션 적용**

  ```bash
  supabase db reset
  ```

  Expected: 마이그레이션 파일 순서대로 적용 완료

  > `supabase db reset`은 모든 마이그레이션을 처음부터 다시 실행함.

- [ ] **Step 2: psql 접속**

  ```bash
  psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
  ```

- [ ] **Step 3: 테스트용 프로필 2개 삽입**

  ```sql
  -- auth.users는 Supabase 내부 테이블이므로 profiles만 직접 INSERT
  INSERT INTO public.profiles (id, nickname, push_enabled)
  VALUES
    ('aaaaaaaa-0000-0000-0000-000000000001', '동준', true),
    ('bbbbbbbb-0000-0000-0000-000000000002', '정주', true);
  ```

- [ ] **Step 4: friend_requests INSERT 트리거 테스트**

  ```sql
  INSERT INTO public.friend_requests (requester_id, addressee_id, status)
  VALUES (
    'aaaaaaaa-0000-0000-0000-000000000001',
    'bbbbbbbb-0000-0000-0000-000000000002',
    'pending'
  );

  -- notifications 행 생성 확인
  SELECT type, title, body, user_id
  FROM public.notifications
  WHERE user_id = 'bbbbbbbb-0000-0000-0000-000000000002';
  ```

  Expected:
  ```
   type           | title              | body                           | user_id
  ----------------+--------------------+--------------------------------+---------
   friend_request | 친구 요청이 왔어요 | 동준님이 친구 요청을 보냈습니다. | bbbb...
  ```

- [ ] **Step 5: appointment_invites 트리거 테스트**

  ```sql
  -- 먼저 이벤트 + 약속 생성
  INSERT INTO public.events (id, user_id, title, start_at, end_at, color, status, visibility)
  VALUES (
    'cccccccc-0000-0000-0000-000000000003',
    'aaaaaaaa-0000-0000-0000-000000000001',
    '테스트 약속', now(), now() + interval '1 hour', '#FF5733', 'pending', 'private'
  );

  INSERT INTO public.appointments (id, event_id, creator_id)
  VALUES (
    'dddddddd-0000-0000-0000-000000000004',
    'cccccccc-0000-0000-0000-000000000003',
    'aaaaaaaa-0000-0000-0000-000000000001'
  );

  -- 초대 INSERT → appointment_invite 알림
  INSERT INTO public.appointment_invites (appointment_id, invitee_id, status)
  VALUES (
    'dddddddd-0000-0000-0000-000000000004',
    'bbbbbbbb-0000-0000-0000-000000000002',
    'pending'
  );

  SELECT type, title, user_id FROM public.notifications
  WHERE type = 'appointment_invite';
  ```

  Expected: `appointment_invite` 타입 알림 1개 (invitee에게)

- [ ] **Step 6: 수락 → appointment_accepted 알림 테스트**

  ```sql
  UPDATE public.appointment_invites
  SET status = 'accepted'
  WHERE appointment_id = 'dddddddd-0000-0000-0000-000000000004'
    AND invitee_id     = 'bbbbbbbb-0000-0000-0000-000000000002';

  SELECT type, title, user_id FROM public.notifications
  WHERE type = 'appointment_accepted';
  ```

  Expected: `appointment_accepted` 타입 알림 1개 (creator에게)

- [ ] **Step 7: 게시글 + 좋아요 트리거 테스트**

  ```sql
  INSERT INTO public.posts (id, user_id, visibility, feed_date)
  VALUES (
    'eeeeeeee-0000-0000-0000-000000000005',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'public', current_date
  );

  -- 다른 사람이 좋아요
  INSERT INTO public.post_likes (post_id, user_id)
  VALUES (
    'eeeeeeee-0000-0000-0000-000000000005',
    'bbbbbbbb-0000-0000-0000-000000000002'
  );

  SELECT type, title, user_id FROM public.notifications
  WHERE type = 'post_liked';
  ```

  Expected: `post_liked` 타입 알림 1개 (post owner에게)

- [ ] **Step 8: 본인 좋아요 skip 테스트**

  ```sql
  -- 본인이 자기 글에 좋아요 (skip되어야 함)
  -- post_likes 테이블 비우고 재테스트
  DELETE FROM public.post_likes;
  DELETE FROM public.notifications WHERE type = 'post_liked';

  INSERT INTO public.post_likes (post_id, user_id)
  VALUES (
    'eeeeeeee-0000-0000-0000-000000000005',
    'aaaaaaaa-0000-0000-0000-000000000001'  -- post owner 본인
  );

  SELECT count(*) FROM public.notifications WHERE type = 'post_liked';
  ```

  Expected: `count = 0` (알림 생성 안됨)

- [ ] **Step 9: pg_net 호출 큐 확인**

  ```sql
  SELECT id, url, status_code, error_msg
  FROM net.http_request_queue
  ORDER BY created desc
  LIMIT 5;
  ```

  Expected: `send-notification` URL로의 HTTP 요청 기록 확인
  > `status_code`는 Edge Function 서빙 중일 때만 채워짐. 로컬에서는 `null`일 수 있음.

- [ ] **Step 10: psql 종료**

  ```sql
  \q
  ```

---

### Task 10: commit + push + PR

**Files:** `supabase/migrations/20260528000001_notification_triggers.sql`

- [ ] **Step 1: 파일 스테이징**

  ```bash
  git add supabase/migrations/20260528000001_notification_triggers.sql
  git status
  ```

  Expected: `new file: supabase/migrations/20260528000001_notification_triggers.sql`

- [ ] **Step 2: 커밋**

  ```bash
  git commit -m "feat: notification DB 트리거 — 친구요청/약속초대/수락/거절/좋아요/댓글 (P1+P2)"
  ```

- [ ] **Step 3: 푸시 + PR 생성**

  ```bash
  git push -u origin feat/notification-triggers

  gh pr create \
    --title "feat: notification DB 트리거 — 알림 타입 7종" \
    --body "$(cat <<'EOF'
  ## Summary
  - pg_net 기반 알림 트리거 5개 (알림 타입 7종) 추가
  - 공통 헬퍼 private.send_push_notification() — notifications INSERT + FCM pg_net 호출
  - 자기 자신 알림 skip (본인 좋아요/댓글)
  - appointment_invites rejected 시 2개 알림 동시 생성 (rejected + suggest_new_date)

  ## 사전 조건
  - feat/notification-send-fcm 머지 완료
  - app.settings.supabase_url / service_role_key DB 파라미터 설정 완료

  ## Test plan
  - [ ] friend_requests INSERT → notifications.type = friend_request
  - [ ] appointment_invites INSERT → notifications.type = appointment_invite
  - [ ] appointment_invites status=accepted → appointment_accepted (creator)
  - [ ] appointment_invites status=rejected → appointment_rejected + suggest_new_date (creator)
  - [ ] post_likes INSERT (타인) → post_liked
  - [ ] post_likes INSERT (본인) → 알림 없음
  - [ ] comments INSERT (타인) → post_commented
  - [ ] comments INSERT (본인) → 알림 없음

  🤖 Generated with [Claude Code](https://claude.ai/claude-code)
  EOF
  )"
  ```

---

## 완료 기준 체크리스트

- [ ] `send-notification` Edge Function — Forbidden/skip/success 케이스 모두 정상 응답
- [ ] Supabase Vault에 `FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_PROJECT_ID` 등록
- [ ] `app.settings.supabase_url`, `app.settings.service_role_key` DB 파라미터 설정
- [ ] 트리거 7종 — 로컬 SQL 테스트 전부 통과
- [ ] 본인 좋아요/댓글 skip 검증
- [ ] 두 PR 모두 머지 완료
