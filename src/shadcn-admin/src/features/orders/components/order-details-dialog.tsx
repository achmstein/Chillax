import { MapPin, MessageSquare } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import type { Order, OrderStatus } from '../types'

const statusConfig: Record<OrderStatus, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  submitted: { label: 'Pending', variant: 'default' },
  confirmed: { label: 'Confirmed', variant: 'secondary' },
  cancelled: { label: 'Cancelled', variant: 'destructive' },
}

interface OrderDetailsDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  order: Order | null
}

export function OrderDetailsDialog({
  open,
  onOpenChange,
  order,
}: OrderDetailsDialogProps) {
  if (!order) return null

  const status = statusConfig[order.status]

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='sm:max-w-[600px]'>
        <DialogHeader>
          <div className='flex items-center gap-2'>
            <DialogTitle>Order #{order.ordernumber}</DialogTitle>
            <Badge variant={status.variant}>{status.label}</Badge>
          </div>
          <DialogDescription>
            Placed on {new Date(order.date).toLocaleString()}
          </DialogDescription>
        </DialogHeader>

        <div className='space-y-4'>
          {/* Order Info */}
          <div className='flex flex-wrap gap-4'>
            {order.tableNumber && (
              <div className='flex items-center gap-2 text-sm'>
                <MapPin className='h-4 w-4 text-muted-foreground' />
                <span>Table {order.tableNumber}</span>
              </div>
            )}
            {order.customerNote && (
              <div className='flex items-center gap-2 text-sm'>
                <MessageSquare className='h-4 w-4 text-muted-foreground' />
                <span>{order.customerNote}</span>
              </div>
            )}
          </div>

          <Separator />

          {/* Order Items */}
          <div className='space-y-3'>
            <h4 className='font-medium'>Order Items</h4>
            {order.orderitems.map((item, index) => (
              <div
                key={index}
                className='flex items-start justify-between rounded-lg border p-3'
              >
                <div className='space-y-1'>
                  <div className='flex items-center gap-2'>
                    <span className='font-medium'>{item.productName}</span>
                    <Badge variant='outline'>x{item.units}</Badge>
                  </div>
                  {item.customizationsDescription && (
                    <p className='text-sm text-muted-foreground'>
                      {item.customizationsDescription}
                    </p>
                  )}
                  {item.specialInstructions && (
                    <p className='text-sm text-amber-600'>
                      Note: {item.specialInstructions}
                    </p>
                  )}
                </div>
                <div className='text-right'>
                  <span className='font-medium'>
                    {(item.unitPrice * item.units).toFixed(2)} EGP
                  </span>
                  {item.discount > 0 && (
                    <div className='text-sm text-green-600'>
                      -{item.discount.toFixed(2)} discount
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>

          <Separator />

          {/* Total */}
          <div className='flex items-center justify-between text-lg font-semibold'>
            <span>Total</span>
            <span>{order.total.toFixed(2)} EGP</span>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
