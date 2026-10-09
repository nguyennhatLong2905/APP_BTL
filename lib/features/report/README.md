# Report — Nhìn lại và Nhật ký đáng tiền

Trạng thái: giữ module report và màn placeholder cũ; chưa triển khai giao diện Nhìn lại. Không tạo feature reflection trùng.

## Phạm vi

Tổng chi tuần, so sánh tuần trước, nhật ký sau 7 ngày, lưu cảm nhận, insight có đủ mẫu và mở đề xuất điều chỉnh kế hoạch.

## Chỗ làm

- `domain/entities/`: Reflection và dữ liệu tổng hợp tuần.
- `domain/repositories/`, `domain/usecases/`: đọc giao dịch qua interface và lưu đánh giá.
- `data/`: nguồn lưu cảm nhận và mapping.
- `providers/`: nối reader transaction và repository reflection.
- `presentation/screens/`, `widgets/`, `providers/`: tổng hợp tuần, journal, insight, gợi ý.

Không tạo bản sao ledger. Mỗi giao dịch có một cảm nhận hiện hành; bỏ qua không xóa giao dịch. Thống kê/insight phải có tập dữ liệu và số mẫu, không hardcode % từ ảnh.

“Điều chỉnh ngân sách” chuyển đề xuất sang planning và cần lưu riêng. Không tự đổi hạn mức từ một insight.

Test đặt tại `test/features/report/`; ưu tiên mốc 7 ngày, upsert đánh giá, tuần trước 0, ít mẫu và ảnh hưởng khi giao dịch sửa/xóa.

Xem [đặc tả màn](../../../docs/vian/UI_UX_SPEC.md), [hợp đồng](../../../docs/vian/DATA_CONTRACTS.md) và [checklist](../../../docs/vian/ACCEPTANCE_CHECKLIST.md).
