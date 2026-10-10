# Ví An — Bộ bàn giao base và thiết kế

Cập nhật: 09/10/2026. Phạm vi lần chuẩn bị này: rà soát tĩnh base, tối ưu đặc tả từ 6 ảnh, bổ sung tài liệu và thư mục giữ chỗ. Chưa triển khai hoặc sửa mã ứng dụng, cấu hình build hay test.

## Đọc theo thứ tự

1. [Đánh giá base và thứ tự xử lý](BASE_REVIEW.md).
2. [Kiến trúc và bản đồ thư mục](ARCHITECTURE.md).
3. [Đặc tả tối ưu 6 màn hình](UI_UX_SPEC.md).
4. [Hợp đồng dữ liệu và phép tính](DATA_CONTRACTS.md).
5. [Phân công và tích hợp](TEAM_HANDOFF.md).
6. [Checklist nghiệm thu](ACCEPTANCE_CHECKLIST.md).
7. [6 ảnh gốc](references/README.md).

## Trạng thái thực tế

| Hạng mục | Trạng thái |
|---|---|
| Flutter, Riverpod, GoRouter, lớp network/storage | Có trong base; chưa xác nhận build trên môi trường này |
| Auth | Có luồng UI/use case; datasource còn mô phỏng |
| Tổng quan, Giao dịch, Ví, Báo cáo | Có màn khung; chưa phải UI trong ảnh |
| Kế hoạch, Mua hay chờ | Đã chuẩn bị thư mục và phạm vi công việc |
| Quy tắc tài chính, dữ liệu chung, UI dùng chung | Đã đặc tả; chưa triển khai |
| Các thư mục test mới | Giữ chỗ; chưa có test mới |

Các đường dẫn màn hình, tên đối tượng và hành vi trong tài liệu là thiết kế đề xuất cho bước triển khai tiếp theo. Không coi chúng là API backend đã tồn tại hoặc route đã được đăng ký.

6 ảnh dùng làm tham chiếu giao diện. Các nhãn như “Tiến hành mua”, “Lưu giao dịch” trong ảnh mô tả sản phẩm, không phải yêu cầu thực hiện giao dịch ở lần chuẩn bị này.

## Quy ước

- Tên sản phẩm: Ví An. Ngôn ngữ mục tiêu: tiếng Việt. Đồng tiền MVP: VND.
- Dữ liệu ngày 02/10/2026 trong ảnh là bộ mẫu cố định, không phải ngày hiện tại.
- `.gitkeep` chỉ để Git lưu thư mục; README trong module chỉ dẫn phạm vi.
- Các tài liệu template khác trong `docs/` được giữ để tham khảo. Khi xây 6 màn Ví An, dùng bộ tài liệu này làm đặc tả và ghi nhận thay đổi khi nhóm chốt lại.
