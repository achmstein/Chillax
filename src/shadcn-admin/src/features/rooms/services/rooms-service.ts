import { roomsApi } from '@/lib/api-client'
import type { Room, RoomSession, EndSessionResult, WalkInSessionResult } from '../types'

export const roomsService = {
  // Get all rooms with their current status
  async getRooms(): Promise<Room[]> {
    const response = await roomsApi.get<Room[]>('/api/rooms')
    return response.data
  },

  // Get available rooms only
  async getAvailableRooms(): Promise<Room[]> {
    const response = await roomsApi.get<Room[]>('/api/rooms/available')
    return response.data
  },

  // Get a single room by ID
  async getRoom(id: number): Promise<Room> {
    const response = await roomsApi.get<Room>(`/api/rooms/${id}`)
    return response.data
  },

  // Reserve a room
  async reserveRoom(roomId: number, customerId: string, customerName?: string): Promise<RoomSession> {
    const response = await roomsApi.post<RoomSession>(`/api/rooms/${roomId}/reserve`, {
      customerId,
      customerName,
    })
    return response.data
  },

  // Start a session (admin starts the timer)
  async startSession(sessionId: number): Promise<RoomSession> {
    const response = await roomsApi.post<RoomSession>(`/api/rooms/sessions/${sessionId}/start`)
    return response.data
  },

  // Start a walk-in session without customer (returns access code)
  async startWalkInSession(roomId: number, notes?: string): Promise<WalkInSessionResult> {
    const response = await roomsApi.post<WalkInSessionResult>(`/api/rooms/sessions/walk-in/${roomId}`, {
      notes,
    })
    return response.data
  },

  // End a session (admin stops the timer, cost is calculated)
  async endSession(sessionId: number): Promise<EndSessionResult> {
    const response = await roomsApi.post<EndSessionResult>(`/api/sessions/${sessionId}/end`)
    return response.data
  },

  // Get active sessions
  async getActiveSessions(): Promise<RoomSession[]> {
    const response = await roomsApi.get<RoomSession[]>('/api/sessions/active')
    return response.data
  },

  // Get session history
  async getSessionHistory(roomId?: number): Promise<RoomSession[]> {
    const url = roomId ? `/api/sessions?roomId=${roomId}` : '/api/sessions'
    const response = await roomsApi.get<RoomSession[]>(url)
    return response.data
  },

  // Update room status (for maintenance)
  async updateRoomStatus(roomId: number, status: string): Promise<Room> {
    const response = await roomsApi.put<Room>(`/api/rooms/${roomId}/status`, { status })
    return response.data
  },
}
