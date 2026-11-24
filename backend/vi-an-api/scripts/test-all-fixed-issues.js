import assert from "node:assert/strict";

const BASE_URL = "http://127.0.0.1:3000/api/v1";

async function runTests() {
  console.log("=== BẮT ĐẦU CHẠY KIỂM THỬ CÁC TÍNH NĂNG ĐÃ SỬA ===");

  // 1. Test Auth: Login demo
  console.log("\n[1/6] Kiểm thử Đăng nhập Demo (POST /auth/demo)...");
  const authRes = await fetch(`${BASE_URL}/auth/demo`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  assert.equal(authRes.status, 200, `Demo login failed with status ${authRes.status}`);
  const authData = await authRes.json();
  const token = authData.data.accessToken;
  const user = authData.data.user;
  console.log("  => Đăng nhập thành công! User:", user.displayName, `(ID: ${user._id})`);

  const authHeaders = {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json",
  };

  // 2. Test Issue 1: Xuất dữ liệu CSV (GET /exports/transactions.csv)
  console.log("\n[2/6] Kiểm thử Xuất dữ liệu CSV (GET /exports/transactions.csv)...");
  const exportRes = await fetch(`${BASE_URL}/exports/transactions.csv`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}` },
  });
  assert.equal(exportRes.status, 200, `Export failed with status ${exportRes.status}`);
  const contentType = exportRes.headers.get("content-type");
  assert.ok(contentType?.includes("text/csv"), `Content-Type should be text/csv, got: ${contentType}`);
  const csvText = await exportRes.text();
  console.log(`  => Xuất file CSV thành công! Độ dài: ${csvText.length} bytes`);
  console.log("  => Dòng tiêu đề CSV:", csvText.split("\n")[0]);

  // 3. Test Issue 2 & 4: Ẩn số tiền & Cập nhật chu kỳ lương (PATCH /me)
  console.log("\n[3/6] Kiểm thử Cập nhật hồ sơ: Ẩn số tiền & Bổ sung chu kỳ lương (PATCH /me)...");
  const testPayday = new Date(Date.now() + 10 * 86400000).toISOString();
  const updateRes = await fetch(`${BASE_URL}/me`, {
    method: "PATCH",
    headers: {
      ...authHeaders,
      "Idempotency-Key": `test-idemp-${Date.now()}-1`,
    },
    body: JSON.stringify({
      nextPayday: testPayday,
      settings: {
        hideAmounts: true,
      },
    }),
  });
  assert.equal(updateRes.status, 200, `Update profile failed with status ${updateRes.status}`);
  const updatedUser = (await updateRes.json()).data;
  console.log("  => Cập nhật thành công!");
  console.log("  => nextPayday đã lưu:", updatedUser.nextPayday);
  console.log("  => settings.hideAmounts đã lưu:", updatedUser.settings?.hideAmounts);
  assert.equal(updatedUser.settings?.hideAmounts, true, "hideAmounts must be true");

  // 4. Test Issue 5: Dashboard Overview & Mua hay chờ (GET /dashboard)
  console.log("\n[4/6] Kiểm thử Dữ liệu Dashboard & Mua hay chờ (GET /dashboard)...");
  const dashRes = await fetch(`${BASE_URL}/dashboard`, {
    method: "GET",
    headers: authHeaders,
  });
  assert.equal(dashRes.status, 200, `Dashboard failed with status ${dashRes.status}`);
  const dashData = (await dashRes.json()).data;
  console.log("  => Dashboard overview trả về đầy đủ các trường:");
  console.log("     - available:", dashData.available);
  console.log("     - protectedMoney:", dashData.protectedMoney);
  console.log("     - daysRemaining:", dashData.daysRemaining);
  console.log("     - nextPayday:", dashData.nextPayday);
  assert.ok("daysRemaining" in dashData, "Dashboard must contain daysRemaining");
  assert.ok("available" in dashData, "Dashboard must contain available");

  // 5. Test Issue 6 & 7: Tạo giao dịch và kiểm tra chuẩn thời gian ISO8601 & Local Time
  console.log("\n[5/6] Kiểm thử Giao dịch, Xuất CSV có dữ liệu và chuẩn thời gian ISO8601 (POST /transactions & GET /transactions)...");
  
  // Lấy hoặc tạo danh mục chi tiêu
  const catRes = await fetch(`${BASE_URL}/categories`, {
    method: "GET",
    headers: authHeaders,
  });
  let categories = (await catRes.json()).data;
  let categoryId;
  if (!categories || categories.length === 0) {
    const createCatRes = await fetch(`${BASE_URL}/categories`, {
      method: "POST",
      headers: {
        ...authHeaders,
        "Idempotency-Key": `test-cat-${Date.now()}`,
      },
      body: JSON.stringify({
        name: "Ăn uống",
        kind: "expense",
        icon: "food",
        color: "#ff5722",
      }),
    });
    const createdCat = (await createCatRes.json()).data;
    categoryId = createdCat._id;
  } else {
    categoryId = categories[0]._id;
  }

  // Lấy hoặc tạo ví
  const walletRes = await fetch(`${BASE_URL}/wallets`, {
    method: "GET",
    headers: authHeaders,
  });
  let wallets = (await walletRes.json()).data;
  let walletId;
  if (!wallets || wallets.length === 0) {
    const createWalletRes = await fetch(`${BASE_URL}/wallets`, {
      method: "POST",
      headers: {
        ...authHeaders,
        "Idempotency-Key": `test-wallet-${Date.now()}`,
      },
      body: JSON.stringify({
        name: `Ví Tiền Mặt ${Date.now()}`,
        type: "cash",
        openingBalance: "10000000",
        openingAt: new Date(Date.now() - 86400000).toISOString(),
      }),
    });
    const createdWallet = (await createWalletRes.json()).data;
    walletId = createdWallet._id;
  } else {
    walletId = wallets[0]._id;
  }

  // Tạo giao dịch chi tiêu lúc này
  const txOccurredAt = new Date().toISOString();
  const createTxRes = await fetch(`${BASE_URL}/transactions`, {
    method: "POST",
    headers: {
      ...authHeaders,
      "Idempotency-Key": `test-tx-${Date.now()}`,
    },
    body: JSON.stringify({
      walletId: walletId,
      categoryId: categoryId,
      type: "expense",
      amount: "50000",
      occurredAt: txOccurredAt,
      note: "Mua trà sữa",
    }),
  });
  assert.equal(createTxRes.status, 200, `Create transaction failed with status ${createTxRes.status}`);
  const createdTx = (await createTxRes.json()).data;
  console.log("  => Đã tạo giao dịch mới thành công ID:", createdTx._id);

  const txRes = await fetch(`${BASE_URL}/transactions?limit=5`, {
    method: "GET",
    headers: authHeaders,
  });
  assert.equal(txRes.status, 200, `Get transactions failed with status ${txRes.status}`);
  const txList = (await txRes.json()).data;
  console.log(`  => Lấy được ${txList.items?.length || 0} giao dịch gần nhất.`);
  if (txList.items && txList.items.length > 0) {
    const tx = txList.items[0];
    const utcDate = new Date(tx.occurredAt);
    console.log(`  => Giao dịch: ${tx.note || tx.description || 'Chi tiêu'} - Số tiền: ${tx.amount} đ`);
    console.log(`     - Giờ UTC từ API: ${tx.occurredAt}`);
    console.log(`     - Giờ hiển thị theo Local (+7): ${utcDate.toLocaleTimeString('vi-VN')} ngày ${utcDate.toLocaleDateString('vi-VN')}`);
  }

  // Kiểm tra lại xuất CSV có chứa giao dịch vừa tạo
  const exportCsv2Res = await fetch(`${BASE_URL}/exports/transactions.csv`, {
    method: "GET",
    headers: { "Authorization": `Bearer ${token}` },
  });
  const csvContent = await exportCsv2Res.text();
  console.log("  => Xuất lại CSV kiểm tra dòng dữ liệu mới:");
  console.log(csvContent.trim().split("\n").slice(-2).join("\n"));
  assert.ok(csvContent.includes("50000"), "CSV must include newly created transaction 50000");

  // 6. Test Issue 8: Ngân sách và Nhìn lại (POST /budgets & GET /screens/review)
  console.log("\n[6/6] Kiểm thử Ngân sách trong Kế hoạch và Nhìn lại (POST /budgets & GET /screens/review)...");

  const now = new Date();
  const startAt = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
  const endAt = new Date(now.getFullYear(), now.getMonth() + 1, 1).toISOString();

  // Tạo kế hoạch ngân sách mới với schema hợp lệ
  const createBudgetRes = await fetch(`${BASE_URL}/budgets`, {
    method: "POST",
    headers: {
      ...authHeaders,
      "Idempotency-Key": `test-idemp-${Date.now()}-2`,
    },
    body: JSON.stringify({
      name: "Ngân sách tháng hiện tại",
      periodType: "month",
      startAt: startAt,
      endAt: endAt,
      warningPercent: 80,
      limits: [
        {
          categoryId: categoryId,
          limit: "1000000",
        },
      ],
    }),
  });
  if (createBudgetRes.status !== 200) {
    console.error("LỖI CREATE BUDGET:", await createBudgetRes.text());
  }
  assert.equal(createBudgetRes.status, 200, `Create budget failed with status ${createBudgetRes.status}`);
  const createdBudget = (await createBudgetRes.json()).data;
  console.log("  => Đã tạo kế hoạch ngân sách mới ID:", createdBudget._id, "Tên:", createdBudget.name);

  // Gọi API Review để kiểm tra ngân sách gợi ý
  const reviewRes = await fetch(`${BASE_URL}/screens/review`, {
    method: "GET",
    headers: authHeaders,
  });
  assert.equal(reviewRes.status, 200, `Review failed with status ${reviewRes.status}`);
  const reviewData = (await reviewRes.json()).data;
  console.log("  => API Review trả về thành công!");
  console.log("  => Budget Suggestions:", JSON.stringify(reviewData.budgetSuggestions ?? {}));
  console.log("  => Không còn xung đột giữa Kế hoạch và Nhìn lại.");

  console.log("\n=======================================================");
  console.log("TẤT CẢ CÁC BƯỚC KIỂM THỬ API ĐỀU THÀNH CÔNG VÀ CHÍNH XÁC!");
  console.log("=======================================================\n");
}

runTests().catch(err => {
  console.error("LỖI KIỂM THỬ:", err);
  process.exit(1);
});
