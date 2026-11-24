import { MongoClient, ObjectId } from "mongodb";

const client = new MongoClient("mongodb://127.0.0.1:27017");
await client.connect();
const db = client.db("vi_an");

console.log("=== KIỂM TRA DỮ LIỆU CƠ SỞ DỮ LIỆU ===");
let users = await db.collection("users").find({}).toArray();
console.log(`Tìm thấy ${users.length} user(s):`, users.map(u => ({ id: u._id.toString(), authSubject: u.authSubject, displayName: u.displayName })));

// Nếu chưa có user hoặc chưa có user demo/local, tạo hoặc lấy user đầu tiên
let user = users[0];
if (!user) {
  console.log("Chưa có user nào, tạo user test...");
  const now = new Date();
  const res = await db.collection("users").insertOne({
    authSubject: "demo:an",
    displayName: "An",
    timezone: "Asia/Ho_Chi_Minh",
    currency: "VND",
    nextPayday: new Date(now.getTime() + 15 * 86400000),
    settings: { hideAmounts: false, reviewDelayDays: 7 },
    tokenVersion: 0,
    createdAt: now,
    updatedAt: now,
  });
  user = await db.collection("users").findOne({ _id: res.insertedId });
} else if (!users.some(u => u.authSubject === "demo:an")) {
  // Tạo user demo:an để hỗ trợ demo login
  const now = new Date();
  await db.collection("users").insertOne({
    authSubject: "demo:an",
    displayName: "An Demo",
    timezone: "Asia/Ho_Chi_Minh",
    currency: "VND",
    nextPayday: new Date(now.getTime() + 15 * 86400000),
    settings: { hideAmounts: false, reviewDelayDays: 7 },
    tokenVersion: 0,
    createdAt: now,
    updatedAt: now,
  });
  console.log("Đã tạo user demo:an");
}

await client.close();
console.log("Hoàn tất kiểm tra database.");

