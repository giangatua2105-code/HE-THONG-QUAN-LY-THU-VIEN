#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if docker info >/dev/null 2>&1;then docker_cmd=(docker);else docker_cmd=(sudo docker);fi
failed=0
check_url(){ local name="$1" url="$2"; if curl --fail --silent --output /dev/null "$url"; then echo "PASS: $name";else echo "FAIL: $name";failed=1;fi; }
"${docker_cmd[@]}" compose ps -a
check_url Website http://127.0.0.1:8080/
check_url 'API + database' http://127.0.0.1:8080/health
check_url pgAdmin http://127.0.0.1:5050/login
check_url Grafana http://127.0.0.1:3001/api/health
check_url Prometheus http://127.0.0.1:9090/-/ready
check_url Mailpit http://127.0.0.1:8025/
if "${docker_cmd[@]}" compose exec -T postgres psql -U postgres -d library -c 'SELECT COUNT(*) AS users FROM users;' ;then echo 'PASS: PostgreSQL có bảng ứng dụng';else failed=1;fi
if ! curl --fail --silent http://127.0.0.1:9090/api/v1/targets | python3 -c '
import json,sys
p=json.load(sys.stdin)
if p.get("status")!="success":sys.exit(1)
t=p.get("data",{}).get("activeTargets",[])
for row in t:print("TARGET:",row["labels"].get("job"),row["health"],row.get("lastError", ""))
expected={"prometheus","library","nginx","postgres","containers"}
up={r["labels"].get("job") for r in t if r.get("health")=="up"}
sys.exit(0 if expected.issubset(up) else 1)
';then echo 'FAIL: một số metrics target chưa UP; đợi 30 giây rồi kiểm tra lại';failed=1;fi
if ! "${docker_cmd[@]}" compose exec -T app node -e '
(async()=>{const r=await fetch("http://loki:3100/ready");if(!r.ok)throw Error("Loki chưa ready");const q="http://loki:3100/loki/api/v1/query_range?query="+encodeURIComponent("{job=\"nginx\"}")+"&limit=1";const a=await fetch(q);const b=await a.json();if(b.status!=="success"||!b.data.result.length)throw Error("Chưa có log Nginx trong Loki; đợi Promtail đọc log rồi chạy lại");console.log("PASS: Loki ready và truy vấn được log Nginx")})().catch(e=>{console.error(e.message);process.exit(1)});
';then failed=1;fi
echo 'Hardening: các dịch vụ DB/metrics không mở cổng ra bên ngoài; frontend và app non-root.'
"${docker_cmd[@]}" compose exec -T app id
"${docker_cmd[@]}" compose exec -T nginx id
"${docker_cmd[@]}" inspect --format '{{.Config.User}} | {{json .HostConfig.SecurityOpt}} | readonly={{.HostConfig.ReadonlyRootfs}}' "$("${docker_cmd[@]}" compose ps -q app)"
echo 'Kiểm tra thêm dashboard Grafana và 3 LogQL query theo hướng dẫn.'
exit "$failed"
