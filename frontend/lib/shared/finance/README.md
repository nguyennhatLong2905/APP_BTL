# Finance dùng chung

Trạng thái: tài liệu và thư mục giữ chỗ. Chưa có Money, snapshot hoặc service mới được triển khai.

## Trách nhiệm

Một định nghĩa VND, chu kỳ và phép tính còn để chi dùng cho mọi màn. Không phải kho số dư mới hoặc feature UI.

| Thư mục | Việc |
|---|---|
| `domain/value_objects/` | Money VND, ngày/phạm vi và các giá trị đã validation |
| `domain/entities/` | Snapshot/đầu vào chuẩn hóa theo hợp đồng |
| `domain/services/` | Phép tính thuần B−P, số ngày, bình quân và tác động mô phỏng |
| `application/` | Tổng hợp đầu vào, snapshot revision, điều phối refresh sau thao tác |
| `providers/` | Điểm ghép reader domain của wallet/transaction/planning; không import widget |

Domain không phụ thuộc Flutter/Riverpod/HTTP/storage. Reader gốc không được đọc ngược snapshot để tránh vòng phụ thuộc.

Chủ dữ liệu vẫn là wallet, transaction và planning. Shared finance đọc đầu vào qua hợp đồng domain, không truy cập repository implementation hoặc datasource của feature.

Test thuần nghiệp vụ đặt tại `test/shared/finance/domain/`; test tổng hợp ở `application/`; fixture ở `test/fixtures/finance/`.

Phải chốt [DATA_CONTRACTS](../../../docs/vian/DATA_CONTRACTS.md) trước khi tạo interface/class; [checklist](../../../docs/vian/ACCEPTANCE_CHECKLIST.md) có các ví dụ số chuẩn.
