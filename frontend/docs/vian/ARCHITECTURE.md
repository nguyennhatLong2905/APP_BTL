# Kiến trúc và thư mục bàn giao

## Ánh xạ 6 màn hình

| Màn trong ảnh | Module | Chỗ làm UI | Route đề xuất |
|---|---|---|---|
| Tổng quan | `home` hiện có | `lib/features/home/presentation/` | `/home` |
| Lịch sử giao dịch | `transaction` hiện có | `presentation/screens/history/`, `widgets/history/` | `/transactions` |
| Thêm giao dịch | Cùng `transaction` | `presentation/screens/editor/`, `widgets/editor/` | `/transactions/new` |
| Kế hoạch chi tiêu | `planning` mới | `lib/features/planning/presentation/` | `/planning` |
| Mua hay chờ | `purchase_decision` mới | `lib/features/purchase_decision/presentation/` | `/purchase-decision` |
| Nhìn lại — Nhật ký đáng tiền | `report` hiện có | `lib/features/report/presentation/` | `/reflection` |

Route là hợp đồng đề xuất, chưa được nối vào `core/router/app_router.dart`. Giữ `home`, `transaction`, `wallet`, `report` để tận dụng base. Màn placeholder hiện có vẫn nằm nguyên vị trí; người tích hợp quyết định thay nội dung hoặc chuyển sang entry màn mới trong giai đoạn code.

## Các vị trí dùng chung

| Vị trí | Trách nhiệm | Không đặt ở đây |
|---|---|---|
| `core/router/` | Route, redirect, điều hướng tab | Phép tính tiền |
| `core/ui/layouts/` | Shell 4 tab, SafeArea, khung màn hành động | Fetch dữ liệu tài chính |
| `core/ui/finance/` | Cách hiển thị tiền, trạng thái, thanh tiến độ dùng chung | Tự tính ngân sách hoặc số dư |
| `core/theme/` | Màu, chữ, spacing và theme | Copy token riêng trong từng màn |
| `core/network/`, `core/storage/` | Hạ tầng truy cập và lưu trữ | Quy tắc hóa đơn hoặc chuyển ví |
| `shared/finance/domain/` | Money VND, chu kỳ, snapshot và phép tính thuần dùng chung | Flutter, Riverpod, HTTP, BuildContext |
| `shared/finance/application/` | Tổng hợp snapshot từ các đầu vào chuẩn hóa; điều phối cập nhật sau thao tác | Widget hoặc gọi trực tiếp datasource của feature |
| `shared/finance/providers/` | Nối reader domain của wallet/transaction/planning vào bộ tổng hợp | Một kho dữ liệu tài chính thứ hai |
| `features/wallet/` | Ví, số dư, đọc thay đổi ledger và cập nhật nguyên tử | Bản sao lịch sử giao dịch riêng |

## Cấu trúc feature ghi dữ liệu

```text
feature/
├── README.md
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── providers/                 # Nối datasource/repository/use case
└── presentation/
    ├── providers/             # Trạng thái và hành động của màn
    ├── screens/
    └── widgets/
```

Đã chuẩn bị cấu trúc này cho transaction, wallet, planning, purchase_decision và report. Home chỉ cần domain/entities, domain/usecases, providers và presentation để đọc dữ liệu tổng hợp; không tạo thêm kho số dư của home.

## Chiều phụ thuộc

Presentation gọi use case/domain; data triển khai interface domain. Provider của module nối các lớp. Domain không biết Flutter, Riverpod hoặc datasource.

Feature chỉ dùng dữ liệu feature khác qua interface domain; không import màn, UI provider hoặc repository implementation của nhau. Riêng `shared/finance/providers` là điểm ghép các reader domain và reader provider công khai của wallet/transaction/planning; tuyệt đối không ghép ngược finance snapshot vào reader đó để tránh vòng phụ thuộc.

- Wallet sở hữu dữ liệu ví; transaction sở hữu giao dịch và lệnh ghi ledger.
- Planning sở hữu chu kỳ lương, ngân sách, hóa đơn, mục tiêu và khoản dành riêng.
- Shared finance nhận giá trị chuẩn hóa và tạo snapshot; chỉ một implementation cho phép tính “còn để chi”.
- Home đọc snapshot, hóa đơn gần đến hạn và giao dịch gần đây.
- Purchase decision đọc snapshot, mô phỏng thuần, chuyển bản nháp sang editor hoặc yêu cầu planning tạo mục tiêu.
- Report đọc giao dịch, lưu cảm nhận riêng; điều chỉnh ngân sách phải qua planning.

## Điều hướng

- 4 tab chính: Tổng quan, Giao dịch, Kế hoạch, Nhìn lại; mỗi tab giữ vị trí cuộn/bộ lọc khi chuyển tab.
- Nút “+” là hành động mở editor, không phải tab thứ năm.
- Mua hay chờ là màn con mở từ Tổng quan, quay lại không tạo giao dịch.
- Editor có một cách đóng rõ ràng; có bản nháp thì hỏi bỏ thay đổi. Lưu thành công trả về nguồn mở và cập nhật dữ liệu liên quan.
- Profile, notifications, settings dùng module hiện có; chưa mở rộng phạm vi nếu không cần cho luồng chính.

## Tránh xung đột trong nhóm

Mỗi module có một người chịu trách nhiệm hợp đồng. History và editor có thể giao hai người nhưng dùng chung entity, repository và validation của transaction. Chỉ người phụ trách nền tích hợp sửa main/router/theme/pubspec/l10n và phần core dùng chung.

Các thư mục test đối ứng đã giữ chỗ. Chưa có test mới. Không chạy generator vào module được giao trước khi kiểm tra đường dẫn output và tên file, vì base có nhiều generator/template cũ.
