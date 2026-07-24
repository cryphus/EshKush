// Типы данных, зеркалящие DTO основного Dart-бэкенда EshKush
// (backend/lib/model/dto, backend/lib/model/entities).

export type UserRole = 'guest' | 'user' | 'partner' | 'support' | 'admin'

export interface User {
  id: number
  username: string
  email: string | null
  number: string | null
  role: UserRole
}

export interface Point {
  id: number
  name: string
  address: string
  rating: number
  city_id: number
  opening_hours: string
  closing_hours: string
  partner_id: number
  longitude: number
  latitude: number
  created_at: string
  updated_at: string | null
}

export interface Product {
  id: number
  name: string
  description: string
  price: number
  image_url: string | null
  partner_id: number
  point_id: number
  weight: number
  is_available: boolean
  is_active: boolean
  created_at: string
  updated_at: string | null
}

export type OrderStatus = 'pending' | 'processing' | 'completed' | 'cancelled'

export interface Order {
  id: number
  products_id: number[]
  user_id: number
  point_id: number
  date: string
  status: OrderStatus
  total_price: number
  created_at: string
  updated_at: string | null
}

export interface Paginated<T> {
  data: T[]
  pagination: {
    limit: number
    offset: number
    count: number
    hasMore: boolean
  }
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  user: {
    id?: number
    username?: string
    email?: string | null
    phoneNumber?: string | null
    role?: UserRole
  }
}
