import { useQuery } from '@tanstack/react-query'
import { CreditCard, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { accountsService } from '../services/accounts-service'
import { TransactionHistory } from './transaction-history'
import type { AccountSummary } from '../types'

interface AccountDetailsDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  account: AccountSummary | null
  onRecordPayment: () => void
}

export function AccountDetailsDialog({
  open,
  onOpenChange,
  account,
  onRecordPayment,
}: AccountDetailsDialogProps) {
  const { data: fullAccount, isLoading } = useQuery({
    queryKey: ['account', account?.customerId],
    queryFn: () => accountsService.getAccount(account!.customerId),
    enabled: open && !!account,
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='max-w-2xl max-h-[90vh] overflow-y-auto'>
        <DialogHeader>
          <DialogTitle>Account Details</DialogTitle>
          <DialogDescription>
            {account?.customerName || 'Customer'}'s account information
          </DialogDescription>
        </DialogHeader>

        {isLoading ? (
          <div className='space-y-4'>
            <Skeleton className='h-24' />
            <Skeleton className='h-48' />
          </div>
        ) : fullAccount ? (
          <div className='space-y-6'>
            <div className='flex items-center justify-between rounded-lg bg-muted p-4'>
              <div>
                <p className='text-sm text-muted-foreground'>Current Balance</p>
                <p className={`text-3xl font-bold ${fullAccount.balance > 0 ? 'text-red-500' : fullAccount.balance < 0 ? 'text-green-500' : ''}`}>
                  {fullAccount.balance.toFixed(2)} EGP
                </p>
                {fullAccount.balance > 0 && (
                  <p className='text-sm text-muted-foreground mt-1'>
                    Amount owed by customer
                  </p>
                )}
              </div>
              {fullAccount.balance > 0 && (
                <Button onClick={onRecordPayment}>
                  <CreditCard className='mr-2 h-4 w-4' />
                  Record Payment
                </Button>
              )}
            </div>

            <TransactionHistory
              transactions={fullAccount.transactions}
              customerName={fullAccount.customerName}
            />
          </div>
        ) : (
          <div className='flex flex-col items-center justify-center py-8'>
            <Loader2 className='h-8 w-8 animate-spin text-muted-foreground' />
            <p className='mt-2 text-muted-foreground'>Loading account details...</p>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
