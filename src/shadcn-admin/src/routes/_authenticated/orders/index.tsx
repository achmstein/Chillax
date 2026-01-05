import { createFileRoute } from '@tanstack/react-router'
import { OrdersManagement } from '@/features/orders'

export const Route = createFileRoute('/_authenticated/orders/')({
  component: OrdersManagement,
})
