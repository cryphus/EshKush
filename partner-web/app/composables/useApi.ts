type FetchOptions = NonNullable<Parameters<typeof $fetch>[1]>
type TokenPair = { access_token: string, refresh_token: string }
let refreshInFlight: Promise<TokenPair> | null = null

/**
 * Аутентифицированный клиент к основному Dart-бэкенду EshKush.
 * Подставляет Authorization: Bearer <access_token>; при 401 один раз
 * пытается обновить токен через /auth/refresh и повторяет запрос,
 * иначе разлогинивает и уводит на /login.
 */
export function useApi() {
  const config = useRuntimeConfig()
  const auth = useAuthStore()

  async function request<T>(path: string, options: FetchOptions = {}): Promise<T> {
    const usedToken = auth.accessToken
    const doRequest = (token: string | null) =>
      $fetch<T>(path, {
        baseURL: config.public.apiBase,
        ...options,
        headers: {
          ...(options.headers as Record<string, string> | undefined),
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        }
      })

    try {
      return await doRequest(usedToken)
    } catch (err) {
      const status = (err as { response?: { status?: number }, status?: number })?.response?.status
        ?? (err as { status?: number })?.status
      if (status === 401 && auth.refreshToken) {
        try {
          if (usedToken !== auth.accessToken) return await doRequest(auth.accessToken)
          refreshInFlight ??= $fetch<TokenPair>(
            '/auth/refresh',
            {
              baseURL: config.public.apiBase,
              method: 'POST',
              body: { refresh_token: auth.refreshToken }
            }
          ).then((pair) => {
            auth.updateTokens(pair.access_token, pair.refresh_token)
            return pair
          }).finally(() => { refreshInFlight = null })
          const refreshed = await refreshInFlight
          return await doRequest(refreshed.access_token)
        } catch {
          auth.logout()
          await navigateTo('/login')
          throw err
        }
      }
      throw err
    }
  }

  return { request }
}
