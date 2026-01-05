import { useState } from 'react'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { ProfileDropdown } from '@/components/profile-dropdown'
import { Search } from '@/components/search'
import { ThemeSwitch } from '@/components/theme-switch'
import { ConfigDrawer } from '@/components/config-drawer'
import { CustomersTable } from './components/customers-table'
import { useCustomers } from './hooks/use-customers'

export function Customers() {
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState<string | undefined>(undefined)

  const { data, isLoading } = useCustomers({
    page,
    pageSize,
    search: search || undefined,
    status,
  })

  return (
    <>
      <Header fixed>
        <Search />
        <div className='ms-auto flex items-center space-x-4'>
          <ThemeSwitch />
          <ConfigDrawer />
          <ProfileDropdown />
        </div>
      </Header>

      <Main className='flex flex-1 flex-col gap-4 sm:gap-6'>
        <div className='flex flex-wrap items-end justify-between gap-2'>
          <div>
            <h2 className='text-2xl font-bold tracking-tight'>Customers</h2>
            <p className='text-muted-foreground'>
              Manage your customers and their orders.
            </p>
          </div>
        </div>

        <CustomersTable
          data={data?.items ?? []}
          totalCount={data?.totalCount ?? 0}
          page={data?.page ?? page}
          pageSize={data?.pageSize ?? pageSize}
          totalPages={data?.totalPages ?? 0}
          isLoading={isLoading}
          onPageChange={setPage}
          onPageSizeChange={setPageSize}
          onSearchChange={setSearch}
          onStatusChange={setStatus}
        />
      </Main>
    </>
  )
}
