#!/usr/bin/env bash
set -euo pipefail

DB_USER="${DB_USER:-pmis}"
DB_PASS="${DB_PASS:-Pmis1234^^}"
DB_NAME="${DB_NAME:-pmis_db}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PMIS_SQL="${PMIS_SQL:-${SCRIPT_DIR}/pmis.sql}"
DEMO_SQL="${DEMO_SQL:-${SCRIPT_DIR}/demo_setup.sql}"

for f in "$PMIS_SQL" "$DEMO_SQL"; do
  if [ ! -f "$f" ]; then
    echo "필요한 SQL 파일을 찾을 수 없습니다: $f" >&2
    exit 1
  fi
done

mysql -u root -p -e "\
  DROP DATABASE IF EXISTS \`${DB_NAME}\`; \
  CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`; \
  CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}'; \
  GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost'; \
  FLUSH PRIVILEGES;"

mysql -u root -p < "$PMIS_SQL"
mysql -u root -p "$DB_NAME" < "$DEMO_SQL"

echo "완료: ${PMIS_SQL} / ${DEMO_SQL}을 ${DB_NAME}에 로드하고 ${DB_USER} 계정에 권한을 부여했다."
