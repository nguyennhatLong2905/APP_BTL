import { readFileSync } from "node:fs";
const ref = (name) => ({ $ref: "#/components/schemas/" + name });
const str = { type: "string" },
  boolean = { type: "boolean" },
  integer = { type: "integer" },
  date = { type: "string", format: "date-time" },
  id = { type: "string", pattern: "^[a-fA-F0-9]{24}$" };
const array = (items) => ({ type: "array", items });
const obj = (properties, required = []) => ({
  type: "object",
  properties,
  ...(required.length ? { required } : {}),
  additionalProperties: true,
});
const money = ref("Money"),
  maybeMoney = { type: "string", pattern: "^-?[0-9]+$", nullable: true };
const identity = { _id: id, userId: id, createdAt: date, updatedAt: date };
const schemas = {
  Money: {
    type: "string",
    pattern: "^-?[0-9]+$",
    description:
      "Số nguyên VND. Chuỗi giữ chính xác BSON Long; số dư khả dụng có thể âm.",
    example: "50000",
  },
  Wallet: obj(
    {
      ...identity,
      name: str,
      type: { type: "string", enum: ["cash", "bank", "ewallet", "savings"] },
      currency: str,
      openingBalance: money,
      openingAt: date,
      balance: money,
      status: str,
      version: integer,
    },
    ["_id", "name", "balance", "version"],
  ),
  Category: obj(
    {
      ...identity,
      name: str,
      kind: { type: "string", enum: ["expense", "income"] },
      status: str,
      icon: str,
      color: str,
    },
    ["_id", "name", "kind"],
  ),
  Transaction: obj(
    {
      ...identity,
      type: {
        type: "string",
        enum: ["expense", "income", "transfer", "adjustment"],
      },
      amount: money,
      currency: str,
      occurredAt: date,
      status: { type: "string", enum: ["posted", "voided"] },
      version: integer,
      walletId: id,
      categoryId: id,
      fromWalletId: id,
      toWalletId: id,
      billOccurrenceId: id,
      purchaseIntentId: id,
      adjustmentDirection: str,
      note: str,
      merchant: str,
      attachments: array(obj({ storageKey: id, mimeType: str })),
      category: {
        oneOf: [
          ref("Category"),
          { type: "object", nullable: true, enum: [null] },
        ],
      },
      wallet: {
        oneOf: [
          ref("Wallet"),
          { type: "object", nullable: true, enum: [null] },
        ],
      },
      fromWallet: {
        oneOf: [
          ref("Wallet"),
          { type: "object", nullable: true, enum: [null] },
        ],
      },
      toWallet: {
        oneOf: [
          ref("Wallet"),
          { type: "object", nullable: true, enum: [null] },
        ],
      },
    },
    ["_id", "type", "amount", "occurredAt", "status", "version"],
  ),
  Bill: obj(
    {
      ...identity,
      templateId: id,
      name: str,
      amount: money,
      categoryId: id,
      dueAt: date,
      scheduledFor: date,
      status: { type: "string", enum: ["unpaid", "paid", "cancelled"] },
      transactionId: id,
      paidAt: date,
      overdue: boolean,
    },
    ["_id", "name", "amount", "dueAt", "status"],
  ),
  Overview: obj(
    {
      asOf: date,
      nextPayday: { ...date, nullable: true },
      daysRemaining: { ...integer, nullable: true },
      missingData: array(str),
      currency: str,
      total: money,
      unpaidBills: money,
      protectedMoney: money,
      available: maybeMoney,
      dailyReference: maybeMoney,
      wallets: array(ref("Wallet")),
      bills: array(ref("Bill")),
    },
    [
      "asOf",
      "nextPayday",
      "daysRemaining",
      "missingData",
      "total",
      "unpaidBills",
      "protectedMoney",
      "available",
      "dailyReference",
      "wallets",
      "bills",
    ],
  ),
  Budget: obj({
    ...identity,
    name: str,
    periodType: { type: "string", enum: ["month", "pay_cycle"] },
    startAt: date,
    endAt: date,
    status: str,
    warningPercent: integer,
    limits: array(
      obj(
        {
          categoryId: id,
          limit: money,
          spent: money,
          remaining: money,
          percent: { type: "number", nullable: true },
          warning: boolean,
        },
        ["categoryId", "limit", "spent", "remaining"],
      ),
    ),
    totalLimit: money,
    totalSpent: money,
  }),
  Goal: obj({
    ...identity,
    name: str,
    targetAmount: money,
    targetAt: date,
    protect: boolean,
    status: str,
    allocated: money,
    percent: { type: "number", nullable: true },
    allocations: array(
      obj({ ...identity, goalId: id, walletId: id, amount: money }),
    ),
  }),
  Reflection: obj({
    ...identity,
    transactionId: id,
    transaction: ref("Transaction"),
    dueAt: date,
    status: { type: "string", enum: ["pending", "rated", "skipped"] },
    rating: { type: "string", enum: ["worth_it", "neutral", "reconsider"] },
    note: str,
    ratedAt: date,
  }),
  Insight: obj({
    ...identity,
    type: str,
    title: str,
    body: str,
    evidenceTransactionIds: array(id),
    status: { type: "string", enum: ["new", "accepted", "dismissed"] },
    generatedAt: date,
    action: obj({ type: str, categoryId: id, challengeType: str }),
  }),
  Report: obj({
    startAt: date,
    endAt: date,
    previousStartAt: date,
    income: money,
    expense: money,
    net: money,
    previousExpense: money,
    expenseChangePercent: { type: "number", nullable: true },
    byCategory: array(
      obj({ type: str, categoryId: id, amount: money, count: integer }),
    ),
  }),
  TransactionPage: obj(
    {
      items: array(ref("Transaction")),
      nextCursor: { type: "string", nullable: true },
    },
    ["items", "nextCursor"],
  ),
  HistoryScreen: obj({
    items: array(ref("Transaction")),
    nextCursor: { type: "string", nullable: true },
    groups: array(
      obj({
        date: { type: "string", format: "date" },
        items: array(ref("Transaction")),
        totalExpense: money,
        totalIncome: money,
        pageExpense: money,
        pageIncome: money,
      }),
    ),
    totalsScope: { type: "string", enum: ["allMatchingTransactionsPerDay"] },
    wallets: array(ref("Wallet")),
    categories: array(ref("Category")),
  }),
  AddTransactionScreen: obj({
    wallets: array(ref("Wallet")),
    categories: array(ref("Category")),
    defaultWalletId: { ...id, nullable: true },
    defaultOccurredAt: date,
    quickAmounts: array(money),
    overview: ref("Overview"),
  }),
  PlansScreen: obj({
    overview: ref("Overview"),
    budgets: array(ref("Budget")),
    goals: array(ref("Goal")),
    bills: array(ref("Bill")),
    categories: array(ref("Category")),
  }),
  ReviewScreen: obj({
    report: ref("Report"),
    reflections: array(ref("Reflection")),
    patterns: obj({
      sampleCount: integer,
      hasEnoughData: boolean,
      byCategory: array(
        obj({ _id: obj({ categoryId: id, rating: str }), count: integer }),
      ),
    }),
    insights: array(ref("Insight")),
    categories: array(ref("Category")),
  }),
  PurchaseSimulation: obj({
    isSimulation: { type: "boolean", enum: [true] },
    before: ref("Overview"),
    price: money,
    releasedReservation: money,
    availableAfter: maybeMoney,
    dailyAfter: maybeMoney,
    assumptions: array(str),
  }),
};
schemas.Dashboard = {
  allOf: [
    ref("Overview"),
    obj({
      displayName: str,
      hideAmounts: boolean,
      recentTransactions: array(ref("Transaction")),
      unreadNotifications: integer,
    }),
  ],
};
const contracts = {
  "GET /dashboard": "Dashboard",
  "GET /screens/add-transaction": "AddTransactionScreen",
  "GET /screens/transactions": "HistoryScreen",
  "GET /screens/plans": "PlansScreen",
  "GET /screens/review": "ReviewScreen",
  "GET /reports": "Report",
  "GET /transactions": "TransactionPage",
  "GET /transactions/{id}": "Transaction",
  "POST /transactions": "Transaction",
  "PUT /transactions/{id}": "Transaction",
  "POST /transactions/{id}/void": "Transaction",
  "POST /transactions/{id}/restore": "Transaction",
  "POST /simulations/purchase": "PurchaseSimulation",
  "POST /simulations/salary-delay": "PurchaseSimulation",
  "POST /wallets": "Wallet",
  "PATCH /wallets/{id}": "Wallet",
  "POST /categories": "Category",
  "PATCH /categories/{id}": "Category",
  "POST /budgets": "Budget",
  "PUT /budgets/{id}": "Budget",
  "POST /bills/{id}/pay": "Transaction",
  "PUT /reflections/{id}": "Reflection",
  "GET /wallets": ["Wallet"],
  "GET /categories": ["Category"],
  "GET /budgets": ["Budget"],
  "GET /goals": ["Goal"],
  "GET /bills": ["Bill"],
  "GET /reflections": ["Reflection"],
  "GET /insights": ["Insight"],
};
const samples = {
  "GET /dashboard": "dashboard",
  "GET /screens/add-transaction": "add-transaction",
  "GET /screens/transactions": "transactions",
  "GET /screens/plans": "plans",
  "GET /screens/review": "review",
  "POST /simulations/purchase": "purchase-simulation",
};
export function documentResponses({ openapiObject: spec }) {
  Object.assign(spec.components.schemas, schemas);
  for (const [name, shape] of Object.entries(contracts)) {
    const [method, path] = name.split(" "),
      op = spec.paths["/api/v1" + path]?.[method.toLowerCase()];
    if (!op) continue;
    const content = {
      schema: obj(
        { data: Array.isArray(shape) ? array(ref(shape[0])) : ref(shape) },
        ["data"],
      ),
    };
    if (samples[name])
      try {
        content.example = JSON.parse(
          readFileSync(
            new URL("../examples/" + samples[name] + ".json", import.meta.url),
            "utf8",
          ),
        );
      } catch {}
    op.responses["200"] = {
      description: "Thành công. Ví dụ minh họa lấy từ database kiểm thử.",
      content: { "application/json": content },
    };
  }
  for (const [path, methods] of Object.entries(spec.paths))
    for (const [method, op] of Object.entries(methods)) {
      if (path === "/api/v1/attachments/{id}" && method === "get")
        op.responses = {
          200: {
            description: "Ảnh cần Bearer token",
            content: {
              "image/png": { schema: { type: "string", format: "binary" } },
              "image/jpeg": { schema: { type: "string", format: "binary" } },
              "image/webp": { schema: { type: "string", format: "binary" } },
            },
          },
        };
      if (path === "/api/v1/exports/transactions.csv")
        op.responses = {
          200: {
            description: "CSV UTF-8 với BOM",
            content: { "text/csv": { schema: { type: "string" } } },
          },
        };
    }
  return spec;
}
