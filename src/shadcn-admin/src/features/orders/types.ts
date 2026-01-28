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
  roomName?: string
  customerNote?: string
  orderitems: OrderItem[]
  total: number
}

export interface PendingOrder extends OrderSummary {
  customerName?: string
  roomName?: string
  customerNote?: string
  itemCount: number
}

export interface PaginatedResult<T> {
  items: T[]
  pageIndex: number
  pageSize: number
  totalCount: number
  totalPages: number
  hasNextPage: boolean
  hasPreviousPage: boolean
}
