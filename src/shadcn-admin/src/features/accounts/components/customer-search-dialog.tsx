import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Search, User } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { accountsService } from '../services/accounts-service'
import type { KeycloakUser } from '../types'

interface CustomerSearchDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSelectCustomer: (customer: KeycloakUser) => void
}

export function CustomerSearchDialog({ open, onOpenChange, onSelectCustomer }: CustomerSearchDialogProps) {
  const [searchTerm, setSearchTerm] = useState('')

  const { data: users = [], isLoading } = useQuery({
    queryKey: ['users', searchTerm],
    queryFn: () => accountsService.getUsers(searchTerm || undefined),
    enabled: open,
  })

  const handleSelectCustomer = (customer: KeycloakUser) => {
    onSelectCustomer(customer)
    onOpenChange(false)
    setSearchTerm('')
  }

  const getDisplayName = (user: KeycloakUser): string => {
    const fullName = [user.firstName, user.lastName].filter(Boolean).join(' ')
    return fullName || user.username
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='max-w-md'>
        <DialogHeader>
          <DialogTitle>Find Customer</DialogTitle>
          <DialogDescription>
            Search for a registered customer by name
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4'>
          <div className='relative'>
            <Search className='absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground' />
            <Input
              placeholder='Search by name...'
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className='pl-10'
            />
          </div>

          <div className='max-h-[300px] overflow-y-auto space-y-2'>
            {isLoading ? (
              <>
                {[...Array(3)].map((_, i) => (
                  <Skeleton key={i} className='h-16' />
                ))}
              </>
            ) : users.length === 0 ? (
              <p className='text-center text-muted-foreground py-8'>
                {searchTerm ? 'No customers found' : 'Enter a name to search'}
              </p>
            ) : (
              users.map((user) => (
                <Button
                  key={user.id}
                  variant='outline'
                  className='w-full justify-start h-auto py-3'
                  onClick={() => handleSelectCustomer(user)}
                >
                  <div className='flex items-center gap-3'>
                    <div className='rounded-full bg-muted p-2'>
                      <User className='h-4 w-4' />
                    </div>
                    <div className='text-left'>
                      <p className='font-medium'>{getDisplayName(user)}</p>
                      {user.email && (
                        <p className='text-sm text-muted-foreground'>{user.email}</p>
                      )}
                    </div>
                  </div>
                </Button>
              ))
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
