export function countLabel(value: number, forms: [string, string, string]) {
  const n = Math.abs(value) % 100
  const last = n % 10
  const index = n >= 11 && n <= 14 ? 2 : last === 1 ? 0 : last >= 2 && last <= 4 ? 1 : 2
  return `${value} ${forms[index]}`
}
