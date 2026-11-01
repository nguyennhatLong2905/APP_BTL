# UI dùng chung cho Ví An

Bộ file Dart ở đây hiện phần lớn là khung chỉ chứa khoảng trắng; chưa có UI kit hoạt động đầy đủ. README này quy định nơi triển khai cho giai đoạn tiếp theo, không bổ sung widget.

## Cách tổ chức

- `buttons/`, `inputs/`, `cards/`, `typography/`, `feedback/`, `dialogs/`, `widgets/`: tận dụng vị trí đã có.
- `navigation/`: thành phần tab/bottom navigation.
- `layouts/`: khung shell 4 tab, SafeArea và khung màn hành động.
- `finance/`: hiển thị số tiền, status chip và thanh tiến độ dùng ở nhiều màn.

Màu/chữ/spacing lấy từ `core/theme/`; phép tính tiền lấy từ `shared/finance/`. UI chung nhận dữ liệu qua tham số, không fetch repository hoặc tính lại nghiệp vụ.

Chỉ đưa component vào đây khi có vai trò dùng chung rõ ràng. Card riêng của màn ở `features/<module>/presentation/widgets/`.

Một số widget thật đang ở `core/widgets/`. Khi triển khai, kiểm tra và tái sử dụng phần phù hợp rồi thống nhất một nơi công khai; chưa xóa hoặc đổi import cũ ở lần chuẩn bị này.

Xem [quy chuẩn UI](../../../docs/vian/UI_UX_SPEC.md) và [kiến trúc](../../../docs/vian/ARCHITECTURE.md).
