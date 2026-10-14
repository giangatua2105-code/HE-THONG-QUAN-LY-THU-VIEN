# Triển khai LibraryHub trên máy ảo Ubuntu

Dành cho bài tập Đề 1. Chạy frontend Nginx, backend Node.js, PostgreSQL, pgAdmin, Prometheus, Grafana, Loki, Promtail và exporters bằng Docker Compose. Gói đã thêm UID 65534:65534 cho Prometheus/PostgreSQL Exporter để tránh lỗi tra tên nobody trên máy bạn.

## 1. Chuẩn bị máy ảo

Dùng Ubuntu Desktop để mở Firefox và demo ngay trong Ubuntu. Script cài đặt hỗ trợ Ubuntu 22.04/24.04/26.04 64-bit theo danh sách Docker hỗ trợ. Nếu máy có đủ tài nguyên, dành khoảng 4 CPU, 6–8 GB RAM, 40 GB đĩa cho máy ảo; đây là mức gợi ý cho cả bộ giám sát, không phải yêu cầu tối thiểu bắt buộc. Nếu máy host ít RAM, cần điều chỉnh phù hợp.

Máy ảo cần kết nối Internet (NAT là đủ). Không cần VPS hoặc IP công khai để demo trực tiếp trên Ubuntu. Ubuntu Desktop/VM và Windows là hai môi trường Docker khác nhau, không tự chia sẻ image hoặc database volume.

## 2. Đưa ZIP vào Ubuntu và giải nén

Tải LibraryHub_Ubuntu_Deployment.zip bằng Firefox trong Ubuntu, hoặc chép từ Windows qua Shared Folder/USB. Mở Terminal (Ctrl+Alt+T):

```bash
sudo apt-get update
sudo apt-get install -y unzip
cd ~/Downloads
unzip LibraryHub_Ubuntu_Deployment.zip
cd LibraryUbuntu
ls
```

Nếu ZIP ở nơi khác, mở thư mục chứa ZIP trong Files, chọn Open in Terminal rồi chạy unzip. Thư mục cần có compose.yaml, backend, frontend và scripts.

## 3. Cài Docker

```bash
bash scripts/01-install-docker.sh
```

Nhập mật khẩu tài khoản Ubuntu khi sudo hỏi; khi gõ sẽ không hiện ký tự, đây là bình thường. Script cài Docker Engine + Compose plugin từ apt repository chính thức; không tự gỡ Docker/container runtime cũ. Nếu đã có Docker + Compose chạy được, giữ bản hiện tại và bổ sung công cụ cần thiết.

Kiểm tra:

```bash
sudo docker version
sudo docker compose version
```

Không cần cài Docker Desktop hoặc Node.js riêng trong Ubuntu. Các lệnh Docker dùng sudo khi tài khoản chưa có quyền truy cập daemon.

## 4. Khởi chạy hệ thống

```bash
bash scripts/02-deploy.sh
```

Script giữ .env nếu đã có; nếu chưa có sẽ tạo mật khẩu ngẫu nhiên, kiểm tra cấu hình YAML, build/chạy Compose và chờ endpoint health. Không xóa volume/database. Quá trình đầu tiên cần tải nhiều image, tốc độ tùy kết nối.

Mở Firefox **trên Ubuntu**:

| Công cụ | URL |
|---|---|
| Website | http://localhost:8080 |
| pgAdmin | http://localhost:5050 |
| Grafana | http://localhost:3001 |
| Prometheus | http://localhost:9090 |
| Mailpit | http://localhost:8025 |

Cổng chỉ bind localhost để demo cục bộ và hạn chế truy cập công cụ quản trị. localhost trong trình duyệt Windows không trỏ tới Ubuntu; mở trình duyệt trong VM theo hướng dẫn này.

Đọc mật khẩu trên máy của bạn:

```bash
nano .env
```

Admin `admin@example.com` → ADMIN_PASSWORD; thủ thư `thuthu@example.com` → LIBRARIAN_PASSWORD; độc giả `docgia@example.com` → READER_PASSWORD. Sao chép phần sau dấu =. Không chụp .env vào báo cáo, không đưa lên GitHub. Các tài khoản đã tồn tại giữ mật khẩu hiện có, seed không ghi đè.

## 5. Database và pgAdmin

Đăng nhập pgAdmin bằng admin@example.com / PGADMIN_PASSWORD. Servers → Register → Server:

- Name: Library.
- Host: postgres; Port: 5432; Maintenance database: library.
- Username: library_app; Password: DB_PASSWORD.

Schemas/public/Tables có users, categories, books, loans, sessions, resets, rate_limits. Dữ liệu lưu named volume pgdata. Mượn/trả trên website rồi Query Tool chạy:

```sql
SELECT id, name, email, role FROM users ORDER BY id;
SELECT id, user_id, book_id, borrowed_at, due_date, returned_at
FROM loans ORDER BY id DESC;
```

Dừng và mở lại vẫn giữ dữ liệu:

```bash
sudo docker compose down
sudo docker compose up -d
```

Không dùng down -v. Backup:

```bash
bash scripts/04-backup.sh
```

File SQL được lưu trong backups/ với quyền hạn chế và không commit lên Git.

## 6. Mang dữ liệu từ Windows sang Ubuntu (tùy chọn)

Chạy mới trên Ubuntu sẽ có database riêng. Nếu muốn mang dữ liệu đang có trên Windows:

1. Tại dự án Windows đang chạy, PowerShell:

```powershell
docker compose exec postgres sh -c 'pg_dump -U postgres -d library > /tmp/library-backup.sql'
docker compose cp postgres:/tmp/library-backup.sql ./library-backup.sql
```

2. Chép file library-backup.sql và .env cũ vào LibraryUbuntu trên Ubuntu **trước lần deploy đầu tiên**. Giữ Windows như một bản sao.
3. Khởi động riêng PostgreSQL trên Ubuntu:

```bash
sudo docker compose up -d postgres
```

4. Khi PostgreSQL healthy, nạp bản sao vào database Ubuntu mới (chỉ làm trên DB đích chưa có dữ liệu; không nhập đè database đang dùng):

```bash
sudo docker compose exec -T postgres psql -U postgres -d library -v ON_ERROR_STOP=1 < library-backup.sql
```

5. Chạy bash scripts/02-deploy.sh để bật phần còn lại. Vì pg_dump mặc định lưu owner library_app và role này được init script tạo sẵn, app dùng lại các bảng/tài khoản cũ. Không tự tạo mật khẩu .env mới trong trường hợp này.

## 7. Kiểm tra metrics và log

```bash
bash scripts/03-check.sh
```

Script kiểm tra HTTP, bảng database, 5 Prometheus Targets, Loki ready + một query log Nginx, UID app/Nginx và hardening của app. Nếu Targets/log chưa có ngay, đợi khoảng 30 giây rồi chạy lại. Kiểm tra không thành công trả exit code khác 0, không tự tuyên bố hệ thống đã hoàn tất.

Prometheus → Status/Targets: jobs prometheus, library, nginx, postgres, containers cần UP. Grafana đăng nhập admin/GRAFANA_PASSWORD, mở dashboard Thư viện - Giám sát. Nếu cAdvisor không có dữ liệu, xem logs và xác nhận các mount /sys, /var/run, /var/lib/docker của Docker Engine Ubuntu, không thay bằng ảnh số liệu giả.

Tạo thao tác mượn/trả trên web, Grafana Explore → Loki → Last 15 minutes, chạy 3 query:

```logql
{job="library"}
```

```logql
{job="library"} | json | status >= 400
```

```logql
{job="nginx"} |= "POST /api/loans"
```

Query 2 có thể trống nếu chưa có request lỗi. Để tạo minh chứng lỗi 400, trong form mượn mở Developer Tools, sửa min của trường hạn trả rồi chọn ngày cũ và gửi; backend sẽ từ chối. Hoặc dùng thử đăng nhập sai để tạo log status 401; thông tin mật khẩu không được log. Không cần tạo lỗi hệ thống 500 giả.

## 8. GitHub — 3 commit kỹ thuật

Nếu chưa có repository local:

```bash
git config --global user.name "Giang A Tua"
git config --global user.email "EMAIL_GITHUB_CUA_BAN"
bash scripts/05-create-git-history.sh
```

Script tạo commit 1 web/DB/Nginx; commit 2 Prometheus/Grafana/exporters; commit 3 Loki/Promtail. Compose từng giai đoạn nằm trong stages; source cuối vẫn là stack đầy đủ. Script không tự push và không sửa repository đã có .git.

Tạo repository trên GitHub theo mã SV của bạn, không khởi tạo README riêng nếu đã có commit local. Sau đó thay URL thật:

```bash
git remote add origin https://github.com/TAI_KHOAN/TEN_REPO.git
git push -u origin main
git log --oneline -3
```

GitHub yêu cầu xác thực cho push HTTPS, không dùng mật khẩu tài khoản GitHub thông thường. Dùng GitHub CLI, SSH hoặc token theo cơ chế hiện có trên máy; không gửi token vào chat. Nếu đã có repo bản trước, giữ lịch sử và commit thay đổi mới thay vì chạy script tạo lịch sử.

## 9. Demo và báo cáo

Xem MINH_CHUNG.md để chụp màn hình đúng 7 tiêu chí. Báo cáo tối thiểu 10 trang cần kết quả thực tế, cấu trúc, sơ đồ và hình minh họa; không chỉ chép báo cáo mẫu. Không ghi rằng đã có HTTPS/UFW/thu log tất cả container vì cấu hình hiện tại chưa làm những việc đó. Đề cho phép security headers thay HTTPS. Promtail đang thu log Node.js và Nginx qua volume.

Kiến trúc: trình duyệt → Nginx (frontend + reverse proxy) → API Node.js → PostgreSQL. Prometheus scrape app + exporters/cAdvisor, Grafana hiển thị; Promtail đọc file log ứng dụng/Nginx → Loki → Grafana Explore. Đây là ứng dụng theo tầng được container hóa kèm dịch vụ hạ tầng; chưa phải các microservice nghiệp vụ độc lập.

## 10. Nếu lỗi

```bash
sudo docker compose ps -a
sudo docker compose logs --tail 100 app nginx postgres prometheus postgres-exporter promtail loki
```

Gửi log phần lỗi, không gửi .env. Chưa có kết nối điều khiển máy ảo trong cuộc trò chuyện; gói này chuẩn bị triển khai, chỉ xác nhận triển khai thành công khi đã chạy và kiểm tra trên Ubuntu của bạn.

Tài liệu cài Docker chính thức: https://docs.docker.com/engine/install/ubuntu/
