import { useState } from 'react'
import {
  type ColumnFiltersState,
  type SortingState,
  type VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from '@tanstack/react-table'
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  DoubleArrowLeftIcon,
  DoubleArrowRightIcon,
} from '@radix-ui/react-icons'
import { cn, getPageNumbers } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { DataTableViewOptions } from '@/components/data-table'
import { type Customer, customerStatuses } from '../data/schema'
import { customersColumns } from './customers-columns'

interface CustomersTableProps {
  data: Customer[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
  isLoading?: boolean
  onPageChange: (page: number) => void
  onPageSizeChange: (pageSize: number) => void
  onSearchChange: (search: string) => void
  onStatusChange: (status: string | undefined) => void
}

export function CustomersTable({
  data,
  totalCount,
  page,
  pageSize,
  totalPages,
  isLoading,
  onPageChange,
  onPageSizeChange,
  onSearchChange,
  onStatusChange,
}: CustomersTableProps) {
  const [sorting, setSorting] = useState<SortingState>([])
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([])
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({})
  const [rowSelection, setRowSelection] = useState({})
  const [searchValue, setSearchValue] = useState('')

  const table = useReactTable({
    data,
    columns: customersColumns,
    manualPagination: true,
    pageCount: totalPages,
    state: {
      sorting,
      columnFilters,
      columnVisibility,
      rowSelection,
      pagination: {
        pageIndex: page - 1,
        pageSize,
      },
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
  })

  const pageNumbers = getPageNumbers(page, totalPages)

  const handleSearch = (value: string) => {
    setSearchValue(value)
    // Debounce the search
    const timeoutId = setTimeout(() => {
      onSearchChange(value)
      onPageChange(1) // Reset to first page on search
    }, 300)
    return () => clearTimeout(timeoutId)
  }

  return (
    <div className='flex flex-1 flex-col gap-4'>
      {/* Toolbar */}
      <div className='flex items-center justify-between'>
        <div className='flex flex-1 items-center space-x-2'>
          <Input
            placeholder='Search customers...'
            value={searchValue}
            onChange={(event) => handleSearch(event.target.value)}
            className='h-8 w-[150px] lg:w-[250px]'
          />
          <Select
            onValueChange={(value) => {
              onStatusChange(value === 'all' ? undefined : value)
              onPageChange(1)
            }}
          >
            <SelectTrigger className='h-8 w-[130px]'>
              <SelectValue placeholder='All statuses' />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value='all'>All statuses</SelectItem>
              {customerStatuses.map((status) => (
                <SelectItem key={status.value} value={status.value}>
                  {status.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <DataTableViewOptions table={table} />
      </div>

      {/* Table */}
      <div className='overflow-hidden rounded-md border'>
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id} className='group/row'>
                {headerGroup.headers.map((header) => {
                  return (
                    <TableHead
                      key={header.id}
                      colSpan={header.colSpan}
                      className={cn(
                        'bg-background group-hover/row:bg-muted',
                        header.column.columnDef.meta?.className
                      )}
                    >
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                    </TableHead>
                  )
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell
                  colSpan={customersColumns.length}
                  className='h-24 text-center'
                >
                  Loading...
                </TableCell>
              </TableRow>
            ) : table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && 'selected'}
                  className='group/row'
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell
                      key={cell.id}
                      className={cn(
                        'bg-background group-hover/row:bg-muted group-data-[state=selected]/row:bg-muted',
                        cell.column.columnDef.meta?.className
                      )}
                    >
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={customersColumns.length}
                  className='h-24 text-center'
                >
                  No customers found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      <div className='flex items-center justify-between px-2'>
        <div className='text-muted-foreground flex-1 text-sm'>
          {totalCount} total customers
        </div>
        <div className='flex items-center space-x-6 lg:space-x-8'>
          <div className='flex items-center space-x-2'>
            <p className='text-sm font-medium'>Rows per page</p>
            <Select
              value={`${pageSize}`}
              onValueChange={(value) => {
                onPageSizeChange(Number(value))
                onPageChange(1)
              }}
            >
              <SelectTrigger className='h-8 w-[70px]'>
                <SelectValue placeholder={pageSize} />
              </SelectTrigger>
              <SelectContent side='top'>
                {[10, 20, 30, 40, 50].map((size) => (
                  <SelectItem key={size} value={`${size}`}>
                    {size}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className='flex w-[100px] items-center justify-center text-sm font-medium'>
            Page {page} of {totalPages || 1}
          </div>
          <div className='flex items-center space-x-2'>
            <Button
              variant='outline'
              className='hidden h-8 w-8 p-0 lg:flex'
              onClick={() => onPageChange(1)}
              disabled={page <= 1}
            >
              <span className='sr-only'>Go to first page</span>
              <DoubleArrowLeftIcon className='h-4 w-4' />
            </Button>
            <Button
              variant='outline'
              className='h-8 w-8 p-0'
              onClick={() => onPageChange(page - 1)}
              disabled={page <= 1}
            >
              <span className='sr-only'>Go to previous page</span>
              <ChevronLeftIcon className='h-4 w-4' />
            </Button>

            {/* Page number buttons */}
            {pageNumbers.map((pageNumber, index) => (
              <div key={`${pageNumber}-${index}`} className='hidden items-center md:flex'>
                {pageNumber === '...' ? (
                  <span className='text-muted-foreground px-1 text-sm'>...</span>
                ) : (
                  <Button
                    variant={page === pageNumber ? 'default' : 'outline'}
                    className='h-8 min-w-8 px-2'
                    onClick={() => onPageChange(pageNumber as number)}
                  >
                    {pageNumber}
                  </Button>
                )}
              </div>
            ))}

            <Button
              variant='outline'
              className='h-8 w-8 p-0'
              onClick={() => onPageChange(page + 1)}
              disabled={page >= totalPages}
            >
              <span className='sr-only'>Go to next page</span>
              <ChevronRightIcon className='h-4 w-4' />
            </Button>
            <Button
              variant='outline'
              className='hidden h-8 w-8 p-0 lg:flex'
              onClick={() => onPageChange(totalPages)}
              disabled={page >= totalPages}
            >
              <span className='sr-only'>Go to last page</span>
              <DoubleArrowRightIcon className='h-4 w-4' />
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
