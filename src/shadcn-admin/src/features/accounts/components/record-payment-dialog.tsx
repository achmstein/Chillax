import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
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
import { Textarea } from '@/components/ui/textarea'
import { accountsService } from '../services/accounts-service'
import type { AccountSummary } from '../types'

interface RecordPaymentDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  account: AccountSummary | null
}

export function RecordPaymentDialog({ open, onOpenChange, account }: RecordPaymentDialogProps) {
  const queryClient = useQueryClient()
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')

  const recordPaymentMutation = useMutation({
    mutationFn: async () => {
      if (!account) return
      await accountsService.recordPayment(account.customerId, {
        amount: parseFloat(amount),
        description: description || undefined,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['accounts'] })
      toast.success(`Payment of ${amount} EGP recorded successfully`)
      handleClose()
    },
    onError: () => {
      toast.error('Failed to record payment')
    },
  })

  const handleClose = () => {
    setAmount('')
    setDescription('')
    onOpenChange(false)
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Please enter a valid amount')
      return
    }
    recordPaymentMutation.mutate()
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Record Payment</DialogTitle>
          <DialogDescription>
            Record a payment from {account?.customerName || 'customer'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className='space-y-4 py-4'>
            {account && (
              <div className='rounded-lg bg-muted p-3'>
                <p className='text-sm text-muted-foreground'>Current balance</p>
                <p className={`text-2xl font-bold ${account.balance > 0 ? 'text-red-500' : 'text-green-500'}`}>
                  {account.balance.toFixed(2)} EGP
                </p>
              </div>
            )}

            <div className='space-y-2'>
              <Label htmlFor='amount'>Payment Amount (EGP)</Label>
              <Input
                id='amount'
                type='number'
                step='0.01'
                min='0.01'
                placeholder='0.00'
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </div>

            <div className='space-y-2'>
              <Label htmlFor='description'>Description (optional)</Label>
              <Textarea
                id='description'
                placeholder='e.g., Cash payment'
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button type='button' variant='outline' onClick={handleClose}>
              Cancel
            </Button>
            <Button type='submit' disabled={recordPaymentMutation.isPending}>
              {recordPaymentMutation.isPending && <Loader2 className='mr-2 h-4 w-4 animate-spin' />}
              Record Payment
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
