# Hợp đồng dữ liệu và nghiệp vụ đề xuất

Tài liệu này chốt ngữ nghĩa để các thành viên viết mã cùng một cách. Các tên dưới đây chưa phải class/interface đã triển khai; không có endpoint backend nào được khẳng định tồn tại.

## 1. Tiền, ngày và đồng bộ

- MVP dùng VND. Số tiền lưu bằng số nguyên đồng, không dùng số thực để cộng trừ số dư; đồng tiền là trường riêng, không lấy từ locale.
- Số tiền giao dịch luôn dương; loại giao dịch quyết định chiều thu/chi. Số dư và khoản còn lại được phép âm.
- Đề xuất giới hạn nhập 999.999.999.999 đ; backend và frontend phải thống nhất cùng giới hạn trước tích hợp.
- Timestamp lưu ISO 8601 UTC. Ngày nghiệp vụ/nhóm lịch sử dùng múi giờ Asia/Ho_Chi_Minh. Ngày đến hạn và ngày chu kỳ là date-only, không đổi ngày qua UTC.
- Bộ mẫu trong ảnh cố định ở 02/10/2026; app thật dùng đồng hồ hiện tại có thể thay thế trong test.
- Ghi dữ liệu có clientOperationId ổn định xuyên suốt các lần retry. Backend hoặc kho cục bộ phải xử lý idempotent; chỉ chặn nút ở UI là chưa đủ.
- Phân biệt pending/synced/failed. Timeout chưa có kết quả xác nhận là trạng thái cần đối soát, không tự tạo lệnh mới.

## 2. Các đối tượng và nơi sở hữu

| Đối tượng | Trường tối thiểu | Chủ sở hữu |
|---|---|---|
| Money | amountVnd, currency=VND | shared/finance/domain |
| Wallet | id, name, type, balanceVnd, updatedAt | wallet |
| Category | id, name, iconKey, applicableType, archivedAt? | transaction; planning tham chiếu categoryId |
| Transaction | id, clientOperationId, type, amountVnd, occurredAt, walletId, categoryId?, note?, receiptRefs, linkedBillId?, transferGroupId?, createdAt, updatedAt, version | transaction |
| Transfer | id, clientOperationId, sourceWalletId, destinationWalletId, amountVnd, occurredAt, note? | transaction điều phối; wallet cập nhật số dư |
| SalaryCycle | id, startDate, nextSalaryDate, timezone, configured/estimated status | planning |
| Budget | id, cycleId hoặc calendarMonth, categoryId, limitVnd | planning |
| Bill | id, title, dueDate, amountVnd, reservedVnd, unpaid/paid status, paidTransactionId? | planning |
| ProtectedAllocation | id, kind=bill/reserve/goal, amountVnd, linkedEntityId?, active status | planning |
| SavingsGoal | id, name, targetVnd, allocatedVnd, targetDate, dailySuggestionVnd, reminderDate?, status | planning |
| FinancialSnapshot | asOf, revision, dataStatus, totalBalanceVnd, protectedVnd, availableVnd, remainingDays?, dailyAvailableVnd?, cycleProgress? | shared/finance/application tổng hợp |
| PurchaseDraft | localDraftId, itemName, priceVnd, categoryId?, walletId?, snapshotRevision, cycleAssumption? | purchase_decision; chuyển bản nháp sang transaction |
| Reflection | id, transactionId, rating, note?, ratedAt, updatedAt | report |

Tên trường có thể điều chỉnh khi chốt API; ý nghĩa và invariant phải giữ. Transaction.type là expense/income/transfer. Chuyển ví có một transfer group với hai bút toán liên kết; UI liệt kê một sự kiện, không tạo hai dòng thu/chi. Repository đảm bảo không vừa lưu event vừa cộng lại hai bút toán khi tổng hợp.

## 3. Ba lớp tiền

- Tổng số dư B = tổng số dư các ví đang được tính trong phạm vi. B là số dư hiện tại, đã phản ánh giao dịch được ghi nhận.
- Tiền đã dành riêng P = tổng các khoản phân bổ đang hoạt động và không trùng nhau: hóa đơn chưa trả, dự phòng, mục tiêu nếu người dùng đã thực sự phân bổ.
- Còn để chi F = B − P. Không trừ lại tổng chi của chu kỳ khỏi B vì sẽ trừ hai lần.
- Mục tiêu vừa tạo nhưng chưa phân bổ tiền có allocatedVnd = 0; không làm giảm F.
- Một khoản dành riêng có thể liên kết hóa đơn hoặc mục tiêu, nhưng chỉ tính một lần vào P. Không cộng cả Bill.reservedVnd và allocation của cùng hóa đơn.
- Nếu P > B thì F âm; hiển thị thiếu hụt và đề nghị rà soát, không ép về 0.
- “Dành riêng” là ghi nhận trong ứng dụng, không có nghĩa tài khoản ngân hàng đã khóa tiền.

**Ví dụ ảnh:** B = 8.000.000; P = 3.500.000 hóa đơn + 2.400.000 dự phòng = 5.900.000; F = 2.100.000 đ.

Nếu trả hóa đơn 3.000.000 đ đã dành đủ tiền: ghi chi làm B giảm 3.000.000, đồng thời giải phóng đúng allocation làm P giảm 3.000.000. F không đổi. Hai bước phải nguyên tử hoặc có cơ chế đối soát; không đánh dấu đã trả mà bỏ quên giải phóng khoản dành riêng.

Nếu hóa đơn chỉ được dành một phần, giải phóng phần thực có; phần chi chưa được dành sẽ giảm F. Hóa đơn chưa thanh toán nhưng chưa dành tiền không tự giảm F; Tổng quan cần cảnh báo nghĩa vụ chưa được cấp đủ tiền.

## 4. Chu kỳ và bình quân ngày

- Khoảng chu kỳ: từ startDate (bao gồm) đến nextSalaryDate (không bao gồm).
- D là số ngày lịch từ hôm nay đến ngày lương kế tiếp, bao gồm hôm nay để chi, không bao gồm ngày lương.
- Với start=16/09/2026, today=02/10/2026, nextSalary=16/10/2026: tổng kỳ 30 ngày, đã qua 16 ngày, D=14, tiến độ khoảng 53%.
- F/ngày = F / D khi D > 0. Giá trị chỉ là mức bình quân của khoản còn lại; không phải cam kết mức chi.
- Giá trị dẫn xuất hiển thị xấp xỉ đến 100 đ với ký hiệu “khoảng” hoặc “~”; phép tính tiếp theo luôn dùng tiền gốc chưa làm tròn.
- 2.100.000 / 14 = 150.000 đ/ngày; sau khoản mua 900.000: F'=1.200.000, F'/14 ≈ 85.700 đ/ngày.
- Tác động/ngày của khoản chi 45.000 trong 14 ngày: giảm khoảng 3.200 đ/ngày; chuyển ví nội bộ: 0.
- D=0 hoặc âm: không chia; hiện “Đến ngày lương — cập nhật chu kỳ”. Không tự coi lương đã được nhận chỉ vì tới ngày dự kiến.
- Nếu thiếu mốc lương, D/daily/progress để trống có lý do. Mô phỏng được dùng giả định rõ ràng, không lưu giả định như dữ liệu thật.
- Khi đổi cách xem theo tháng, ngân sách dùng phạm vi tháng; “còn để chi đến ngày lương” vẫn dùng chu kỳ và được ghi nhãn riêng.

## 5. Ngân sách khác với tiền còn để chi

- Ngân sách còn lại = tổng hạn mức − tổng chi đủ điều kiện trong phạm vi. Có thể khác F vì F phụ thuộc số dư và tiền đã dành riêng.
- Ngân sách chỉ tính expense theo categoryId, loại chuyển ví ra khỏi chi tiêu.
- Đề xuất MVP: hóa đơn có linkedBillId được quản lý ở tab Hóa đơn, không tính lần nữa vào ngân sách chi tiêu tự do. Tổng chi thực tế ở lịch sử/báo cáo vẫn bao gồm khoản thanh toán hóa đơn.
- Một giao dịch chỉ thuộc một danh mục; hoàn tiền ghi income liên kết giao dịch gốc nếu cần, không âm hóa amount.
- Xóa/lưu trữ danh mục không xóa lịch sử; thay đổi tên vẫn tra được giao dịch đã có.
- Mẫu ngân sách: hạn mức 5.500.000, đã chi 3.400.000, còn 2.100.000, đã dùng ≈62%.
- Chi theo 4 danh mục: 1.850.000 + 420.000 + 880.000 + 250.000 = 3.400.000. Hạn mức: 2.500.000 + 600.000 + 1.000.000 + 1.400.000 = 5.500.000.
- Thông báo gần hạn mức đề xuất tại ≥80%; vượt hạn mức tại >100%. Trạng thái phải có chữ, không chỉ màu. Đây là ngưỡng UI cấu hình được, không phải lời khuyên tài chính.

## 6. Giao dịch và tổng ngày

- Expense giảm ví, income tăng ví. Chuyển A → B giảm A và tăng B cùng số tiền, tổng ví không đổi, không tính vào Thu/Chi của toàn bộ ứng dụng.
- Danh sách tất cả ví: totalExpense và totalIncome loại chuyển nội bộ. Có thể hiển thị net = income − expense nhưng phải ghi rõ nhãn.
- Khi lọc một ví, chuyển tiền hiển thị chiều vào/ra của ví đó, vẫn không cộng vào tổng “Chi tiêu”.
- Sửa/xóa giao dịch phải đảo ảnh hưởng cũ rồi áp dụng ảnh hưởng mới nguyên tử; cập nhật lại ngân sách, snapshot và báo cáo.
- Snapshot dùng cùng revision/asOf cho các giá trị trên một màn; không ghép số dư mới với allocation cũ.
- Lưu/sửa/xóa xong cần làm mới đúng nhóm dữ liệu phụ thuộc. Không tự cộng/trừ riêng trong từng widget rồi giữ nhiều phiên bản số dư.

## 7. Mô phỏng và nhật ký

- Mô phỏng không ghi ledger, không trừ tiền bảo vệ, không xác nhận thanh toán.
- F' = F − price; nếu F' < 0 thì báo thiếu. Nhấn ghi khoản mua chỉ chuyển PurchaseDraft sang editor.
- Để dành 900.000 trong 30 ngày → gợi ý 30.000 đ/ngày. Chỉ tạo kế hoạch/nhắc nhở; không tự tạo 30 giao dịch hoặc allocation.
- Giao dịch expense đủ 7 ngày lịch tại múi giờ nghiệp vụ mới đủ điều kiện đánh giá; bỏ qua không làm thay đổi giao dịch.
- Mỗi transaction có tối đa một Reflection hiện hành; cho sửa, không tạo bản trùng khi retry.
- Rating: worth_it / neutral / reconsider. Bỏ qua là trạng thái xử lý danh sách riêng, không phải rating.
- Thống kê tuần dùng 7 ngày liên tiếp và hai tuần có độ dài bằng nhau. Tuần trước chi 0 thì không chia %; hiển thị số tăng/giảm tuyệt đối.
- Đề xuất ngưỡng tối thiểu cho insight: 10 đánh giá hợp lệ trong tập đang so sánh; dưới ngưỡng chỉ trình bày thống kê mô tả. Nhóm xác nhận ngưỡng sản phẩm khi triển khai.
- Xóa giao dịch: bỏ khỏi chi tiêu và tập insight, xử lý Reflection liên quan nhất quán. Sửa ngày/loại giao dịch: tính lại eligibility và tập thống kê.

## 8. Ranh giới tích hợp backend

Nhóm backend/frontend cần chốt endpoint thật, schema lỗi, phân trang, quy tắc ownership theo tài khoản, idempotency, version/concurrency và cách đối soát timeout trước khi nối dữ liệu.

Không đưa chi tiết MongoDB vào domain. Giữ việc map _id/id và ISO timestamp ở data. Không coi MongoDbHelper hoặc Dio có sẵn là bằng chứng backend đã hoạt động.
