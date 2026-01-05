import { apiClient } from './client'

export interface Customer {
  id: string
  userName: string
  email: string
  phoneNumber: string | null
  fullName: string
  isBlocked: boolean
  emailVerified: boolean
  phoneVerified: boolean
  lastOrderAt: string | null
  totalOrders: number
  totalSpent: number
}

export interface CustomersResponse {
  items: Customer[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
}

export interface GetCustomersParams {
  page?: number
  pageSize?: number
  search?: string
  status?: string // 'blocked' | 'active' | 'unverified'
}

export const customersApi = {
  getCustomers: async (params: GetCustomersParams = {}): Promise<CustomersResponse> => {
    const { page = 1, pageSize = 10, search, status } = params
    const response = await apiClient.get<CustomersResponse>('/api/v1/customers', {
      params: { page, pageSize, search, status },
    })
    return response.data
  },

  blockCustomer: async (customerId: string): Promise<void> => {
    await apiClient.post(`/api/v1/customers/${customerId}/block`)
  },

  unblockCustomer: async (customerId: string): Promise<void> => {
    await apiClient.post(`/api/v1/customers/${customerId}/unblock`)
  },
}
