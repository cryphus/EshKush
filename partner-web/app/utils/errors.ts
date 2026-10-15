/** Достаёт человекочитаемое сообщение из ошибки $fetch (ofetch) или обычного Error. */
export function getErrorMessage(err: unknown, fallback = 'Не удалось выполнить запрос'): string {
  if (err && typeof err === 'object') {
    const data = (err as { data?: { error?: string | { message?: string }, message?: string } }).data
    if (typeof data?.error === 'string') return data.error
    if (data?.error?.message) return data.error.message
    if (typeof data?.message === 'string') return data.message
    const message = (err as { message?: string }).message
    if (message) return message
  }
  return fallback
}
