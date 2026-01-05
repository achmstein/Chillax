import { useEffect, useState } from 'react'
import { Loader2, Clock, User, Gamepad2, Play, Square } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import type { Room, RoomSession, SessionStatus } from '../types'

const sessionStatusConfig: Record<SessionStatus, { label: string; variant: 'default' | 'secondary' | 'destructive' | 'outline' }> = {
  reserved: { label: 'Reserved', variant: 'outline' },
  active: { label: 'Active', variant: 'default' },
  completed: { label: 'Completed', variant: 'secondary' },
  cancelled: { label: 'Cancelled', variant: 'destructive' },
}

function formatDuration(startTime: string): string {
  const start = new Date(startTime)
  const now = new Date()
  const diffMs = now.getTime() - start.getTime()
  const hours = Math.floor(diffMs / (1000 * 60 * 60))
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((diffMs % (1000 * 60)) / 1000)
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
}

function calculateCurrentCost(startTime: string, hourlyRate: number): number {
  const start = new Date(startTime)
  const now = new Date()
  const hours = (now.getTime() - start.getTime()) / (1000 * 60 * 60)
  return Math.ceil(hours * hourlyRate * 100) / 100
}

interface SessionDetailsDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  session: RoomSession | null
  room?: Room
  onEndSession: (sessionId: number) => void
  isEnding: boolean
}

export function SessionDetailsDialog({
  open,
  onOpenChange,
  session,
  room,
  onEndSession,
  isEnding,
}: SessionDetailsDialogProps) {
  const [, setTick] = useState(0)

  // Update every second for live timer
  useEffect(() => {
    if (!open || !session?.startTime || session.status !== 'active') return
    const interval = setInterval(() => setTick((t) => t + 1), 1000)
    return () => clearInterval(interval)
  }, [open, session?.startTime, session?.status])

  if (!session) return null

  const statusInfo = sessionStatusConfig[session.status]

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='sm:max-w-[450px]'>
        <DialogHeader>
          <DialogTitle className='flex items-center gap-2'>
            <Gamepad2 className='h-5 w-5' />
            Session Details
          </DialogTitle>
          <DialogDescription>
            {room?.name} - Session #{session.id}
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4'>
          {/* Status Badge */}
          <div className='flex justify-center'>
            <Badge variant={statusInfo.variant} className='px-4 py-2 text-lg'>
              {session.status === 'active' && (
                <Play className='mr-2 h-4 w-4 animate-pulse' />
              )}
              {statusInfo.label}
            </Badge>
          </div>

          {/* Customer Info */}
          {session.customerName && (
            <div className='flex items-center justify-center gap-2 text-muted-foreground'>
              <User className='h-4 w-4' />
              <span>{session.customerName}</span>
            </div>
          )}

          <Separator />

          {/* Timer and Cost */}
          {session.startTime && session.status === 'active' && (
            <div className='rounded-lg bg-muted p-6 text-center'>
              <div className='flex items-center justify-center gap-2 text-muted-foreground mb-2'>
                <Clock className='h-4 w-4' />
                <span>Duration</span>
              </div>
              <div className='font-mono text-4xl font-bold'>
                {formatDuration(session.startTime)}
              </div>
              <Separator className='my-4' />
              <div className='text-muted-foreground mb-1'>Current Cost</div>
              <div className='text-3xl font-bold text-primary'>
                {room
                  ? calculateCurrentCost(session.startTime, room.hourlyRate).toFixed(2)
                  : '0.00'}{' '}
                EGP
              </div>
              <div className='text-sm text-muted-foreground mt-1'>
                @ {room?.hourlyRate} EGP/hour
              </div>
            </div>
          )}

          {/* Completed Session Info */}
          {session.status === 'completed' && session.totalCost !== undefined && (
            <div className='rounded-lg bg-muted p-6 text-center'>
              <div className='text-muted-foreground mb-1'>Final Cost</div>
              <div className='text-3xl font-bold text-primary'>
                {session.totalCost.toFixed(2)} EGP
              </div>
              {session.startTime && session.endTime && (
                <div className='text-sm text-muted-foreground mt-2'>
                  {new Date(session.startTime).toLocaleTimeString()} -{' '}
                  {new Date(session.endTime).toLocaleTimeString()}
                </div>
              )}
            </div>
          )}

          {/* Reserved Info */}
          {session.status === 'reserved' && (
            <div className='rounded-lg bg-yellow-500/10 p-6 text-center'>
              <div className='text-yellow-600 font-medium'>
                Waiting to start session
              </div>
              <div className='text-sm text-muted-foreground mt-2'>
                Reserved at {new Date(session.reservationTime).toLocaleString()}
              </div>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant='outline' onClick={() => onOpenChange(false)}>
            Close
          </Button>
          {session.status === 'active' && (
            <Button
              variant='destructive'
              onClick={() => onEndSession(session.id)}
              disabled={isEnding}
            >
              {isEnding ? (
                <Loader2 className='mr-2 h-4 w-4 animate-spin' />
              ) : (
                <Square className='mr-2 h-4 w-4' />
              )}
              End Session
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
