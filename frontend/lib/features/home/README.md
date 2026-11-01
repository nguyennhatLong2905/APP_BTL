# Home — Tổng quan

Trạng thái: màn Dart hiện có là demo hồ sơ/base; chưa thay bằng giao diện Ví An. Các thư mục mới chỉ giữ chỗ.

## Phạm vi

Card còn để chi, cảnh báo cấu hình chu kỳ, cách tính 3 lớp tiền, hóa đơn sắp tới, giao dịch gần đây và lối vào Mua hay chờ.

## Chỗ làm

- `presentation/screens/`: màn Tổng quan; tận dụng entry hiện có khi tích hợp.
- `presentation/widgets/`: card và section chỉ dùng tại Tổng quan.
- `presentation/providers/`: trạng thái tải/refresh/ẩn tiền của màn.
- `domain/entities/`, `domain/usecases/`: dữ liệu trình bày tổng hợp và truy vấn.
- `providers/`: nối các reader và use case.

Home đọc FinancialSnapshot, hóa đơn và giao dịch từ hợp đồng chung. Không tạo datasource số dư hoặc tính F=B−P trong widget. Trạng thái ẩn tiền dùng cùng cài đặt với các màn đọc khác.

## Bàn giao

Đủ loading/rỗng/lỗi/thiếu chu kỳ, số tiền khớp snapshot, mở đúng editor/planning/purchase decision. Test đặt tại `test/features/home/`.

Xem [đặc tả màn](../../../docs/vian/UI_UX_SPEC.md), [hợp đồng dữ liệu](../../../docs/vian/DATA_CONTRACTS.md) và [phân công](../../../docs/vian/TEAM_HANDOFF.md).
