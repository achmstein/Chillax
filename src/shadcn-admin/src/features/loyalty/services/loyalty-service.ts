import { loyaltyApi } from '@/lib/api-client'
import type {
  LoyaltyAccount,
  LoyaltyStats,
  TierInfo,
  PointsTransaction,
  EarnPointsRequest,
  RedeemPointsRequest,
  AdjustPointsRequest,
} from '../types'

export const loyaltyService = {
  // Get paginated list of loyalty accounts
  async getAccounts(first = 0, max = 50): Promise<LoyaltyAccount[]> {
    const params = new URLSearchParams({
      first: String(first),
      max: String(max),
      'api-version': '1.0',
    })
    const response = await loyaltyApi.get<LoyaltyAccount[]>(`/api/loyalty/accounts?${params}`)
    return response.data
  },

  // Get a single loyalty account by user ID
  async getAccount(userId: string): Promise<LoyaltyAccount> {
    const response = await loyaltyApi.get<LoyaltyAccount>(
      `/api/loyalty/accounts/${userId}?api-version=1.0`
    )
    return response.data
  },

  // Get loyalty program statistics
  async getStats(): Promise<LoyaltyStats> {
    const response = await loyaltyApi.get<LoyaltyStats>('/api/loyalty/stats?api-version=1.0')
    return response.data
  },

  // Get tier information
  async getTiers(): Promise<TierInfo[]> {
    const response = await loyaltyApi.get<TierInfo[]>('/api/loyalty/tiers?api-version=1.0')
    return response.data
  },

  // Get transaction history for a user
  async getTransactions(userId: string, max = 50): Promise<PointsTransaction[]> {
    const params = new URLSearchParams({
      max: String(max),
      'api-version': '1.0',
    })
    const response = await loyaltyApi.get<PointsTransaction[]>(
      `/api/loyalty/transactions/${userId}?${params}`
    )
    return response.data
  },

  // Earn points for a user
  async earnPoints(data: EarnPointsRequest): Promise<void> {
    await loyaltyApi.post('/api/loyalty/transactions/earn?api-version=1.0', data)
  },

  // Redeem points for a user
  async redeemPoints(data: RedeemPointsRequest): Promise<void> {
    await loyaltyApi.post('/api/loyalty/transactions/redeem?api-version=1.0', data)
  },

  // Adjust points for a user (admin only)
  async adjustPoints(data: AdjustPointsRequest): Promise<void> {
    await loyaltyApi.post('/api/loyalty/transactions/adjust?api-version=1.0', data)
  },

  // Create a new loyalty account
  async createAccount(userId: string): Promise<LoyaltyAccount> {
    const response = await loyaltyApi.post<LoyaltyAccount>(
      '/api/loyalty/accounts?api-version=1.0',
      { userId }
    )
    return response.data
  },
}
