import { useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import {
  ClipboardList,
  Coffee,
  Gamepad2,
  Play,
  Clock,
  TrendingUp,
  ArrowRight,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { ProfileDropdown } from '@/components/profile-dropdown'
import { ThemeSwitch } from '@/components/theme-switch'
import { ordersService } from '@/features/orders/services/orders-service'
import { roomsService } from '@/features/rooms/services/rooms-service'
import { menuService } from '@/features/menu/services/menu-service'

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

export function Dashboard() {
  // Fetch data
  const { data: pendingOrders = [], isLoading: loadingOrders } = useQuery({
    queryKey: ['orders', 'pending'],
    queryFn: () => ordersService.getPendingOrders(),
    refetchInterval: 30000,
  })

  const { data: allOrders = [] } = useQuery({
    queryKey: ['orders', 'all'],
    queryFn: () => ordersService.getOrders(),
  })

  const { data: rooms = [], isLoading: loadingRooms } = useQuery({
    queryKey: ['rooms'],
    queryFn: () => roomsService.getRooms(),
  })

  const { data: activeSessions = [] } = useQuery({
    queryKey: ['sessions', 'active'],
    queryFn: () => roomsService.getActiveSessions(),
    refetchInterval: 60000,
  })

  const { data: menuItems } = useQuery({
    queryKey: ['menuItems', 'all'],
    queryFn: () => menuService.getMenuItems(0, 100),
  })

  // Calculate stats
  const todayOrders = allOrders.filter((o) => {
    const orderDate = new Date(o.date)
    const today = new Date()
    return orderDate.toDateString() === today.toDateString()
  })

  const todayRevenue = todayOrders.reduce((sum, o) => sum + o.total, 0)
  const activeRoomsCount = rooms.filter((r) => r.status === 'occupied').length
  const availableMenuItems = menuItems?.data.filter((i) => i.isAvailable).length || 0

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
          <h2 className='text-2xl font-bold tracking-tight'>
            Welcome back!
          </h2>
          <p className='text-muted-foreground'>
            Here's what's happening at your cafe today.
          </p>
        </div>

        {/* Stats Cards */}
        <div className='grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-6'>
          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Pending Orders
              </CardTitle>
              <ClipboardList className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>{pendingOrders.length}</div>
              <p className='text-xs text-muted-foreground'>
                Waiting for confirmation
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Today's Orders
              </CardTitle>
              <TrendingUp className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>{todayOrders.length}</div>
              <p className='text-xs text-muted-foreground'>
                {todayRevenue.toFixed(2)} EGP revenue
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>
                Active Rooms
              </CardTitle>
              <Gamepad2 className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>
                {activeRoomsCount} / {rooms.length}
              </div>
              <p className='text-xs text-muted-foreground'>
                PlayStation sessions
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
              <CardTitle className='text-sm font-medium'>Menu Items</CardTitle>
              <Coffee className='h-4 w-4 text-muted-foreground' />
            </CardHeader>
            <CardContent>
              <div className='text-2xl font-bold'>{availableMenuItems}</div>
              <p className='text-xs text-muted-foreground'>
                Available for ordering
              </p>
            </CardContent>
          </Card>
        </div>

        <div className='grid gap-6 lg:grid-cols-2'>
          {/* Pending Orders */}
          <Card>
            <CardHeader className='flex flex-row items-center justify-between'>
              <div>
                <CardTitle>Pending Orders</CardTitle>
                <CardDescription>
                  Orders waiting for confirmation
                </CardDescription>
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
                    <Skeleton key={i} className='h-12 w-full' />
                  ))}
                </div>
              ) : pendingOrders.length === 0 ? (
                <div className='text-center py-8 text-muted-foreground'>
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
                          {new Date(order.date).toLocaleTimeString()}
                        </div>
                      </div>
                      <div className='text-right'>
                        <Badge variant='default'>Pending</Badge>
                        <div className='text-sm font-medium mt-1'>
                          {order.total.toFixed(2)} EGP
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Active Room Sessions */}
          <Card>
            <CardHeader className='flex flex-row items-center justify-between'>
              <div>
                <CardTitle>Active Sessions</CardTitle>
                <CardDescription>
                  Currently running PlayStation sessions
                </CardDescription>
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
                    <Skeleton key={i} className='h-12 w-full' />
                  ))}
                </div>
              ) : activeSessions.filter((s) => s.status === 'active').length ===
                0 ? (
                <div className='text-center py-8 text-muted-foreground'>
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
                            <div className='bg-red-500/10 text-red-500 rounded-full p-2'>
                              <Play className='h-4 w-4' />
                            </div>
                            <div>
                              <div className='font-medium'>{room?.name}</div>
                              {session.customerName && (
                                <div className='text-sm text-muted-foreground'>
                                  {session.customerName}
                                </div>
                              )}
                            </div>
                          </div>
                          <div className='text-right'>
                            <div className='flex items-center gap-1 text-sm'>
                              <Clock className='h-3 w-3' />
                              {session.startTime &&
                                formatDuration(session.startTime)}
                            </div>
                            <div className='text-sm font-medium text-amber-600'>
                              ~
                              {session.startTime && room
                                ? calculateCurrentCost(
                                    session.startTime,
                                    room.hourlyRate
                                  ).toFixed(2)
                                : '0.00'}{' '}
                              EGP
                            </div>
                          </div>
                        </div>
                      )
                    })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </Main>
    </>
  )
}
