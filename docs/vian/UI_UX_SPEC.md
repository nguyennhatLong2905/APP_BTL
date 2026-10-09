# Đặc tả tối ưu giao diện 6 màn

Giữ tinh thần xanh mint, thẻ trắng và giọng điệu bình tĩnh của ảnh. Tối ưu thứ bậc thông tin, tính nhất quán và thao tác. Đây là đặc tả để thành viên triển khai, chưa phải giao diện đã dựng.

## Quy chuẩn dùng chung

| Thành phần | Quy ước đề xuất |
|---|---|
| Màu | Nền mint nhạt; chữ xanh đậm; CTA xanh teal; cảnh báo hổ phách; lỗi đỏ. Chốt token tại theme, không lấy nhiều màu gần giống nhau theo từng ảnh |
| Bố cục | Lề màn 16–24 logical px, khoảng cách theo nhịp 8, padding thẻ 16, bo góc thẻ khoảng 20; giảm thẻ lồng thẻ nếu chỉ chứa một dòng |
| Chữ | Một tiêu đề ngắn cho mỗi màn. Nội dung chính 14–16, tiêu đề 20–24, số tiền nổi bật 32–40 và co giãn theo chiều rộng |
| Tiền | VND, dạng 2.100.000 đ; số và đơn vị đi cùng nhau. Không xuống dòng riêng ký hiệu đ; không trộn 900k/900.000 trong cùng phép so sánh |
| Thao tác | Vùng chạm tối thiểu 48 × 48 logical px; icon có nhãn đọc. Một CTA chính ở mỗi bước |
| Trạng thái | Có loading, empty, error/retry, dữ liệu cũ/offline, thiếu cấu hình; phân biệt “0” với chưa có dữ liệu |
| Tiến độ | Thanh hiển thị giới hạn 0–100%; số thật và phần vượt vẫn hiện bằng chữ. Không dùng màu làm tín hiệu duy nhất |
| Responsive | Kiểm tra rộng 320/360/390/430 logical px và chữ phóng 200%. Dùng bố cục linh hoạt, không ép chiều cao thẻ theo ảnh dài |
| Điều hướng | Thanh đáy nhất quán trên 4 tab; chừa SafeArea và khoảng cuối nội dung cho nút “+”. Màn hành động dùng nút quay lại/đóng phù hợp |
| Riêng tư | Ẩn tiền áp dụng cho mọi vùng có tiền trên 4 tab và màn Mua hay chờ. Editor phải cho nhập/đọc số tiền đang sửa; nhãn giải thích ngoại lệ này |

Mẫu trống/dữ liệu mẫu đặt trong menu phụ hoặc trạng thái rỗng. Khi bật dữ liệu mẫu, gắn nhãn rõ trên toàn màn, không trộn vào dữ liệu thật.

## 1. Tổng quan

Tham chiếu: [overview.png](references/overview.png).

**Vấn đề:** banner cảnh báo chiếm vùng đầu; “3 lớp tiền” dài; nhiều nhãn mô tả trùng nhau. Nhãn 58% tiến độ không khớp chu kỳ mẫu theo quy tắc ngày được chốt. “Được khóa bảo vệ an toàn” dễ bị hiểu là ngân hàng thực sự khóa tiền.

**Bố cục đề xuất, từ trên xuống:**

1. Header “Tổng quan”, lời chào ngắn, icon ẩn tiền, tài khoản/thông báo.
2. Cảnh báo thiếu ngày lương dạng banner gọn với CTA “Cập nhật chu kỳ”; mở rộng khi bấm chi tiết. Nếu số tiền chỉ là ước tính, gắn nhãn ngay cạnh kết quả.
3. Thẻ chính “Còn để chi đến ngày lương”: số tiền, bình quân/ngày, ngày lương và số ngày còn lại. “Cách tính” mở bảng giải thích.
4. “Tiền của bạn” gồm 3 dòng: Tổng số dư / Đã dành riêng / Còn để chi; chỉ mở chi tiết khoản bảo vệ khi cần.
5. Lối vào “Mua hay chờ?” gọn một hàng.
6. Tối đa 2 hóa đơn sắp tới và 3 giao dịch gần đây, mỗi mục có “Xem tất cả”.

**Hành vi cần chốt:** thiếu chu kỳ thì cho cấu hình hoặc hiển thị số ước tính có lý do; hết chu kỳ thì cập nhật mốc mới; tiền âm thì hiện thiếu hụt, không gắn “an tâm”. Thanh tiến độ tính từ ngày, tách khỏi tiến độ ngân sách.

**Câu chữ:** thay “được khóa bảo vệ” bằng “đã dành riêng trong kế hoạch”; không hứa “an toàn tuyệt đối”. “Khoảng lặng tài chính” chỉ là trạng thái theo dữ liệu ghi nhận, không khẳng định đã biết mọi chi tiêu.

## 2. Lịch sử giao dịch

Tham chiếu: [transaction_history.png](references/transaction_history.png).

**Vấn đề:** nhiều hàng chip khiến bộ lọc khó hiểu; tên giao dịch/ví và nhãn loại bị cắt giữa từ; 500.000 đ chuyển ví dễ bị hiểu là thu hoặc chi; card động viên dài hơn thông tin hữu ích.

**Tối ưu:**

- Search cố định đầu danh sách; bộ lọc chính gồm khoảng thời gian, ví và nút “Bộ lọc” có số điều kiện đang áp dụng. Điều kiện chọn hiện thành chip có thể xóa.
- Khoảng ngày là lựa chọn loại trừ nhau: tháng, tuần, hôm nay hoặc tùy chỉnh. Không để người dùng hiểu “Tháng 10” và “Hôm nay” là hai bộ lọc đồng thời không rõ nghĩa.
- Nhóm theo ngày, tiêu đề ghi “Hôm nay · 02/10/2026”; tổng ngày ghi rõ Thu, Chi hoặc Thu − Chi theo [hợp đồng](DATA_CONTRACTS.md).
- Mỗi dòng: icon danh mục, tên tối đa 2 dòng, giờ · ví; số tiền ở cột riêng; loại giao dịch là nhãn ngắn. Chuyển ví ghi “Ví A → Ví B”, không dùng dấu +/− của thu/chi.
- Tap mở chi tiết để sửa/xóa; nếu là chuyển ví, thao tác áp dụng cả cặp hạch toán.
- Danh sách tải từng trang theo ngày/giờ; có trạng thái tải thêm và retry, không tải toàn bộ lịch sử một lần.
- Rỗng do chưa có giao dịch: CTA “Thêm giao dịch”. Rỗng do lọc: “Không có kết quả” và “Xóa bộ lọc”.
- Đưa card động viên xuống sau dữ liệu hoặc rút thành một câu theo trạng thái thật.

**Nhất quán mẫu:** “Cà phê sáng” trong ảnh Tổng quan là 08:15 nhưng Lịch sử là 08:30; chốt một giá trị từ cùng giao dịch. Dùng cùng ngày/giờ trên mọi màn.

## 3. Thêm giao dịch

Tham chiếu: [transaction_editor.png](references/transaction_editor.png).

**Vấn đề:** có cả quay lại và nút X ở card; nội dung nguồn tiền/ngày bị cắt; bàn phím số thiếu hành vi nhập rõ; form chuyển ví chưa được thể hiện.

**Tối ưu:**

- Dùng một header “Thêm giao dịch” với một nút đóng/quay lại; bỏ lớp tiêu đề “Ghi nhận giao dịch” lặp.
- 3 chế độ Chi tiêu / Thu nhập / Chuyển ví đổi trường theo loại, dùng chung một bản nháp có validation.
- Số tiền là vùng nhập chính; hỗ trợ bàn phím hệ thống hoặc keypad tùy chỉnh có semantics đầy đủ. Nếu dùng keypad riêng, không bật bàn phím hệ thống chồng lên.
- Chip cộng nhanh có cuộn ngang rõ và không bị cắt. Có xóa một chữ số, xóa hết và giới hạn theo hợp đồng số tiền.
- Ngày và ví được đọc đầy đủ; màn hẹp xếp dọc. Danh mục có icon + nhãn; “Khác” mở danh sách, không bắt người dùng chọn sai vì thiếu danh mục.
- Chuyển ví có ví nguồn và ví đích khác nhau; bỏ trường danh mục thu/chi, giải thích không làm đổi tổng tiền.
- Ghi chú/ảnh hóa đơn là phần tùy chọn thu gọn; lỗi tải ảnh giữ nguyên số tiền và các trường khác.
- CTA “Lưu giao dịch” nằm trong vùng nhìn thấy khi nhập; có trạng thái đang lưu, chống bấm lặp và lỗi tại trường.
- Chỉ hiển thị tác động/ngày khi snapshot và chu kỳ hợp lệ; đổi theo loại thu/chi, không gắn giảm tiền cho chuyển ví.

**Luồng Mua hay chờ:** nhận bản nháp tên món, số tiền, danh mục, ví nếu có; cho sửa; chỉ ghi sau khi bấm Lưu. Hủy form không có giao dịch.

## 4. Kế hoạch chi tiêu

Tham chiếu: [spending_plan.png](references/spending_plan.png).

**Vấn đề:** tiêu đề dài; số tiền danh mục mua sắm xuống dòng; “còn để chi thực tế” đang dễ bị đồng nhất với ngân sách còn lại; tab Mục tiêu/Hóa đơn chưa có giao diện chi tiết trong bộ ảnh.

**Tối ưu:**

- Header “Kế hoạch”; một card chu kỳ hiển thị 16/09–16/10/2026, 14 ngày còn lại và nút chỉnh mốc.
- Tab Ngân sách / Mục tiêu / Hóa đơn nhất quán; chuyển tháng/chu kỳ lương dưới tab Ngân sách và hiển thị rõ phạm vi đang xem.
- Thẻ ngân sách dùng “Ngân sách còn lại”: 2.100.000 đ trong mẫu, “Đã dùng 3.400.000 / 5.500.000 đ · 62%”. Nếu bằng “còn để chi” của Tổng quan thì vẫn có nhãn phân biệt.
- Mỗi danh mục: tên linh hoạt, hạn mức căn phải, đã chi, tiến độ và nút sửa vùng chạm đủ lớn. 88% dùng nhãn “Gần hạn mức”, vượt 100% có số vượt.
- Dòng cảnh báo mua sắm giữ “Còn 120.000 đ trong kỳ”, CTA “Điều chỉnh” nằm riêng, không gạch chân/vỡ dòng giữa từ.
- “Thêm danh mục ngân sách” là thao tác phụ ở cuối; khi tổng phân bổ vượt giới hạn kế hoạch thì hiện chênh lệch và yêu cầu xem lại.
- Mục tiêu: danh sách số cần đạt, đã dành, ngày dự kiến; tạo/sửa/hủy riêng. Hóa đơn: sắp tới/đã trả/quá hạn, ngày đến hạn, số đã dành và hành động ghi nhận trả.

Mục tiêu/Hóa đơn là đề xuất tối thiểu từ hai tab trong ảnh, chưa có mẫu hình chi tiết. Người phụ trách dùng cùng UI kit và ghi nhận quyết định thiết kế trước khi triển khai phần mở rộng.

## 5. Mua hay chờ

Tham chiếu: [purchase_decision.png](references/purchase_decision.png).

**Vấn đề:** màn quá dài để thấy lựa chọn; có cả back và X; nhiều thẻ lồng nhau; gọi “Tiến hành mua” trong khi chỉ mở form; đề xuất chờ nhưng người dùng khó thấy tác động trước.

**Bố cục đề xuất:**

1. Header “Mua hay chờ?” và một nút quay lại.
2. Nhập tên món, giá và danh mục; phần giả định chu kỳ có thể chỉnh, phân biệt giả định với cấu hình đã lưu.
3. Thẻ so sánh Hiện tại / Sau khi mua, mỗi cột có tổng tiền và bình quân/ngày. Màn hẹp hoặc chữ lớn xếp dọc.
4. Một đoạn diễn giải: “Sau khoản chi này, bạn còn khoảng 85.700 đ/ngày trong 14 ngày”.
5. Hai lựa chọn ở cùng vùng nhìn thấy: “Ghi khoản mua này” và “Để dành mua sau”.
6. Chi tiết tiền đã dành riêng và form kế hoạch chờ mở khi cần.

**Hành vi:**

- “Ghi khoản mua này” chỉ mở editor điền sẵn, không thanh toán, không tự ghi.
- Thiếu snapshot/chu kỳ thì vẫn nhập món nhưng kết quả yêu cầu bổ sung giả định; không tự dùng 14 ngày.
- Giá lớn hơn khoản tự do: hiển thị phần thiếu, không tuyên bố khoản bảo vệ còn nguyên nếu người dùng vẫn ghi chi vượt khả năng.
- “Để dành mua sau” mặc định ngày nhắc bằng ngày lương kế tiếp + 1 ngày, cho sửa. Mục tiêu 900.000 trong 30 ngày hiển thị 30.000 đ/ngày, không tự chuyển tiền.
- Bỏ nhãn “Khuyên dùng” cố định; mô tả tác động trung tính để người dùng chọn.
- Giả định mô phỏng không ghi đè kế hoạch thật nếu chưa có thao tác lưu riêng.

## 6. Nhìn lại — Nhật ký đáng tiền

Tham chiếu: [reflection.png](references/reflection.png).

**Vấn đề:** nhiều vùng cuộn, mỗi giao dịch lặp CTA lưu; insight 90%/60% với ít đánh giá trông chắc chắn quá mức; văn bản và đơn vị bị xuống dòng khó đọc.

**Tối ưu:**

- Header “Nhìn lại”, chọn tuần; thẻ tổng chi và so sánh tuần trước có phạm vi ngày rõ ràng.
- Đưa nhật ký ngay sau tổng chi; nhóm “Chờ đánh giá” và “Đã đánh giá”, hiển thị vài mục rồi “Xem thêm”.
- Giao dịch đủ 7 ngày mới vào danh sách chờ đánh giá. Nút “Bỏ qua” chỉ bỏ qua đánh giá, không xóa giao dịch.
- 3 lựa chọn cảm nhận có nhãn + trạng thái chọn, không phụ thuộc emoji; ghi chú không bắt buộc.
- Lưu theo từng giao dịch, báo thành công ngay trên card; giữ bản nháp nếu lưu lỗi và không cho cảm giác đã lưu khi chưa thành công.
- “Thấu hiểu bản thân” luôn có số mẫu, thời gian thống kê và lối xem dữ liệu. Khi ít mẫu, hiện “Chưa đủ dữ liệu để nhận xét” thay kết luận mạnh.
- Không hardcode 90%, 60% hoặc nội dung gợi ý từ ảnh; insight và đề xuất ngân sách lấy từ dữ liệu thật, trình bày như gợi ý.
- “Điều chỉnh ngân sách” mở planning với đề xuất, cần người dùng lưu. Thử thách 48h chỉ tạo nhắc nhở sau khi chọn và xác nhận lịch.

## Phạm vi MVP

Ưu tiên 6 luồng chính, phép tính nhất quán, chuyển ví đúng, form chống ghi trùng và đủ trạng thái. OCR hóa đơn, đồng bộ ngân hàng, tư vấn AI, thanh toán, insight nâng cao và thử thách tự động chưa nằm trong phần cần triển khai để hoàn thiện base lần đầu.
