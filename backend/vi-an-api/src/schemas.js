import { z } from "zod";
import {
  id,
  money,
  positive,
  timestamp,
  text,
  note,
  version,
} from "./common.js";
export const obj = (shape) => z.object(shape).strict();
export const entry = obj({
  type: z.enum(["expense", "income", "transfer", "adjustment"]),
  amount: positive,
  occurredAt: timestamp,
  walletId: id.optional(),
  fromWalletId: id.optional(),
  toWalletId: id.optional(),
  categoryId: id.optional(),
  adjustmentDirection: z.enum(["increase", "decrease"]).optional(),
  note: note.optional(),
  merchant: text.optional(),
  trackReview: z.boolean().optional(),
  attachmentIds: z.array(id).max(10).optional(),
});
export const entryQuery = obj({
  status: z.enum(["posted", "voided"]).optional(),
  type: z.enum(["expense", "income", "transfer", "adjustment"]).optional(),
  walletId: id.optional(),
  categoryId: id.optional(),
  search: z.string().max(100).optional(),
  amount: money.optional(),
  startAt: timestamp.optional(),
  endAt: timestamp.optional(),
  cursor: z.string().max(500).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(30),
});
export const wallet = obj({
  name: text,
  type: z.enum(["cash", "bank", "ewallet", "savings"]),
  openingBalance: money,
  openingAt: timestamp,
});
export const category = obj({
  name: text,
  kind: z.enum(["expense", "income"]),
  icon: text.optional(),
  color: z
    .string()
    .regex(/^#[\da-f]{6}$/i)
    .optional(),
});
export const budget = obj({
  name: text,
  periodType: z.enum(["month", "pay_cycle"]),
  startAt: timestamp,
  endAt: timestamp,
  warningPercent: z.number().int().min(1).max(100).default(80),
  limits: z
    .array(obj({ categoryId: id, limit: money }))
    .min(1)
    .max(100),
});
export const goal = obj({
  name: text,
  targetAmount: positive,
  targetAt: timestamp.optional(),
  protect: z.boolean().default(true),
});
export const template = obj({
  name: text,
  estimatedAmount: positive,
  categoryId: id,
  preferredWalletId: id.optional(),
  frequency: z.enum(["once", "monthly", "yearly"]),
  startAt: timestamp,
  reminderDaysBefore: z.number().int().min(0).max(30).default(3),
});
export const purchase = obj({
  name: text,
  price: positive,
  categoryId: id,
  remindAt: timestamp.optional(),
  dailySaving: money.optional(),
});
export const settings = obj({
  hideAmounts: z.boolean().optional(),
  defaultWalletId: id.optional(),
  reviewDelayDays: z.number().int().min(0).max(90).optional(),
  workIncome: positive.optional(),
  workHours: z.number().int().min(1).max(1000).optional(),
  appLockEnabled: z.boolean().optional(),
});
export const profile = obj({
  displayName: text.optional(),
  nextPayday: timestamp.nullable().optional(),
  paydayDay: z.number().int().min(1).max(31).optional(),
  settings: settings.optional(),
});
export const signup = obj({
  email: z.email().max(254),
  password: z.string().min(10).max(128),
  displayName: text,
  nextPayday: timestamp.optional(),
});
export const login = obj({
  email: z.email().max(254),
  password: z.string().min(1).max(128),
});
export { z, id, money, positive, timestamp, text, note, version };
