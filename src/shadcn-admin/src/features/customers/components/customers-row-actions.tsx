import { MoreHorizontal, Ban, CheckCircle } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { type Customer } from '../data/schema'
import { useBlockCustomer, useUnblockCustomer } from '../hooks/use-customers'

interface CustomersRowActionsProps {
  customer: Customer
}

export function CustomersRowActions({ customer }: CustomersRowActionsProps) {
  const blockMutation = useBlockCustomer()
  const unblockMutation = useUnblockCustomer()

  const handleBlock = async () => {
    try {
      await blockMutation.mutateAsync(customer.id)
      toast.success(`Customer ${customer.fullName} has been blocked`)
    } catch {
      toast.error('Failed to block customer')
    }
  }

  const handleUnblock = async () => {
    try {
      await unblockMutation.mutateAsync(customer.id)
      toast.success(`Customer ${customer.fullName} has been unblocked`)
    } catch {
      toast.error('Failed to unblock customer')
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant='ghost'
          className='data-[state=open]:bg-muted flex h-8 w-8 p-0'
        >
          <MoreHorizontal className='h-4 w-4' />
          <span className='sr-only'>Open menu</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align='end' className='w-[160px]'>
        <DropdownMenuItem>View details</DropdownMenuItem>
        <DropdownMenuItem>View orders</DropdownMenuItem>
        <DropdownMenuSeparator />
        {customer.isBlocked ? (
          <DropdownMenuItem
            onClick={handleUnblock}
            disabled={unblockMutation.isPending}
          >
            <CheckCircle className='mr-2 h-4 w-4' />
            Unblock
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem
            onClick={handleBlock}
            disabled={blockMutation.isPending}
            className='text-destructive focus:text-destructive'
          >
            <Ban className='mr-2 h-4 w-4' />
            Block
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
