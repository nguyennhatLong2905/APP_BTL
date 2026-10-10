# Purchase decision — Mua hay chờ

Trạng thái: chỉ có README và thư mục giữ chỗ; chưa có Dart mới.

## Phạm vi

Nhập món và giá, so sánh tiền trước/sau khoản chi, chỉnh giả định, chuyển draft sang editor hoặc tạo kế hoạch để dành qua planning.

## Chỗ làm

- `domain/entities/`: PurchaseDraft, giả định và kết quả mô phỏng.
- `domain/usecases/`: mô phỏng thuần dựa trên Money/cycle/snapshot chung.
- `domain/repositories/`, `data/`: chỉ dùng nếu cần lưu bản nháp/nhắc nhở; không tạo API mua hàng giả.
- `providers/`: nối reader snapshot và các hợp đồng liên module.
- `presentation/screens/`, `widgets/`, `providers/`: form và trạng thái UI.

## Đầu vào / đầu ra

Đọc FinancialSnapshot cùng revision. Mô phỏng trả giá trị dự kiến, không sửa ledger hoặc allocation. “Ghi khoản mua này” chuyển draft sang transaction/editor; editor là nơi xác nhận lưu.

“Để dành mua sau” gửi yêu cầu tạo mục tiêu/nhắc nhở qua planning, không tự tạo giao dịch. Giả định mô phỏng không ghi đè chu kỳ thật nếu chưa có hành động lưu riêng.

Giá vượt tiền tự do phải hiện thiếu; thiếu chu kỳ không tự lấy mốc 14 ngày. Không import màn editor hoặc planning trực tiếp vào domain.

Test đặt tại `test/features/purchase_decision/`; kiểm tra mô phỏng không làm đổi dữ liệu thật, đủ/thiếu tiền và đường chuyển bản nháp.

Xem [đặc tả màn](../../../docs/vian/UI_UX_SPEC.md) và [hợp đồng](../../../docs/vian/DATA_CONTRACTS.md).
