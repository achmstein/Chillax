import { identityApi } from '@/lib/api-client'
import type { Customer, CustomerParams } from '../types'

export const customersService = {
  // Get paginated list of customers
  async getCustomers(params: CustomerParams = {}): Promise<Customer[]> {
    const queryParams = new URLSearchParams()
    if (params.first !== undefined) {
      queryParams.append('first', String(params.first))
    }
    if (params.max !== undefined) {
      queryParams.append('max', String(params.max))
    }
    if (params.search) {
      queryParams.append('search', params.search)
    }

    const url = `/api/identity/users${queryParams.toString() ? `?${queryParams}` : ''}`
    const response = await identityApi.get<Customer[]>(url)
    return response.data
  },

  // Get a single customer by ID
  async getCustomer(userId: string): Promise<Customer> {
    const response = await identityApi.get<Customer>(`/api/identity/users/${userId}`)
    return response.data
  },

  // Get total customer count
  async getCustomerCount(search?: string): Promise<number> {
    const queryParams = search ? `?search=${encodeURIComponent(search)}` : ''
    const response = await identityApi.get<number>(`/api/identity/users/count${queryParams}`)
    return response.data
  },
}
