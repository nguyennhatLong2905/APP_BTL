# Ghép sáu màn hình Ví An với API

Mọi đường dẫn bên dưới có tiền tố `/api/v1`. Response JSON có lớp ngoài `{ "data": ... }`; `vi-an-client.js` đã bỏ lớp ngoài đó. Các API ghi yêu cầu token và `Idempotency-Key` (trừ đăng ký/đăng nhập). Lấy `_id` và `version` từ server; không hard-code ID ngoài chế độ demo.

## Tổng quan

| Thành phần / thao tác trên giao diện   | API và trường cần dùng                                                                            |
| -------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Lời chào, số tiền còn để chi, mức/ngày | `GET /dashboard`: displayName, available, dailyReference, daysRemaining, nextPayday               |
| Mở phần giải thích “Cách tính”         | total, unpaidBills, protectedMoney, wallets, bills trong cùng response                            |
| Ví tiền mặt/ngân hàng                  | wallets[].name, balance, type; thêm ví bằng `POST /wallets`                                       |
| Ba giao dịch gần đây                   | recentTransactions; đã có category/wallet name và icon                                            |
| Hóa đơn sắp tới                        | bills; UI có thể lấy hai khoản đầu; nút xem hết dùng `GET /bills`                                 |
| Ẩn/hiện số tiền                        | `PATCH /me` body `{ "settings": { "hideAmounts": true } }`; frontend che số ở tất cả màn hình     |
| Đổi ngày lương                         | `PATCH /me` body `{ "nextPayday": "2026-10-16T00:00:00+07:00" }`                                  |
| Thiếu thông tin ban đầu                | missingData; chuyển tới form tạo ví/đặt ngày lương; null không hiển thị thành 0                   |
| Chuông thông báo                       | unreadNotifications; danh sách `GET /notifications`, đọc `POST /notifications/:id/read` body `{}` |

Không tự tính lại “còn để chi” trên frontend từ các card rời. `available` có thể âm. Lương dự kiến không phải giao dịch income.

## Thêm giao dịch

| Thành phần / thao tác                                    | API                                                                                                   |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Danh mục có biểu tượng, ví, giá trị nhanh, ngày mặc định | `GET /screens/add-transaction`: categories, wallets, quickAmounts, defaultWalletId, defaultOccurredAt |
| Chọn chi / thu / chuyển ví                               | type = expense / income / transfer; category.kind phải khớp loại thu/chi                              |
| Ảnh hóa đơn                                              | `POST /attachments` → `_id`; đưa vào attachmentIds khi lưu khoản chi                                  |
| Hiển thị “sau khoản chi này còn bao nhiêu/ngày”          | `POST /simulations/purchase` body `{ "price": "50000" }`; dùng availableAfter, dailyAfter             |
| Lưu giao dịch                                            | `POST /transactions`; server cập nhật ví cùng transaction                                             |
| Theo dõi đáng tiền                                       | `trackReview: true` tạo reflection và lịch nhắc theo thiết lập                                        |
| Thành công / hoàn tác                                    | Lưu response `_id`, `version`; nút hoàn tác gọi `POST /transactions/:id/void` với expectedVersion     |

Ví dụ chuyển ví:

```json
{
  "type": "transfer",
  "amount": "100000",
  "fromWalletId": "000000000000000000000003",
  "toWalletId": "000000000000000000000002",
  "occurredAt": "2026-10-03T10:30:00+07:00",
  "note": "Rút tiền mặt"
}
```

Chuyển ví không có walletId/categoryId. Income và expense có walletId/categoryId. Đối chiếu dùng `POST /wallets/:id/reconcile` với actualBalance, expectedVersion, note; không sửa trực tiếp wallet.balance.

## Lịch sử giao dịch

`GET /screens/transactions?limit=30&walletId=...&startAt=...&endAt=...`

| Thành phần / thao tác       | Trường / API                                                                   |
| --------------------------- | ------------------------------------------------------------------------------ |
| Dòng giao dịch              | items[].type, amount, occurredAt, note, category, wallet, fromWallet, toWallet |
| Nhóm theo ngày và tổng tiền | groups[].date, items, totalExpense, totalIncome                                |
| Tải thêm                    | nextCursor; truyền lại cùng bộ lọc; gộp nhóm có cùng date                      |
| Tìm ghi chú                 | search; là chuỗi literal, không phải regex MongoDB                             |
| Tìm đúng số tiền            | amount, ví dụ amount=50000; UI có thể chuyển input số sang bộ lọc này          |
| Lọc danh mục, ví, loại      | categoryId, walletId, type; walletId cũng khớp ví nguồn/đích khi chuyển        |
| Giao dịch đã hủy            | status=voided; mặc định posted                                                 |
| Mở chi tiết                 | `GET /transactions/:id`                                                        |
| Sửa                         | `PUT /transactions/:id` gửi đầy đủ trường giao dịch + expectedVersion          |
| Hủy / hoàn tác hủy          | `POST /transactions/:id/void` hoặc `/restore`, body `{ "expectedVersion": 2 }` |
| Xuất CSV                    | `GET /exports/transactions.csv` với startAt/endAt/walletId nếu cần             |

`totalExpense/totalIncome` là tổng **cả ngày trong bộ lọc**, kể cả khi chỉ tải một trang; không cộng lại các total khi tải trang tiếp theo. `pageExpense/pageIncome` chỉ tính các dòng trong trang. Sau edit/void/restore: thay dữ liệu bằng response mới, tải lại tổng quan và kế hoạch; gặp 409 VERSION_CONFLICT thì tải lại trước khi cho sửa tiếp. PUT bỏ attachmentIds sẽ giữ ảnh hiện có; gửi `[]` để gỡ liên kết tất cả ảnh.

## Kế hoạch chi tiêu

`GET /screens/plans` trả overview, budgets, goals, bills, categories phục vụ ba tab.

| Tab / thao tác                   | API và quy tắc                                                                                                                                 |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Ngân sách theo tháng/kỳ lương    | budgets[].periodType, startAt/endAt; limits[].limit, spent, remaining, percent, warning                                                        |
| Tạo/sửa hạn mức                  | `POST /budgets`, `PUT /budgets/:id`; PUT gửi toàn bộ limits của kỳ                                                                             |
| Kết thúc kỳ                      | `POST /budgets/:id/close`, body `{}`                                                                                                           |
| Mục tiêu tiết kiệm               | goals[].targetAmount, allocated, percent, targetAt, protect                                                                                    |
| Tạo / sửa mục tiêu               | `POST /goals`, `PATCH /goals/:id`                                                                                                              |
| Thêm tiền vào quỹ                | `PUT /goals/:id/allocation` body `{ "walletId": "...", "amount": "300000" }`; amount là **tổng phân bổ mới** trong ví, không phải số cộng thêm |
| Rút phân bổ                      | Cũng endpoint allocation với tổng mới thấp hơn hoặc `"0"`                                                                                      |
| Bật/tắt quỹ bảo vệ               | `PATCH /goals/:id` body `{ "protect": false }`; trả availableBefore/availableAfter để giải thích tác động; phân bổ vẫn tồn tại                 |
| Hóa đơn định kỳ                  | `POST /bill-templates`; sinh bill_occurrences theo lịch, không sinh giao dịch chi                                                              |
| Sửa một kỳ hóa đơn               | `PATCH /bills/:id` amount/dueAt/status                                                                                                         |
| Thanh toán                       | `POST /bills/:id/pay` walletId, occurredAt, amount thực tế nếu khác dự tính                                                                    |
| Đã ghi khoản chi ở màn hình khác | `POST /bills/:id/link-transaction` transactionId, expectedVersion; không tạo khoản chi thứ hai                                                 |
| Ngừng lịch lặp                   | `PATCH /bill-templates/:id` active=false; cancelFutureUnpaid=true nếu muốn hủy các kỳ tương lai chưa trả                                       |

Khi hoàn thành hoặc lưu trữ mục tiêu cần giải phóng phân bổ trước. Tạo mục tiêu không tự giữ toàn bộ targetAmount: chỉ khoản đã phân bổ mới là tiền hiện có của mục tiêu.

## Mua hay chờ

| Thành phần / thao tác                   | API                                                                                                              |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Nhập giá, xem trước/sau                 | `POST /simulations/purchase` price; response before.available, availableAfter, before.dailyReference, dailyAfter |
| Mô phỏng thanh toán hóa đơn đã dự phòng | Thêm billOccurrenceId; dùng releasedReservation để giải thích phần dự phòng được giải phóng                      |
| Danh sách đang cân nhắc                 | `GET /purchases`; chi tiết và số liệu cập nhật `GET /purchases/:id`                                              |
| Để sau, đặt ngày nhắc                   | `POST /purchases` name, price, categoryId, remindAt; `PATCH /purchases/:id` để thay đổi                          |
| Kế hoạch 30.000đ/ngày                   | `POST /purchases/:id/saving-plan` targetAt, dailySaving; tạo goal nhưng chưa phân bổ tiền                        |
| Đã quyết định mua                       | `POST /purchases/:id/buy` walletId, occurredAt, trackReview; tạo đúng một expense                                |
| Lương về muộn                           | `POST /simulations/salary-delay` delayDays; không sửa ngày lương thực tế                                         |
| Giá theo giờ công                       | `PATCH /me` settings.workIncome/workHours, sau đó `POST /simulations/work-hours` price                           |
| Bớt một thói quen                       | `POST /simulations/habit` amountPerOccurrence, occurrencesPerWeek, weeks, reductionPercent                       |
| Cân nhắc các lựa chọn                   | `POST /recommendations` question, options, minimumDaily; engine=rules, trả số liệu và lý do                      |

Frontend yêu cầu người dùng xác nhận trước khi gọi buy. Không gọi buy từ câu trả lời gợi ý tự động. Khi availableAfter âm hoặc thiếu dữ liệu, hiển thị lý do; bản mô phỏng không cam kết ví được chọn có đủ tiền tại lúc mua. Server sẽ kiểm tra lại lúc ghi.

## Nhìn lại — Nhật ký đáng tiền

`GET /screens/review?startAt=...&endAt=...` trả report, reflections, patterns, insights, categories.

| Thành phần / thao tác                  | API / trường                                                                                                      |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Tổng chi tuần và so kỳ trước           | report.expense, previousExpense, expenseChangePercent; kỳ trước có cùng độ dài                                    |
| Biểu đồ danh mục                       | report.byCategory; frontend nối categoryId với categories                                                         |
| Danh sách khoản cần nhìn lại           | reflections[].transaction, dueAt, status; frontend chia “đến hạn” / “sắp tới”                                     |
| Đáng tiền / bình thường / cân nhắc lại | `PUT /reflections/:id` status=rated, rating=worth_it / neutral / reconsider, note                                 |
| Để sau / bỏ qua                        | `PUT /reflections/:id` status=skipped; không tạo rating giả                                                       |
| Theo dõi khoản cũ                      | `POST /reflections` transactionId                                                                                 |
| Làm mới gợi ý từ đánh giá              | `POST /insights/generate` body `{}` sau khi người dùng yêu cầu hoặc lưu review                                    |
| “Tăng ngân sách học tập”               | Với insight action=adjust_budget: hiển thị form chọn kỳ/hạn mức rồi `POST /insights/:id/apply` budgetId, newLimit |
| “Thử khoảng lặng 48h”                  | Với insight action=start_challenge: xác nhận rồi `POST /insights/:id/apply` body `{}`                             |
| Ẩn gợi ý                               | `POST /insights/:id/dismiss` body `{}`                                                                            |
| Theo dõi/dừng thử thách                | `GET /challenges`, `POST /challenges/:id/cancel` body `{}`                                                        |

Không dùng câu kết luận mẫu trong ảnh khi dữ liệu chưa đủ. Response có số lượng mẫu và evidenceTransactionIds để mở các khoản chi liên quan. Chênh lệch phần trăm là null nếu kỳ trước bằng 0; frontend dùng thông điệp “chưa có kỳ so sánh”.

## Luồng phụ trong Word

Onboarding: register → PATCH /me ngày lương (có thể để null) → POST /wallets → tùy chọn POST /goals/bill-templates. Ví mở đầu có openingBalance, không tạo income giả. Quỹ mùa vụ dùng POST /seasonal-goals.

Nhập CSV: POST /imports/preview → cho xem từng dòng lỗi/nghi trùng → POST /imports/:id/commit với selectedRows và includeSuspectedDuplicates nếu người dùng xác nhận. Mỗi index bắt đầu từ 0, không phải số dòng trong Excel.

Backup: GET /backup → frontend tải nguyên JSON → POST /backup/preview khi muốn khôi phục → cho xem counts và confirmationText → POST /backup/:previewId/restore với confirmation chính xác. Không gửi thẳng tệp vào MongoDB.

Xóa dữ liệu: POST /data/erase-preview → hiển thị số lượng và yêu cầu xác nhận → POST /data/:previewId/erase. Sau xóa/restore cần đăng nhập lại. Không đặt hai bước này trong hàm tự chạy khi mở màn hình.

UI khóa app đọc/ghi settings.appLockEnabled; việc xác thực PIN/sinh trắc học thực hiện ở frontend/nền tảng. Hành vi push/email/AI ngoài ứng dụng cần kết nối nhà cung cấp như đã ghi trong README.
