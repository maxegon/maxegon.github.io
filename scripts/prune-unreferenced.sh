#!/usr/bin/env bash
# Toglie da una cartella-giorno di GitHub Pages le immagini (png/jpg) che nessun JSON del giorno cita.
# Sono passaggi intermedi del rendering (copie PNG accanto ai JPG, thumbs/, frames/): pesano centinaia di MB
# e non le legge nessuno (Make, Meta e la verifica manifest usano solo gli URL scritti nei manifest).
# Uso: prune-unreferenced.sh <cartella-giorno> [--dry-run]
# Prudenza: senza manifest nella cartella non tocca nulla; i video (.mp4) e i .json non si toccano mai.
set -euo pipefail
DIR="${1:?cartella del giorno}"; DRY="${2:-}"
[ -d "$DIR" ] || { echo "prune: cartella assente ($DIR), niente da fare"; exit 0; }
ls "$DIR"/manifest*.json >/dev/null 2>&1 || { echo "prune: nessun manifest in $DIR, non tocco nulla"; exit 0; }
REFS="$(mktemp)"; trap 'rm -f "$REFS"' EXIT
find "$DIR" -name '*.json' -print0 | xargs -0 cat > "$REFS"
n=0; kb=0
while IFS= read -r -d '' f; do
  key="$(basename "$(dirname "$f")")/$(basename "$f")"   # es. SVL_20261108_1000_CAR/01_copertina.png
  if ! grep -qF -- "$key" "$REFS"; then
    kb=$((kb + $(du -k "$f" | cut -f1))); n=$((n + 1))
    [ "$DRY" = "--dry-run" ] || rm -f -- "$f"
  fi
done < <(find "$DIR" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print0)
# cartelle rimaste vuote
[ "$DRY" = "--dry-run" ] || find "$DIR" -mindepth 1 -type d -empty -delete
echo "prune: $n immagini non citate ($((kb / 1024)) MB) $([ "$DRY" = "--dry-run" ] && echo 'DA TOGLIERE (dry-run)' || echo 'tolte') in $DIR"
