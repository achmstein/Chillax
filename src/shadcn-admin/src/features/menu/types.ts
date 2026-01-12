// Menu item types matching the Catalog.API models

export interface CatalogType {
  id: number
  type: string
}

export interface CustomizationOption {
  id: number
  itemCustomizationId: number
  name: string
  priceAdjustment: number
  isDefault: boolean
}

export interface ItemCustomization {
  id: number
  catalogItemId: number
  name: string
  isRequired: boolean
  allowMultiple: boolean
  options: CustomizationOption[]
}

export interface MenuItem {
  id: number
  name: string
  description?: string
  price: number
  pictureFileName?: string
  catalogTypeId: number
  catalogType?: CatalogType
  isAvailable: boolean
  preparationTimeMinutes?: number
  customizations: ItemCustomization[]
}

export interface MenuItemFormData {
  name: string
  description?: string
  price: number
  catalogTypeId: number
  isAvailable: boolean
  preparationTimeMinutes?: number
}

export interface PaginatedItems<T> {
  pageIndex: number
  pageSize: number
  count: number
  data: T[]
}

export interface CategoryFormData {
  type: string
}
