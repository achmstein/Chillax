import { ArrowDownCircle, ArrowUpCircle } from 'lucide-react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { AccountTransaction } from '../types'

interface TransactionHistoryProps {
  transactions: AccountTransaction[]
  customerName?: string
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function TransactionHistory({ transactions, customerName }: TransactionHistoryProps) {
  if (transactions.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Transaction History</CardTitle>
          <CardDescription>
            {customerName ? `Transactions for ${customerName}` : 'All transactions'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className='text-center text-muted-foreground py-8'>No transactions yet</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Transaction History</CardTitle>
        <CardDescription>
          {customerName ? `Transactions for ${customerName}` : 'All transactions'}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className='space-y-4'>
          {transactions.map((transaction) => (
            <div
              key={transaction.id}
              className='flex items-center justify-between rounded-lg border p-4'
            >
              <div className='flex items-center gap-4'>
                <div className={`rounded-full p-2 ${
                  transaction.type === 'charge'
                    ? 'bg-red-100 text-red-600'
                    : 'bg-green-100 text-green-600'
                }`}>
                  {transaction.type === 'charge' ? (
                    <ArrowUpCircle className='h-5 w-5' />
                  ) : (
                    <ArrowDownCircle className='h-5 w-5' />
                  )}
                </div>
                <div>
                  <div className='flex items-center gap-2'>
                    <Badge variant={transaction.type === 'charge' ? 'destructive' : 'default'}>
                      {transaction.type === 'charge' ? 'Charge' : 'Payment'}
                    </Badge>
                    <span className='text-sm text-muted-foreground'>
                      by {transaction.recordedBy}
                    </span>
                  </div>
                  {transaction.description && (
                    <p className='text-sm text-muted-foreground mt-1'>
                      {transaction.description}
                    </p>
                  )}
                  <p className='text-xs text-muted-foreground mt-1'>
                    {formatDate(transaction.createdAt)}
                  </p>
                </div>
              </div>
              <div className={`text-lg font-bold ${
                transaction.type === 'charge' ? 'text-red-600' : 'text-green-600'
              }`}>
                {transaction.type === 'charge' ? '+' : '-'}{transaction.amount.toFixed(2)} EGP
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
