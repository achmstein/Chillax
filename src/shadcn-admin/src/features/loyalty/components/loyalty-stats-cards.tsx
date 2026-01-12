import { Users, Star, TrendingUp, Calendar } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { LoyaltyStats } from '../types'

interface LoyaltyStatsCardsProps {
  stats: LoyaltyStats | undefined
  isLoading: boolean
}

export function LoyaltyStatsCards({ stats, isLoading }: LoyaltyStatsCardsProps) {
  const cards = [
    {
      title: 'Total Accounts',
      value: stats?.totalAccounts ?? 0,
      icon: Users,
      description: 'Loyalty program members',
    },
    {
      title: 'Points Today',
      value: stats?.pointsIssuedToday ?? 0,
      icon: Star,
      description: 'Points issued today',
    },
    {
      title: 'Points This Week',
      value: stats?.pointsIssuedThisWeek ?? 0,
      icon: TrendingUp,
      description: 'Points issued this week',
    },
    {
      title: 'Points This Month',
      value: stats?.pointsIssuedThisMonth ?? 0,
      icon: Calendar,
      description: 'Points issued this month',
    },
  ]

  return (
    <div className='grid gap-4 md:grid-cols-2 lg:grid-cols-4'>
      {cards.map((card) => (
        <Card key={card.title}>
          <CardHeader className='flex flex-row items-center justify-between space-y-0 pb-2'>
            <CardTitle className='text-sm font-medium'>{card.title}</CardTitle>
            <card.icon className='h-4 w-4 text-muted-foreground' />
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className='h-8 w-20 animate-pulse rounded bg-muted' />
            ) : (
              <>
                <div className='text-2xl font-bold'>
                  {card.value.toLocaleString()}
                </div>
                <p className='text-xs text-muted-foreground'>{card.description}</p>
              </>
            )}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
