# Checklist nghiệm thu cho giai đoạn triển khai

Chưa thực thi các mục chức năng dưới đây. Đây là tiêu chí cho thành viên viết mã và kiểm tra sau; các thư mục test hiện chỉ giữ chỗ.

## Bộ fixture tài chính cố định

Thời điểm nghiệp vụ: 02/10/2026, múi giờ Asia/Ho_Chi_Minh. Mỗi dòng là một ca độc lập từ trạng thái nền, trừ khi nêu khác.

| Ca | Đầu vào | Kết quả mong đợi |
|---|---|---|
| Nền | Ví 600.000 + 7.400.000; dành riêng 3.500.000 + 2.400.000 | Tổng 8.000.000; dành riêng 5.900.000; còn 2.100.000 |
| Chu kỳ | 16/09 → 16/10, hôm nay 02/10 | 30 ngày/kỳ; còn 14; đã qua 16; khoảng 53%; 150.000 đ/ngày |
| Mua 900.000 | Mô phỏng từ nền | Còn 1.200.000; khoảng 85.700 đ/ngày; ví và lịch sử thực tế không đổi |
| Ghi chi 45.000 | Bản ghi hợp lệ từ nền | Tổng 7.955.000; dành riêng 5.900.000; còn 2.055.000; giảm khoảng 3.200 đ/ngày |
| Chuyển ví 500.000 | Tiền mặt → tài khoản từ nền | Tiền mặt 100.000; tài khoản 7.900.000; tổng 8.000.000; còn 2.100.000; chi tiêu = 0 |
| Trả hóa đơn 3.000.000 | Có allocation đủ, trả từ tài khoản | Tổng 5.000.000; dành riêng 2.900.000; còn 2.100.000; hóa đơn paid, chỉ một giao dịch |
| Thu nhập 25.000 | Từ nền | Tổng 8.025.000; còn 2.125.000; không tăng tổng chi |
| Mục tiêu mới | 900.000/30 ngày, chưa phân bổ | Gợi ý 30.000/ngày; còn để chi vẫn 2.100.000 |
| Mua vượt tự do | Giá 2.500.000 từ nền | Mô phỏng còn −400.000; cảnh báo thiếu, không gắn “an tâm” |
| Ngân sách | Hạn mức 5.500.000; chi 3.400.000 | Còn 2.100.000; đã dùng khoảng 62%; 4 danh mục cộng khớp |
| So sánh tuần | Tuần này 1.150.000; trước 1.400.000 | Giảm 250.000, khoảng 18% |

## Nền và dữ liệu

- [ ] Analyze/build không bị import package thiếu; package mở rộng không dùng đã được xử lý có chủ đích.
- [ ] Demo auth/sync phân biệt rõ với dữ liệu thật; trạng thái synced chỉ sau xác nhận.
- [ ] Không ghi token/header nhạy cảm hoặc dữ liệu tài chính đầy đủ vào log release.
- [ ] Tiền là số nguyên VND; locale tiếng Việt; đổi ngôn ngữ không đổi đồng tiền.
- [ ] Một snapshot revision dùng nhất quán ở Tổng quan, Kế hoạch và Mua hay chờ.
- [ ] Retry cùng clientOperationId không tạo giao dịch, transfer hoặc reflection trùng.
- [ ] Sửa/xóa giao dịch cập nhật ledger, ngân sách, snapshot, lịch sử và báo cáo; thao tác lỗi không cập nhật nửa chừng.
- [ ] Trả hóa đơn không bị trừ tiền hai lần; allocation không bị tính trùng.
- [ ] Thiếu ngày lương, D=0, D<0, số dư âm, P>B và ngân sách 0 đều có trạng thái hợp lệ.
- [ ] Nhóm ngày đúng múi giờ; giao dịch gần nửa đêm không nhảy nhóm khi lưu UTC.

## 6 màn hình

- [ ] Tổng quan: cảnh báo thiếu cấu hình, cách tính, ẩn tiền, hóa đơn và giao dịch gần đây dùng dữ liệu nhất quán.
- [ ] Lịch sử: bộ lọc có thể xóa, tìm không có kết quả, tổng ngày rõ nghĩa, transfer không bị cộng vào chi tiêu.
- [ ] Lịch sử: tải thêm không trùng/bỏ dòng, thay filter không nhận nhầm phản hồi cũ; sửa xong danh sách cập nhật.
- [ ] Editor: số tiền 0/âm/vượt giới hạn/không hợp lệ bị chặn; ví và danh mục hợp loại.
- [ ] Editor: ví nguồn = ví đích bị chặn; lỗi lưu giữ form; bấm lặp không ghi trùng; hủy bản nháp không ghi.
- [ ] Editor: nhận draft từ Mua hay chờ, cho sửa, chỉ lưu khi người dùng chọn.
- [ ] Planning: phân biệt ngân sách còn lại và còn để chi; đổi tháng/chu kỳ có nhãn phạm vi; tiến độ và số vượt đúng.
- [ ] Planning: ngân sách/mục tiêu/hóa đơn có rỗng, tạo, sửa, lỗi; thay allocation phản ánh snapshot.
- [ ] Mua hay chờ: đổi giá/giả định cập nhật mô phỏng; không ghi số dư; giá vượt F báo thiếu.
- [ ] Mua hay chờ: kế hoạch chờ không tự trừ tiền; ngày nhắc mặc định theo lương +1 ngày, cho chỉnh.
- [ ] Nhìn lại: đủ 7 ngày mới mời đánh giá; lưu/sửa cảm nhận không trùng; bỏ qua không xóa giao dịch.
- [ ] Nhìn lại: ít hơn 10 đánh giá không kết luận insight mạnh; có số mẫu và lối xem dữ liệu.
- [ ] Nhìn lại: tuần trước = 0 không chia %; điều chỉnh ngân sách chỉ lưu qua planning.

## UI, điều hướng và khả năng tiếp cận

- [ ] Đủ loading / empty / error+retry / stale / offline / missing configuration; không dùng 0 giả cho thiếu dữ liệu.
- [ ] 320/360/390/430 logical px không tràn ngang; tiền không rơi riêng đơn vị đ; tên dài không cắt giữa từ.
- [ ] Chữ phóng 200% vẫn đọc và thao tác được; vùng chạm ≥48; đọc màn hình hiểu icon và số tiền.
- [ ] Cảnh báo có chữ/icon; độ tương phản chữ được kiểm tra, không chỉ nhìn màu mint.
- [ ] Nội dung cuối màn không bị thanh đáy, nút “+”, SafeArea hoặc bàn phím che.
- [ ] 4 tab giữ vị trí/bộ lọc; nút “+” mở hành động; back từ editor/purchase trở về đúng nguồn.
- [ ] Cài đặt ẩn tiền có hiệu lực trên các màn đọc; draft đang sửa dùng ngoại lệ đã giải thích.
- [ ] Tên, số tiền và thời gian cùng một giao dịch đồng nhất giữa Tổng quan, Lịch sử và Nhìn lại.

## Kiểm tra của lần chuẩn bị không code

Đã rà soát bằng kiểm tra file: chỉ tài liệu Markdown, ảnh tham chiếu nguyên bản và `.gitkeep` được bổ sung/chỉnh sửa; không thay Dart, YAML, ARB, script, platform hoặc test thực thi. Không chạy Flutter analyze/test do SDK không có trong PATH.
