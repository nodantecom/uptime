#!/usr/bin/env bash
# Her adresi 3 kez dener (30 sn arayla); üçü de düşerse "düştü" sayılır.
# Durum state.txt'de tutulur; yalnız değişince Telegram'a yazar (düştü / düzeldi).
set -uo pipefail
cd "$(dirname "$0")"

up() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "https://$1/" || true)
  case $code in 2??|3??|401|403) return 0 ;; *) return 1 ;; esac
}

mapfile -t hosts < <(grep -v '^\s*#' hosts.txt | grep .)
down=()
for h in "${hosts[@]}"; do up "$h" || down+=("$h"); done
for attempt in 2 3; do
  [ ${#down[@]} -eq 0 ] && break
  sleep 30
  still=()
  for h in "${down[@]}"; do up "$h" || still+=("$h"); done
  down=("${still[@]}")
done

new=$(printf '%s\n' "${down[@]}" | grep . | sort || true)
old=$(cat state.txt 2>/dev/null || true)
echo "düşen: ${#down[@]}/${#hosts[@]}"; [ -n "$new" ] && echo "$new"

[ "$new" = "$old" ] && exit 0
printf '%s' "$new" > state.txt

went_down=$(comm -13 <(echo "$old" | grep .) <(echo "$new" | grep .) || true)
came_up=$(comm -23 <(echo "$old" | grep .) <(echo "$new" | grep .) || true)
n_down=$(echo "$went_down" | grep -c . || true)

msg=""
if [ "${#down[@]}" -ge $(( ${#hosts[@]} / 2 )) ] && [ "$n_down" -gt 0 ]; then
  msg="🔴 Sunucuya dışarıdan ulaşılamıyor (${#down[@]}/${#hosts[@]} adres düştü). Sentinel de susmuş olabilir."
elif [ "$n_down" -gt 0 ]; then
  msg="🔴 Düştü: $(echo "$went_down" | paste -sd, - | sed 's/,/, /g')"
fi
if [ -n "$came_up" ]; then
  [ -n "$msg" ] && msg="$msg"$'\n'
  if [ -z "$new" ]; then msg="${msg}🟢 Hepsi düzeldi."; else msg="${msg}🟢 Düzeldi: $(echo "$came_up" | paste -sd, - | sed 's/,/, /g')"; fi
fi

if [ -n "${TG_TOKEN:-}" ] && [ -n "$msg" ]; then
  curl -s -o /dev/null -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
    --data-urlencode "chat_id=$TG_CHAT_ID" --data-urlencode "text=$msg"
fi
echo "$msg"
