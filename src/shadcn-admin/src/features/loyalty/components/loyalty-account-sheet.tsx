import { useState } from 'react'
import { Award, Plus, RefreshCw, TrendingUp, Calendar } from 'lucide-react'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { useLoyaltyTransactions } from '../hooks/use-loyalty'
import { LoyaltyTransactionList } from './loyalty-transaction-list'
import { EarnPointsDialog } from './earn-points-dialog'
import { AdjustPointsDialog } from './adjust-points-dialog'
import {
  type LoyaltyAccount,
  tierColors,
  formatTierName,
  getNextTier,
} from '../types'

interface LoyaltyAccountSheetProps {
  account: LoyaltyAccount | null
  open: boolean
  onOpenChange: (open: boolean) => void
}

const tierPointsRequired: Record<string, number> = {
  bronze: 0,
  silver: 1000,
  gold: 5000,
  platinum: 10000,
}

export function LoyaltyAccountSheet({
  account,
  open,
  onOpenChange,
}: LoyaltyAccountSheetProps) {
  const [earnDialogOpen, setEarnDialogOpen] = useState(false)
  const [adjustDialogOpen, setAdjustDialogOpen] = useState(false)

  const { data: transactions, isLoading: transactionsLoading } =
    useLoyaltyTransactions(account?.userId ?? '')

  if (!account) return null

  const tierColor = tierColors[account.currentTier]
  const nextTier = getNextTier(account.currentTier)
  const nextTierPoints = nextTier ? tierPointsRequired[nextTier] : null
  const progressToNextTier = nextTierPoints
    ? Math.min(
        100,
        Math.round((account.lifetimePoints / nextTierPoints) * 100)
      )
    : 100

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    })
  }

  return (
    <>
      <Sheet open={open} onOpenChange={onOpenChange}>
        <SheetContent className='w-full sm:max-w-md'>
          <SheetHeader>
            <SheetTitle className='flex items-center gap-2'>
              <Award className='h-5 w-5' style={{ color: tierColor }} />
              Loyalty Account
            </SheetTitle>
            <SheetDescription className='font-mono text-xs'>
              {account.userId}
            </SheetDescription>
          </SheetHeader>

          <div className='mt-6 space-y-6'>
            {/* Tier Badge */}
            <div className='flex items-center justify-center'>
              <Badge
                className='gap-2 px-4 py-2 text-lg'
                style={{
                  backgroundColor: `${tierColor}20`,
                  borderColor: tierColor,
                  color: tierColor,
                }}
                variant='outline'
              >
                <Award className='h-5 w-5' />
                {formatTierName(account.currentTier)} Member
              </Badge>
            </div>

            {/* Points Summary */}
            <div className='grid grid-cols-2 gap-4'>
              <div className='rounded-lg bg-muted p-4 text-center'>
                <div className='text-2xl font-bold'>
                  {account.pointsBalance.toLocaleString()}
                </div>
                <div className='text-xs text-muted-foreground'>
                  Available Points
                </div>
              </div>
              <div className='rounded-lg bg-muted p-4 text-center'>
                <div className='text-2xl font-bold'>
                  {account.lifetimePoints.toLocaleString()}
                </div>
                <div className='text-xs text-muted-foreground'>
                  Lifetime Points
                </div>
              </div>
            </div>

            {/* Next Tier Progress */}
            {nextTier && nextTierPoints && (
              <div className='space-y-2'>
                <div className='flex items-center justify-between text-sm'>
                  <span className='flex items-center gap-1 text-muted-foreground'>
                    <TrendingUp className='h-3 w-3' />
                    Progress to {formatTierName(nextTier)}
                  </span>
                  <span className='font-medium'>
                    {account.lifetimePoints.toLocaleString()} /{' '}
                    {nextTierPoints.toLocaleString()}
                  </span>
                </div>
                <div className='h-2 rounded-full bg-muted overflow-hidden'>
                  <div
                    className='h-full rounded-full transition-all'
                    style={{
                      width: `${progressToNextTier}%`,
                      backgroundColor: tierColors[nextTier],
                    }}
                  />
                </div>
                <p className='text-xs text-muted-foreground text-center'>
                  {nextTierPoints - account.lifetimePoints > 0
                    ? `${(nextTierPoints - account.lifetimePoints).toLocaleString()} points to ${formatTierName(nextTier)}`
                    : `Eligible for ${formatTierName(nextTier)}!`}
                </p>
              </div>
            )}

            {/* Member Since */}
            <div className='flex items-center gap-2 text-sm text-muted-foreground'>
              <Calendar className='h-4 w-4' />
              Member since {formatDate(account.createdAt)}
            </div>

            <Separator />

            {/* Actions */}
            <div className='flex gap-2'>
              <Button
                className='flex-1'
                onClick={() => setEarnDialogOpen(true)}
              >
                <Plus className='mr-2 h-4 w-4' />
                Earn Points
              </Button>
              <Button
                variant='outline'
                className='flex-1'
                onClick={() => setAdjustDialogOpen(true)}
              >
                <RefreshCw className='mr-2 h-4 w-4' />
                Adjust
              </Button>
            </div>

            <Separator />

            {/* Transaction History */}
            <LoyaltyTransactionList
              transactions={transactions}
              isLoading={transactionsLoading}
            />
          </div>
        </SheetContent>
      </Sheet>

      <EarnPointsDialog
        open={earnDialogOpen}
        onOpenChange={setEarnDialogOpen}
        userId={account.userId}
      />

      <AdjustPointsDialog
        open={adjustDialogOpen}
        onOpenChange={setAdjustDialogOpen}
        userId={account.userId}
        currentBalance={account.pointsBalance}
      />
    </>
  )
}
