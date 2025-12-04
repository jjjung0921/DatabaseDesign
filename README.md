# PMIS Demo 빠른 실행 가이드

MySQL만 설치된 상태에서 데이터베이스를 만들고 `index.html` 데모를 띄워 API 동작을 확인하는 최소 절차를 정리한다.

## 1) 요구 사항
- MySQL 8.x (root 계정 로그인 가능)
- JDK 17 이상 (Spring Boot 실행용, 없으면 설치 필요)
- macOS/Linux 기준 쉘 명령 예시 사용

## 2) 데이터베이스 준비
### 2-1) 스크립트로 한 번에
프로젝트 루트에서 실행하면 계정/권한 생성 후 스키마를 로드한다.

```bash
cd /Users/leejungjin/Lecture/DatabaseDesign/Project
chmod +x init_db.sh
./init_db.sh           # root 비밀번호 입력
# 필요하면 환경변수로 사용자/비번/DB명을 변경한다:
# DB_USER=myuser DB_PASS=mypass DB_NAME=mydb ./init_db.sh
```

### 2-2) 직접 명령으로 처리
루트(`Project/pmis.sql`)의 스키마를 리다이렉션으로 불러온다.

```bash
# 1. 계정 생성 및 권한 부여
mysql -u root -p -e "\
  CREATE USER IF NOT EXISTS 'pmis'@'localhost' IDENTIFIED BY 'Pmis1234^^'; \
  GRANT ALL PRIVILEGES ON pmis_db.* TO 'pmis'@'localhost'; \
  FLUSH PRIVILEGES;"

# 2. 스키마 로드(루트에서 pmis.sql 실행)
cd /Users/leejungjin/Lecture/DatabaseDesign/Project
mysql -u root -p < pmis.sql
```

> 참고: 다른 디렉터리에서 실행할 경우 `pmis.sql`의 경로만 맞춰주면 된다. 파일 안에 `CREATE DATABASE pmis_db;`와 `USE pmis_db;`가 포함되어 있어 바로 로드하면 된다.

## 3) 백엔드(API) 실행
Spring Boot가 `pmis_db`에 접속해 REST API와 정적 페이지(`index.html`)를 제공한다.

```bash
cd /Users/leejungjin/Lecture/DatabaseDesign/Project/demo
./gradlew bootRun   # Windows는 gradlew.bat
```

- 서버 기본 포트: `8080`
- DB 접속 정보는 `src/main/resources/application.yaml`의 `pmis` 계정/비밀번호를 사용한다.

## 4) 데모 페이지 열기
백엔드를 켠 상태에서 브라우저에서 접속한다.

- http://localhost:8080/index.html
- 각 섹션의 버튼을 눌러 `/api/**` 엔드포인트를 호출하면 응답 JSON이 페이지 하단 콘솔에 표시된다.

## 5) 자주 묻는 문제
- **포트 충돌(8080 사용 중)**: `SERVER_PORT=8081 ./gradlew bootRun`처럼 환경변수로 포트를 바꿔 실행한 뒤 브라우저 주소도 포트에 맞춰 변경한다.
- **DB 연결 오류**: MySQL에서 `pmis_db`와 `pmis` 계정이 생성됐는지, 비밀번호(`Pmis1234^^`)가 맞는지 확인하고 `mysql -u pmis -p pmis_db`로 접속 테스트를 진행한다.
