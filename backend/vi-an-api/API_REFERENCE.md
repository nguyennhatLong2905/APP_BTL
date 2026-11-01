# Danh mục API Ví An

75 operations. Header Authorization cần cho mọi API trừ /auth/register, /auth/login, /auth/demo. Cột Key là Idempotency-Key. Body, query, các model response chính và ví dụ nằm trong openapi.json hoặc Swagger /docs.

## Auth

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/auth/register` | Đăng ký tài khoản | Không |
| POST | `/api/v1/auth/login` | Đăng nhập | Không |
| POST | `/api/v1/auth/demo` | Token cho dữ liệu An trên máy local | Không |
| POST | `/api/v1/auth/logout-all` | Thu hồi toàn bộ token | Có |

## Profile

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/me` | Hồ sơ và thiết lập | Không |
| PATCH | `/api/v1/me` | Cập nhật ngày lương, ẩn số tiền và thiết lập | Có |

## Wallets

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/wallets` | Danh sách ví | Không |
| POST | `/api/v1/wallets` | Tạo ví với số dư ban đầu | Có |
| PATCH | `/api/v1/wallets/{id}` | Đổi tên hoặc lưu trữ ví | Có |
| POST | `/api/v1/wallets/{id}/reconcile` | Đối chiếu và tạo điều chỉnh số dư | Có |

## Categories

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/categories` | Danh mục thu chi | Không |
| POST | `/api/v1/categories` | Tạo danh mục | Có |
| PATCH | `/api/v1/categories/{id}` | Sửa/lưu trữ danh mục | Có |

## Transactions

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/transactions` | Tìm giao dịch và phân trang cursor | Không |
| POST | `/api/v1/transactions` | Ghi thu/chi/chuyển ví và cập nhật số dư atomically | Có |
| GET | `/api/v1/transactions/{id}` | Chi tiết giao dịch | Không |
| PUT | `/api/v1/transactions/{id}` | Sửa giao dịch và đảo tác động cũ | Có |
| POST | `/api/v1/transactions/{id}/void` | Hủy giao dịch và hoàn tiền về ví | Có |
| POST | `/api/v1/transactions/{id}/restore` | Hoàn tác hủy giao dịch | Có |

## Plans

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/budgets` | Các ngân sách và số đã chi | Không |
| POST | `/api/v1/budgets` | Tạo kỳ ngân sách | Có |
| PUT | `/api/v1/budgets/{id}` | Thay đổi hạn mức ngân sách | Có |
| POST | `/api/v1/budgets/{id}/close` | Đóng kỳ ngân sách | Có |

## Goals

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/goals` | Mục tiêu và tiến độ | Không |
| POST | `/api/v1/goals` | Tạo mục tiêu tiết kiệm | Có |
| PATCH | `/api/v1/goals/{id}` | Sửa mục tiêu hoặc bật/tắt bảo vệ | Có |
| PUT | `/api/v1/goals/{id}/allocation` | Đặt số tiền phân bổ của mục tiêu trong một ví | Có |
| POST | `/api/v1/seasonal-goals` | Lập quỹ Tết, học phí, hiếu hỉ | Có |

## Bills

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/bill-templates` | Lịch hóa đơn định kỳ | Không |
| POST | `/api/v1/bill-templates` | Tạo lịch hóa đơn và sinh các kỳ | Có |
| PATCH | `/api/v1/bill-templates/{id}` | Bật/tắt lịch lặp; tùy chọn hủy hóa đơn tương lai chưa trả | Có |
| GET | `/api/v1/bills` | Hóa đơn từng kỳ và trạng thái quá hạn | Không |
| PATCH | `/api/v1/bills/{id}` | Điều chỉnh hoặc hủy hóa đơn chưa trả | Có |
| POST | `/api/v1/bills/{id}/pay` | Thanh toán hóa đơn và trừ ví cùng một transaction | Có |
| POST | `/api/v1/bills/{id}/link-transaction` | Liên kết khoản chi đã ghi, không trừ ví lần nữa | Có |

## Notifications

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/jobs/run` | Sinh hóa đơn và lịch nhắc cho người dùng hiện tại | Có |
| GET | `/api/v1/notifications` | Thông báo trong app đã đến thời điểm hiển thị | Không |
| POST | `/api/v1/notifications/{id}/read` | Đánh dấu đã đọc | Có |

## Screens

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/dashboard` | Tổng quan, cách tính, hóa đơn và giao dịch gần đây | Không |
| GET | `/api/v1/screens/add-transaction` | Dữ liệu form thêm giao dịch | Không |
| GET | `/api/v1/screens/transactions` | Giao dịch với tên ví/danh mục và nhóm theo ngày | Không |
| GET | `/api/v1/screens/plans` | Ba tab ngân sách, mục tiêu, hóa đơn | Không |
| GET | `/api/v1/screens/review` | Báo cáo tuần, nhật ký đáng tiền và gợi ý | Không |

## Reports

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/reports` | Thu chi theo kỳ và so sánh kỳ trước | Không |

## Simulation

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/simulations/purchase` | Mua hay chờ: tính tác động, không ghi chi | Không |
| POST | `/api/v1/simulations/salary-delay` | Mô phỏng lương về muộn | Không |
| POST | `/api/v1/simulations/work-hours` | Quy đổi giá món hàng thành giờ công | Không |
| POST | `/api/v1/simulations/habit` | Thử giảm một thói quen chi tiêu | Không |

## Purchases

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/purchases` | Danh sách mong muốn | Không |
| POST | `/api/v1/purchases` | Lưu khoản mua để cân nhắc | Có |
| GET | `/api/v1/purchases/{id}` | Chi tiết khoản mua và tác động hiện tại | Không |
| PATCH | `/api/v1/purchases/{id}` | Sửa giá hoặc nhắc lại khoản mua | Có |
| POST | `/api/v1/purchases/{id}/buy` | Xác nhận mua và tạo giao dịch thực tế | Có |
| POST | `/api/v1/purchases/{id}/saving-plan` | Để dành mua sau: tạo mục tiêu, chưa phân bổ tiền | Có |

## Reflection

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| GET | `/api/v1/reflections` | Các khoản chi được theo dõi | Không |
| POST | `/api/v1/reflections` | Theo dõi khoản chi để đánh giá sau 7 ngày | Có |
| PUT | `/api/v1/reflections/{id}` | Lưu đánh giá hoặc bỏ qua | Có |
| GET | `/api/v1/insights` | Gợi ý đã lưu và căn cứ | Không |
| POST | `/api/v1/insights/{id}/dismiss` | Ẩn gợi ý | Có |
| GET | `/api/v1/challenges` | Các thử thách đang theo dõi | Không |
| POST | `/api/v1/challenges` | Kích hoạt khoảng lặng 48h hoặc thay đổi thói quen | Có |
| POST | `/api/v1/challenges/{id}/cancel` | Dừng thử thách | Có |
| POST | `/api/v1/insights/generate` | Sinh gợi ý từ tối thiểu 5 đánh giá thực tế mỗi danh mục | Có |
| POST | `/api/v1/insights/{id}/apply` | Xác nhận gợi ý: đổi hạn mức đã chọn hoặc tạo thử thách 48h | Có |

## Advice

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/recommendations` | So sánh các phương án bằng dữ liệu tài chính thật | Không |

## Attachments

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/attachments` | Tải ảnh hóa đơn PNG/JPEG/WebP tối đa 2 MB | Có |
| GET | `/api/v1/attachments/{id}` | Đọc ảnh hóa đơn có xác thực | Không |

## Data

| Method | Endpoint | Chức năng | Key |
|---|---|---|---|
| POST | `/api/v1/imports/preview` | Đọc CSV, ghép cột, kiểm tra lỗi và nghi trùng | Có |
| POST | `/api/v1/imports/{id}/commit` | Xác nhận các dòng được nhập, toàn bộ cùng thành công hoặc rollback | Có |
| GET | `/api/v1/exports/transactions.csv` | Xuất giao dịch CSV | Không |
| GET | `/api/v1/backup` | Tạo bản sao dữ liệu có chữ ký; không chứa thông tin đăng nhập | Không |
| POST | `/api/v1/backup/preview` | Xem tác động khôi phục bản sao của cùng người dùng | Có |
| POST | `/api/v1/backup/{id}/restore` | Khôi phục dữ liệu theo preview đã xác nhận | Có |
| POST | `/api/v1/data/erase-preview` | Xem phạm vi xóa toàn bộ dữ liệu tài chính của tài khoản | Có |
| POST | `/api/v1/data/{id}/erase` | Xóa dữ liệu tài chính sau khi xác nhận preview | Có |
