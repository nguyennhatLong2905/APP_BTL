# Kết quả kiểm thử Ví An API

Ngày: 2026-10-03T09:19:04.155Z
Node.js: v24.19.0
MongoDB test: 8.0.13, replica set một node tạm.
MongoDB Node driver: 7.7.0.

6 unit test: đạt.
19 tình huống tích hợp: đạt (Node báo 20 gồm test cha).
Không kết nối vào MongoDB trên Mac của người dùng.

Phạm vi: xác thực; schema; sáu màn hình; thêm/sửa/hủy/khôi phục; retry và ghi đồng thời; chuyển ví; hóa đơn; mục tiêu; phân quyền; CSV rollback; ảnh hóa đơn; phân trang/tổng ngày; mua hay chờ; lịch tháng ngắn; gợi ý có căn cứ; cảnh báo ngân sách; onboarding; xóa dữ liệu; backup/restore.

OpenAPI: 75 API operations, 18 model response; đã kiểm tra các tham chiếu nội bộ.
Chưa kiểm thử trên frontend thực tế của người dùng, push notification, khóa sinh trắc học hoặc dịch vụ LLM ngoài.

Log integration:

```text
▶ API integration with a real ephemeral MongoDB replica set
  ✔ auth and schema failures are explicit (6.026549ms)
  ✔ six screen APIs and exact money strings (97.725782ms)
  ✔ create expense, duplicate retry, conflict and balance (41.543777ms)
  ✔ edit, stale version, void and undo remain balanced (65.612899ms)
  ✔ parallel spending does not overdraw and a transfer conserves total (66.800711ms)
  ✔ bill payment releases reservation and void restores it (58.87338ms)
  ✔ allocated money cannot be spent or over-allocated (34.781933ms)
  ✔ one user cannot read or mutate another user wallet (66.030669ms)
  ✔ CSV preview, commit, repeat, export (36.540143ms)
  ✔ simultaneous retries with one key debit only once (27.699305ms)
  ✔ receipt upload, owner check and expense attachment (82.591011ms)
  ✔ pagination retains whole-day totals and literal search (56.952105ms)
  ✔ purchase simulation is read-only, saving goal is unallocated, buy and undo (92.892449ms)
  ✔ bill recurrence clamps month end; rescheduling does not recreate original occurrence (128.680274ms)
  ✔ import rolls back all rows if one expense exceeds balance (41.22837ms)
  ✔ real ratings produce explainable suggestions and require explicit budget confirmation (138.329521ms)
  ✔ budget threshold notification updates without duplicate records (39.482907ms)
  ✔ empty onboarding and confirmed data erasure are user scoped (118.760331ms)
  ✔ signed backup preview and restore (91.089111ms)
✔ API integration with a real ephemeral MongoDB replica set (2919.85953ms)
ℹ tests 20
ℹ suites 0
ℹ pass 20
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 3306.335967
```
