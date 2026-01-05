import { useEffect } from 'react'
import { useAuth } from 'react-oidc-context'
import { useNavigate, useSearch } from '@tanstack/react-router'
import { Loader2 } from 'lucide-react'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { AuthLayout } from '../auth-layout'

export function SignIn() {
  const auth = useAuth()
  const navigate = useNavigate()
  const { redirect } = useSearch({ from: '/(auth)/sign-in' })

  useEffect(() => {
    // If already authenticated, redirect to dashboard or specified path
    if (auth.isAuthenticated) {
      navigate({ to: redirect || '/', replace: true })
    }
  }, [auth.isAuthenticated, navigate, redirect])

  const handleLogin = () => {
    // Store the redirect URL in session storage for after authentication
    if (redirect) {
      sessionStorage.setItem('auth_redirect', redirect)
    }
    auth.signinRedirect()
  }

  if (auth.isLoading) {
    return (
      <AuthLayout>
        <Card className='gap-4'>
          <CardContent className='flex items-center justify-center py-12'>
            <Loader2 className='h-8 w-8 animate-spin' />
            <span className='ml-2'>Loading...</span>
          </CardContent>
        </Card>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout>
      <Card className='gap-4'>
        <CardHeader className='text-center'>
          <CardTitle className='text-2xl tracking-tight'>
            Welcome to Chillax Admin
          </CardTitle>
          <CardDescription>
            Sign in to manage your cafe, menu items, orders, and PlayStation rooms
          </CardDescription>
        </CardHeader>
        <CardContent className='flex flex-col gap-4'>
          <Button
            onClick={handleLogin}
            disabled={auth.isLoading}
            size='lg'
            className='w-full'
          >
            {auth.isLoading ? (
              <Loader2 className='mr-2 h-4 w-4 animate-spin' />
            ) : null}
            Sign in with Chillax Account
          </Button>
          <p className='text-muted-foreground text-center text-sm'>
            Use your Chillax admin credentials to access the dashboard
          </p>
        </CardContent>
      </Card>
    </AuthLayout>
  )
}
