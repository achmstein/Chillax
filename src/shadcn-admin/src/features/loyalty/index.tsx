import { useState } from 'react'
import { Header } from '@/components/layout/header'
import { Main } from '@/components/layout/main'
import { ProfileDropdown } from '@/components/profile-dropdown'
import { ThemeSwitch } from '@/components/theme-switch'
import { useLoyaltyStats, useLoyaltyAccounts } from './hooks/use-loyalty'
import { LoyaltyStatsCards } from './components/loyalty-stats-cards'
import { LoyaltyTierBreakdown } from './components/loyalty-tier-breakdown'
import { LoyaltyAccountsTable } from './components/loyalty-accounts-table'
import { LoyaltyAccountSheet } from './components/loyalty-account-sheet'
import type { LoyaltyAccount } from './types'

export default function LoyaltyPage() {
  const [selectedAccount, setSelectedAccount] = useState<LoyaltyAccount | null>(
    null
  )
  const [sheetOpen, setSheetOpen] = useState(false)

  const { data: stats, isLoading: statsLoading } = useLoyaltyStats()
  const { data: accounts, isLoading: accountsLoading } = useLoyaltyAccounts()

  const handleViewAccount = (account: LoyaltyAccount) => {
    setSelectedAccount(account)
    setSheetOpen(true)
  }

  return (
    <>
      <Header fixed>
        <div className='ml-auto flex items-center space-x-4'>
          <ThemeSwitch />
          <ProfileDropdown />
        </div>
      </Header>

      <Main>
        <div className='mb-2 flex items-center justify-between space-y-2'>
          <div>
            <h2 className='text-2xl font-bold tracking-tight'>
              Loyalty Program
            </h2>
            <p className='text-muted-foreground'>
              Manage loyalty accounts, points, and tiers
            </p>
          </div>
        </div>

        <div className='-mx-4 flex-1 overflow-auto px-4 py-1 lg:flex-row lg:space-x-12 lg:space-y-0'>
          <div className='space-y-6'>
            {/* Stats Cards */}
            <LoyaltyStatsCards stats={stats} isLoading={statsLoading} />

            {/* Tier Breakdown */}
            <LoyaltyTierBreakdown stats={stats} isLoading={statsLoading} />

            {/* Accounts Table */}
            <LoyaltyAccountsTable
              accounts={accounts}
              isLoading={accountsLoading}
              onViewAccount={handleViewAccount}
            />
          </div>
        </div>
      </Main>

      {/* Account Detail Sheet */}
      <LoyaltyAccountSheet
        account={selectedAccount}
        open={sheetOpen}
        onOpenChange={setSheetOpen}
      />
    </>
  )
}
