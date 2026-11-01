# Transaction — Lịch sử và Thêm giao dịch

Trạng thái: có màn placeholder cũ, chưa triển khai 2 giao diện tham chiếu. Các thư mục mới chỉ giữ chỗ.

## Phạm vi và chia việc

Một domain/repository cho expense, income và transfer. History và editor có thể giao hai người, nhưng cần một người chốt các lớp dùng chung.

| Việc | Chỗ làm |
|---|---|
| Lịch sử, search/filter, chi tiết, nhóm ngày | `presentation/screens/history/`, `presentation/widgets/history/` |
| Form thêm/sửa, 3 chế độ, nhận PurchaseDraft | `presentation/screens/editor/`, `presentation/widgets/editor/` |
| Trạng thái UI theo màn | `presentation/providers/`; tách tên history/editor |
| Transaction, Transfer, Category | `domain/entities/` |
| Interface truy vấn và ghi | `domain/repositories/` |
| Validation, tạo/sửa/xóa, chuyển ví nguyên tử | `domain/usecases/` |
| DTO, mapping, datasource, implementation | `data/models/`, `data/datasources/`, `data/repositories/` |
| Đăng ký dependency | `providers/` |

Không tạo feature add_transaction/history riêng. Không tạo hai lớp Transaction cho hai màn. Không để widget tự cập nhật số dư.

## Đầu vào / đầu ra

History nhận bộ lọc, trả danh sách có phân trang và tổng thu/chi rõ nghĩa. Editor nhận bản nháp tùy chọn, trả kết quả lưu đã xác nhận hoặc giữ bản nháp khi lỗi. Thu/chi cập nhật ví; transfer đổi hai ví cùng lúc, tổng tiền không đổi.

Sau thao tác thành công cần làm mới snapshot, ngân sách và báo cáo phụ thuộc. Retry giữ clientOperationId; xóa transfer xử lý cả nhóm bút toán.

Test đặt tại `test/features/transaction/`, tách presentation/history và presentation/editor. Fixture dùng chung ở `test/fixtures/transactions/`.

Xem [đặc tả 2 màn](../../../docs/vian/UI_UX_SPEC.md), [hợp đồng](../../../docs/vian/DATA_CONTRACTS.md) và [checklist](../../../docs/vian/ACCEPTANCE_CHECKLIST.md).
