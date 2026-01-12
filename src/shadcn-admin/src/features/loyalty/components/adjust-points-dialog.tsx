import { useState } from 'react'
import { RefreshCw } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useAdjustPoints } from '../hooks/use-loyalty'

interface AdjustPointsDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  userId: string
  userName?: string
  currentBalance: number
}

export function AdjustPointsDialog({
  open,
  onOpenChange,
  userId,
  userName,
  currentBalance,
}: AdjustPointsDialogProps) {
  const [points, setPoints] = useState('')
  const [reason, setReason] = useState('')

  const adjustPoints = useAdjustPoints()

  const pointsValue = parseInt(points, 10) || 0
  const newBalance = currentBalance + pointsValue

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    if (pointsValue === 0 || !reason.trim()) return

    adjustPoints.mutate(
      {
        userId,
        points: pointsValue,
        reason: reason.trim(),
      },
      {
        onSuccess: () => {
          onOpenChange(false)
          resetForm()
        },
      }
    )
  }

  const resetForm = () => {
    setPoints('')
    setReason('')
  }

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      resetForm()
    }
    onOpenChange(open)
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className='sm:max-w-[425px]'>
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle className='flex items-center gap-2'>
              <RefreshCw className='h-5 w-5' />
              Adjust Points
            </DialogTitle>
            <DialogDescription>
              Adjust points balance for {userName || 'this account'}. Use
              negative values to deduct points.
            </DialogDescription>
          </DialogHeader>

          <div className='grid gap-4 py-4'>
            <div className='rounded-lg bg-muted p-3'>
              <div className='flex justify-between text-sm'>
                <span className='text-muted-foreground'>Current Balance</span>
                <span className='font-medium'>
                  {currentBalance.toLocaleString()} pts
                </span>
              </div>
              {pointsValue !== 0 && (
                <>
                  <div className='flex justify-between text-sm mt-1'>
                    <span className='text-muted-foreground'>Adjustment</span>
                    <span
                      className={`font-medium ${
                        pointsValue > 0 ? 'text-green-600' : 'text-red-600'
                      }`}
                    >
                      {pointsValue > 0 ? '+' : ''}
                      {pointsValue.toLocaleString()} pts
                    </span>
                  </div>
                  <div className='border-t mt-2 pt-2 flex justify-between text-sm'>
                    <span className='text-muted-foreground'>New Balance</span>
                    <span className='font-bold'>
                      {newBalance.toLocaleString()} pts
                    </span>
                  </div>
                </>
              )}
            </div>

            <div className='grid gap-2'>
              <Label htmlFor='points'>Adjustment Amount</Label>
              <Input
                id='points'
                type='number'
                placeholder='Enter points (use - for deduction)'
                value={points}
                onChange={(e) => setPoints(e.target.value)}
                required
              />
              <p className='text-xs text-muted-foreground'>
                Positive to add, negative to deduct
              </p>
            </div>

            <div className='grid gap-2'>
              <Label htmlFor='reason'>Reason</Label>
              <Textarea
                id='reason'
                placeholder='Enter reason for adjustment (required)'
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              type='button'
              variant='outline'
              onClick={() => handleOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type='submit'
              disabled={adjustPoints.isPending || pointsValue === 0 || !reason.trim()}
            >
              {adjustPoints.isPending ? 'Adjusting...' : 'Adjust Points'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
