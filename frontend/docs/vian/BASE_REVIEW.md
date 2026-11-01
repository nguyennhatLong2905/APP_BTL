# Đánh giá base hiện tại

## Kết luận

Base phù hợp làm điểm khởi đầu cho nhóm Flutter: đã có feature-first, Riverpod, GoRouter, error/network/storage và test của auth/network/notifications. Base chưa sẵn sàng để ghép ngay 6 màn tài chính: màn chức năng còn khung, bộ UI chung phần lớn chưa triển khai, nghiệp vụ tiền và chu kỳ chưa có nguồn tính chung.

Không cần đổi framework hoặc tạo một bộ core thứ hai. Ưu tiên làm rõ hợp đồng tài chính, phân quyền sửa file chung và hoàn thiện phần nền đang thiếu trước khi tích hợp UI.

## Phương pháp và giới hạn

- Đọc mã, cấu hình, cây thư mục, test hiện có và đối chiếu 6 ảnh người dùng cung cấp.
- Kiểm kê trước chỉnh sửa: 168 file Dart trong `lib/`; 45 file chỉ chứa khoảng trắng, bao gồm các file `core/ui`, một số theme/cache/provider/generator.
- Git ban đầu sạch. Các file generated được tham chiếu bằng `part` đều có mặt trong checkout; chưa xác nhận nội dung còn đồng bộ với nguồn.
- Không tìm thấy `flutter` hoặc `dart` trong PATH của phiên làm việc. Chưa chạy analyze, test hoặc đo hiệu năng; các vấn đề dưới đây là bằng chứng tĩnh và rủi ro cần xác nhận khi chạy.

## Ưu tiên xử lý khi bước vào giai đoạn code

| Mức | Phát hiện và bằng chứng trong repo | Tác động / hướng xử lý |
|---|---|---|
| P0 | `lib/features/auth/data/datasources/auth_remote_data_source.dart` trả user mô phỏng; repository lưu `response.id` ở khóa token | Không coi là xác thực backend hoàn chỉnh. Tách demo và thật, dùng token đúng hợp đồng backend, kiểm tra khôi phục phiên |
| P0 | `core/network/offline_sync_service.dart` đánh dấu synced sau delay mô phỏng | Không dùng trạng thái đó làm bằng chứng giao dịch đã lên server. Chỉ xác nhận synced sau phản hồi hợp lệ |
| P0 | `core/network/interceptors/retry_interceptor.dart` chọn retry theo loại lỗi, không kiểm tra HTTP method hoặc khóa idempotency | Rủi ro gửi lại lệnh tạo giao dịch khi timeout. Chốt cơ chế chống ghi trùng trước khi bật retry cho thao tác ghi |
| P0 | `core/providers/network_providers.dart` bật log request/response header và body không có điều kiện debug tại đây | Khi triển khai auth thật, chặn log token, dữ liệu cá nhân và nội dung tài chính; không bật log đầy đủ ở bản phát hành |
| P0 | `workmanager`, `web_socket_channel`, `grpc`, `protobuf` được import ở các module mở rộng nhưng không khai báo trong `pubspec.yaml` | Kiểm tra dependency/analyze. Chọn giữ module và khai báo đúng, hoặc loại module không dùng ở một thay đổi code riêng; chưa sửa ở lần này |
| P0 | `lib/l10n/l10n.dart` và `l10n.yaml` chưa có locale `vi`; symbol tiền hiện theo locale và mặc định là USD | Cần tiếng Việt và formatter VND độc lập với ngôn ngữ. Không dùng formatter hiện tại cho số dư Ví An |
| P0 | Chưa có mô hình chung cho chu kỳ lương, tiền được bảo vệ, snapshot tài chính | Các màn dễ hiển thị số khác nhau. Dùng [hợp đồng chung](DATA_CONTRACTS.md) trước khi chia implementation |
| P1 | `home_screen.dart` là trang hồ sơ/demo; transaction/wallet/report là placeholder; router chưa đăng ký các màn tài chính đó | Chuẩn bị shell 4 tab, route hành động và khôi phục vị trí tab; tích hợp sau khi module đạt hợp đồng |
| P1 | `core/ui/*` phần lớn chỉ chứa khoảng trắng; `core/widgets/*` có một số widget thật | Chọn `core/ui` làm nơi triển khai UI chung cho Ví An, tái sử dụng phần phù hợp của widgets cũ; không giả định UI kit đã hoạt động |
| P1 | Có 2 vị trí Logger; có cache manager thật ở `core/storage/cache_manager.dart` và bộ khung ở `core/storage/cache/`; secure storage provider nằm cả core và auth | Chốt một điểm đăng ký cho từng service. Không xóa hàng loạt trước khi kiểm tra toàn bộ import |
| P1 | `main.dart` quản lý theme mode; router watch auth và locale để tạo GoRouter | Cần kiểm tra giữ stack/tab khi auth/locale thay đổi và vòng đời router; tránh mất bản nháp |
| P1 | Tài liệu cũ nêu SDK khác với `pubspec.yaml`; `pubspec.lock` đang bị ignore | README đã sửa yêu cầu Dart. Khi triển khai, chốt bản Flutter tương ứng và chính sách commit lockfile cho ứng dụng |
| P2 | Template có gRPC, webhook, websocket, generator, nhiều ngôn ngữ, update/background/analytics ngoài 6 màn | Hoãn mở rộng đến sau luồng chính. Đánh giá từng dependency và import trước khi dọn mã; không cài thêm package để giải quyết phần chưa dùng |

P0: xử lý trước tích hợp dữ liệu thật. P1: xử lý trước nghiệm thu nhóm. P2: hoàn thiện sau MVP.

## Những tối ưu đã thực hiện trong phạm vi không code

- Chỉnh README thành điểm vào đúng sản phẩm và đúng trạng thái base.
- Giữ tên module sẵn có; không tạo thêm dashboard, history, add_transaction hoặc reflection ở cấp feature gây trùng nghiệp vụ.
- Tạo vị trí cho planning, purchase_decision, finance dùng chung và các lớp còn thiếu của feature hiện có.
- Định nghĩa một phép tính tiền dùng chung, phân biệt ngân sách với số dư, quy định chuyển ví, hóa đơn, ngày lương và cách hiển thị thiếu dữ liệu.
- Đặc tả UI theo 6 ảnh, giảm tràn chữ, làm rõ CTA, trạng thái rỗng/lỗi/đang lưu và khả năng đọc trên màn nhỏ.
- Chép nguyên bản 6 ảnh vào thư mục tham chiếu để thành viên không phụ thuộc thư mục Downloads của một máy.

## Việc chưa thực hiện

Chưa sửa Dart, pubspec, router, theme, l10n, platform, backend, cấu hình test hoặc dependency. Chưa xóa module template, chưa sinh mã, chưa tạo test thực thi, chưa commit/push. Tối ưu hiệu năng chạy thực tế cần thực hiện và đo trong giai đoạn code.
