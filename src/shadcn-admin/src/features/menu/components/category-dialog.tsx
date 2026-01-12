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
import { Button } from '@/components/ui/button'
import { menuService } from '../services/menu-service'
import type { CatalogType, CategoryFormData } from '../types'

interface CategoryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  category: CatalogType | null
}

export function CategoryDialog({
  open,
  onOpenChange,
  category,
}: CategoryDialogProps) {
  const queryClient = useQueryClient()
  const isEditing = !!category

  const [formData, setFormData] = useState<CategoryFormData>({
    type: '',
  })

  const [errors, setErrors] = useState<Record<string, string>>({})

  // Reset form when category changes
  useEffect(() => {
    if (category) {
      setFormData({
        type: category.type,
      })
    } else {
      setFormData({
        type: '',
      })
    }
    setErrors({})
  }, [category, open])

  const createMutation = useMutation({
    mutationFn: (data: CategoryFormData) => menuService.createCategory(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] })
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Category created successfully')
      onOpenChange(false)
    },
    onError: () => {
      toast.error('Failed to create category')
    },
  })

  const updateMutation = useMutation({
    mutationFn: (data: CategoryFormData) =>
      menuService.updateCategory(category!.id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] })
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Category updated successfully')
      onOpenChange(false)
    },
    onError: () => {
      toast.error('Failed to update category')
    },
  })

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {}
    if (!formData.type.trim()) {
      newErrors.type = 'Category name is required'
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
      <DialogContent className='sm:max-w-[400px]'>
        <DialogHeader>
          <DialogTitle>{isEditing ? 'Edit Category' : 'Add Category'}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? 'Update the category name below'
              : 'Enter a name for the new menu category'}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className='space-y-4'>
          <div className='space-y-2'>
            <Label htmlFor='type'>Category Name</Label>
            <Input
              id='type'
              placeholder='e.g., Drinks, Food, Desserts'
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
              autoFocus
            />
            {errors.type && <p className='text-sm text-destructive'>{errors.type}</p>}
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
