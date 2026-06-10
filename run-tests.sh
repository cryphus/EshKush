#!/usr/bin/env bash
# run-tests.sh — запуск всех тестов с итоговой таблицей

set -uo pipefail

# Немедленный SIGKILL контейнеров — таблица появляется сразу после тестов.
export COMPOSE_STOP_TIMEOUT=0

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

# ── Парсинг "+N ~M -K" из лога dart test ─────────────────────────────────────
_parse() {
  local log="$1" last='' p=0 s=0 f=0
  last=$(tr -d '\r' < "$log" | grep -oE '\+[0-9]+( ~[0-9]+)?( -[0-9]+)?' | tail -1)
  [[ "$last" =~ \+([0-9]+) ]] && p="${BASH_REMATCH[1]}"
  [[ "$last" =~ ~([0-9]+)  ]] && s="${BASH_REMATCH[1]}"
  [[ "$last" =~ -([0-9]+)  ]] && f="${BASH_REMATCH[1]}"
  echo "$p $s $f"
}

NAMES=(); PASSED=(); SKIPPED=(); FAILED=(); CODES=()

# ── Запускает команду, показывает только строки тестов, собирает статистику ───
_stage() {
  local name="$1"; shift
  printf "\n${BOLD}▶ %s${NC}\n" "$name"
  local tmp; tmp=$(mktemp)
  set +e
  "$@" 2>&1 | tee "$tmp" \
    | grep --line-buffered -E 'All tests|Some tests|\[E\]|loading test|exited with code' \
    | sed 's/.*| //'
  local code=${PIPESTATUS[0]}
  set -e
  local p=0 s=0 f=0
  read -r p s f < <(_parse "$tmp")
  rm -f "$tmp"
  NAMES+=("$name"); PASSED+=("${p:-0}"); SKIPPED+=("${s:-0}")
  FAILED+=("${f:-0}"); CODES+=("${code:-1}")
}

_down() { docker-compose down --remove-orphans > /dev/null 2>&1 || true; }

# ── Этапы ─────────────────────────────────────────────────────────────────────
_stage "Unit tests" \
  docker-compose run --rm unit-tests

_stage "Integration tests" \
  docker-compose up --abort-on-container-exit \
    --exit-code-from repo-tests postgres-test repo-tests

_down

_stage "E2E tests" \
  docker-compose up --abort-on-container-exit \
    --exit-code-from e2e-tests postgres redis backend e2e-tests

_down

# ══════════════════════════════════════════════════════════════════════════════
# Итоговая таблица — 74 символа в ширину
#
# Столбцы (видимых символов между ║):  Название=24  Прошло=10  Пропущ.=10
#                                        Упало=10  Результат=14
# ══════════════════════════════════════════════════════════════════════════════

total_p=0; total_s=0; total_f=0; overall=0
for i in "${!NAMES[@]}"; do
  (( total_p += PASSED[$i]  )) || true
  (( total_s += SKIPPED[$i] )) || true
  (( total_f += FAILED[$i]  )) || true
  [[ "${CODES[$i]}" -ne 0 ]] && overall=1
done

C="${CYAN}"; N="${NC}"; B="${BOLD}"; G="${GREEN}"; R="${RED}"

echo ""
echo -e "${C}╔══════════════════════════════════════════════════════════════════════════╗${N}"
echo -e "${C}║${B}                        РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ                         ${C}║${N}"
echo -e "${C}╠════════════════════════╦══════════╦══════════╦══════════╦══════════════╣${N}"
echo -e "${C}║${N}  Тесты                 ${C}║${N}   Прошло ${C}║${N}  Пропущ. ${C}║${N}   Упало  ${C}║${N}  Результат   ${C}║${N}"
echo -e "${C}╠════════════════════════╬══════════╬══════════╬══════════╬══════════════╣${N}"

for i in "${!NAMES[@]}"; do
  p="${PASSED[$i]}"; s="${SKIPPED[$i]}"; f="${FAILED[$i]}"; c="${CODES[$i]}"
  sd="$( [[ "$s" -gt 0 ]] && echo "$s" || echo '-' )"
  fd="$( [[ "$f" -gt 0 ]] && echo "$f" || echo '-' )"

  # Первые 4 столбца: имя (ASCII) и числа — printf справляется без проблем
  printf "${C}║${N}  %-22s ${C}║${N} %8s ${C}║${N} %8s ${C}║${N} %8s ${C}║${N}" \
    "${NAMES[$i]}" "$p" "$sd" "$fd"

  # Последний столбец: фиксированные пробелы, чтобы итог = 14 видимых символов
  if [[ "$c" -eq 0 ]]; then
    echo -e "  ${G}✓ OK${N}        ${C}║${N}"   # 2 + 4 + 8 = 14
  else
    echo -e "  ${R}✗ FAIL${N}      ${C}║${N}"   # 2 + 6 + 6 = 14
  fi
done

echo -e "${C}╠════════════════════════╬══════════╬══════════╬══════════╬══════════════╣${N}"

sd_t="$( [[ "$total_s" -gt 0 ]] && echo "$total_s" || echo '-' )"
fd_t="$( [[ "$total_f" -gt 0 ]] && echo "$total_f" || echo '-' )"

# ИТОГО — имя хардкодом (обходим printf+кириллица), числа через %s
printf "${C}║${N}${B}  ИТОГО                 ${N}${C}║${N}${B} %8s ${N}${C}║${N}${B} %8s ${N}${C}║${N}${B} %8s ${N}${C}║${N}" \
  "$total_p" "$sd_t" "$fd_t"

if [[ $overall -eq 0 ]]; then
  echo -e "  ${G}${B}✓ PASSED${N}    ${C}║${N}"   # 2 + 8 + 4 = 14
else
  echo -e "  ${R}${B}✗ ERRORS${N}    ${C}║${N}"   # 2 + 8 + 4 = 14
fi

echo -e "${C}╚════════════════════════╩══════════╩══════════╩══════════╩══════════════╝${N}"
echo ""

exit $overall
