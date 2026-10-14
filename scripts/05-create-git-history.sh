#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if [[ -d .git ]];then echo 'Đã có Git repository. Giữ lịch sử hiện có, không tự tạo lại commit.' >&2;exit 1;fi
git var GIT_AUTHOR_IDENT >/dev/null || { echo 'Cấu hình git user.name và user.email trước.' >&2;exit 1; }
compose_saved="$(mktemp)"
cp compose.yaml "$compose_saved"
trap 'cp "$compose_saved" compose.yaml; rm -f "$compose_saved"' EXIT
git init
git branch -M main
cp stages/commit1.yaml compose.yaml
git add .gitignore .env.example README.md README_UBUNTU.md BAT_DAU.txt KIEM_THU.md MINH_CHUNG.md scripts stages setup.js compose.yaml frontend backend/app backend/package.json backend/package-lock.json backend/Dockerfile backend/.dockerignore backend/.gitignore backend/README.md backend/API.md backend/tests backend/infra/db-init.sh
git commit -m 'commit 1: deploy Node library PostgreSQL pgAdmin and secure Nginx'
cp stages/commit2.yaml compose.yaml
git add compose.yaml backend/infra/prometheus.yml backend/infra/grafana
git commit -m 'commit 2: monitor containers Nginx PostgreSQL with Prometheus Grafana'
cp "$compose_saved" compose.yaml
git add compose.yaml backend/infra/loki.yml backend/infra/promtail.yml backend/infra/promtail.Dockerfile
git commit -m 'commit 3: integrate Loki Promtail and LogQL'
git status --short
git log --oneline -3
echo 'Đã tạo 3 commit local. Đọc README_UBUNTU.md để thêm remote và push GitHub.'
