# Kiểm thử bản tách Backend / Frontend

## Kết quả

- **16 nhóm test backend: 16 đạt, 0 lỗi.** Express chạy thật với PostgreSQL engine PGlite, không dùng database giả bằng mảng.
- Giữ 14 nhóm kiểm tra nghiệp vụ bản trước: đăng ký/auth/CSRF, quyền, CRUD, hạn trả/date CHECK, kho sách, FK, trả đúng chủ, mã reset một lần/hết hạn, thu hồi session, mượn/trả hộ, overdue.
- Thêm test tổng quan: số liệu thật, reader chỉ thấy phiếu của mình, không thấy tổng độc giả; API chưa đăng nhập bị chặn.
- Thêm test API không tồn tại: JSON 404 và X-Request-Id.
- **Kiểm tra trình duyệt Chromium thực:** đăng nhập; tổng quan; phân trang/tìm sách; mở modal mượn/lưu phiếu; xác nhận trả; đăng xuất; admin có menu riêng; thêm thể loại. Không có lỗi JavaScript.
- Kiểm tra ảnh chụp trang đăng nhập, tổng quan, kho sách ở desktop 1440px và mobile 390px. Mobile không tràn ngang toàn trang; bảng/menu có vùng cuộn riêng.
- Parse YAML/JSON; kiểm tra đường build/bind mount/dependency/network trong Compose và bảo toàn tên project/volume PostgreSQL.
- Source giữ package-lock của bản trước đã audit 0 lỗ hổng production được báo. Refactor không thêm thư viện production.

## Giới hạn

Chưa chạy toàn bộ stack Docker trong môi trường kiểm tra: cần xác nhận PostgreSQL container, Nginx proxy/CSP, image, volume permissions, Mailpit SMTP và metrics/log end-to-end trên Docker Desktop của bạn. Browser test dùng Express phục vụ frontend để xác nhận UI/API tương tác; không thay thế test proxy Nginx. PGlite chạy PostgreSQL WebAssembly; test tuần tự, chưa đo concurrency trên PostgreSQL server nhiều connection.

## Chạy lại

Tại backend:

```powershell
npm ci
npm test
```

Tại LibraryPro:

```powershell
docker compose up -d --build
docker compose ps
docker compose logs --tail 100 app nginx
```

Mở http://localhost:8080. Kiểm tra đăng nhập bằng ba vai trò, đăng ký, quên/reset mật khẩu qua Mailpit; thêm/sửa/xóa dữ liệu chưa có liên kết; mượn/trả và hạn trả; kiểm tra dữ liệu trong pgAdmin; kiểm tra Prometheus Targets và Grafana/LogQL. Dùng lại .env và cùng tên project khi nâng cấp để giữ database cũ.

## Gói Ubuntu
Đã kiểm tra cú pháp bash của 5 script; parse Compose với UID 65534 cho Prometheus/PostgreSQL Exporter. Script Git tạo 3 commit theo từng giai đoạn. Chưa có phiên điều khiển máy ảo Ubuntu của người dùng: chưa cài Docker hay chạy stack tại đó. Cần chạy 03-check.sh và demo thực tế trước khi xác nhận hoàn thành.
