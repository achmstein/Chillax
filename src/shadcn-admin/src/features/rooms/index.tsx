import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Gamepad2, Play, Clock, User, Wrench } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { roomsService } from './services/rooms-service'
import { StartSessionDialog } from './components/start-session-dialog'
import { SessionDetailsDialog } from './components/session-details-dialog'
import type { Room, RoomSession, RoomStatus } from './types'

const roomStatusConfig: Record<RoomStatus, { label: string; color: string; icon: React.ReactNode }> = {
  available: { label: 'Available', color: 'bg-green-500', icon: <Gamepad2 className='h-6 w-6' /> },
  occupied: { label: 'Occupied', color: 'bg-red-500', icon: <Play className='h-6 w-6' /> },
  reserved: { label: 'Reserved', color: 'bg-yellow-500', icon: <Clock className='h-6 w-6' /> },
  maintenance: { label: 'Maintenance', color: 'bg-gray-500', icon: <Wrench className='h-6 w-6' /> },
}

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

export function RoomsManagement() {
  const queryClient = useQueryClient()
  const [startDialogOpen, setStartDialogOpen] = useState(false)
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null)
  const [sessionDetailsOpen, setSessionDetailsOpen] = useState(false)
  const [selectedSession, setSelectedSession] = useState<RoomSession | null>(null)
  const [, setTick] = useState(0)

  // Update timer every minute
  useEffect(() => {
    const interval = setInterval(() => setTick((t) => t + 1), 60000)
    return () => clearInterval(interval)
  }, [])

  // Fetch rooms
  const { data: rooms = [], isLoading: loadingRooms } = useQuery({
    queryKey: ['rooms'],
    queryFn: () => roomsService.getRooms(),
  })

  // Fetch active sessions
  const { data: activeSessions = [], isLoading: loadingSessions } = useQuery({
    queryKey: ['sessions', 'active'],
    queryFn: () => roomsService.getActiveSessions(),
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  // End session mutation
  const endSessionMutation = useMutation({
    mutationFn: (sessionId: number) => roomsService.endSession(sessionId),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['rooms'] })
      queryClient.invalidateQueries({ queryKey: ['sessions'] })
      toast.success(
        `Session ended. Duration: ${result.durationMinutes} min. Total: ${result.totalCost.toFixed(2)} EGP`
      )
      setSessionDetailsOpen(false)
    },
    onError: () => {
      toast.error('Failed to end session')
    },
  })

  const handleStartSession = (room: Room) => {
    setSelectedRoom(room)
    setStartDialogOpen(true)
  }

  const handleViewSession = (session: RoomSession) => {
    setSelectedSession(session)
    setSessionDetailsOpen(true)
  }

  const getActiveSession = (roomId: number): RoomSession | undefined => {
    return activeSessions.find(
      (s) => s.roomId === roomId && (s.status === 'active' || s.status === 'reserved')
    )
  }

  const isLoading = loadingRooms || loadingSessions

  return (
    <>
      <Header>
        <div className='flex items-center gap-2'>
          <h1 className='text-xl font-semibold'>PlayStation Rooms</h1>
          <Badge variant='outline' className='gap-1'>
            <Gamepad2 className='h-3 w-3' />
            {activeSessions.filter((s) => s.status === 'active').length} Active
          </Badge>
        </div>
      </Header>

      <Main>
        {/* Room Status Grid */}
        <Card className='mb-6'>
          <CardHeader>
            <CardTitle>Room Status</CardTitle>
            <CardDescription>
              Click on an available room to start a session
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className='grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'>
                {[...Array(7)].map((_, i) => (
                  <Skeleton key={i} className='h-40' />
                ))}
              </div>
            ) : (
              <div className='grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'>
                {rooms.map((room) => {
                  const statusInfo = roomStatusConfig[room.status]
                  const activeSession = getActiveSession(room.id)

                  return (
                    <Card
                      key={room.id}
                      className={`relative cursor-pointer transition-all hover:shadow-lg ${
                        room.status === 'available' ? 'hover:border-green-500' : ''
                      }`}
                      onClick={() => {
                        if (room.status === 'available') {
                          handleStartSession(room)
                        } else if (activeSession) {
                          handleViewSession(activeSession)
                        }
                      }}
                    >
                      <div
                        className={`absolute right-2 top-2 h-3 w-3 rounded-full ${statusInfo.color}`}
                      />
                      <CardContent className='pt-6'>
                        <div className='flex flex-col items-center gap-2 text-center'>
                          <div className='bg-muted rounded-full p-4'>
                            {statusInfo.icon}
                          </div>
                          <h3 className='font-semibold'>{room.name}</h3>
                          <Badge variant='outline'>{statusInfo.label}</Badge>
                          <p className='text-lg font-bold text-primary'>
                            {room.hourlyRate} EGP/hr
                          </p>

                          {activeSession && activeSession.startTime && (
                            <div className='mt-2 space-y-1 text-sm'>
                              <div className='flex items-center justify-center gap-1 text-muted-foreground'>
                                <Clock className='h-3 w-3' />
                                {formatDuration(activeSession.startTime)}
                              </div>
                              <div className='font-medium text-amber-600'>
                                ~{calculateCurrentCost(activeSession.startTime, room.hourlyRate).toFixed(2)} EGP
                              </div>
                              {activeSession.customerName && (
                                <div className='flex items-center justify-center gap-1 text-muted-foreground'>
                                  <User className='h-3 w-3' />
                                  {activeSession.customerName}
                                </div>
                              )}
                            </div>
                          )}

                          {activeSession && activeSession.status === 'reserved' && (
                            <div className='mt-2 text-sm text-yellow-600'>
                              Reserved - waiting to start
                            </div>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            )}
          </CardContent>
        </Card>

      </Main>

      <StartSessionDialog
        open={startDialogOpen}
        onOpenChange={setStartDialogOpen}
        room={selectedRoom}
      />

      <SessionDetailsDialog
        open={sessionDetailsOpen}
        onOpenChange={setSessionDetailsOpen}
        session={selectedSession}
        room={rooms.find((r) => r.id === selectedSession?.roomId)}
        onEndSession={(id) => endSessionMutation.mutate(id)}
        isEnding={endSessionMutation.isPending}
      />
    </>
  )
}
