import { useMemo } from "react";

// Пока просто возвращаем user: null.
// Когда подключишь реальную авторизацию — поменяешь это место.
export function useAuth() {
  const user = useMemo(() => null, []);
  return { user };
}
