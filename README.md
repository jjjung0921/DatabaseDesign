# PMIS Demo 실행 안내

3자가 빠르게 DB를 준비하고 백엔드/데모를 돌릴 수 있도록 단계별로 정리했습니다.

## 요구 사항
- MySQL 8.x (root 로그인 가능)
- JDK 17 이상
- macOS/Linux 기준 쉘 예시

## 1) 데이터베이스 준비 (자동)
프로젝트 루트에서 스크립트 한 번이면 DB 생성→시드→권한 함수→데모 데이터까지 적용됩니다.
```bash
cd /Users/{UserName}/Lecture/DatabaseDesign/Project
chmod +x init_db.sh
./init_db.sh             # root 비밀번호 입력
# 사용자/비번/DB명 커스터마이즈
# DB_USER=myuser DB_PASS=mypass DB_NAME=mydb ./init_db.sh
```
- 적용 순서: `sql/schema_base.sql` → `sql/seed_core.sql` → `sql/functions_permissions.sql` → `demo_setup.sql`
- 기본 계정/DB: `pmis` / `Pmis1234^^` / `pmis_db`

## 2) 데이터베이스 준비 (수동)
직접 MySQL에 실행하려면 아래 순서로 진행합니다.
```bash
# 1) 계정/권한
mysql -u root -p -e "\
  CREATE USER IF NOT EXISTS 'pmis'@'localhost' IDENTIFIED BY 'Pmis1234^^'; \
  GRANT ALL PRIVILEGES ON pmis_db.* TO 'pmis'@'localhost'; \
  FLUSH PRIVILEGES;"

# 2) 스키마
mysql -u root -p < sql/schema_base.sql

# 3) 시드(역할/기본 권한 플래그) + 함수/트리거/프로시저 + 데모 데이터
mysql -u root -p pmis_db < sql/seed_core.sql
mysql -u root -p pmis_db < sql/functions_permissions.sql
mysql -u root -p pmis_db < demo_setup.sql
```

## 3) 백엔드(API) 실행
```bash
cd /Users/{UserName}/Lecture/DatabaseDesign/Project/demo
./gradlew bootRun   # Windows는 gradlew.bat
```
- 기본 포트: `8080`
- DB 접속: `src/main/resources/application.yaml`의 `pmis` 계정 사용

## 4) 데모 페이지 확인
- 브라우저에서 접속: http://localhost:8080/index.html
- 각 섹션 버튼으로 `/api/**` 호출 → 결과 JSON은 페이지 하단 콘솔에 표시

## 5) 문제 해결
- 포트 충돌: `SERVER_PORT=8081 ./gradlew bootRun` 후 브라우저 포트도 맞춰 변경
- DB 연결 오류: `mysql -u pmis -p pmis_db` 접속 확인, 비밀번호(`Pmis1234^^`) 점검