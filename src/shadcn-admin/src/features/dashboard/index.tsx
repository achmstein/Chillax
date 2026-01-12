import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import {
  ClipboardList,
  Coffee,
  Gamepad2,
  Play,
  Clock,
  DollarSign,
  ArrowRight,
  Check,
  X,
  Square,
  DoorOpen,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
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
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { ProfileDropdown } from '@/components/profile-dropdown'
import { ThemeSwitch } from '@/components/theme-switch'
import { ordersService } from '@/features/orders/services/orders-service'
import { roomsService } from '@/features/rooms/services/rooms-service'
import type { OrderSummary } from '@/features/orders/types'
import type { RoomSession } from '@/features/rooms/types'
import { toast } from 'sonner'

function formatDuration(startTime: string): string {
  const start = new Date(startTime)
  const now = new Date()
  const diffMs = now.getTime() - start.getTime()
  const hours = Math.floor(diffMs / (1000 * 60 * 60))
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
  return `${hours}h ${minutes}m`
}

function calculateCurrentCost(startTime: string, hourlyRate: number): number {
  const start = new Date(startTime)
  const now = new Date()
  const hours = (now.getTime() - start.getTime()) / (1000 * 60 * 60)
  return Math.ceil(hours * hourlyRate * 100) / 100
}

function generateRequestId(): string {
  return crypto.randomUUID()
}

export function Dashboard() {
  const queryClient = useQueryClient()
  const [cancelOrderId, setCancelOrderId] = useState<number | null>(null)
  const [endSessionId, setEndSessionId] = useState<number | null>(null)

  // Fetch data
  const { data: pendingOrders = [], isLoading: loadingOrders } = useQuery({
    queryKey: ['orders', 'pending'],
    queryFn: () => ordersService.getPendingOrders(),
    refetchInterval: 30000,
  })

  const { data: allOrders = [] } = useQuery({
    queryKey: ['orders', 'all'],
    queryFn: () => ordersService.getOrders(),
    refetchInterval: 30000,
  })

  const { data: rooms = [], isLoading: loadingRooms } = useQuery({
    queryKey: ['rooms'],
    queryFn: () => roomsService.getRooms(),
    refetchInterval: 10000,
  })

  const { data: activeSessions = [] } = useQuery({
    queryKey: ['sessions', 'active'],
    queryFn: () => roomsService.getActiveSessions(),
    refetchInterval: 10000,
  })

  // Mutations
  const confirmMutation = useMutation({
    mutationFn: (orderId: number) =>
      ordersService.confirmOrder(orderId, generateRequestId()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      toast.success('Order confirmed')
    },
    onError: () => {
      toast.error('Failed to confirm order')
    },
  })

  const cancelMutation = useMutation({
    mutationFn: (orderId: number) =>
      ordersService.cancelOrder(orderId, generateRequestId()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      toast.success('Order cancelled')
    },
    onError: () => {
      toast.error('Failed to cancel order')
    },
  })

  const endSessionMutation = useMutation({
    mutationFn: (sessionId: number) => roomsService.endSession(sessionId),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['sessions'] })
      queryClient.invalidateQueries({ queryKey: ['rooms'] })
      toast.success(`Session ended - ${result.totalCost.toFixed(2)} EGP`)
    },
    onError: () => {
      toast.error('Failed to end session')
    },
  })

  // Calculate stats
  const todayOrders = allOrders.filter((o) => {
    const orderDate = new Date(o.date)
    const today = new Date()
    return orderDate.toDateString() === today.toDateString()
  })

  const todayRevenue = todayOrders
    .filter((o) => o.status !== 'cancelled')
    .reduce((sum, o) => sum + o.total, 0)
  const activeSessionsCount = activeSessions.filter(
    (s) => s.status === 'active'
  ).length
  const availableRoomsCount = rooms.filter((r) => r.status === 'available').length

  const handleConfirmOrder = (order: OrderSummary) => {
    confirmMutation.mutate(order.ordernumber)
  }

  const handleCancelOrder = () => {
    if (cancelOrderId) {
      cancelMutation.mutate(cancelOrderId)
      setCancelOrderId(null)
    }
  }

  const handleEndSession = () => {
    if (endSessionId) {
      endSessionMutation.mutate(endSessionId)
      setEndSessionId(null)
    }
  }

  return (
    <>
      <Header>
        <div className='flex items-center gap-2'>
          <Coffee className='h-6 w-6' />
          <h1 className='text-xl font-semibold'>Chillax Dashboard</h1>
        </div>
        <div className='ms-auto flex items-center space-x-4'>
          <ThemeSwitch />
          <ProfileDropdown />
        </div>
      </Header>

      <Main>
        <div className='mb-6'>
          <h2 className='text-2xl font-bold tracking-tight'>Welcome back!</h2>
          <p className='text-muted-foreground'>
            Here's what's happening at your cafe today.
          </p>
        </div>

        {/* Stats Cards - Matching Flutter layout */}
        <div className='grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-6'>
          <Card
            className={
              pendingOrders.length > 0
                ? 'border-destructive bg-destructive/5'
                : ''
            }
          >
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Pending Orders
              </CardTitle>
              <ClipboardList
                className={`h-4 w-4 ${
                  pendingOrders.length > 0
                    ? 'text-destructive'
                    : 'text-muted-foreground'
                }`}
              />
            </CardHeader>
            <CardContent>
              <div
                className={`text-2xl font-bold ${
                  pendingOrders.length > 0 ? 'text-destructive' : ''
                }`}
              >
                {pendingOrders.length}
              </div>
              <p className='text-xs text-muted-foreground'>
                Waiting to be confirmed
              </p>
            </CardContent>
          </Card>

          <Card
            className={
              activeSessionsCount > 0 ? 'border-primary bg-primary/5' : ''
            }
          >
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Active Sessions
              </CardTitle>
              <Gamepad2
                className={`h-4 w-4 ${
                  activeSessionsCount > 0
                    ? 'text-primary'
                    : 'text-muted-foreground'
                }`}
              />
            </CardHeader>
            <CardContent>
              <div
                className={`text-2xl font-bold ${
                  activeSessionsCount > 0 ? 'text-primary' : ''
                }`}
              >
                {activeSessionsCount}
              </div>
              <p className='text-xs text-muted-foreground'>PS rooms in use</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Available Rooms
              </CardTitle>
              <DoorOpen className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>{availableRoomsCount}</div>
              <p className='text-xs text-muted-foreground'>
                Ready for customers
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Today's Revenue
              </CardTitle>
              <DollarSign className='h-4 w-4 text-green-500' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold text-green-600'>
                {todayRevenue.toFixed(2)} EGP
              </div>
              <p className='text-xs text-muted-foreground'>
                From confirmed orders
              </p>
            </CardContent>
          </Card>
        </div>

        <div className='grid gap-6 lg:grid-cols-2'>
          {/* Pending Orders with Quick Actions */}
          <Card>
            <CardHeader className='flex flex-row items-center justify-between'>
              <div className='flex items-center gap-2'>
                <div>
                  <CardTitle>Pending Orders</CardTitle>
                  <CardDescription>
                    Orders waiting for confirmation
                  </CardDescription>
                </div>
                {pendingOrders.length > 0 && (
                  <Badge variant='destructive'>{pendingOrders.length}</Badge>
                )}
              </div>
              <Link to='/orders'>
                <Button variant='outline' size='sm'>
                  View All
                  <ArrowRight className='ml-2 h-4 w-4' />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {loadingOrders ? (
                <div className='space-y-4'>
                  {[...Array(3)].map((_, i) => (
                    <Skeleton key={i} className='h-16 w-full' />
                  ))}
                </div>
              ) : pendingOrders.length === 0 ? (
                <div className='text-center py-8 text-muted-foreground'>
                  <Check className='mx-auto h-12 w-12 mb-2 opacity-50' />
                  No pending orders
                </div>
              ) : (
                <div className='space-y-4'>
                  {pendingOrders.slice(0, 5).map((order) => (
                    <div
                      key={order.ordernumber}
                      className='flex items-center justify-between rounded-lg border p-3'
                    >
                      <div>
                        <div className='font-medium'>
                          Order #{order.ordernumber}
                        </div>
                        <div className='text-sm text-muted-foreground'>
                          {order.orderitems?.length || 0} items -{' '}
                          {order.total.toFixed(2)} EGP
                        </div>
                        <div className='text-xs text-muted-foreground'>
                          {new Date(order.date).toLocaleTimeString()}
                        </div>
                      </div>
                      <div className='flex items-center gap-2'>
                        <Button
                          variant='outline'
                          size='sm'
                          onClick={() => setCancelOrderId(order.ordernumber)}
                          disabled={cancelMutation.isPending}
                        >
                          <X className='h-4 w-4 mr-1' />
                          Cancel
                        </Button>
                        <Button
                          size='sm'
                          onClick={() => handleConfirmOrder(order)}
                          disabled={confirmMutation.isPending}
                        >
                          <Check className='h-4 w-4 mr-1' />
                          Confirm
                        </Button>
                      </div>
                    </div>
                  ))}
                  {pendingOrders.length > 5 && (
                    <Link to='/orders'>
                      <Button variant='ghost' className='w-full'>
                        View all {pendingOrders.length} orders
                      </Button>
                    </Link>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Active Room Sessions with End Session */}
          <Card>
            <CardHeader className='flex flex-row items-center justify-between'>
              <div className='flex items-center gap-2'>
                <div>
                  <CardTitle>Active Sessions</CardTitle>
                  <CardDescription>
                    Currently running PlayStation sessions
                  </CardDescription>
                </div>
                {activeSessionsCount > 0 && (
                  <Badge>{activeSessionsCount}</Badge>
                )}
              </div>
              <Link to='/rooms'>
                <Button variant='outline' size='sm'>
                  Manage Rooms
                  <ArrowRight className='ml-2 h-4 w-4' />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {loadingRooms ? (
                <div className='space-y-4'>
                  {[...Array(3)].map((_, i) => (
                    <Skeleton key={i} className='h-16 w-full' />
                  ))}
                </div>
              ) : activeSessions.filter((s) => s.status === 'active').length ===
                0 ? (
                <div className='text-center py-8 text-muted-foreground'>
                  <Gamepad2 className='mx-auto h-12 w-12 mb-2 opacity-50' />
                  No active sessions
                </div>
              ) : (
                <div className='space-y-4'>
                  {activeSessions
                    .filter((s) => s.status === 'active')
                    .slice(0, 5)
                    .map((session) => {
                      const room = rooms.find((r) => r.id === session.roomId)
                      return (
                        <div
                          key={session.id}
                          className='flex items-center justify-between rounded-lg border p-3'
                        >
                          <div className='flex items-center gap-3'>
                            <div className='bg-primary/10 text-primary rounded-full p-2'>
                              <Play className='h-4 w-4' />
                            </div>
                            <div>
                              <div className='flex items-center gap-2'>
                                <span className='font-medium'>
                                  {room?.name}
                                </span>
                                <Badge variant='default' className='text-xs'>
                                  Active
                                </Badge>
                              </div>
                              <div className='flex items-center gap-3 mt-1'>
                                <div className='flex items-center gap-1 text-sm font-mono bg-muted px-2 py-0.5 rounded'>
                                  <Clock className='h-3 w-3' />
                                  {session.startTime &&
                                    formatDuration(session.startTime)}
                                </div>
                                <span className='text-sm font-medium text-primary'>
                                  ~
                                  {session.startTime && room
                                    ? calculateCurrentCost(
                                        session.startTime,
                                        room.hourlyRate
                                      ).toFixed(2)
                                    : '0.00'}{' '}
                                  EGP
                                </span>
                              </div>
                            </div>
                          </div>
                          <Button
                            variant='destructive'
                            size='sm'
                            onClick={() => setEndSessionId(session.id)}
                            disabled={endSessionMutation.isPending}
                          >
                            <Square className='h-4 w-4 mr-1' />
                            End
                          </Button>
                        </div>
                      )
                    })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </Main>

      {/* Cancel Order Confirmation */}
      <AlertDialog
        open={cancelOrderId !== null}
        onOpenChange={(open) => !open && setCancelOrderId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Cancel Order?</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to cancel this order? This action cannot be
              undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>No, Keep</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleCancelOrder}
              className='bg-destructive text-destructive-foreground hover:bg-destructive/90'
            >
              Yes, Cancel
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* End Session Confirmation */}
      <AlertDialog
        open={endSessionId !== null}
        onOpenChange={(open) => !open && setEndSessionId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>End Session?</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to end this session? The customer will be
              charged for the time used.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleEndSession}>
              End Session
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
