import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Check, X, Eye, Clock, CheckCircle, XCircle, ChevronLeft, ChevronRight } from 'lucide-react'
import { toast } from 'sonner'
import { v4 as uuidv4 } from 'uuid'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { ordersService } from './services/orders-service'
import { OrderDetailsDialog } from './components/order-details-dialog'
import type { Order, OrderStatus, OrderSummary, PaginatedResult } from './types'

const statusConfig: Record<OrderStatus, { label: string; variant: 'default' | 'secondary' | 'destructive'; icon: React.ReactNode }> = {
  submitted: { label: 'Pending', variant: 'default', icon: <Clock className='h-3 w-3' /> },
  confirmed: { label: 'Confirmed', variant: 'secondary', icon: <CheckCircle className='h-3 w-3' /> },
  cancelled: { label: 'Cancelled', variant: 'destructive', icon: <XCircle className='h-3 w-3' /> },
}

const PAGE_SIZE = 20

export function OrdersManagement() {
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState<string>('pending')
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const [detailsOpen, setDetailsOpen] = useState(false)
  const [pageIndex, setPageIndex] = useState(0)

  // Fetch all orders with pagination
  const { data: allOrdersData, isLoading: loadingAll } = useQuery({
    queryKey: ['orders', 'all', pageIndex],
    queryFn: () => ordersService.getOrders(pageIndex, PAGE_SIZE),
  })

  // Fetch pending orders
  const { data: pendingOrders = [], isLoading: loadingPending } = useQuery({
    queryKey: ['orders', 'pending'],
    queryFn: () => ordersService.getPendingOrders(),
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  const allOrders = allOrdersData?.items ?? []
  const totalPages = allOrdersData?.totalPages ?? 0
  const hasNextPage = allOrdersData?.hasNextPage ?? false
  const hasPreviousPage = allOrdersData?.hasPreviousPage ?? false

  // Confirm order mutation
  const confirmMutation = useMutation({
    mutationFn: (orderId: number) => ordersService.confirmOrder(orderId, uuidv4()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      toast.success('Order confirmed!')
    },
    onError: () => {
      toast.error('Failed to confirm order')
    },
  })

  // Cancel order mutation
  const cancelMutation = useMutation({
    mutationFn: (orderId: number) => ordersService.cancelOrder(orderId, uuidv4()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      toast.success('Order cancelled')
    },
    onError: () => {
      toast.error('Failed to cancel order')
    },
  })

  const viewOrderDetails = async (orderId: number) => {
    try {
      const order = await ordersService.getOrder(orderId)
      setSelectedOrder(order)
      setDetailsOpen(true)
    } catch {
      toast.error('Failed to load order details')
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('en-US', {
      dateStyle: 'short',
      timeStyle: 'short',
    })
  }

  const renderOrdersTable = (orders: OrderSummary[], showActions = false) => {
    if (!orders.length) {
      return (
        <div className='flex h-24 items-center justify-center text-muted-foreground'>
          No orders found
        </div>
      )
    }

    return (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Order #</TableHead>
            <TableHead>Date</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className='text-right'>Total</TableHead>
            <TableHead className='text-right'>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {orders.map((order) => {
            const status = statusConfig[order.status]
            return (
              <TableRow key={order.ordernumber}>
                <TableCell className='font-medium'>#{order.ordernumber}</TableCell>
                <TableCell>{formatDate(order.date)}</TableCell>
                <TableCell>
                  <Badge variant={status.variant} className='gap-1'>
                    {status.icon}
                    {status.label}
                  </Badge>
                </TableCell>
                <TableCell className='text-right font-medium'>
                  {order.total.toFixed(2)} EGP
                </TableCell>
                <TableCell className='text-right'>
                  <div className='flex justify-end gap-2'>
                    <Button
                      variant='ghost'
                      size='icon'
                      onClick={() => viewOrderDetails(order.ordernumber)}
                    >
                      <Eye className='h-4 w-4' />
                    </Button>
                    {showActions && order.status === 'submitted' && (
                      <>
                        <Button
                          variant='ghost'
                          size='icon'
                          onClick={() => confirmMutation.mutate(order.ordernumber)}
                          disabled={confirmMutation.isPending}
                        >
                          <Check className='h-4 w-4 text-green-600' />
                        </Button>
                        <Button
                          variant='ghost'
                          size='icon'
                          onClick={() => cancelMutation.mutate(order.ordernumber)}
                          disabled={cancelMutation.isPending}
                        >
                          <X className='h-4 w-4 text-destructive' />
                        </Button>
                      </>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    )
  }

  const isLoading = activeTab === 'pending' ? loadingPending : loadingAll

  return (
    <>
      <Header>
        <div className='flex items-center gap-2'>
          <h1 className='text-xl font-semibold'>Orders</h1>
          {pendingOrders.length > 0 && (
            <Badge variant='default' className='h-6'>
              {pendingOrders.length} pending
            </Badge>
          )}
        </div>
      </Header>

      <Main>
        <Card>
          <CardHeader>
            <CardTitle>Order Management</CardTitle>
            <CardDescription>
              View and manage customer orders. Confirm pending orders to send them to the POS.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className='mb-4'>
                <TabsTrigger value='pending'>
                  Pending Orders
                  {pendingOrders.length > 0 && (
                    <Badge variant='secondary' className='ml-2'>
                      {pendingOrders.length}
                    </Badge>
                  )}
                </TabsTrigger>
                <TabsTrigger value='all'>All Orders</TabsTrigger>
              </TabsList>

              <TabsContent value='pending'>
                {isLoading ? (
                  <div className='space-y-4'>
                    {[...Array(3)].map((_, i) => (
                      <Skeleton key={i} className='h-16 w-full' />
                    ))}
                  </div>
                ) : (
                  renderOrdersTable(pendingOrders, true)
                )}
              </TabsContent>

              <TabsContent value='all'>
                {loadingAll ? (
                  <div className='space-y-4'>
                    {[...Array(5)].map((_, i) => (
                      <Skeleton key={i} className='h-16 w-full' />
                    ))}
                  </div>
                ) : (
                  <>
                    {renderOrdersTable(allOrders)}
                    {/* Pagination controls */}
                    {totalPages > 1 && (
                      <div className='flex items-center justify-between border-t pt-4 mt-4'>
                        <div className='text-sm text-muted-foreground'>
                          Page {pageIndex + 1} of {totalPages}
                          {allOrdersData?.totalCount && (
                            <span className='ml-2'>
                              ({allOrdersData.totalCount} total orders)
                            </span>
                          )}
                        </div>
                        <div className='flex gap-2'>
                          <Button
                            variant='outline'
                            size='sm'
                            onClick={() => setPageIndex(p => p - 1)}
                            disabled={!hasPreviousPage}
                          >
                            <ChevronLeft className='h-4 w-4 mr-1' />
                            Previous
                          </Button>
                          <Button
                            variant='outline'
                            size='sm'
                            onClick={() => setPageIndex(p => p + 1)}
                            disabled={!hasNextPage}
                          >
                            Next
                            <ChevronRight className='h-4 w-4 ml-1' />
                          </Button>
                        </div>
                      </div>
                    )}
                  </>
                )}
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </Main>

      <OrderDetailsDialog
        open={detailsOpen}
        onOpenChange={setDetailsOpen}
        order={selectedOrder}
      />
    </>
  )
}
