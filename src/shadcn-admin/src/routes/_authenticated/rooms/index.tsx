import { createFileRoute } from '@tanstack/react-router'
import { RoomsManagement } from '@/features/rooms'

export const Route = createFileRoute('/_authenticated/rooms/')({
  component: RoomsManagement,
})
