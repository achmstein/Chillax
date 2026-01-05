import { type ColumnDef } from '@tanstack/react-table'
import { Badge } from '@/components/ui/badge'
import { Checkbox } from '@/components/ui/checkbox'
import { DataTableColumnHeader } from '@/components/data-table'
import { type Customer } from '../data/schema'
import { CustomersRowActions } from './customers-row-actions'

export const customersColumns: ColumnDef<Customer>[] = [
  {
    id: 'select',
    header: ({ table }) => (
      <Checkbox
        checked={
          table.getIsAllPageRowsSelected() ||
          (table.getIsSomePageRowsSelected() && 'indeterminate')
        }
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label='Select all'
        className='translate-y-[2px]'
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label='Select row'
        className='translate-y-[2px]'
      />
    ),
    enableSorting: false,
    enableHiding: false,
    meta: {
      className: 'w-[40px]',
    },
  },
  {
    accessorKey: 'fullName',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Name' />
    ),
    cell: ({ row }) => {
      const customer = row.original
      return (
        <div className='flex flex-col'>
          <span className='font-medium'>{customer.fullName}</span>
          <span className='text-muted-foreground text-xs'>{customer.email}</span>
        </div>
      )
    },
  },
  {
    accessorKey: 'phoneNumber',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Phone' />
    ),
    cell: ({ row }) => row.original.phoneNumber || '-',
  },
  {
    accessorKey: 'isBlocked',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Status' />
    ),
    cell: ({ row }) => {
      const customer = row.original
      if (customer.isBlocked) {
        return <Badge variant='destructive'>Blocked</Badge>
      }
      if (!customer.emailVerified) {
        return <Badge variant='secondary'>Unverified</Badge>
      }
      return <Badge variant='default'>Active</Badge>
    },
    filterFn: (row, _id, filterValue: string[]) => {
      const customer = row.original
      if (!filterValue.length) return true

      const status = customer.isBlocked
        ? 'blocked'
        : !customer.emailVerified
          ? 'unverified'
          : 'active'

      return filterValue.includes(status)
    },
  },
  {
    accessorKey: 'totalOrders',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Orders' />
    ),
    cell: ({ row }) => row.original.totalOrders,
  },
  {
    accessorKey: 'totalSpent',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Total Spent' />
    ),
    cell: ({ row }) => {
      const amount = row.original.totalSpent
      const formatted = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(amount)
      return formatted
    },
  },
  {
    accessorKey: 'lastOrderAt',
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title='Last Order' />
    ),
    cell: ({ row }) => {
      const date = row.original.lastOrderAt
      if (!date) return '-'
      return new Date(date).toLocaleDateString()
    },
  },
  {
    id: 'actions',
    cell: ({ row }) => <CustomersRowActions customer={row.original} />,
    meta: {
      className: 'w-[50px]',
    },
  },
]
