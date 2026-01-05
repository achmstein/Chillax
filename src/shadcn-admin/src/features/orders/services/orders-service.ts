import { ordersApi } from '@/lib/api-client'
import type { Order, OrderSummary } from '../types'

export const ordersService = {
  // Get all orders for the current user (admin sees all)
  async getOrders(): Promise<OrderSummary[]> {
    const response = await ordersApi.get<OrderSummary[]>('/api/orders')
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
