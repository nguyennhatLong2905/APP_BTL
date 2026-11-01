# Phân công và tích hợp

Các mã công việc dưới đây là gói việc, không giả định nhóm có đúng 6 người. Điền người phụ trách khi chia nhóm; một người có thể nhận nhiều gói. Tất cả ở trạng thái “chưa code”.

| Gói việc | Người phụ trách | Phạm vi chính | Chỗ làm | Phụ thuộc |
|---|---|---|---|---|
| Nền chung | Chưa gán | UI kit, shell, router, theme, vi/VND, xử lý P0 của base | core, main, cấu hình | Chốt hợp đồng trước |
| Dữ liệu tài chính | Chưa gán | Ví, nguồn ledger, snapshot, Money và chu kỳ | wallet, shared/finance | transaction/planning thống nhất reader |
| Tổng quan | Chưa gán | Card tiền, hóa đơn sắp tới, giao dịch gần đây, trạng thái thiếu cấu hình | home | Snapshot + reader transaction/planning |
| Lịch sử | Chưa gán | Search, filter, nhóm ngày, chi tiết, tải trang | transaction/history | Contract transaction dùng chung |
| Thêm giao dịch | Chưa gán | Form 3 loại, bản nháp, validation, ghi/sửa/xóa | transaction/editor | Ledger/wallet + idempotency |
| Kế hoạch | Chưa gán | Chu kỳ, ngân sách, hóa đơn, mục tiêu, allocation | planning | Transaction reader + finance contract |
| Mua hay chờ | Chưa gán | Nhập món, mô phỏng, chuyển bản nháp, tạo kế hoạch chờ | purchase_decision | Snapshot + editor + planning |
| Nhìn lại | Chưa gán | Tổng chi tuần, nhật ký, cảm nhận, insight đủ mẫu | report | Transaction reader + planning |

## Điểm bắt đầu cho từng người

Đọc README của module được giao trong `lib/features/` rồi đọc mục màn tương ứng ở [UI_UX_SPEC](UI_UX_SPEC.md). Các lớp đã có thư mục và `.gitkeep`; chưa có class mới hoặc API giả.

History và editor thuộc cùng module transaction. Hai người có thể sửa song song ở `screens/history`, `screens/editor`, `widgets/history`, `widgets/editor`. Chỉ định một người chốt entity/repository/use case/DI dùng chung; không tạo hai bộ Transaction.

## File dùng chung cần một người điều phối

- `lib/main.dart`, `lib/core/router/*`, `lib/core/theme/*`.
- `lib/core/ui/*`, `lib/core/providers/*`, `lib/core/network/*`, `lib/core/storage/*`.
- `lib/shared/finance/*`, `lib/l10n/*`, `l10n.yaml`.
- `pubspec.yaml`, lockfile, analyzer, cấu hình platform và build.

Các thành viên mô tả thay đổi cần thiết trong PR của mình để người phụ trách nền ghép. Không copy UI chung hoặc tự thêm package ở từng module.

## Thứ tự triển khai sau khi kết thúc giai đoạn chuẩn bị

1. **Chốt nền:** xác nhận backend/phạm vi offline, SDK và hợp đồng; xử lý P0 trong đánh giá base. Tạo token/UI chung, shell, vi/VND.
2. **Chốt dữ liệu:** transaction, wallet, planning thống nhất ledger, chu kỳ và snapshot. Dùng bộ dữ liệu mẫu có chủ đích cho UI độc lập, gắn nhãn demo.
3. **Làm UI song song:** từng người dựng màn trong module của mình, đủ các trạng thái; giao diện gọi hợp đồng đã thống nhất.
4. **Tích hợp:** người phụ trách router nối 4 tab và 2 màn hành động; kiểm tra chuyển bản nháp, refresh, quay lại, lưu lỗi và retry.
5. **Nghiệm thu:** đối chiếu [checklist](ACCEPTANCE_CHECKLIST.md), sửa sai số và lỗi responsive trước polish.

Đồ thị nghiệp vụ cần tránh vòng lặp: reader gốc của wallet/transaction/planning → bộ tổng hợp finance → màn tiêu thụ. Màn hoặc provider tiêu thụ snapshot không được đưa snapshot quay lại làm đầu vào của reader gốc.

## Quy ước PR cho giai đoạn code

- Branch theo gói việc, ví dụ `feature/vian-planning`; không push trực tiếp main.
- PR ghi màn/phạm vi, hợp đồng dùng, ảnh chụp trạng thái chính, validation đã chạy và các dependency chưa ghép.
- Không tự đổi schema/enum/route dùng chung giữa chừng. Cập nhật hợp đồng và trao đổi trong nhóm trước khi ghép.
- Không dùng generator chưa kiểm tra để ghi đè thư mục module khác.
- Khi đã có Flutter SDK: chạy analyze và test đúng phạm vi thay đổi; chạy toàn bộ suite ở bước tích hợp. Các test hiện có chưa bảo đảm nghiệp vụ tiền.
- Ngày fixture phải cố định; kiểm tra UI trên 320–430 logical px và chữ lớn, không chỉ dựa vào ảnh mockup dài.

## Những quyết định còn cần nhóm xác nhận khi triển khai

Số người và người nhận từng gói; endpoint backend thật; lưu cục bộ/đồng bộ; bản Flutter cụ thể; quy tắc thanh toán hóa đơn một phần; lịch lương không đều; ngưỡng insight. Bộ hợp đồng đưa ra mặc định để bắt đầu thảo luận, không bổ sung phạm vi code cho lần chuẩn bị này.
