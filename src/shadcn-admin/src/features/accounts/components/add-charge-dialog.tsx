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
import type { KeycloakUser } from '../types'

interface AddChargeDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  customer: KeycloakUser | null
}

export function AddChargeDialog({ open, onOpenChange, customer }: AddChargeDialogProps) {
  const queryClient = useQueryClient()
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')

  const addChargeMutation = useMutation({
    mutationFn: async () => {
      if (!customer) return
      const customerName = [customer.firstName, customer.lastName].filter(Boolean).join(' ') || customer.username
      await accountsService.addCharge(customer.id, {
        amount: parseFloat(amount),
        description: description || undefined,
        customerName,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['accounts'] })
      toast.success(`Charge of ${amount} EGP added successfully`)
      handleClose()
    },
    onError: () => {
      toast.error('Failed to add charge')
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
    addChargeMutation.mutate()
  }

  const customerName = customer
    ? [customer.firstName, customer.lastName].filter(Boolean).join(' ') || customer.username
    : ''

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add Charge</DialogTitle>
          <DialogDescription>
            Add an unpaid amount to {customerName}'s account
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className='space-y-4 py-4'>
            <div className='space-y-2'>
              <Label htmlFor='amount'>Amount (EGP)</Label>
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
                placeholder='e.g., Remaining from session - Room 3'
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button type='button' variant='outline' onClick={handleClose}>
              Cancel
            </Button>
            <Button type='submit' disabled={addChargeMutation.isPending}>
              {addChargeMutation.isPending && <Loader2 className='mr-2 h-4 w-4 animate-spin' />}
              Add Charge
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
