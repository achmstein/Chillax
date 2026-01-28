import { ordersApi } from '@/lib/api-client'
import type { Order, OrderSummary, PaginatedResult } from '../types'

export const ordersService = {
  // Get all orders with pagination
  async getOrders(pageIndex = 0, pageSize = 20): Promise<PaginatedResult<OrderSummary>> {
    const response = await ordersApi.get<PaginatedResult<OrderSummary>>('/api/orders', {
      params: { pageIndex, pageSize }
    })
    return response.data
  },

  // Get pending orders (status = Submitted)
  async getPendingOrders(): Promise<OrderSummary[]> {
    const response = await ordersApi.get<OrderSummary[]>('/api/orders/pending')
    return response.data
  },

  // Get a single order by ID
  async getOrder(orderId: number): Promise<Order> {
    const response = await ordersApi.get<Order>(`/api/orders/${orderId}`)
    return response.data
  },

  // Confirm an order (changes status from Submitted to Confirmed)
  async confirmOrder(orderId: number, requestId: string): Promise<boolean> {
    const response = await ordersApi.put<boolean>(
      '/api/orders/confirm',
      { orderNumber: orderId },
      { headers: { 'x-requestid': requestId } }
    )
    return response.data
  },

  // Cancel an order
  async cancelOrder(orderId: number, requestId: string): Promise<boolean> {
    const response = await ordersApi.put<boolean>(
      '/api/orders/cancel',
      { orderNumber: orderId },
      { headers: { 'x-requestid': requestId } }
    )
    return response.data
  },
}
