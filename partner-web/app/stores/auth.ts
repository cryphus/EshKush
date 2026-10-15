import { defineStore } from 'pinia'
import type { LoginResponse, User } from '~/types/api'

const STORAGE_KEY = 'eshkush_partner_auth'

interface StoredAuth {
  accessToken: string
  refreshToken: string
  user: User
}

function readStorage(): StoredAuth | null {
  if (typeof window === 'undefined') return null
  const raw = window.localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredAuth
  } catch {
    return null
  }
}

function writeStorage(data: StoredAuth | null) {
  if (typeof window === 'undefined') return
  if (data) {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  } else {
    window.localStorage.removeItem(STORAGE_KEY)
  }
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as User | null,
    accessToken: null as string | null,
    refreshToken: null as string | null,
    // true пока не прочитали localStorage хотя бы раз — чтобы middleware
    // не редиректил на /login до восстановления сессии из хранилища.
    hydrated: false
  }),

  getters: {
    isAuthenticated: state => !!state.accessToken && !!state.user,
    isPartnerOrAdmin: state =>
      state.user?.role === 'partner' || state.user?.role === 'admin'
  },

  actions: {
    acceptSession(res: LoginResponse) {
      const user: User = {
        id: res.user.id ?? 0, username: res.user.username ?? 'Александр',
        email: res.user.email ?? null, number: res.user.phoneNumber ?? null,
        role: res.user.role ?? 'user'
      }
      this.user = user
      this.accessToken = res.access_token
      this.refreshToken = res.refresh_token
      this.hydrated = true
      writeStorage({ user, accessToken: res.access_token, refreshToken: res.refresh_token })
    },
    async verifyCode(challengeId: string, code: string) {
      const config = useRuntimeConfig()
      const res = await $fetch<LoginResponse>('/demo/auth/verify', {
        baseURL: config.public.apiBase, method: 'POST', body: { challenge_id: challengeId, code }
      })
      this.acceptSession(res)
    },
    async demoLogin(role: 'user' | 'partner' | 'admin' = 'user') {
      const config = useRuntimeConfig()
      const res = await $fetch<LoginResponse>('/demo/session', {
        baseURL: config.public.apiBase, method: 'POST', body: { role }
      })
      const user: User = {
        id: res.user.id ?? 0, username: res.user.username ?? 'demo',
        email: res.user.email ?? null, number: res.user.phoneNumber ?? null,
        role: res.user.role ?? role
      }
      this.user = user
      this.accessToken = res.access_token
      this.refreshToken = res.refresh_token
      this.hydrated = true
      writeStorage({ user, accessToken: res.access_token, refreshToken: res.refresh_token })
    },
    updateTokens(accessToken: string, refreshToken: string) {
      this.accessToken = accessToken
      this.refreshToken = refreshToken
      if (this.user) writeStorage({ accessToken, refreshToken, user: this.user })
    },
    /** Восстанавливает сессию из localStorage. Вызывается один раз при старте приложения. */
    hydrate() {
      if (this.hydrated) return
      const stored = readStorage()
      if (stored) {
        this.accessToken = stored.accessToken
        this.refreshToken = stored.refreshToken
        this.user = stored.user
      }
      this.hydrated = true
    },

    /** Логин по логину/паролю через основной backend (POST /login). */
    async login(username: string, password: string) {
      const config = useRuntimeConfig()
      const res = await $fetch<LoginResponse>('/login', {
        baseURL: config.public.apiBase,
        method: 'POST',
        body: { username, password }
      })

      const role = (res.user?.role as User['role']) || 'user'
      if (role !== 'partner' && role !== 'admin') {
        throw new Error('Доступ разрешён только партнёрам')
      }

      const user: User = {
        id: res.user?.id ?? 0,
        username: res.user?.username ?? username,
        email: res.user?.email ?? null,
        number: res.user?.phoneNumber ?? null,
        role
      }

      this.accessToken = res.access_token
      this.refreshToken = res.refresh_token
      this.user = user
      writeStorage({ accessToken: res.access_token, refreshToken: res.refresh_token, user })
    },

    logout() {
      const token = this.accessToken
      if (token) {
        const config = useRuntimeConfig()
        void $fetch('/logout', { baseURL: config.public.apiBase, method: 'POST',
          headers: { Authorization: `Bearer ${token}` }, body: {} }).catch(() => {})
      }
      this.accessToken = null
      this.refreshToken = null
      this.user = null
      writeStorage(null)
    },

    /** Обновляет access-токен после успешного refresh (см. useApi 401-перехватчик). */
    updateAccessToken(token: string) {
      this.accessToken = token
      if (this.refreshToken && this.user) {
        writeStorage({ accessToken: token, refreshToken: this.refreshToken, user: this.user })
      }
    }
  }
})
