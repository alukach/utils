#!/bin/zsh
# Finds rebuildable build folders in ~/github (node_modules, .venv, Rust target/)
# that haven't changed in DAYS days. Dry run by default: lists them with sizes.
# Usage: clean-github.sh [days] [--delete]   (days defaults to 30)

ROOT=~/github
DAYS=30
for a in "$@"; do [[ $a == --delete ]] && DELETE=1 || DAYS=$a; done

free_gb() { df -k /System/Volumes/Data | awk 'NR==2{printf "%.1f", $4/1048576}'; }
START=$(free_gb)

# ponytail: folder mtime approximates "last install/build"; an active repo's
# untouched node_modules can match, but rebuilding is just `npm i` / `cargo build`.
dirs=()
while IFS= read -r -d '' d; do
  [[ ${d:t} == target && ! -f ${d:h}/Cargo.toml ]] && continue  # only Rust target/
  dirs+=("$d")
done < <(find "$ROOT" \( -name node_modules -o -name .venv -o -name target \) \
           -type d -prune -mtime +"$DAYS" -print0 2>/dev/null)

(( ${#dirs} )) || { echo "Nothing older than $DAYS days."; exit 0; }

for d in "${dirs[@]}"; do
  kb=$(du -sk "$d" 2>/dev/null | cut -f1)
  printf "%8.1f GB  %s\n" $((kb / 1048576.0)) "${d#$ROOT/}"
done | sort -rn
total=$(du -skc "${dirs[@]}" 2>/dev/null | tail -1 | cut -f1)
printf "%d folders, %.1f GB total (untouched > %d days)\n" ${#dirs} $((total / 1048576.0)) $DAYS

if [[ -z $DELETE ]]; then
  echo "Dry run. Re-run with --delete to remove them."
  exit 0
fi

read -q "?Delete these ${#dirs} folders? [y/N] " || { echo; exit 1; }
echo
rm -rf "${dirs[@]}"
echo "Free space: ${START} GB -> $(free_gb) GB"
