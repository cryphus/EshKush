/** Достаёт человекочитаемое сообщение из ошибки $fetch (ofetch) или обычного Error. */
export function getErrorMessage(err: unknown, fallback = 'Не удалось выполнить запрос'): string {
  if (err && typeof err === 'object') {
    const data = (err as { data?: { error?: { message?: string } } }).data
    if (data?.error?.message) return data.error.message
    const message = (err as { message?: string }).message
    if (message) return message
  }
  return fallback
}
