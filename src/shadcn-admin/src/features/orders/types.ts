// Order types matching the Ordering.API models

export type OrderStatus = 'submitted' | 'confirmed' | 'cancelled'

export interface OrderItem {
  productId: number
  productName: string
  unitPrice: number
  discount: number
  units: number
  pictureUrl?: string
  specialInstructions?: string
  customizationsDescription?: string
}

export interface OrderSummary {
  ordernumber: number
  date: string
  status: OrderStatus
  total: number
}

export interface Order {
  ordernumber: number
  date: string
  status: OrderStatus
  description?: string
  tableNumber?: number
  customerNote?: string
  orderitems: OrderItem[]
  total: number
}

export interface PendingOrder extends OrderSummary {
  customerName?: string
  tableNumber?: number
  customerNote?: string
  itemCount: number
}
