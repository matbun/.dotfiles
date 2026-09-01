#!/bin/sh
# update-tmux-lock.sh — re-pin tmux plugins to whatever is checked out now.
#
# tmux has no ":Lazy restore" equivalent, so this is the deliberate update step:
#
#   1. update plugins in tmux:   prefix + U
#   2. ./update-tmux-lock.sh     rewrite the lockfile from the live checkouts
#   3. git diff home/.tmux/plugins.lock   review what moved
#   4. commit
#
# Nothing here touches the network or changes a checkout; it only records state.

set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCK="$REPO/home/.tmux/plugins.lock"
PLUGDIR="$HOME/.tmux/plugins"

[ -d "$PLUGDIR" ] || { printf 'no %s - nothing to lock\n' "$PLUGDIR" >&2; exit 1; }

TMPF=$(mktemp) || exit 1
trap 'rm -f "$TMPF"' EXIT INT TERM

cat > "$TMPF" <<'HEADER'
# tmux plugin pins — the tmux counterpart of nvim's lazy-lock.json.
# Format:  <name> <git-url> <commit>
# Restore with:  ./install.sh          (checks out exactly these commits)
# Update with:   prefix + U, then ./update-tmux-lock.sh
HEADER

for dir in "$PLUGDIR"/*/; do
    [ -d "$dir/.git" ] || continue
    name=$(basename "$dir")
    url=$(git -C "$dir" remote get-url origin 2>/dev/null || echo '')
    commit=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo '')
    [ -n "$url" ] && [ -n "$commit" ] || continue
    # strip credential noise some tpm clones leave in the remote url
    url=$(printf '%s' "$url" | sed 's|://[^@/]*@|://|')
    printf '%s %s %s\n' "$name" "$url" "$commit" >> "$TMPF"
done

if [ -f "$LOCK" ] && cmp -s "$TMPF" "$LOCK"; then
    printf 'plugins.lock already up to date\n'
else
    cp "$TMPF" "$LOCK"
    printf 'wrote %s\n\n' "$LOCK"
    sed -n '5,$p' "$LOCK"
fi
