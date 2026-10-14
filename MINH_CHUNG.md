# Minh chứng cần chụp cho báo cáo tối thiểu 10 trang

Chỉ ghi kết quả sau khi kiểm tra trên Ubuntu. Không chụp .env, mật khẩu, token hoặc mã reset. Ảnh phải đọc được chữ, thấy ngữ cảnh Ubuntu/Terminal khi phù hợp.

| Tiêu chí | Nội dung minh chứng |
|---|---|
| GitHub | Repository có backend/frontend/compose/infra/README; git log và 3 commit kỹ thuật |
| Ứng dụng | Đăng nhập; admin/thủ thư; độc giả tự mượn/trả; chặn hạn trả trước ngày mượn |
| Database | pgAdmin kết nối PostgreSQL; bảng users/books/loans và phiếu vừa thao tác |
| Nginx | Website localhost:8080; cấu hình proxy /api/; curl -I localhost:8080 cho security headers |
| Metrics | Prometheus Targets UP; Grafana dashboard CPU/RAM container, Nginx, PostgreSQL và request app |
| Logs | Grafana Explore chạy 3 LogQL query, có kết quả; query lỗi có request lỗi hợp lệ |
| Hardening | docker compose exec app id; nginx id; network database internal; ports DB không publish; app role không superuser |
| Bền vững dữ liệu | Phiếu trước/sau down và up không xóa volume; kết quả backup |

Bố cục gợi ý 12 trang (tùy lượng hình):
1. Bìa: Giàng A Tủa; MSSV/lớp cần điền thông tin thật; đề tài Hệ thống Quản lý Thư viện; Thái Nguyên 2026.
2. Mục lục tự động, mục tiêu/phạm vi.
3–4. Kiến trúc và chuẩn bị máy ảo Ubuntu, Docker, cấu trúc repo.
5–6. Web, PostgreSQL, pgAdmin, nghiệp vụ và Nginx.
7–8. Prometheus/Grafana và các metrics container/web/database.
9. Loki/Promtail và 3 LogQL query hợp lệ.
10. Hardening đã triển khai và kiểm tra.
11. Kết quả demo, lỗi thực tế và cách xử lý, giữ/backup dữ liệu.
12. Kết luận, hạn chế, hướng phát triển, tài liệu tham khảo.

Sửa nội dung mẫu: cổng web hiện tại là 8080 bind localhost; dùng X-Frame-Options DENY, nosniff, CSP, Referrer-Policy; chưa có SSL/TLS tự ký, UFW hoặc thu log tất cả container. Non-root giảm quyền và rủi ro, không đảm bảo ngăn tuyệt đối leo thang đặc quyền. Chưa ghi “đủ mọi tiêu chí” cho tới khi demo GitHub, pgAdmin, Targets, Grafana, LogQL và hardening thành công.
