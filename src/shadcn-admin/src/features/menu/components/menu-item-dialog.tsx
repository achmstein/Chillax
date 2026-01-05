import { useEffect, useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { menuService } from '../services/menu-service'
import type { CatalogType, MenuItem, MenuItemFormData } from '../types'

interface MenuItemDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  item: MenuItem | null
  categories: CatalogType[]
}

export function MenuItemDialog({
  open,
  onOpenChange,
  item,
  categories,
}: MenuItemDialogProps) {
  const queryClient = useQueryClient()
  const isEditing = !!item

  const [formData, setFormData] = useState<MenuItemFormData>({
    name: '',
    description: '',
    price: 0,
    catalogTypeId: 1,
    isAvailable: true,
    preparationTimeMinutes: undefined,
  })

  const [errors, setErrors] = useState<Record<string, string>>({})

  // Reset form when item changes
  useEffect(() => {
    if (item) {
      setFormData({
        name: item.name,
        description: item.description || '',
        price: item.price,
        catalogTypeId: item.catalogTypeId,
        isAvailable: item.isAvailable,
        preparationTimeMinutes: item.preparationTimeMinutes || undefined,
      })
    } else {
      setFormData({
        name: '',
        description: '',
        price: 0,
        catalogTypeId: 1,
        isAvailable: true,
        preparationTimeMinutes: undefined,
      })
    }
    setErrors({})
  }, [item, open])

  const createMutation = useMutation({
    mutationFn: (data: MenuItemFormData) => menuService.createMenuItem(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Item created successfully')
      onOpenChange(false)
    },
    onError: () => {
      toast.error('Failed to create item')
    },
  })

  const updateMutation = useMutation({
    mutationFn: (data: MenuItemFormData) =>
      menuService.updateMenuItem(item!.id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Item updated successfully')
      onOpenChange(false)
    },
    onError: () => {
      toast.error('Failed to update item')
    },
  })

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {}
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required'
    }
    if (formData.price < 0) {
      newErrors.price = 'Price must be positive'
    }
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return

    if (isEditing) {
      updateMutation.mutate(formData)
    } else {
      createMutation.mutate(formData)
    }
  }

  const isLoading = createMutation.isPending || updateMutation.isPending

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='sm:max-w-[500px]'>
        <DialogHeader>
          <DialogTitle>{isEditing ? 'Edit Menu Item' : 'Add Menu Item'}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? 'Update the menu item details below'
              : 'Fill in the details to add a new menu item'}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className='space-y-4'>
          <div className='space-y-2'>
            <Label htmlFor='name'>Name</Label>
            <Input
              id='name'
              placeholder='Cappuccino'
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />
            {errors.name && <p className='text-sm text-destructive'>{errors.name}</p>}
          </div>

          <div className='space-y-2'>
            <Label htmlFor='description'>Description</Label>
            <Textarea
              id='description'
              placeholder='A rich espresso topped with steamed milk foam...'
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div className='grid grid-cols-2 gap-4'>
            <div className='space-y-2'>
              <Label htmlFor='price'>Price (EGP)</Label>
              <Input
                id='price'
                type='number'
                step='0.01'
                min='0'
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) || 0 })}
              />
              {errors.price && <p className='text-sm text-destructive'>{errors.price}</p>}
            </div>

            <div className='space-y-2'>
              <Label htmlFor='category'>Category</Label>
              <Select
                value={String(formData.catalogTypeId)}
                onValueChange={(value) => setFormData({ ...formData, catalogTypeId: parseInt(value) })}
              >
                <SelectTrigger>
                  <SelectValue placeholder='Select category' />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat.id} value={String(cat.id)}>
                      {cat.type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className='space-y-2'>
            <Label htmlFor='prepTime'>Preparation Time (minutes)</Label>
            <Input
              id='prepTime'
              type='number'
              min='0'
              placeholder='Optional'
              value={formData.preparationTimeMinutes || ''}
              onChange={(e) => setFormData({
                ...formData,
                preparationTimeMinutes: e.target.value ? parseInt(e.target.value) : undefined
              })}
            />
            <p className='text-sm text-muted-foreground'>
              Estimated time to prepare this item
            </p>
          </div>

          <div className='flex flex-row items-center justify-between rounded-lg border p-4'>
            <div className='space-y-0.5'>
              <Label className='text-base'>Available</Label>
              <p className='text-sm text-muted-foreground'>
                Make this item available for ordering
              </p>
            </div>
            <Switch
              checked={formData.isAvailable}
              onCheckedChange={(checked) => setFormData({ ...formData, isAvailable: checked })}
            />
          </div>

          <DialogFooter>
            <Button
              type='button'
              variant='outline'
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type='submit' disabled={isLoading}>
              {isLoading && <Loader2 className='mr-2 h-4 w-4 animate-spin' />}
              {isEditing ? 'Update' : 'Create'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
