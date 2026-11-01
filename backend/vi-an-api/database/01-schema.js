// mongosh: load('01-schema.js'); safe to rerun; never drops collections.
(() => {
const d = db.getSiblingDB('vi_an');
const id = {bsonType:'objectId'}, str={bsonType:'string'}, date={bsonType:'date'};
const money={bsonType:'long',minimum:0};
const positive={bsonType:'long',minimum:1};
const en=(...values)=>({enum:values});
const common={_id:id,userId:id,createdAt:date,updatedAt:date};
function define(name,required,properties,extra={}) {
 const schema={bsonType:'object',required:['_id','userId','createdAt','updatedAt',...required],properties:{...common,...properties},...extra};
 const options={validator:{$jsonSchema:schema},validationLevel:'strict',validationAction:'error'};
 if(d.getCollectionNames().includes(name)) d.runCommand({collMod:name,...options});
 else d.createCollection(name,options);
}
// users are the only documents without userId; auth credentials stay with auth provider.
const us={bsonType:'object',required:['_id','authSubject','displayName','timezone','currency','nextPayday','createdAt','updatedAt'],properties:{_id:id,authSubject:str,displayName:str,timezone:str,currency:{enum:['VND']},nextPayday:date,paydayDay:{bsonType:'int',minimum:1,maximum:31},settings:{bsonType:'object',properties:{hideAmounts:{bsonType:'bool'},defaultWalletId:id,reviewDelayDays:{bsonType:'int',minimum:0},workIncome:money,workHours:{bsonType:'int',minimum:1}}},createdAt:date,updatedAt:date}};
if(d.getCollectionNames().includes('users')) d.runCommand({collMod:'users',validator:{$jsonSchema:us},validationLevel:'strict',validationAction:'error'});
else d.createCollection('users',{validator:{$jsonSchema:us},validationLevel:'strict',validationAction:'error'});
define('wallets',['name','type','currency','openingBalance','openingAt','balance','status','version'],{
 name:str,type:en('cash','bank','ewallet','savings'),currency:en('VND'),openingBalance:{bsonType:'long'},openingAt:date,balance:{bsonType:'long'},status:en('active','archived'),version:{bsonType:'int',minimum:0},icon:str,color:str});
define('categories',['name','kind','status'],{name:str,kind:en('expense','income'),status:en('active','archived'),icon:str,color:str,sortOrder:{bsonType:'int'}});
define('transactions',['type','amount','currency','occurredAt','status','idempotencyKey','version'],{
 type:en('expense','income','transfer','adjustment'),amount:positive,currency:en('VND'),occurredAt:date,status:en('posted','voided'),idempotencyKey:str,version:{bsonType:'int',minimum:1},walletId:id,fromWalletId:id,toWalletId:id,categoryId:id,adjustmentDirection:en('increase','decrease'),note:str,merchant:str,billOccurrenceId:id,purchaseIntentId:id,voidedAt:date,source:en('manual','import','bill','purchase','reconciliation'),attachments:{bsonType:'array',maxItems:10,items:{bsonType:'object',required:['storageKey','mimeType'],properties:{storageKey:str,mimeType:str}}}
},{oneOf:[
 {required:['walletId','categoryId'],properties:{type:en('expense','income')},not:{anyOf:[{required:['fromWalletId']},{required:['toWalletId']}]}},
 {required:['fromWalletId','toWalletId'],properties:{type:en('transfer')},not:{anyOf:[{required:['walletId']},{required:['categoryId']}]}},
 {required:['walletId','adjustmentDirection'],properties:{type:en('adjustment')},not:{anyOf:[{required:['fromWalletId']},{required:['toWalletId']},{required:['categoryId']}]}}
]});
define('budget_plans',['name','periodType','startAt','endAt','limits','status'],{name:str,periodType:en('month','pay_cycle'),startAt:date,endAt:date,status:en('active','closed'),warningPercent:{bsonType:'int',minimum:1,maximum:100},limits:{bsonType:'array',items:{bsonType:'object',required:['categoryId','limit'],properties:{categoryId:id,limit:money}}}});
define('goals',['name','targetAmount','protect','status'],{name:str,targetAmount:positive,targetAt:date,protect:{bsonType:'bool'},status:en('active','completed','archived'),icon:str});
define('goal_allocations',['goalId','walletId','amount'],{goalId:id,walletId:id,amount:money});
define('bill_templates',['name','estimatedAmount','categoryId','frequency','active'],{name:str,estimatedAmount:positive,categoryId:id,preferredWalletId:id,frequency:en('once','monthly','yearly'),dueDay:{bsonType:'int',minimum:1,maximum:31},active:{bsonType:'bool'},reminderDaysBefore:{bsonType:'int',minimum:0}});
define('bill_occurrences',['templateId','name','amount','categoryId','dueAt','status'],{templateId:id,name:str,amount:positive,categoryId:id,dueAt:date,status:en('unpaid','paid','cancelled'),transactionId:id,paidAt:date});
define('purchase_intents',['name','price','categoryId','status'],{name:str,price:positive,categoryId:id,status:en('draft','waiting','purchased','cancelled'),remindAt:date,dailySaving:money,transactionId:id,snapshot:{bsonType:'object',required:['calculatedAt','nextPayday','availableBefore','daysRemaining'],properties:{calculatedAt:date,nextPayday:date,availableBefore:{bsonType:'long'},daysRemaining:{bsonType:'int',minimum:0}}}});
define('reflections',['transactionId','dueAt','status'],{transactionId:id,dueAt:date,status:en('pending','rated','skipped'),rating:en('worth_it','neutral','reconsider'),note:str,ratedAt:date});
define('insights',['type','title','evidenceTransactionIds','status','generatedAt'],{type:en('spending_pattern','budget_suggestion','cooldown_suggestion','ai_recommendation'),title:str,body:str,evidenceTransactionIds:{bsonType:'array',maxItems:100,items:id},status:en('new','accepted','dismissed'),generatedAt:date,action:{bsonType:'object'},modelVersion:str,expiresAt:date});
define('challenges',['type','startAt','endAt','status'],{type:en('cooldown_48h','reduce_habit'),startAt:date,endAt:date,status:en('active','completed','cancelled'),purchaseIntentId:id,configuration:{bsonType:'object'}});
define('notifications',['type','scheduledAt','status','dedupeKey'],{type:en('bill_due','review_due','purchase_reminder','budget_warning'),scheduledAt:date,status:en('pending','processing','sent','cancelled'),dedupeKey:str,entityId:id,sentAt:date,lockedUntil:date,attempts:{bsonType:'int',minimum:0}});
const idx=(c,k,o={})=>d[c].createIndex(k,o);
idx('users',{authSubject:1},{unique:true});
idx('wallets',{userId:1,status:1}); idx('categories',{userId:1,kind:1,status:1});
idx('transactions',{userId:1,idempotencyKey:1},{unique:true});
idx('transactions',{userId:1,status:1,occurredAt:-1,_id:-1});
for(const field of ['walletId','fromWalletId','toWalletId','categoryId']) idx('transactions',{userId:1,[field]:1,status:1,occurredAt:-1,_id:-1});
idx('transactions',{userId:1,billOccurrenceId:1},{unique:true,partialFilterExpression:{status:'posted',billOccurrenceId:{$type:'objectId'}}});
idx('transactions',{userId:1,purchaseIntentId:1},{unique:true,partialFilterExpression:{status:'posted',purchaseIntentId:{$type:'objectId'}}});
idx('budget_plans',{userId:1,periodType:1,startAt:1},{unique:true});
idx('goals',{userId:1,status:1});
idx('goal_allocations',{userId:1,goalId:1,walletId:1},{unique:true});
idx('goal_allocations',{userId:1,walletId:1});
idx('bill_templates',{userId:1,active:1});
idx('bill_occurrences',{userId:1,templateId:1,dueAt:1},{unique:true});
idx('bill_occurrences',{userId:1,status:1,dueAt:1});
idx('purchase_intents',{userId:1,status:1,remindAt:1});
idx('reflections',{userId:1,transactionId:1},{unique:true});
idx('reflections',{userId:1,status:1,dueAt:1});
idx('insights',{userId:1,status:1,generatedAt:-1});
idx('challenges',{userId:1,status:1,endAt:1});
idx('notifications',{userId:1,dedupeKey:1},{unique:true});
idx('notifications',{status:1,scheduledAt:1});
print('vi_an: 14 collections and indexes ready.');
})();
