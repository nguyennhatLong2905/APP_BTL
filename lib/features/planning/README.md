# Planning — Kế hoạch chi tiêu

Trạng thái: chỉ có README và thư mục giữ chỗ; chưa có Dart mới.

## Phạm vi

Chu kỳ lương, 3 tab Ngân sách / Mục tiêu / Hóa đơn, khoản dành riêng và đề xuất phân bổ. Không cung cấp chức năng thanh toán ngân hàng.

## Chỗ làm

- `domain/entities/`: cycle, budget, bill, allocation, savings goal.
- `domain/repositories/`, `domain/usecases/`: hợp đồng truy vấn/ghi và quy tắc phân bổ.
- `data/`: datasource, DTO/mapping và implementation.
- `providers/`: đăng ký dependency.
- `presentation/screens/`: màn Kế hoạch và form con khi cần.
- `presentation/widgets/`: nhóm budget/goal/bill bằng tiền tố file khi triển khai.
- `presentation/providers/`: tab, phạm vi tháng/chu kỳ và trạng thái thao tác.

## Ràng buộc

Ngân sách còn lại không phải số dư tự do. Allocation liên kết hóa đơn/mục tiêu chỉ được tính một lần. Tạo mục tiêu chưa phân bổ không trừ tiền.

Thanh toán hóa đơn mở/điều phối giao dịch với linkedBillId; ghi chi và giải phóng khoản đã dành phải nhất quán. Không đánh dấu paid chỉ bằng thay đổi local state ở widget.

Ảnh chỉ cho chi tiết tab Ngân sách; Mục tiêu/Hóa đơn theo đặc tả tối thiểu, cần chốt bố cục khi triển khai. Đầu ra cho finance là cycle và tập khoản dành riêng chuẩn hóa.

Test đặt tại `test/features/planning/`; fixture ở `test/fixtures/planning/`.

Xem [đặc tả màn](../../../docs/vian/UI_UX_SPEC.md), [hợp đồng](../../../docs/vian/DATA_CONTRACTS.md) và [checklist](../../../docs/vian/ACCEPTANCE_CHECKLIST.md).
