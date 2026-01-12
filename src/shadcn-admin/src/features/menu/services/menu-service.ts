import { catalogApi } from '@/lib/api-client'
import type { CatalogType, CategoryFormData, MenuItem, MenuItemFormData, PaginatedItems } from '../types'

export const menuService = {
  // Get paginated menu items
  async getMenuItems(pageIndex = 0, pageSize = 10, typeId?: number): Promise<PaginatedItems<MenuItem>> {
    const params = new URLSearchParams({
      pageIndex: String(pageIndex),
      pageSize: String(pageSize),
    })
    if (typeId) {
      params.append('type', String(typeId))
    }
    const response = await catalogApi.get<PaginatedItems<MenuItem>>(`/api/catalog/items?${params}`)
    return response.data
  },

  // Get a single menu item by ID
  async getMenuItem(id: number): Promise<MenuItem> {
    const response = await catalogApi.get<MenuItem>(`/api/catalog/items/${id}`)
    return response.data
  },

  // Create a new menu item
  async createMenuItem(data: MenuItemFormData): Promise<MenuItem> {
    const response = await catalogApi.post<MenuItem>('/api/catalog/items', data)
    return response.data
  },

  // Update an existing menu item
  async updateMenuItem(id: number, data: MenuItemFormData): Promise<MenuItem> {
    const response = await catalogApi.put<MenuItem>(`/api/catalog/items/${id}`, {
      id,
      ...data,
    })
    return response.data
  },

  // Delete a menu item
  async deleteMenuItem(id: number): Promise<void> {
    await catalogApi.delete(`/api/catalog/items/${id}`)
  },

  // Toggle item availability
  async toggleAvailability(id: number, isAvailable: boolean): Promise<MenuItem> {
    const item = await menuService.getMenuItem(id)
    return menuService.updateMenuItem(id, {
      name: item.name,
      description: item.description,
      price: item.price,
      catalogTypeId: item.catalogTypeId,
      isAvailable,
      preparationTimeMinutes: item.preparationTimeMinutes,
    })
  },

  // Get all catalog types (menu categories)
  async getCategories(): Promise<CatalogType[]> {
    const response = await catalogApi.get<CatalogType[]>('/api/catalog/catalogtypes')
    return response.data
  },

  // Get item picture URL
  getItemPictureUrl(id: number): string {
    return `${catalogApi.defaults.baseURL}/api/catalog/items/${id}/pic`
  },

  // Create a new category
  async createCategory(data: CategoryFormData): Promise<CatalogType> {
    const response = await catalogApi.post<CatalogType>('/api/catalog/categories', data)
    return response.data
  },

  // Update an existing category
  async updateCategory(id: number, data: CategoryFormData): Promise<CatalogType> {
    const response = await catalogApi.put<CatalogType>(`/api/catalog/categories/${id}`, data)
    return response.data
  },

  // Delete a category
  async deleteCategory(id: number): Promise<void> {
    await catalogApi.delete(`/api/catalog/categories/${id}`)
  },

  // Get item count per category
  async getItemCountByCategory(): Promise<Record<number, number>> {
    // Fetch all items and count by category
    const response = await catalogApi.get<PaginatedItems<MenuItem>>('/api/catalog/items?pageSize=1000')
    const counts: Record<number, number> = {}
    for (const item of response.data.data) {
      counts[item.catalogTypeId] = (counts[item.catalogTypeId] || 0) + 1
    }
    return counts
  },
}
