import { z } from 'zod'

export const customerSchema = z.object({
  id: z.string(),
  userName: z.string(),
  email: z.string(),
  phoneNumber: z.string().nullable(),
  fullName: z.string(),
  isBlocked: z.boolean(),
  emailVerified: z.boolean(),
  phoneVerified: z.boolean(),
  lastOrderAt: z.string().nullable(),
  totalOrders: z.number(),
  totalSpent: z.number(),
})

export type Customer = z.infer<typeof customerSchema>

export const customerStatuses = [
  { value: 'active', label: 'Active' },
  { value: 'blocked', label: 'Blocked' },
  { value: 'unverified', label: 'Unverified' },
] as const

export type CustomerStatus = (typeof customerStatuses)[number]['value']
