import { useState } from 'react'
import { useAuth } from 'react-oidc-context'
import {
  Info,
  Server,
  Coffee,
  Gamepad2,
  ShoppingCart,
  Award,
  Shield,
  LogOut,
} from 'lucide-react'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { API_CONFIG } from '@/config/api-config'

interface ApiEndpoint {
  name: string
  url: string
  icon: React.ComponentType<{ className?: string }>
}

const apiEndpoints: ApiEndpoint[] = [
  { name: 'Identity Provider', url: API_CONFIG.identity, icon: Shield },
  { name: 'Catalog API', url: API_CONFIG.catalog, icon: Coffee },
  { name: 'Orders API', url: API_CONFIG.orders, icon: ShoppingCart },
  { name: 'Rooms API', url: API_CONFIG.rooms, icon: Gamepad2 },
  { name: 'Loyalty API', url: API_CONFIG.loyalty, icon: Award },
]

export function SettingsProfile() {
  const auth = useAuth()
  const [signOutOpen, setSignOutOpen] = useState(false)

  // Extract user info from OIDC
  const user = auth.user?.profile
  const name = user?.name || user?.preferred_username || 'Admin User'
  const email = user?.email || ''
  const initials = name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  // Extract roles from token
  const realmRoles = (auth.user?.profile?.realm_access as { roles?: string[] })?.roles || []
  const resourceRoles = (auth.user?.profile?.resource_access as Record<string, { roles?: string[] }>) || {}
  const clientRoles = resourceRoles['chillax-admin']?.roles || []
  const roles = [...new Set([...realmRoles, ...clientRoles])].filter(
    (role) => !role.startsWith('default-') && !role.startsWith('uma_') && role !== 'offline_access'
  )

  const handleSignOut = () => {
    auth.signoutRedirect()
  }

  return (
    <div className='space-y-6'>
      <div>
        <h3 className='text-lg font-medium'>Profile</h3>
        <p className='text-sm text-muted-foreground'>
          Your account information and settings.
        </p>
      </div>

      <Separator />

      {/* Profile Card */}
      <Card>
        <CardContent className='pt-6'>
          <div className='flex items-start gap-6'>
            <Avatar className='h-20 w-20'>
              <AvatarFallback className='text-2xl'>{initials}</AvatarFallback>
            </Avatar>
            <div className='flex-1 space-y-2'>
              <div>
                <h4 className='text-xl font-semibold'>{name}</h4>
                {email && (
                  <p className='text-sm text-muted-foreground'>{email}</p>
                )}
              </div>
              {roles.length > 0 && (
                <div className='flex flex-wrap gap-2'>
                  {roles.map((role) => (
                    <Badge
                      key={role}
                      variant={role.toLowerCase() === 'admin' ? 'default' : 'secondary'}
                    >
                      {role}
                    </Badge>
                  ))}
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* About Section */}
      <div className='space-y-4'>
        <h4 className='text-lg font-medium'>About</h4>
        <Card>
          <CardHeader className='pb-3'>
            <CardTitle className='flex items-center gap-2 text-sm font-medium'>
              <Info className='h-4 w-4' />
              Application Info
            </CardTitle>
          </CardHeader>
          <CardContent className='space-y-0'>
            <div className='flex items-center justify-between py-3 border-b'>
              <span className='text-sm font-medium'>App Version</span>
              <span className='text-sm text-muted-foreground'>1.0.0</span>
            </div>
            <div className='flex items-center justify-between py-3'>
              <span className='text-sm font-medium'>Environment</span>
              <Badge variant='outline'>
                {import.meta.env.DEV ? 'Development' : 'Production'}
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className='pb-3'>
            <CardTitle className='flex items-center gap-2 text-sm font-medium'>
              <Server className='h-4 w-4' />
              API Endpoints
            </CardTitle>
          </CardHeader>
          <CardContent className='space-y-0'>
            {apiEndpoints.map((endpoint, index) => {
              const Icon = endpoint.icon
              return (
                <div
                  key={endpoint.name}
                  className={`flex items-center gap-3 py-3 ${
                    index < apiEndpoints.length - 1 ? 'border-b' : ''
                  }`}
                >
                  <Icon className='h-4 w-4 text-muted-foreground' />
                  <div className='flex-1 min-w-0'>
                    <span className='text-sm font-medium'>{endpoint.name}</span>
                    <p className='text-xs text-muted-foreground truncate'>
                      {endpoint.url}
                    </p>
                  </div>
                </div>
              )
            })}
          </CardContent>
        </Card>
      </div>

      {/* Sign Out */}
      <div className='pt-4'>
        <Button
          variant='destructive'
          className='w-full'
          onClick={() => setSignOutOpen(true)}
        >
          <LogOut className='mr-2 h-4 w-4' />
          Sign Out
        </Button>
      </div>

      {/* Sign Out Confirmation */}
      <AlertDialog open={signOutOpen} onOpenChange={setSignOutOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Sign Out?</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to sign out? You will need to sign in again
              to access the admin panel.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleSignOut}>
              Sign Out
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
