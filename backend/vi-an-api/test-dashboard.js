import { MongoClient, ObjectId } from "mongodb";
import { overview, listEntries } from "./src/views.js";
import { now } from "./src/common.js";

async function test() {
  const client = new MongoClient("mongodb://127.0.0.1:27017/");
  await client.connect();
  const db = client.db("vi_an");

  const req = { owner: new ObjectId('6af7e1c48790a3bff575e33e') };

  try {
    const o = await overview(db, req.owner);
    const recent = await listEntries(db, req.owner, { limit: 3 });
    const user = await db.collection("users").findOne({ _id: req.owner });

    async function enrich(userId, items) {
      const cats = await db.collection("categories").find({ userId }).toArray();
      const wallets = await db.collection("wallets").find({ userId }).toArray();
      const names = (rows, id) => rows.find((x) => id && x._id.equals(id)) || null;
      return items.map((t) => ({
        ...t,
        category: names(cats, t.categoryId),
        wallet: names(wallets, t.walletId),
        fromWallet: names(wallets, t.fromWalletId),
        toWallet: names(wallets, t.toWalletId),
      }));
    }

    const res = {
      ...o,
      displayName: user.displayName,
      hideAmounts: user.settings?.hideAmounts || false,
      recentTransactions: await enrich(req.owner, recent.items),
      unreadNotifications: await db
        .collection("notifications")
        .countDocuments({
          userId: req.owner,
          scheduledAt: { $lte: now() },
          status: { $ne: "cancelled" },
          readAt: { $exists: false },
        }),
    };
    console.log("SUCCESS:", res);
  } catch (e) {
    console.error("ERROR:", e);
  } finally {
    await client.close();
  }
}
test();