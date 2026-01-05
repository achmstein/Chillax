// API endpoints configuration
// In development, APIs run on different ports
// In production, all should be behind a single gateway

export const API_CONFIG = {
  catalog: import.meta.env.VITE_CATALOG_API_URL || 'https://localhost:5221',
  orders: import.meta.env.VITE_ORDERS_API_URL || 'https://localhost:5224',
  rooms: import.meta.env.VITE_ROOMS_API_URL || 'https://localhost:5250',
  identity: import.meta.env.VITE_IDENTITY_URL || 'https://localhost:5243',
} as const
