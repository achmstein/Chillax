import axios from 'axios'
import { useAuthStore } from '@/stores/auth-store'

const API_BASE_URL = import.meta.env.VITE_ADMIN_API_URL || 'https://localhost:5101'

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add auth token to requests
apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().auth.accessToken
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle response errors
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // Let the query cache handle 401/403 errors
    return Promise.reject(error)
  }
)
