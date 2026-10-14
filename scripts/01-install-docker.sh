#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then echo 'Script này dành cho Ubuntu.' >&2; exit 1; fi
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y curl python3 unzip git
  sudo systemctl start docker
  echo 'Đã có Docker + Compose; giữ nguyên bản đang cài.'
  sudo docker version
  exit 0
fi
case "${VERSION_ID:-}" in 22.04|24.04|26.04) ;; *) echo "Ubuntu $VERSION_ID: kiểm tra phiên bản hỗ trợ tại docs.docker.com/engine/install/ubuntu trước khi cài." >&2;exit 1;; esac
conflicts=()
for pkg in docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc; do
  if [[ "$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)" == 'install ok installed' ]]; then conflicts+=("$pkg"); fi
done
if ((${#conflicts[@]})); then
  echo "Có package Docker/container runtime cũ: ${conflicts[*]}. Không tự gỡ để tránh ảnh hưởng công việc đang chạy. Gửi thông tin này để chọn cách chuyển đổi." >&2
  exit 1
fi
sudo apt-get update
sudo apt-get install -y ca-certificates curl python3 unzip git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
ubuntu_suite="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
ubuntu_arch="$(dpkg --print-architecture)"
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<REPO
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $ubuntu_suite
Components: stable
Architectures: $ubuntu_arch
Signed-By: /etc/apt/keyrings/docker.asc
REPO
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
sudo docker compose version
