# Ví An — Base ứng dụng quản lý chi tiêu

Flutter · Riverpod · GoRouter · Clean Architecture theo feature.

Base hiện có auth mô phỏng, hạ tầng network/storage và các màn tài chính khung. Bộ 6 giao diện người dùng cung cấp đã được rà soát, tối ưu thành đặc tả và chia sẵn thư mục để nhóm triển khai.

**Lần chuẩn bị này chỉ thay đổi tài liệu, ảnh tham chiếu và thư mục giữ chỗ; chưa viết hoặc sửa mã chức năng.**

## Bắt đầu từ bộ bàn giao

- [Đánh giá base, vấn đề ưu tiên](docs/vian/BASE_REVIEW.md).
- [Đặc tả tối ưu 6 màn](docs/vian/UI_UX_SPEC.md).
- [Kiến trúc và thư mục](docs/vian/ARCHITECTURE.md).
- [Hợp đồng dữ liệu, chu kỳ và phép tính tiền](docs/vian/DATA_CONTRACTS.md).
- [Phân công, thứ tự triển khai và tích hợp](docs/vian/TEAM_HANDOFF.md).
- [Checklist nghiệm thu](docs/vian/ACCEPTANCE_CHECKLIST.md).
- [6 ảnh tham chiếu nguyên bản](docs/vian/references/README.md).

## Chỗ code cho các thành viên

| Màn / phần chung | Thư mục |
|---|---|
| Tổng quan | [lib/features/home](lib/features/home/README.md) |
| Lịch sử và Thêm giao dịch | [lib/features/transaction](lib/features/transaction/README.md) |
| Kế hoạch: ngân sách, mục tiêu, hóa đơn | [lib/features/planning](lib/features/planning/README.md) |
| Mua hay chờ | [lib/features/purchase_decision](lib/features/purchase_decision/README.md) |
| Nhìn lại — Nhật ký đáng tiền | [lib/features/report](lib/features/report/README.md) |
| Ví và số dư | [lib/features/wallet](lib/features/wallet/README.md) |
| Quy tắc tiền và snapshot dùng chung | [lib/shared/finance](lib/shared/finance/README.md) |
| UI dùng chung | [lib/core/ui](lib/core/ui/README.md) |
| Kiểm thử | [test](test/README.md) |

Các thư mục trống được giữ bằng `.gitkeep`. Mỗi module có README chỉ rõ đầu vào, đầu ra, phạm vi và phụ thuộc. Route mới chưa được đăng ký; placeholder Dart cũ vẫn được giữ.

## Môi trường cho giai đoạn triển khai

`pubspec.yaml` hiện yêu cầu **Dart >=3.10.0 và <4.0.0**. Cần bản Flutter đi kèm Dart tương ứng; repo chưa chốt phiên bản Flutter cụ thể. Không nhầm ràng buộc Dart này với Flutter 3.10.

Khi có SDK phù hợp, thành viên cài dependency, kiểm tra mã generated, chạy analyze/test rồi mới tích hợp màn. Phiên chuẩn bị hiện tại không có `flutter`/`dart` trong PATH nên chưa xác nhận build hoặc test.

README cũ đề cập NestJS/MongoDB là hướng tích hợp. Checkout này chưa cung cấp backend; datasource auth và offline sync vẫn có hành vi mô phỏng. Xem đánh giá base trước khi nối dữ liệu thật.

## Làm việc nhóm

Chia branch theo gói việc, không push trực tiếp main. Một người điều phối main/router/theme/pubspec/l10n và hợp đồng tài chính; từng người làm trong module được giao. Lịch sử và editor dùng chung transaction domain/repository.

Tài liệu template cũ trong `docs/` được giữ làm tham khảo. Đặc tả cho 6 màn Ví An tập trung ở [docs/vian](docs/vian/README.md).

Dự án sử dụng [MIT License](LICENSE).
