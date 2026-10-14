# Chạy trên Ubuntu: bắt đầu với README_UBUNTU.md

# LibraryHub — Backend và Frontend tách riêng

Bản nâng cấp giao diện và cấu trúc mã nguồn của dự án Node.js trước đó. Hai ZIP là hai phần của **cùng một hệ thống**. Giải nén cả hai vào cùng một thư mục cha để có cấu trúc:

```text
LibraryUbuntu/
  compose.yaml
  setup.js
  .env.example
  README.md
  backend/
    Dockerfile
    package.json
    package-lock.json
    app/
    tests/
    infra/
  frontend/
    Dockerfile
    nginx.conf
    index.html
    app.js
    style.css
```

## Chạy lần đầu trên Windows

Mở Docker Desktop, dùng Linux containers. Mở PowerShell trong thư mục **LibraryUbuntu** chứa compose.yaml (không ở backend hoặc frontend).

```powershell
docker run --rm -v "${PWD}:/work" -w /work node:22.16.0-alpine node setup.js
docker compose up -d --build
docker compose ps
```

Nếu có Node.js 22+, có thể dùng `node setup.js` thay cho lệnh docker run đầu tiên. Mở http://localhost:8080 sau khi app healthy và nginx Up.

| Chức vụ | Email | Mật khẩu trong .env |
|---|---|---|
| Admin | admin@example.com | ADMIN_PASSWORD |
| Thủ thư | thuthu@example.com | LIBRARIAN_PASSWORD |
| Độc giả | docgia@example.com | READER_PASSWORD |

Sao chép phần sau dấu =. Tài khoản seed chỉ tạo nếu email chưa tồn tại. Tự đăng ký cũng tạo được độc giả mới. Dữ liệu PostgreSQL thật, không dùng localStorage giả lập.

## Nâng cấp từ bản LibrarySimple và giữ dữ liệu

Bản này giữ `name: library-simple` và cùng tên volume `pgdata`; schema nghiệp vụ tương thích bản trước. Để dùng lại database trên **cùng Docker Desktop**:

1. Ở thư mục dự án cũ, có thể sao lưu database đang chạy trước khi nâng cấp:

```powershell
docker compose exec postgres sh -c 'pg_dump -U postgres -d library > /tmp/library-backup.sql'
docker compose cp postgres:/tmp/library-backup.sql ./library-backup.sql
```

2. Dừng stack cũ và giữ volume:

```powershell
docker compose down
```

3. Giải nén hai ZIP vào một thư mục mới. **Sao chép file .env từ dự án cũ vào LibraryUbuntu**, cùng cấp compose.yaml. Không tạo bộ mật khẩu mới nếu dùng lại database cũ.
4. Mở PowerShell tại LibraryUbuntu và chạy:

```powershell
docker compose up -d --build
docker compose ps
docker compose logs --tail 100 app nginx
```

5. Dùng tài khoản/mật khẩu đang có. Kiểm tra sách và phiếu mượn cũ trong giao diện/pgAdmin. Ctrl+F5 để tải giao diện mới.

Không chạy `down -v`, không xóa/reset dữ liệu Docker, không đổi `name:` nếu muốn dùng lại volume này. Nếu trước đó chạy với `docker compose -p TEN_KHAC`, bản nâng cấp cũng phải chạy với chính `-p TEN_KHAC` đó. Việc chuyển sang máy Ubuntu khác không tự mang volume theo; cần sao lưu/phục hồi database riêng.

## Thay đổi giao diện

- Bố cục sidebar, thanh điều hướng, trang đăng nhập hai cột, màu xanh trầm/kem.
- Trang tổng quan lấy số liệu từ API/database, giới hạn phiếu theo độc giả đăng nhập.
- Kho sách dạng thẻ, tìm kiếm trực tiếp, lọc thể loại, phân trang.
- Bảng mượn/trả có trạng thái đang mượn/đã trả/quá hạn; tìm kiếm, lọc và phân trang.
- Bảng người dùng, phân quyền chức vụ, form thêm/sửa; xác nhận xóa/trả bằng hộp thoại.
- Thông báo thành công/lỗi, chống bấm gửi nhiều lần, hiện/ẩn mật khẩu; giao diện điện thoại.
- Không tải font/icon từ CDN, không phụ thuộc dịch vụ bên ngoài để hiển thị giao diện.

## Chức năng và quy tắc giữ lại

Độc giả tự mượn/trả sách và chỉ xem phiếu của mình. Thủ thư/admin CRUD sách, thể loại, độc giả và mượn/trả hộ. Admin phân quyền reader/librarian/admin; không tự đổi chức vụ. Đăng ký luôn tạo reader. Phiên cũ bị thu hồi khi đổi quyền hoặc đặt lại mật khẩu.

**Hạn trả >= ngày mượn**. Ngày mượn/trả thực tế lấy NOW() từ PostgreSQL; ngày tính theo Asia/Ho_Chi_Minh. Quá hạn từ ngày tiếp theo sau hạn trả. Trả trễ vẫn được phép. Danh sách phiếu/tổng quan tự cập nhật mỗi 60 giây khi không mở hộp thoại.

Chặn sách hết, mượn trùng một sách đang giữ, giảm kho dưới số đang mượn. Khóa dòng/transaction khi mượn. Không xóa dữ liệu đã có lịch sử phiếu hoặc thể loại đang chứa sách. Phải trả hết sách trước khi đổi độc giả thành chức vụ khác.

Quên mật khẩu: nhập email → http://localhost:8025 Mailpit → lấy mã → Tôi đã có mã đặt lại → nhập mã/mật khẩu mới. Mã dùng một lần, hiệu lực 15 phút, database lưu hash. Mailpit chỉ nhận thư thử, không gửi Gmail thật. SMTP thật cấu hình qua biến môi trường của Compose.

## Công cụ và database

| Dịch vụ | URL | Tài khoản |
|---|---|---|
| Web/Nginx | http://localhost:8080 | Tài khoản thư viện |
| pgAdmin | http://localhost:5050 | admin@example.com / PGADMIN_PASSWORD |
| Grafana | http://localhost:3001 | admin / GRAFANA_PASSWORD |
| Prometheus | http://localhost:9090 | Cục bộ |
| Mailpit | http://localhost:8025 | Cục bộ |

pgAdmin Register Server → Name Library → Connection: Host **postgres**, Port **5432**, Maintenance database **library**, Username **library_app**, Password **DB_PASSWORD**. Database nằm ở named volume; dừng/rebuild container vẫn giữ dữ liệu nếu không xóa volume.

Grafana có dashboard Thư viện - Giám sát và datasource Prometheus/Loki. Prometheus theo dõi app, Nginx, PostgreSQL, cAdvisor. cAdvisor phụ thuộc khả năng cgroups của Docker Desktop; xác nhận Targets và metrics trên máy chạy.

LogQL: tạo thao tác web trước, mở Grafana Explore → Loki, chọn Last 15 minutes:

```logql
{job="library"}
```

```logql
{job="library"} | json | status >= 400
```

```logql
{job="nginx"} |= "POST /api/loans"
```

## Backend được tổ chức lại

- app/app.js: cấu hình Express, middleware, auth guard, đăng ký các route.
- app/routes/auth.js: đăng ký/đăng nhập/đăng xuất/quên/reset mật khẩu.
- app/routes/catalog.js: sách/thể loại.
- app/routes/loans.js: nghiệp vụ mượn/trả.
- app/routes/users.js: độc giả và phân quyền.
- app/routes/stats.js: số liệu tổng quan có kiểm tra phạm vi người dùng.
- app/session-store.js: session PostgreSQL.
- app/error-handler.js: lỗi JSON nhất quán, requestId hỗ trợ tra log.
- app/db.js: pool giới hạn connection và timeout.
- app/server.js: SMTP, log, shutdown đóng connection khi SIGTERM/SIGINT.
- app/schema.sql, init.js: schema và seed, không xóa dữ liệu cũ.

CSRF, cookie HttpOnly/SameSite, scrypt password, SQL tham số và kiểm tra quyền backend giữ nguyên. Nginx phục vụ frontend, chuyển `/api/` tới Node.js trong mạng Docker: không cần cấu hình CORS và không phải mở cổng database. App/Nginx chạy non-root và read-only. PostgreSQL/exporter dùng role riêng; công cụ quản trị chỉ mở localhost. Nginx dùng security headers theo lựa chọn của đề; chưa cài HTTPS tự ký.

## Kiểm thử và phát triển

```powershell
cd backend
npm ci
npm test
```

Xem KIEM_THU.md. Khi đổi frontend/backend, tại LibraryUbuntu chạy `docker compose up -d --build`, rồi Ctrl+F5 trình duyệt. `npm start` ở backend chỉ chạy API, không phục vụ frontend; để dùng đầy đủ hệ thống, chạy Compose.

## GitHub

ZIP chưa được đưa lên GitHub. Tạo repository của bạn rồi, tại LibraryUbuntu:

```powershell
git init
git branch -M main
git add .
git commit -m "feat: split Node API and redesign library frontend"
git remote add origin https://github.com/TAI_KHOAN/TEN_REPO.git
git push -u origin main
```

`.env`, node_modules và backup SQL được bỏ qua. Nếu đang có repo của bản trước, đưa source mới vào repo đó và commit; không tạo lại repo nếu muốn giữ lịch sử các commit Nginx/giám sát/log đã nộp.
