import { Copy, QrCode } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'

interface AccessCodeDisplayProps {
  accessCode: string
  roomName: string
}

export function AccessCodeDisplay({ accessCode, roomName }: AccessCodeDisplayProps) {
  const copyToClipboard = () => {
    navigator.clipboard.writeText(accessCode)
    toast.success('Access code copied to clipboard')
  }

  return (
    <div className='space-y-4'>
      <div className='text-center'>
        <p className='text-sm text-muted-foreground mb-2'>
          Share this code with customers to join the session
        </p>
        <div className='font-mono text-4xl font-bold tracking-[0.5em] bg-primary/10 py-4 px-6 rounded-lg'>
          {accessCode}
        </div>
      </div>

      <div className='flex justify-center gap-2'>
        <Button variant='outline' onClick={copyToClipboard}>
          <Copy className='h-4 w-4 mr-2' />
          Copy Code
        </Button>
        <Button
          variant='outline'
          onClick={() => {
            const url = `chillax://join/${accessCode}`
            navigator.clipboard.writeText(url)
            toast.success('Deep link copied to clipboard')
          }}
        >
          <QrCode className='h-4 w-4 mr-2' />
          Copy Link
        </Button>
      </div>

      <p className='text-xs text-muted-foreground text-center'>
        {roomName} - Session Active
      </p>
    </div>
  )
}
