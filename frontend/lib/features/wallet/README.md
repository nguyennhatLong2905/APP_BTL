# Wallet — Ví và số dư

Trạng thái: có màn placeholder cũ; chưa có nghiệp vụ số dư hoàn chỉnh. Đây là module hỗ trợ 6 màn, không phải tab mới.

## Phạm vi

Danh sách ví, loại ví, số dư và reader chuẩn hóa cho snapshot. Phối hợp transaction để ghi thu/chi/chuyển ví nguyên tử, tránh có ledger thứ hai.

## Chỗ làm

- `domain/entities/`, `domain/repositories/`, `domain/usecases/`: hợp đồng ví và thao tác nghiệp vụ.
- `data/`: datasource, DTO/mapping và implementation.
- `providers/`: dependency injection.
- `presentation/`: màn/chọn ví và trạng thái UI.

Wallet cung cấp tổng số dư hiện tại, đã phản ánh ledger. Không trừ lại chi tiêu chu kỳ để tính số dư. Planning cung cấp khoản dành riêng; shared finance tính số tự do.

Khi sửa giao dịch hoặc chuyển ví, rollback/đối soát đầy đủ nếu ghi lỗi. Ví đã có lịch sử được lưu trữ thay vì xóa làm mất tham chiếu.

Test đặt tại `test/features/wallet/`; ưu tiên cập nhật số dư, chuyển ví và tính nhất quán khi retry.

Xem [kiến trúc](../../../docs/vian/ARCHITECTURE.md) và [hợp đồng dữ liệu](../../../docs/vian/DATA_CONTRACTS.md).
