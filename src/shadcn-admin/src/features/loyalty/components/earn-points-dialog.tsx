import { useState } from 'react'
import { Plus } from 'lucide-react'
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useEarnPoints } from '../hooks/use-loyalty'

interface EarnPointsDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  userId: string
  userName?: string
}

const earnTypes = [
  { value: 'purchase', label: 'Purchase' },
  { value: 'bonus', label: 'Bonus' },
  { value: 'promotion', label: 'Promotion' },
  { value: 'referral', label: 'Referral' },
  { value: 'other', label: 'Other' },
]

export function EarnPointsDialog({
  open,
  onOpenChange,
  userId,
  userName,
}: EarnPointsDialogProps) {
  const [points, setPoints] = useState('')
  const [type, setType] = useState('bonus')
  const [description, setDescription] = useState('')
  const [referenceId, setReferenceId] = useState('')

  const earnPoints = useEarnPoints()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    const pointsValue = parseInt(points, 10)
    if (isNaN(pointsValue) || pointsValue <= 0) return

    earnPoints.mutate(
      {
        userId,
        points: pointsValue,
        type,
        description: description || `${type} points`,
        referenceId: referenceId || undefined,
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
    setType('bonus')
    setDescription('')
    setReferenceId('')
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
              <Plus className='h-5 w-5' />
              Earn Points
            </DialogTitle>
            <DialogDescription>
              Add points to {userName || 'this account'}.
            </DialogDescription>
          </DialogHeader>

          <div className='grid gap-4 py-4'>
            <div className='grid gap-2'>
              <Label htmlFor='points'>Points Amount</Label>
              <Input
                id='points'
                type='number'
                min='1'
                placeholder='Enter points to add'
                value={points}
                onChange={(e) => setPoints(e.target.value)}
                required
              />
            </div>

            <div className='grid gap-2'>
              <Label htmlFor='type'>Type</Label>
              <Select value={type} onValueChange={setType}>
                <SelectTrigger>
                  <SelectValue placeholder='Select type' />
                </SelectTrigger>
                <SelectContent>
                  {earnTypes.map((t) => (
                    <SelectItem key={t.value} value={t.value}>
                      {t.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className='grid gap-2'>
              <Label htmlFor='description'>Description</Label>
              <Input
                id='description'
                placeholder='Optional description'
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>

            <div className='grid gap-2'>
              <Label htmlFor='referenceId'>Reference ID</Label>
              <Input
                id='referenceId'
                placeholder='Optional order/reference ID'
                value={referenceId}
                onChange={(e) => setReferenceId(e.target.value)}
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
            <Button type='submit' disabled={earnPoints.isPending}>
              {earnPoints.isPending ? 'Adding...' : 'Add Points'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
