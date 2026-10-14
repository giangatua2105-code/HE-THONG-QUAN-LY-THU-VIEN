#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if docker info >/dev/null 2>&1;then docker_cmd=(docker);else docker_cmd=(sudo docker);fi
umask 077
mkdir -p backups
backup_path="backups/library-$(date +%Y%m%d-%H%M%S).sql"
"${docker_cmd[@]}" compose exec -T postgres pg_dump -U postgres -d library > "$backup_path"
echo "Đã sao lưu: $backup_path"
