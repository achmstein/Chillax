import { useState } from 'react'
import { Award, ChevronLeft, ChevronRight, Eye } from 'lucide-react'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { type LoyaltyAccount, tierColors, formatTierName } from '../types'

interface LoyaltyAccountsTableProps {
  accounts: LoyaltyAccount[] | undefined
  isLoading: boolean
  onViewAccount: (account: LoyaltyAccount) => void
}

const PAGE_SIZE = 10

export function LoyaltyAccountsTable({
  accounts,
  isLoading,
  onViewAccount,
}: LoyaltyAccountsTableProps) {
  const [page, setPage] = useState(0)

  const totalAccounts = accounts?.length ?? 0
  const totalPages = Math.ceil(totalAccounts / PAGE_SIZE)
  const paginatedAccounts = accounts?.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE) ?? []

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    })
  }

  if (isLoading) {
    return (
      <div className='space-y-4'>
        <h3 className='text-lg font-semibold'>Loyalty Accounts</h3>
        <div className='rounded-md border'>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User ID</TableHead>
                <TableHead>Tier</TableHead>
                <TableHead className='text-right'>Balance</TableHead>
                <TableHead className='text-right'>Lifetime</TableHead>
                <TableHead>Joined</TableHead>
                <TableHead className='w-[80px]'>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell><Skeleton className='h-4 w-32' /></TableCell>
                  <TableCell><Skeleton className='h-6 w-16' /></TableCell>
                  <TableCell><Skeleton className='ml-auto h-4 w-16' /></TableCell>
                  <TableCell><Skeleton className='ml-auto h-4 w-20' /></TableCell>
                  <TableCell><Skeleton className='h-4 w-24' /></TableCell>
                  <TableCell><Skeleton className='h-8 w-8' /></TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>
    )
  }

  return (
    <div className='space-y-4'>
      <div className='flex items-center justify-between'>
        <h3 className='text-lg font-semibold'>Loyalty Accounts</h3>
        <span className='text-sm text-muted-foreground'>
          {totalAccounts} total accounts
        </span>
      </div>

      <div className='rounded-md border'>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User ID</TableHead>
              <TableHead>Tier</TableHead>
              <TableHead className='text-right'>Balance</TableHead>
              <TableHead className='text-right'>Lifetime</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead className='w-[80px]'>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {paginatedAccounts.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className='h-24 text-center'>
                  No loyalty accounts found.
                </TableCell>
              </TableRow>
            ) : (
              paginatedAccounts.map((account) => {
                const tierColor = tierColors[account.currentTier]
                return (
                  <TableRow key={account.id}>
                    <TableCell className='font-mono text-sm'>
                      {account.userId.slice(0, 8)}...
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant='outline'
                        className='gap-1'
                        style={{
                          borderColor: tierColor,
                          color: tierColor,
                        }}
                      >
                        <Award className='h-3 w-3' />
                        {formatTierName(account.currentTier)}
                      </Badge>
                    </TableCell>
                    <TableCell className='text-right font-medium'>
                      {account.pointsBalance.toLocaleString()}
                    </TableCell>
                    <TableCell className='text-right text-muted-foreground'>
                      {account.lifetimePoints.toLocaleString()}
                    </TableCell>
                    <TableCell className='text-muted-foreground'>
                      {formatDate(account.createdAt)}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant='ghost'
                        size='icon'
                        onClick={() => onViewAccount(account)}
                      >
                        <Eye className='h-4 w-4' />
                      </Button>
                    </TableCell>
                  </TableRow>
                )
              })
            )}
          </TableBody>
        </Table>
      </div>

      {totalPages > 1 && (
        <div className='flex items-center justify-end gap-2'>
          <Button
            variant='outline'
            size='sm'
            onClick={() => setPage((p) => Math.max(0, p - 1))}
            disabled={page === 0}
          >
            <ChevronLeft className='h-4 w-4' />
            Previous
          </Button>
          <span className='text-sm text-muted-foreground'>
            Page {page + 1} of {totalPages}
          </span>
          <Button
            variant='outline'
            size='sm'
            onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
            disabled={page >= totalPages - 1}
          >
            Next
            <ChevronRight className='h-4 w-4' />
          </Button>
        </div>
      )}
    </div>
  )
}
