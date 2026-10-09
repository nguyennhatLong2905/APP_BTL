# Chỗ kiểm thử cho các module Ví An

Test hiện có của auth/network/notifications được giữ nguyên. Lần chuẩn bị này chỉ tạo thư mục test và fixture rỗng bằng `.gitkeep`, không viết test mới.

| Thư mục | Phạm vi khi triển khai |
|---|---|
| `shared/finance/domain/` | Phép tính tiền, chu kỳ, bình quân và số âm |
| `shared/finance/application/` | Snapshot tổng hợp, revision và làm mới dữ liệu |
| `features/home/` | Truy vấn tổng hợp và UI Tổng quan |
| `features/transaction/` | Ghi ledger, retry/idempotency, chuyển ví và UI history/editor |
| `features/wallet/` | Số dư và cập nhật nguyên tử |
| `features/planning/` | Ngân sách, allocation, hóa đơn và mục tiêu |
| `features/purchase_decision/` | Mô phỏng, bản nháp và tác động bằng 0 lên dữ liệu thật |
| `features/report/` | Mốc 7 ngày, cảm nhận, tổng hợp tuần và insight |
| `fixtures/finance/`, `fixtures/transactions/`, `fixtures/planning/` | Dữ liệu mẫu có đồng hồ cố định, chưa tạo tệp dữ liệu |

Ưu tiên test quy tắc tiền và trạng thái thao tác. Không viết test chỉ kiểm tra thư mục hoặc lặp lại cách implementation được viết.

Xem [hợp đồng](../docs/vian/DATA_CONTRACTS.md) và [checklist nghiệm thu](../docs/vian/ACCEPTANCE_CHECKLIST.md). Các ảnh trong `docs/vian/references/` là mockup gốc, không phải golden của ứng dụng hiện tại.
