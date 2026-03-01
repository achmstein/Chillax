import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Loader2, Gamepad2, CheckCircle } from 'lucide-react'
import { toast } from 'sonner'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { roomsService } from '../services/rooms-service'
import { AccessCodeDisplay } from './access-code-display'
import type { Room, WalkInSessionResult } from '../types'

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
  const [notes, setNotes] = useState('')
  const [sessionResult, setSessionResult] = useState<WalkInSessionResult | null>(null)

  const startWalkInMutation = useMutation({
    mutationFn: async () => {
      return roomsService.startWalkInSession(room!.id, notes || undefined)
    },
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['rooms'] })
      queryClient.invalidateQueries({ queryKey: ['sessions'] })
      setSessionResult(result)
      toast.success(`Session started for ${room?.name}`)
    },
    onError: () => {
      toast.error('Failed to start session')
    },
  })

  const handleClose = () => {
    setNotes('')
    setSessionResult(null)
    onOpenChange(false)
  }

  if (!room) return null

  // Show access code after session started
  if (sessionResult) {
    return (
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className='sm:max-w-[400px]'>
          <DialogHeader>
            <DialogTitle className='flex items-center gap-2'>
              <CheckCircle className='h-5 w-5 text-green-500' />
              Session Started
            </DialogTitle>
            <DialogDescription>
              Share the access code with customers to join
            </DialogDescription>
          </DialogHeader>

          <div className='py-4'>
            <AccessCodeDisplay
              accessCode={sessionResult.accessCode}
              roomName={room.name}
            />
          </div>

          <DialogFooter>
            <Button onClick={handleClose}>
              Done
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
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
              {room.singleRate} / {room.multiRate} EGP/hr
            </p>
          </div>

          <div className='space-y-2'>
            <Label htmlFor='notes'>Notes (Optional)</Label>
            <Textarea
              id='notes'
              placeholder='Add any notes for this session'
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
            />
          </div>

          <p className='text-sm text-muted-foreground'>
            An access code will be generated for customers to join this session.
          </p>
        </div>

        <DialogFooter>
          <Button
            type='button'
            variant='outline'
            onClick={handleClose}
          >
            Cancel
          </Button>
          <Button
            onClick={() => startWalkInMutation.mutate()}
            disabled={startWalkInMutation.isPending}
          >
            {startWalkInMutation.isPending && (
              <Loader2 className='mr-2 h-4 w-4 animate-spin' />
            )}
            Start Session
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
