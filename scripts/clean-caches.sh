#!/bin/zsh
# Clears rebuildable caches and shows disk usage before/after each step.
# Doesn't touch ~/github, Docker volumes, or ~/.docker.bkp.

free_gb() { df -k /System/Volumes/Data | awk 'NR==2{printf "%.1f", $4/1048576}'; }
size()    { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

step() {  # step <label> <path-to-measure> <command...>
  local label=$1 dir=$2; shift 2
  local before=$(size "$dir")
  "$@" >/dev/null 2>&1
  printf "%-16s %8s -> %-8s\n" "$label" "$before" "$(size "$dir")"
}

START=$(free_gb)
printf "%-16s %8s    %-8s\n" "CACHE" "BEFORE" "AFTER"

step "npm"            ~/.npm           npm cache clean --force
step "uv"             ~/.cache/uv      uv cache clean
step "Library/Caches" ~/Library/Caches zsh -c 'rm -rf ~/Library/Caches/*(N)'  # locked items are skipped

if timeout 20 docker info >/dev/null 2>&1; then
  echo "Docker (unused images, containers, build cache):"
  docker system df
  docker system prune -af >/dev/null
  docker system df
else
  echo "Docker: daemon not responding, skipped"
fi

echo "Free space: ${START} GB -> $(free_gb) GB"
