// Room types matching the Rooms.API models

export type RoomStatus = 'available' | 'occupied' | 'reserved' | 'maintenance'

export type SessionStatus = 'reserved' | 'active' | 'completed' | 'cancelled'

export interface Room {
  id: number
  name: string
  description?: string
  status: RoomStatus
  hourlyRate: number
  pictureFileName?: string
}

export interface RoomSession {
  id: number
  roomId: number
  room?: Room
  customerId: string
  customerName?: string
  reservationTime: string
  startTime?: string
  endTime?: string
  totalCost?: number
  status: SessionStatus
}

export interface StartSessionRequest {
  roomId: number
  customerId: string
  customerName?: string
}

export interface ReserveRoomRequest {
  roomId: number
  customerId: string
  customerName?: string
  reservationTime: string
}

export interface EndSessionResult {
  session: RoomSession
  totalCost: number
  durationMinutes: number
}

export interface WalkInSessionResult {
  reservationId: number
  accessCode: string
}
