import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Pencil, Trash2, Tag, Loader2, RefreshCw } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { menuService } from '../services/menu-service'
import { CategoryDialog } from './category-dialog'
import type { CatalogType } from '../types'

export function CategoriesList() {
  const queryClient = useQueryClient()
  const [dialogOpen, setDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState<CatalogType | null>(null)

  // Fetch categories
  const { data: categories = [], isLoading: categoriesLoading, refetch } = useQuery({
    queryKey: ['categories'],
    queryFn: () => menuService.getCategories(),
  })

  // Fetch item counts
  const { data: itemCounts = {} } = useQuery({
    queryKey: ['itemCounts'],
    queryFn: () => menuService.getItemCountByCategory(),
  })

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id: number) => menuService.deleteCategory(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] })
      queryClient.invalidateQueries({ queryKey: ['itemCounts'] })
      toast.success('Category deleted successfully')
      setDeleteDialogOpen(false)
      setSelectedCategory(null)
    },
    onError: (error: Error) => {
      // Handle 409 Conflict - category has items
      if (error.message.includes('409') || error.message.includes('Conflict')) {
        toast.error('Cannot delete category that has menu items')
      } else {
        toast.error('Failed to delete category')
      }
    },
  })

  const handleAdd = () => {
    setSelectedCategory(null)
    setDialogOpen(true)
  }

  const handleEdit = (category: CatalogType) => {
    setSelectedCategory(category)
    setDialogOpen(true)
  }

  const handleDeleteClick = (category: CatalogType) => {
    setSelectedCategory(category)
    setDeleteDialogOpen(true)
  }

  const handleDeleteConfirm = () => {
    if (selectedCategory) {
      deleteMutation.mutate(selectedCategory.id)
    }
  }

  const getItemCount = (categoryId: number) => itemCounts[categoryId] || 0

  return (
    <>
      <Header>
        <div className='flex w-full items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold tracking-tight'>Menu Categories</h1>
            <p className='text-muted-foreground'>
              Manage your menu categories
            </p>
          </div>
          <div className='flex items-center gap-2'>
            <Button variant='outline' size='icon' onClick={() => refetch()}>
              <RefreshCw className='h-4 w-4' />
            </Button>
            <Button onClick={handleAdd}>
              <Plus className='mr-2 h-4 w-4' />
              Add Category
            </Button>
          </div>
        </div>
      </Header>

      <Main>
        {categoriesLoading ? (
          <div className='flex items-center justify-center py-12'>
            <Loader2 className='h-8 w-8 animate-spin text-muted-foreground' />
          </div>
        ) : categories.length === 0 ? (
          <div className='flex flex-col items-center justify-center py-12 text-center'>
            <Tag className='h-12 w-12 text-muted-foreground mb-4' />
            <h3 className='text-lg font-semibold'>No categories found</h3>
            <p className='text-muted-foreground mb-4'>
              Create your first category to organize menu items
            </p>
            <Button onClick={handleAdd}>
              <Plus className='mr-2 h-4 w-4' />
              Add Category
            </Button>
          </div>
        ) : (
          <div className='grid gap-4 md:grid-cols-2 lg:grid-cols-3'>
            {categories.map((category) => {
              const itemCount = getItemCount(category.id)
              return (
                <Card key={category.id}>
                  <CardContent className='flex items-center justify-between p-4'>
                    <div className='flex items-center gap-4'>
                      <div className='flex h-10 w-10 items-center justify-center rounded-lg bg-secondary'>
                        <Tag className='h-5 w-5 text-primary' />
                      </div>
                      <div>
                        <h3 className='font-semibold'>{category.type}</h3>
                        <p className='text-sm text-muted-foreground'>
                          {itemCount} item{itemCount !== 1 ? 's' : ''}
                        </p>
                      </div>
                    </div>
                    <div className='flex items-center gap-2'>
                      <Button
                        variant='ghost'
                        size='icon'
                        onClick={() => handleEdit(category)}
                      >
                        <Pencil className='h-4 w-4' />
                      </Button>
                      <Button
                        variant='ghost'
                        size='icon'
                        onClick={() => handleDeleteClick(category)}
                        disabled={itemCount > 0}
                        title={itemCount > 0 ? 'Cannot delete: has items' : 'Delete category'}
                      >
                        <Trash2 className={`h-4 w-4 ${itemCount > 0 ? 'text-muted-foreground/50' : 'text-destructive'}`} />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        )}
      </Main>

      {/* Add/Edit Dialog */}
      <CategoryDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        category={selectedCategory}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Category</AlertDialogTitle>
            <AlertDialogDescription>
              {selectedCategory && getItemCount(selectedCategory.id) > 0 ? (
                <>
                  This category has {getItemCount(selectedCategory.id)} item(s).
                  Move or delete the items before deleting the category.
                </>
              ) : (
                <>
                  Are you sure you want to delete "{selectedCategory?.type}"?
                  This action cannot be undone.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteMutation.isPending}>
              Cancel
            </AlertDialogCancel>
            {selectedCategory && getItemCount(selectedCategory.id) === 0 && (
              <AlertDialogAction
                onClick={handleDeleteConfirm}
                disabled={deleteMutation.isPending}
                className='bg-destructive text-destructive-foreground hover:bg-destructive/90'
              >
                {deleteMutation.isPending && (
                  <Loader2 className='mr-2 h-4 w-4 animate-spin' />
                )}
                Delete
              </AlertDialogAction>
            )}
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
