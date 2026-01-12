import { type ColumnDef } from '@tanstack/react-table'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { DataTableColumnHeader } from '@/components/data-table'
import { type Customer, getCustomerDisplayName, getCustomerInitials } from '../types'

export const customersColumns: ColumnDef<Customer>[] = [
  {
    id: 'avatar',
    header: '',
    cell: ({ row }) => {
      const customer = row.original
      return (
        <Avatar className='h-8 w-8'>
          <AvatarFallback className='bg-primary/10 text-primary text-xs'>
            {getCustomerInitials(customer)}
          </AvatarFallback>
        </Avatar>
      )
    },
    meta: {
      className: 'w-[50px]',
    },
  },
  {
    id: 'name',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Name' />
    ),
    cell: ({ row }) => {
      const customer = row.original
      return (
        <div className='flex flex-col'>
          <span className='font-medium'>{getCustomerDisplayName(customer)}</span>
          <span className='text-muted-foreground text-xs'>{customer.email || '-'}</span>
        </div>
      )
    },
  },
  {
    accessorKey: 'username',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Username' />
    ),
    cell: ({ row }) => row.original.username || '-',
  },
  {
    id: 'joinDate',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Joined' />
    ),
    cell: ({ row }) => {
      const timestamp = row.original.createdTimestamp
      if (!timestamp) return '-'
      return new Date(timestamp).toLocaleDateString()
    },
  },
  {
    accessorKey: 'enabled',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Status' />
    ),
    cell: ({ row }) => {
      const enabled = row.original.enabled
      return enabled ? (
        <Badge variant='default'>Active</Badge>
      ) : (
        <Badge variant='destructive'>Disabled</Badge>
      )
    },
  },
]
