import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Loader2, Gamepad2 } from 'lucide-react'
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
import { roomsService } from '../services/rooms-service'
import type { Room } from '../types'

interface StartSessionDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  room: Room | null
}

export function StartSessionDialog({
  open,
  onOpenChange,
  room,
}: StartSessionDialogProps) {
  const queryClient = useQueryClient()
  const [customerName, setCustomerName] = useState('')

  const reserveMutation = useMutation({
    mutationFn: async () => {
      // First reserve the room
      const session = await roomsService.reserveRoom(
        room!.id,
        'walk-in', // For walk-in customers
        customerName || undefined
      )
      // Then immediately start the session
      return roomsService.startSession(session.id)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['rooms'] })
      queryClient.invalidateQueries({ queryKey: ['sessions'] })
      toast.success(`Session started for ${room?.name}`)
      setCustomerName('')
      onOpenChange(false)
    },
    onError: () => {
      toast.error('Failed to start session')
    },
  })

  if (!room) return null

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='sm:max-w-[400px]'>
        <DialogHeader>
          <DialogTitle className='flex items-center gap-2'>
            <Gamepad2 className='h-5 w-5' />
            Start Session
          </DialogTitle>
          <DialogDescription>
            Start a new gaming session for {room.name}
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4 py-4'>
          <div className='rounded-lg bg-muted p-4 text-center'>
            <h3 className='text-lg font-semibold'>{room.name}</h3>
            <p className='text-2xl font-bold text-primary'>
              {room.hourlyRate} EGP/hr
            </p>
          </div>

          <div className='space-y-2'>
            <Label htmlFor='customerName'>Customer Name (Optional)</Label>
            <Input
              id='customerName'
              placeholder='Enter customer name'
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
            />
          </div>
        </div>

        <DialogFooter>
          <Button
            type='button'
            variant='outline'
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            onClick={() => reserveMutation.mutate()}
            disabled={reserveMutation.isPending}
          >
            {reserveMutation.isPending && (
              <Loader2 className='mr-2 h-4 w-4 animate-spin' />
            )}
            Start Session
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
