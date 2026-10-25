# 이동혁 1:1 채팅 웹앱

모바일 우선 React + Vite + Supabase 프로젝트입니다. 방문자 메시지는 텍스트만 가능하고, 관리자 답장은 방문자에게 이동혁의 왼쪽 말풍선으로 표시됩니다. 관리자 화면은 `/admin`입니다.

## 먼저 필요한 것

실제 운영 사이트로 만들려면 본인 Supabase 프로젝트와 웹 호스팅 계정이 필요합니다. 이 ZIP 자체는 아직 공개 URL에 배포된 사이트가 아니며, 프로젝트 설정을 대신 생성하거나 계정에 배포할 수는 없습니다.

## 설정

1. Supabase에서 프로젝트 생성
2. Authentication → Providers에서 **Anonymous Sign-Ins** 활성화
3. Authentication에서 관리자 계정을 이메일/비밀번호로 생성
4. SQL Editor에서 `supabase.sql` 전체 실행
5. 관리자 사용자에 대해 `app_metadata`의 `role` 값을 `admin`으로 설정하세요. 예: 서버 측 Admin API로 `app_metadata: { "role": "admin" }` 설정. 브라우저에서 사용자가 수정할 수 있는 `user_metadata`는 관리자 권한에 사용하지 않습니다.
6. `.env.example`을 `.env`로 복사하고 Supabase Project URL과 anon/publishable key 입력
7. 터미널에서 `npm install`, `npm run dev`
8. 배포하려면 Vercel/Netlify 등에 저장소를 연결하고 같은 환경변수를 설정

## 보안 메모

- 방문자는 Supabase 익명 인증 사용자 ID로 본인 방에만 접근합니다.
- 방 목록 조회, 호감도 수정, 이미지 업로드는 `app_metadata.role=admin`으로 확인되는 관리자에게만 RLS 정책으로 허용됩니다.
- 관리자 비밀번호나 `service_role` 키를 프런트엔드 코드에 넣지 마세요. 관리자 계정 역할 설정은 Supabase 서버 측 관리 기능으로만 하세요.
- 공개 이미지 버킷은 채팅에서 이미지 URL을 쉽게 표시하도록 설정되어 있습니다. 사진 URL을 비밀로 취급해야 하는 서비스라면 private bucket + signed URL 방식으로 변경하세요.
- 실제 서비스 공개 전 RLS 정책과 로그인 흐름을 테스트하세요. 관리자 메시지 발송 및 호감도 0 종료는 클라이언트 UI와 RLS로 제한하지만, 운영 수준의 강화가 필요하면 Edge Function에서 추가 검증을 권장합니다.
