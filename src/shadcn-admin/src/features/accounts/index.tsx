import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Plus, Search, User, Wallet } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { accountsService } from './services/accounts-service'
import { CustomerSearchDialog } from './components/customer-search-dialog'
import { AddChargeDialog } from './components/add-charge-dialog'
import { RecordPaymentDialog } from './components/record-payment-dialog'
import { AccountDetailsDialog } from './components/account-details-dialog'
import type { AccountSummary, KeycloakUser } from './types'

export function AccountsManagement() {
  const [searchTerm, setSearchTerm] = useState('')
  const [customerSearchOpen, setCustomerSearchOpen] = useState(false)
  const [addChargeOpen, setAddChargeOpen] = useState(false)
  const [recordPaymentOpen, setRecordPaymentOpen] = useState(false)
  const [detailsOpen, setDetailsOpen] = useState(false)
  const [selectedCustomer, setSelectedCustomer] = useState<KeycloakUser | null>(null)
  const [selectedAccount, setSelectedAccount] = useState<AccountSummary | null>(null)

  // Fetch all accounts with balances
  const { data: accounts = [], isLoading } = useQuery({
    queryKey: ['accounts', searchTerm],
    queryFn: () => accountsService.searchAccounts(searchTerm || undefined),
  })

  const accountsWithBalance = accounts.filter((a) => a.balance !== 0)
  const totalOwed = accounts.reduce((sum, a) => sum + Math.max(0, a.balance), 0)

  const handleSelectCustomerForCharge = (customer: KeycloakUser) => {
    setSelectedCustomer(customer)
    setAddChargeOpen(true)
  }

  const handleRecordPayment = (account: AccountSummary) => {
    setSelectedAccount(account)
    setRecordPaymentOpen(true)
  }

  const handleViewDetails = (account: AccountSummary) => {
    setSelectedAccount(account)
    setDetailsOpen(true)
  }

  const handleRecordPaymentFromDetails = () => {
    setDetailsOpen(false)
    setRecordPaymentOpen(true)
  }

  return (
    <>
      <Header>
        <div className='flex items-center gap-2'>
          <h1 className='text-xl font-semibold'>Customer Accounts</h1>
          <Badge variant='outline' className='gap-1'>
            <Wallet className='h-3 w-3' />
            {totalOwed.toFixed(2)} EGP owed
          </Badge>
        </div>
        <Button onClick={() => setCustomerSearchOpen(true)}>
          <Plus className='mr-2 h-4 w-4' />
          Add Charge
        </Button>
      </Header>

      <Main>
        {/* Summary Card */}
        <Card className='mb-6'>
          <CardHeader>
            <CardTitle>Account Summary</CardTitle>
            <CardDescription>
              Overview of customer balances
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className='grid gap-4 sm:grid-cols-3'>
              <div className='rounded-lg bg-muted p-4'>
                <p className='text-sm text-muted-foreground'>Total Outstanding</p>
                <p className='text-2xl font-bold text-red-500'>{totalOwed.toFixed(2)} EGP</p>
              </div>
              <div className='rounded-lg bg-muted p-4'>
                <p className='text-sm text-muted-foreground'>Customers with Balance</p>
                <p className='text-2xl font-bold'>{accountsWithBalance.length}</p>
              </div>
              <div className='rounded-lg bg-muted p-4'>
                <p className='text-sm text-muted-foreground'>Total Accounts</p>
                <p className='text-2xl font-bold'>{accounts.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Search and List */}
        <Card>
          <CardHeader>
            <CardTitle>Customer Balances</CardTitle>
            <CardDescription>
              Customers with outstanding balances
            </CardDescription>
            <div className='relative mt-4'>
              <Search className='absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground' />
              <Input
                placeholder='Search customers...'
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className='pl-10'
              />
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className='space-y-4'>
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className='h-20' />
                ))}
              </div>
            ) : accountsWithBalance.length === 0 ? (
              <div className='flex flex-col items-center justify-center py-12 text-center'>
                <Wallet className='h-12 w-12 text-muted-foreground mb-4' />
                <h3 className='text-lg font-semibold'>No outstanding balances</h3>
                <p className='text-muted-foreground mt-1'>
                  All customers are up to date with their payments
                </p>
              </div>
            ) : (
              <div className='space-y-4'>
                {accountsWithBalance.map((account) => (
                  <div
                    key={account.id}
                    className='flex items-center justify-between rounded-lg border p-4 cursor-pointer hover:bg-muted/50 transition-colors'
                    onClick={() => handleViewDetails(account)}
                  >
                    <div className='flex items-center gap-4'>
                      <div className='rounded-full bg-muted p-3'>
                        <User className='h-5 w-5' />
                      </div>
                      <div>
                        <p className='font-semibold'>{account.customerName || 'Unknown Customer'}</p>
                        <p className='text-sm text-muted-foreground'>
                          Last updated: {new Date(account.updatedAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                    <div className='flex items-center gap-4'>
                      <div className='text-right'>
                        <p className={`text-xl font-bold ${account.balance > 0 ? 'text-red-500' : 'text-green-500'}`}>
                          {account.balance.toFixed(2)} EGP
                        </p>
                        <p className='text-xs text-muted-foreground'>
                          {account.balance > 0 ? 'owes' : 'credit'}
                        </p>
                      </div>
                      {account.balance > 0 && (
                        <Button
                          size='sm'
                          onClick={(e) => {
                            e.stopPropagation()
                            handleRecordPayment(account)
                          }}
                        >
                          Record Payment
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </Main>

      <CustomerSearchDialog
        open={customerSearchOpen}
        onOpenChange={setCustomerSearchOpen}
        onSelectCustomer={handleSelectCustomerForCharge}
      />

      <AddChargeDialog
        open={addChargeOpen}
        onOpenChange={setAddChargeOpen}
        customer={selectedCustomer}
      />

      <RecordPaymentDialog
        open={recordPaymentOpen}
        onOpenChange={setRecordPaymentOpen}
        account={selectedAccount}
      />

      <AccountDetailsDialog
        open={detailsOpen}
        onOpenChange={setDetailsOpen}
        account={selectedAccount}
        onRecordPayment={handleRecordPaymentFromDetails}
      />
    </>
  )
}
