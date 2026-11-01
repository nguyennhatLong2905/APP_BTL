// Run ONLY against an empty demo database. Never resets existing data.
(() => {
const d=db.getSiblingDB('vi_an');
if(d.getCollectionNames().some(name=>d.getCollection(name).countDocuments({})>0)) throw new Error('Demo seed requires an empty database.');
const oid=n=>ObjectId(n.toString(16).padStart(24,'0'));
const L=n=>NumberLong(String(n));
const at=s=>new Date(s);
const now=at('2026-10-02T23:59:59+07:00');
const user=oid(1), cash=oid(2), bank=oid(3);
const cat={food:oid(10),travel:oid(11),shopping:oid(12),other:oid(13),bills:oid(14),learning:oid(15),income:oid(16)};
const base={userId:user,createdAt:now,updatedAt:now};
d.users.insertOne({_id:user,authSubject:'demo:an',displayName:'An',timezone:'Asia/Ho_Chi_Minh',currency:'VND',nextPayday:at('2026-10-16T00:00:00+07:00'),paydayDay:NumberInt(16),settings:{hideAmounts:false,defaultWalletId:cash,reviewDelayDays:NumberInt(7)},createdAt:now,updatedAt:now});
d.wallets.insertMany([
 {_id:cash,...base,name:'Ví tiền mặt',type:'cash',currency:'VND',openingBalance:L(215000),openingAt:at('2026-09-16T00:00:00+07:00'),balance:L(600000),status:'active',version:NumberInt(0)},
 {_id:bank,...base,name:'Tài khoản thanh toán',type:'bank',currency:'VND',openingBalance:L(8765000),openingAt:at('2026-09-16T00:00:00+07:00'),balance:L(7400000),status:'active',version:NumberInt(0)}
]);
d.categories.insertMany(Object.entries(cat).map(([k,_id],i)=>({_id,...base,name:{food:'Ăn uống',travel:'Đi lại',shopping:'Mua sắm cá nhân',other:'Sinh hoạt & khác',bills:'Hóa đơn',learning:'Học tập',income:'Thu nhập'}[k],kind:k==='income'?'income':'expense',status:'active',sortOrder:NumberInt(i)})));
const tx=(n,type,amount,time,extra)=>({_id:oid(n),...base,type,amount:L(amount),currency:'VND',occurredAt:at(time),status:'posted',idempotencyKey:'demo:'+n,version:NumberInt(1),source:'manual',...extra});
d.transactions.insertMany([
 tx(100,'expense',45000,'2026-10-02T08:30:00+07:00',{walletId:cash,categoryId:cat.food,note:'Cà phê sáng'}),
 tx(101,'expense',60000,'2026-10-02T12:15:00+07:00',{walletId:bank,categoryId:cat.food,note:'Cơm trưa văn phòng'}),
 tx(102,'expense',70000,'2026-10-02T17:45:00+07:00',{walletId:cash,categoryId:cat.travel,note:'Đổ xăng xe máy'}),
 tx(103,'income',25000,'2026-10-01T10:00:00+07:00',{walletId:bank,categoryId:cat.income,note:'Tiền hoàn cashback'}),
 tx(104,'transfer',500000,'2026-10-01T15:00:00+07:00',{fromWalletId:bank,toWalletId:cash,note:'Rút tiền mặt'}),
 tx(105,'expense',450000,'2026-09-25T10:00:00+07:00',{walletId:bank,categoryId:cat.learning,note:'Khóa học tiếng Anh giao tiếp'}),
 tx(106,'expense',380000,'2026-09-24T10:00:00+07:00',{walletId:bank,categoryId:cat.shopping,note:'Áo khoác gió thu đông'})
]);
d.budget_plans.insertOne({_id:oid(200),...base,name:'Kỳ lương 16/09 – 16/10',periodType:'pay_cycle',startAt:at('2026-09-16T00:00:00+07:00'),endAt:at('2026-10-16T00:00:00+07:00'),status:'active',warningPercent:NumberInt(80),limits:[{categoryId:cat.food,limit:L(2500000)},{categoryId:cat.travel,limit:L(600000)},{categoryId:cat.shopping,limit:L(1000000)},{categoryId:cat.other,limit:L(1400000)}]});
d.goals.insertOne({_id:oid(300),...base,name:'Quỹ dự phòng',targetAmount:L(12000000),protect:true,status:'active'});
d.goal_allocations.insertOne({_id:oid(301),...base,goalId:oid(300),walletId:bank,amount:L(2400000)});
d.bill_templates.insertMany([
 {_id:oid(400),...base,name:'Tiền nhà',estimatedAmount:L(3000000),categoryId:cat.bills,preferredWalletId:bank,frequency:'monthly',dueDay:NumberInt(5),active:true,reminderDaysBefore:NumberInt(3)},
 {_id:oid(401),...base,name:'Điện nước sinh hoạt',estimatedAmount:L(500000),categoryId:cat.bills,preferredWalletId:bank,frequency:'monthly',dueDay:NumberInt(10),active:true,reminderDaysBefore:NumberInt(3)}
]);
d.bill_occurrences.insertMany([
 {_id:oid(410),...base,templateId:oid(400),name:'Tiền nhà',amount:L(3000000),categoryId:cat.bills,dueAt:at('2026-10-05T00:00:00+07:00'),status:'unpaid'},
 {_id:oid(411),...base,templateId:oid(401),name:'Điện nước sinh hoạt',amount:L(500000),categoryId:cat.bills,dueAt:at('2026-10-10T00:00:00+07:00'),status:'unpaid'}
]);
d.purchase_intents.insertOne({_id:oid(500),...base,name:'Tai nghe chống ồn không dây',price:L(900000),categoryId:cat.shopping,status:'waiting',remindAt:at('2026-10-16T09:00:00+07:00'),dailySaving:L(30000),snapshot:{calculatedAt:now,nextPayday:at('2026-10-16T00:00:00+07:00'),availableBefore:L(2100000),daysRemaining:NumberInt(14)}});
d.reflections.insertMany([
 {_id:oid(600),...base,transactionId:oid(105),dueAt:at('2026-10-02T10:00:00+07:00'),status:'pending'},
 {_id:oid(601),...base,transactionId:oid(106),dueAt:at('2026-10-01T10:00:00+07:00'),status:'pending'}
]);
d.insights.insertOne({_id:oid(700),...base,type:'cooldown_suggestion',title:'Thử khoảng lặng 48h trước khi mua',body:'Gợi ý trải nghiệm; chưa đủ đánh giá để kết luận về thói quen cá nhân.',evidenceTransactionIds:[],status:'new',generatedAt:now,action:{type:'start_challenge',challengeType:'cooldown_48h'}});
d.notifications.insertMany([
 {_id:oid(800),...base,type:'bill_due',entityId:oid(410),scheduledAt:at('2026-10-02T09:00:00+07:00'),status:'pending',dedupeKey:'bill:410:2026-10',attempts:NumberInt(0)},
 {_id:oid(801),...base,type:'review_due',entityId:oid(600),scheduledAt:at('2026-10-02T10:00:00+07:00'),status:'pending',dedupeKey:'review:105',attempts:NumberInt(0)}
]);
print('Seed ready: demo user '+user+'; balances 600,000 + 7,400,000 VND.');
})();
