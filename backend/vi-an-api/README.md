# Ví An — Backend API

Backend Node.js + Fastify + MongoDB cho sáu màn hình Ví An và các luồng trong `Luồng nghiệp vụ APP.docx`. Dùng lại database `vi_an`, tên collection và BSON ObjectId/Long của bộ MongoDB trước đó. Số liệu trả về được tính từ database; không gán cố định các con số trên ảnh giao diện.

Đọc `API_UI_MAPPING.md` để ghép từng nút với API, `API_REFERENCE.md` để tra toàn bộ endpoint. `openapi.json` có thể import vào Postman. Thư mục `examples/` chứa response thật từ bộ dữ liệu kiểm thử, không phải dữ liệu trên máy của bạn.

## 1. Chạy MongoDB trên Mac

Backend cần MongoDB replica set để cập nhật giao dịch, số dư, hóa đơn trong cùng một transaction. Chỉ cần một node cho máy phát triển. Không chạy hai tiến trình `mongod` trên cùng thư mục dữ liệu.

Kiểm tra bằng **Terminal của macOS**, không nhập lệnh shell vào ô Filter trong Compass:

```bash
mongosh "mongodb://127.0.0.1:27017" --quiet --eval 'db.hello()'
```

Nếu kết quả có `setName: 'rs0'` và `isWritablePrimary: true`, bỏ qua phần chuyển đổi. Nếu tên replica set khác, dùng đúng tên đó trong `MONGODB_URI` ở `.env`.

Nếu bạn đang chạy bằng `mongod --dbpath ~/data/db`, quay lại Terminal đang chạy MongoDB và nhấn **Ctrl+C** để dừng, rồi chạy lại với **cùng thư mục dữ liệu**:

```bash
mongod --dbpath "$HOME/data/db" --replSet rs0 --bind_ip localhost
```

Giữ Terminal này mở. Mở Terminal thứ hai và khởi tạo replica set **một lần**:

```bash
mongosh "mongodb://127.0.0.1:27017" --eval 'rs.initiate({_id:"rs0",members:[{_id:0,host:"localhost:27017"}]})'
```

Kiểm tra đến khi kết quả là `true`:

```bash
mongosh "mongodb://127.0.0.1:27017" --quiet --eval 'db.hello().isWritablePrimary'
```

`AlreadyInitialized` nghĩa là đã khởi tạo; dùng lệnh kiểm tra thay vì khởi tạo lại. Nếu MongoDB được Homebrew chạy như dịch vụ, cập nhật cấu hình dịch vụ đang dùng với `replication.replSetName: rs0` rồi restart chính dịch vụ đó. Giữ nguyên `storage.dbPath`; không dùng lệnh chạy tay ở trên khi dịch vụ còn chiếm cổng 27017.

Nếu không chắc MongoDB dùng thư mục nào, xem `parsed.storage.dbPath` bằng lệnh này **trước khi dừng**:

```bash
mongosh "mongodb://127.0.0.1:27017" --quiet --eval 'db.adminCommand({getCmdLineOpts:1}).parsed'
```

Hướng dẫn chuyển đổi chính thức: https://www.mongodb.com/docs/manual/tutorial/convert-standalone-to-replica-set/

## 2. Chạy backend

Giải nén để có thư mục `vi-an-api` trên Desktop. Cần Node.js 22 trở lên; kiểm tra `node -v`. Nếu chưa có Node, có thể cài bằng Homebrew: `brew install node`.

```bash
cd ~/Desktop/vi-an-api
npm ci
npm run setup:env
npm run db:init
npm start
```

- `setup:env` tạo `.env` và secret ngẫu nhiên; không ghi đè `.env` đã có.
- `db:init` cập nhật validator/index và thêm các collection API; không xóa hay tạo lại dữ liệu tài chính. Server cũng kiểm tra schema khi khởi động.
- **Đã có dữ liệu An thì không chạy seed.** `npm run db:seed` chỉ dành cho database trống; script từ chối khi đã có người dùng/ví/giao dịch.
- Không cần chạy lại các file `02-seed.js`, `03-queries.js`, `04-check-demo.js` cũ để chạy API.

Mở:

- Swagger thử API: http://127.0.0.1:3000/docs
- Kiểm tra server: http://127.0.0.1:3000/health — cần `transactionCapable: true`.
- OpenAPI: http://127.0.0.1:3000/openapi.json

`.env` mặc định:

```dotenv
HOST=127.0.0.1
PORT=3000
MONGODB_URI=mongodb://127.0.0.1:27017/?replicaSet=rs0
MONGODB_DB=vi_an
JWT_SECRET=<được tạo tự động>
CORS_ORIGINS=http://localhost:5173,http://localhost:3001,http://127.0.0.1:5173
ALLOW_DEMO_LOGIN=true
JOBS_ENABLED=true
NODE_ENV=development
```

Nếu frontend chạy cổng khác, bổ sung đúng origin vào `CORS_ORIGINS`, rồi restart backend. Compass có thể kết nối bằng cùng `MONGODB_URI`.

## 3. Thử API với dữ liệu An đã có

Trong Swagger:

1. Mở **Auth → POST /api/v1/auth/demo → Try it out**, nhập `{}` và Execute.
2. Sao chép `data.accessToken`.
3. Nhấn **Authorize**, dán token vào ô bearerAuth, không thêm chữ `Bearer`.
4. Chạy **Screens → GET /api/v1/dashboard**.
5. Với API ghi dữ liệu, nhập `Idempotency-Key` khác nhau cho mỗi thao tác, ví dụ `them-bua-an-20261003-001`.

Demo chỉ đăng nhập người dùng `authSubject: "demo:an"` và chỉ được server cho phép trên localhost ở môi trường development. Tài khoản thật dùng `POST /auth/register`, sau đó `POST /auth/login`. Token hết hạn sau một ngày; `POST /auth/logout-all` thu hồi các token hiện tại.

Ví dụ body thêm khoản chi; thay ID bằng dữ liệu từ `/screens/add-transaction` nếu không dùng seed An:

```json
{
  "type": "expense",
  "amount": "50000",
  "walletId": "000000000000000000000002",
  "categoryId": "00000000000000000000000a",
  "occurredAt": "2026-10-03T10:30:00+07:00",
  "note": "Ăn trưa",
  "trackReview": true
}
```

`POST /api/v1/transactions` tự trừ số dư ví. **Không chạy thêm query `$inc` trừ tiền trong Compass.** Khi thử sau ngày trên, nên dùng thời điểm thực tế của giao dịch. Backend từ chối thời gian tương lai hoặc trước ngày mở ví.

## 4. Kết nối frontend

Copy `frontend/vi-an-client.js` vào dự án frontend. File này dùng Fetch, chạy với React, Vue hoặc JavaScript thuần. Cách gọi:

```js
import { createViAnClient, formatVnd } from "./vi-an-client.js";

let accessToken;
const api = createViAnClient({ getToken: () => accessToken });
const auth = await api.demoLogin(); // Local; tài khoản thật dùng api.login(...).
accessToken = auth.accessToken;

const dashboard = await api.dashboard();
console.log(formatVnd(dashboard.available));

const form = await api.transactionForm();
// Người dùng chọn walletId/categoryId từ form.wallets/form.categories.
```

Khi lưu: giữ nguyên **body và key** cho mọi lần thử lại của cùng yêu cầu. Tạo key ở lúc bắt đầu thao tác, không tạo key mới trong vòng retry. `occurredAt` cũng phải giữ nguyên. Sau khi thành công, tải lại các phần bị ảnh hưởng: dashboard, wallets, transactions, plans, review.

Có sẵn trang thử kết nối. Giữ backend chạy, mở Terminal mới:

```bash
cd ~/Desktop/vi-an-api
npm run frontend:example
```

Mở http://127.0.0.1:5173. Trang này đọc được sáu màn hình và có form tạo khoản chi **thật** vào database đang kết nối. Đây là trang kiểm tra tích hợp; giao diện thiết kế của bạn dùng cùng API/client.

## 5. Quy ước API

Base URL: `http://127.0.0.1:3000/api/v1`.

| Nội dung      | Quy ước                                                                                                               |
| ------------- | --------------------------------------------------------------------------------------------------------------------- |
| Xác thực      | `Authorization: Bearer <accessToken>`; lấy userId từ token, không nhận userId tùy ý trong body                        |
| Ghi dữ liệu   | Header `Idempotency-Key`, dài 8–128 ký tự; cùng key + body trả lại kết quả cũ; khác body trả 409                      |
| Ngoại lệ key  | Đăng ký/đăng nhập và API mô phỏng/so sánh không yêu cầu key; mô phỏng không ghi số dư                                 |
| Thành công    | HTTP 200, `{ "data": ... }`; CSV và ảnh là dữ liệu thô                                                                |
| Tiền          | Chuỗi số nguyên VND như `"50000"`; MongoDB lưu BSON Long; các tổng có thể âm; không dùng số thực                      |
| ID            | Chuỗi ObjectId 24 ký tự hex; tên trường trong response là `_id`                                                       |
| Thời gian     | ISO 8601 kèm timezone; response UTC; ngày trên giao diện tính theo Asia/Ho_Chi_Minh                                   |
| Khoảng ngày   | `startAt` bao gồm, `endAt` không bao gồm; ngày 03/10 dùng `[03/10 00:00+07, 04/10 00:00+07)`                          |
| Phân trang    | `limit` từ 1 đến 100, `nextCursor` opaque; cursor đi cùng các bộ lọc ban đầu                                          |
| Sửa giao dịch | PUT gửi đủ nội dung + `expectedVersion`; hủy/khôi phục cũng cần version hiện tại                                      |
| Lỗi           | `{ "error": { "code": "...", "message": "...", "details": ... }, "requestId": "..." }`; details/requestId có thể vắng |

Các lỗi cần hiển thị: `VERSION_CONFLICT` → tải lại trước khi sửa; `INSUFFICIENT_BALANCE` → đổi ví/số tiền; `ALLOCATED_FUNDS` → giải phóng phân bổ mục tiêu; `IDEMPOTENCY_CONFLICT` → kiểm tra body/key; HTTP 401 → đăng nhập lại; HTTP 400/422 → sửa dữ liệu form; `REPLICA_SET_REQUIRED` → cấu hình replica set.

## 6. Quy tắc đã triển khai

- Còn để chi = tổng số dư ví active − hóa đơn unpaid đến trước ngày lương (gồm quá hạn) − phân bổ của mục tiêu active có protect. Ngày lương chưa nhận không được cộng vào số dư.
- Bình quân/ngày chia theo số ngày lịch Việt Nam tới ngày lương. Thiếu ngày lương hoặc ngày đã qua: trả `missingData` và `dailyReference: null`; frontend hiển thị lời nhắc cập nhật. Số âm giữ nguyên để hiển thị cảnh báo.
- Thu/chi/chuyển ví/điều chỉnh cập nhật sổ giao dịch và số dư trong transaction. Chuyển ví không làm tăng tổng tiền; điều chỉnh không tính vào thu nhập/chi tiêu báo cáo.
- Sửa đảo tác động cũ rồi áp dụng tác động mới. Hủy là `voided`, không xóa lịch sử. Hoàn tác kiểm tra lại số dư và các liên kết. Không cho ví âm.
- Phân bổ mục tiêu là một phần của tiền trong ví, không cộng thêm vào tổng tài sản. Mọi phân bổ phải được giảm rõ ràng trước khi tiêu vào phần tiền đó. `protect` quyết định phần nào bị trừ trong chỉ số “còn để chi”; việc tắt protect không tự xóa phân bổ. Đây là quy ước cần giữ đồng nhất ở UI.
- Thanh toán hóa đơn vừa ghi expense vừa đổi paid; dự phòng hóa đơn được giải phóng nên không trừ hai lần vào “còn để chi”. Link giao dịch có sẵn không trừ ví lần nữa. Hủy giao dịch trả hóa đơn về unpaid.
- Lưu mong muốn và mô phỏng không tạo chi phí. Mua ngay phải xác nhận mới ghi expense. Tạo kế hoạch để dành chưa phân bổ tiền tự động.
- Ngân sách tính từ expense posted trong kỳ, có cảnh báo và thông báo tại ngưỡng. Hai kỳ active cùng periodType không được chồng ngày.
- Review mặc định sau 7 ngày; người dùng có thể đánh giá sớm, sửa đánh giá hoặc bỏ qua. Khi hủy khoản chi, khoản đó không tham gia nhận xét/báo cáo.
- Gợi ý thói quen dùng tối thiểu 5 đánh giá trong một danh mục và tối đa 100 đánh giá gần nhất. Có evidenceTransactionIds; ít dữ liệu không kết luận. Chỉ thao tác apply được xác nhận mới tạo thử thách/đổi ngân sách.
- Scheduler khi server chạy: kiểm tra mỗi phút, sinh lịch mỗi ngày theo timezone người dùng, chuẩn bị hóa đơn tới một năm sau. Ngày 31 được kẹp về cuối tháng ngắn. Server tắt thì không chạy lịch; khởi động lại sẽ bổ sung các kỳ còn thiếu.

## 7. Dữ liệu cũ và giới hạn tích hợp

Migration giữ 14 collection nghiệp vụ gốc, thêm `auth_accounts`, `api_requests`, `audit_events`, `import_jobs`, `backup_previews`, `attachments`. Cho phép `nextPayday: null` để hỗ trợ bỏ qua onboarding. Không tự tái tính số dư từ seed vì seed chứa số dư mở kỳ và lịch sử phục vụ demo. Nếu từng thêm giao dịch bằng Compass mà chưa cập nhật ví, dùng API reconcile để đối chiếu số dư thực tế.

Ảnh hóa đơn PNG/JPEG/WebP: tối đa 2 MB/ảnh, 10 ảnh/giao dịch; upload base64 JSON; lưu Binary trong MongoDB. Chưa có OCR. Tải ảnh cần token; frontend dùng Blob URL, không gắn URL cần Authorization trực tiếp vào `<img src>`.

CSV: tối đa 500 dòng/lần nhập, 10.000 dòng/lần xuất. Preview đánh dấu nghi trùng, commit do người dùng chọn; toàn bộ batch cùng thành công hoặc rollback. CSV yêu cầu ID ví/danh mục và số tiền nguyên, không tự đoán tên ví, ngày tháng hoặc số tiền định dạng `50.000đ`.

Backup trong app: tối đa 10.000 bản ghi và 4 MB, gồm ảnh nên dễ chạm giới hạn. Bản sao có chữ ký của server, chỉ phục hồi vào cùng tài khoản và với cùng secret. Khôi phục **thay thế** dữ liệu tài chính của tài khoản sau preview/xác nhận; không phải merge. Đổi `JWT_SECRET` sẽ khiến bản sao cũ không xác minh được. Khôi phục/xóa dữ liệu thu hồi token; đăng nhập lại. Xóa giữ tài khoản đăng nhập, xóa dữ liệu tài chính. Với database lớn dùng công cụ backup MongoDB riêng.

Thông báo hiện là thông báo trong app qua `/notifications`; chưa kết nối FCM/APNs/email. `appLockEnabled` là thiết lập; PIN/Face ID/khóa ứng dụng cần frontend và cơ chế khóa của nền tảng. `/recommendations` hiện dùng quy tắc và phép tính, không gọi LLM, không tra giá sản phẩm ngoài mạng. Chưa có đồng bộ ngân hàng. Các điểm này được trả/ghi rõ để frontend không mô tả chức năng chưa kết nối là đã hoạt động.

Khi triển khai ra mạng: tắt demo, dùng tài khoản thật, cấu hình MongoDB có xác thực/TLS và API sau HTTPS, đổi CORS theo frontend thực tế. Bản mặc định chỉ lắng nghe localhost, phục vụ phát triển và ghép giao diện.

## 8. Kiểm thử và cấu trúc

```bash
npm test
npm run test:integration
npm run docs:export
```

Integration test tự chạy MongoDB replica set tạm, không dùng URI/database của bạn. Lần đầu tải MongoDB 8.0.13 nên cần Internet; có thể đặt `MONGOMS_VERSION`, `MONGOMS_DOWNLOAD_DIR` nếu cần. Đã kiểm tra với Node.js 24 và MongoDB 8.0.13; chưa chạy trực tiếp trên MongoDB ở Mac của bạn.

`src/ledger.js`: quy tắc thay đổi số dư; `src/views.js`: tổng quan/báo cáo/mô phỏng; `src/routes-*.js`: REST; `src/signals.js`: cảnh báo/gợi ý; `src/jobs.js`: lịch hóa đơn; `src/migrate.js`: tương thích schema cũ; `test/`: kiểm thử; `frontend/`: ví dụ nối giao diện.

Tài liệu kỹ thuật tham khảo: [MongoDB transactions](https://www.mongodb.com/docs/drivers/node/current/fundamentals/transactions/), [Fastify validation](https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/), [Swagger plugin](https://github.com/fastify/fastify-swagger).
