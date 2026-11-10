#!/usr/bin/env bash
# Toglie da GitHub Pages le cartelle <app>/social/AAAA-MM-GG piu vecchie di N giorni (default 14, ora di Roma).
# Tiene il sito sotto il limite di deploy. Nessuno legge giorni vecchi: Make e la verifica usano solo il manifest di oggi.
# Uso: pulizia-giorni-vecchi.sh [giorni] [--dry-run]   (da lanciare nella radice del repo)
# Prudenze: tocca solo cartelle col nome di una data, mai oggi o il futuro; si ferma se ne dovrebbe togliere troppe.
set -euo pipefail
KEEP="${1:-14}"; DRY="${2:-}"; MAX_DIRS="${MAX_DIRS:-80}"
[[ "$KEEP" =~ ^[0-9]+$ ]] && [ "$KEEP" -ge 7 ] || { echo "giorni non validi ($KEEP, minimo 7)"; exit 1; }
if CUT="$(TZ=Europe/Rome date -d "$KEEP days ago" +%F 2>/dev/null)"; then :; else CUT="$(TZ=Europe/Rome date -v-"$KEEP"d +%F)"; fi
OGGI="$(TZ=Europe/Rome date +%F)"
[[ "$CUT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$CUT" < "$OGGI" ]] || { echo "data limite non valida: $CUT"; exit 1; }
echo "tengo le cartelle dal $CUT in poi (oggi $OGGI, $KEEP giorni)"
LISTA="$(mktemp)"; trap 'rm -f "$LISTA"' EXIT
for d in */social/20??-??-??; do
  [ -d "$d" ] || continue
  g="$(basename "$d")"
  [[ "$g" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$g" < "$CUT" ]] && echo "$d" >> "$LISTA"
done
N=$(wc -l < "$LISTA" | tr -d ' ')
echo "da togliere: $N cartelle"
[ "$N" -le "$MAX_DIRS" ] || { echo "troppe ($N > $MAX_DIRS): mi fermo per sicurezza"; exit 1; }
[ "$N" -gt 0 ] || exit 0
cat "$LISTA"
[ "$DRY" = "--dry-run" ] && { echo "(dry-run: non tolgo nulla)"; exit 0; }
xargs -I{} rm -rf -- "{}" < "$LISTA"
echo "tolte $N cartelle"
