/** Browser/React/Vue client. Keep the access token in application memory. */
export function createViAnClient({
  baseUrl = "http://127.0.0.1:3000/api/v1",
  getToken = () => null,
} = {}) {
  async function request(
    method,
    path,
    { body, query, key, raw = false, signal } = {},
  ) {
    const url = new URL(baseUrl.replace(/\/$/, "") + path);
    for (const [name, value] of Object.entries(query || {}))
      if (value !== undefined && value !== null && value !== "")
        url.searchParams.set(name, String(value));
    const token = getToken();
    const response = await fetch(url, {
      method,
      signal,
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
        ...(key ? { "Idempotency-Key": key } : {}),
      },
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
    if (!response.ok) {
      const payload = await response.json().catch(() => ({}));
      const error = new Error(
        payload.error?.message || `HTTP ${response.status}`,
      );
      Object.assign(error, {
        status: response.status,
        code: payload.error?.code,
        details: payload.error?.details,
        requestId: payload.requestId,
      });
      throw error;
    }
    return raw ? response.blob() : (await response.json()).data;
  }
  const read = (path, query) => request("GET", path, { query });
  // Retain this key for retries of the SAME operation; create a fresh key for a new action.
  const mutate = (method, path, body, key = crypto.randomUUID()) =>
    request(method, path, { body, key });
  return {
    request,
    read,
    mutate,
    demoLogin: () => request("POST", "/auth/demo", { body: {} }),
    login: (body) => request("POST", "/auth/login", { body }),
    register: (body) => request("POST", "/auth/register", { body }),
    me: () => read("/me"),
    updateProfile: (body, key) => mutate("PATCH", "/me", body, key),
    dashboard: () => read("/dashboard"),
    transactionForm: () => read("/screens/add-transaction"),
    history: (filters) => read("/screens/transactions", filters),
    plans: () => read("/screens/plans"),
    review: (period) => read("/screens/review", period),
    transaction: (id) => read(`/transactions/${id}`),
    createTransaction: (body, key) =>
      mutate("POST", "/transactions", body, key),
    editTransaction: (id, body, key) =>
      mutate("PUT", `/transactions/${id}`, body, key),
    voidTransaction: (id, expectedVersion, key) =>
      mutate("POST", `/transactions/${id}/void`, { expectedVersion }, key),
    restoreTransaction: (id, expectedVersion, key) =>
      mutate("POST", `/transactions/${id}/restore`, { expectedVersion }, key),
    simulatePurchase: (body) =>
      request("POST", "/simulations/purchase", { body }),
    savePurchase: (body, key) => mutate("POST", "/purchases", body, key),
    buyPurchase: (id, body, key) =>
      mutate("POST", `/purchases/${id}/buy`, body, key),
    payBill: (id, body, key) => mutate("POST", `/bills/${id}/pay`, body, key),
    allocateGoal: (id, body, key) =>
      mutate("PUT", `/goals/${id}/allocation`, body, key),
    rateReflection: (id, body, key) =>
      mutate("PUT", `/reflections/${id}`, body, key),
    generateInsights: (key) => mutate("POST", "/insights/generate", {}, key),
    applyInsight: (id, body, key) =>
      mutate("POST", `/insights/${id}/apply`, body, key),
    notifications: () => read("/notifications"),
    recommendations: (body) => request("POST", "/recommendations", { body }),
    exportTransactions: (query) =>
      request("GET", "/exports/transactions.csv", { query, raw: true }),
    attachment: (id) => request("GET", `/attachments/${id}`, { raw: true }),
    async uploadReceipt(file, key) {
      if (file.size > 2_000_000) throw new Error("Ảnh tối đa 2 MB.");
      const base64 = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result).split(",")[1]);
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
      });
      return mutate(
        "POST",
        "/attachments",
        { filename: file.name, mimeType: file.type, base64 },
        key,
      );
    },
  };
}
export function formatVnd(value) {
  return value == null
    ? "Chưa đủ dữ liệu"
    : new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND",
        maximumFractionDigits: 0,
      }).format(BigInt(value));
}
