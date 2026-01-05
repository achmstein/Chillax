import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios'
import { API_CONFIG } from '@/config/api-config'

// Create an axios instance factory that adds auth token
function createApiClient(baseURL: string): AxiosInstance {
  const client = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
  })

  // Request interceptor to add auth token
  client.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
      // Get the access token from OIDC user in session storage
      const oidcStorage = sessionStorage.getItem(
        `oidc.user:${import.meta.env.VITE_IDENTITY_URL || 'https://localhost:5243'}:chillax-admin`
      )
      if (oidcStorage) {
        const user = JSON.parse(oidcStorage)
        if (user?.access_token) {
          config.headers.Authorization = `Bearer ${user.access_token}`
        }
      }
      return config
    },
    (error) => Promise.reject(error)
  )

  return client
}

// API clients for each service
export const catalogApi = createApiClient(API_CONFIG.catalog)
export const ordersApi = createApiClient(API_CONFIG.orders)
export const roomsApi = createApiClient(API_CONFIG.rooms)
