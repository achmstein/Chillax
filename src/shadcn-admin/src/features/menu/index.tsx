import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Pencil, Trash2, Coffee, UtensilsCrossed, Cookie, IceCream } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { menuService } from './services/menu-service'
import { MenuItemDialog } from './components/menu-item-dialog'
import { DeleteConfirmDialog } from './components/delete-confirm-dialog'
import type { MenuItem } from './types'

const categoryIcons: Record<number, React.ReactNode> = {
  1: <Coffee className='h-4 w-4' />,
  2: <UtensilsCrossed className='h-4 w-4' />,
  3: <Cookie className='h-4 w-4' />,
  4: <IceCream className='h-4 w-4' />,
}

export function MenuManagement() {
  const queryClient = useQueryClient()
  const [selectedCategory, setSelectedCategory] = useState<string>('all')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null)
  const [deleteItem, setDeleteItem] = useState<MenuItem | null>(null)

  // Fetch categories
  const { data: categories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: () => menuService.getCategories(),
  })

  // Fetch menu items
  const { data: menuData, isLoading } = useQuery({
    queryKey: ['menuItems', selectedCategory],
    queryFn: () =>
      menuService.getMenuItems(
        0,
        100,
        selectedCategory !== 'all' ? parseInt(selectedCategory) : undefined
      ),
  })

  // Toggle availability mutation
  const toggleMutation = useMutation({
    mutationFn: ({ id, isAvailable }: { id: number; isAvailable: boolean }) =>
      menuService.toggleAvailability(id, isAvailable),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Item availability updated')
    },
    onError: () => {
      toast.error('Failed to update availability')
    },
  })

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id: number) => menuService.deleteMenuItem(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['menuItems'] })
      toast.success('Item deleted successfully')
      setDeleteItem(null)
    },
    onError: () => {
      toast.error('Failed to delete item')
    },
  })

  const handleEdit = (item: MenuItem) => {
    setEditingItem(item)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setEditingItem(null)
    setDialogOpen(true)
  }

  const handleDialogClose = () => {
    setDialogOpen(false)
    setEditingItem(null)
  }

  const getCategoryName = (typeId: number) => {
    const category = categories.find((c) => c.id === typeId)
    return category?.type || 'Unknown'
  }

  return (
    <>
      <Header>
        <div className='flex items-center gap-2'>
          <h1 className='text-xl font-semibold'>Menu Management</h1>
        </div>
        <div className='flex items-center gap-2'>
          <Select value={selectedCategory} onValueChange={setSelectedCategory}>
            <SelectTrigger className='w-[180px]'>
              <SelectValue placeholder='All Categories' />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value='all'>All Categories</SelectItem>
              {categories.map((cat) => (
                <SelectItem key={cat.id} value={String(cat.id)}>
                  {cat.type}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button onClick={handleCreate}>
            <Plus className='mr-2 h-4 w-4' />
            Add Item
          </Button>
        </div>
      </Header>

      <Main>
        <Card>
          <CardHeader>
            <CardTitle>Menu Items</CardTitle>
            <CardDescription>
              Manage your cafe menu items, prices, and availability
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className='space-y-4'>
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className='h-16 w-full' />
                ))}
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Item</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead className='text-right'>Price</TableHead>
                    <TableHead className='text-center'>Prep Time</TableHead>
                    <TableHead className='text-center'>Available</TableHead>
                    <TableHead className='text-right'>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {menuData?.data.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>
                        <div className='flex items-center gap-3'>
                          <div className='bg-muted flex h-10 w-10 items-center justify-center rounded-md'>
                            {categoryIcons[item.catalogTypeId] || (
                              <Coffee className='h-4 w-4' />
                            )}
                          </div>
                          <div>
                            <div className='font-medium'>{item.name}</div>
                            {item.description && (
                              <div className='text-muted-foreground text-sm line-clamp-1'>
                                {item.description}
                              </div>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant='outline'>
                          {getCategoryName(item.catalogTypeId)}
                        </Badge>
                      </TableCell>
                      <TableCell className='text-right font-medium'>
                        {item.price.toFixed(2)} EGP
                      </TableCell>
                      <TableCell className='text-center'>
                        {item.preparationTimeMinutes
                          ? `${item.preparationTimeMinutes} min`
                          : '-'}
                      </TableCell>
                      <TableCell className='text-center'>
                        <Switch
                          checked={item.isAvailable}
                          onCheckedChange={(checked) =>
                            toggleMutation.mutate({ id: item.id, isAvailable: checked })
                          }
                        />
                      </TableCell>
                      <TableCell className='text-right'>
                        <div className='flex justify-end gap-2'>
                          <Button
                            variant='ghost'
                            size='icon'
                            onClick={() => handleEdit(item)}
                          >
                            <Pencil className='h-4 w-4' />
                          </Button>
                          <Button
                            variant='ghost'
                            size='icon'
                            onClick={() => setDeleteItem(item)}
                          >
                            <Trash2 className='h-4 w-4 text-destructive' />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                  {menuData?.data.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={6} className='h-24 text-center'>
                        No menu items found
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </Main>

      <MenuItemDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        item={editingItem}
        categories={categories}
      />

      <DeleteConfirmDialog
        open={!!deleteItem}
        onOpenChange={() => setDeleteItem(null)}
        onConfirm={() => deleteItem && deleteMutation.mutate(deleteItem.id)}
        itemName={deleteItem?.name || ''}
        isLoading={deleteMutation.isPending}
      />
    </>
  )
}
