#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! command -v docker >/dev/null; then echo 'Chạy bash scripts/01-install-docker.sh trước.' >&2;exit 1;fi
if docker info >/dev/null 2>&1; then docker_cmd=(docker);else docker_cmd=(sudo docker);fi
"${docker_cmd[@]}" compose version >/dev/null
if [[ ! -f .env ]]; then
  "${docker_cmd[@]}" run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work node:22.16.0-alpine node setup.js
fi
chmod 600 .env
"${docker_cmd[@]}" compose config --quiet
"${docker_cmd[@]}" compose up -d --build
"${docker_cmd[@]}" compose ps -a
ready=false
for ((attempt=0;attempt<60;attempt++)); do
  if curl --fail --silent http://127.0.0.1:8080/health >/dev/null; then ready=true;break;fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo 'Website chưa healthy. Log app/nginx:' >&2
  "${docker_cmd[@]}" compose logs --tail 60 app nginx
  exit 1
fi
echo 'Website: http://localhost:8080 (mở Firefox trên Ubuntu)'
echo 'pgAdmin: http://localhost:5050 | Grafana: http://localhost:3001'
echo 'Đọc .env để lấy mật khẩu; chạy bash scripts/03-check.sh để kiểm tra các dịch vụ.'
