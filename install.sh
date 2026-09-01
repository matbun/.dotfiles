#!/bin/sh
# install.sh — link matbun/.dotfiles into $HOME.
#
# POSIX sh. Idempotent: a second run is a no-op. Never needs sudo.
# Everything under home/ is symlinked to the matching path in $HOME, so edits
# to the live file propagate straight back into the repo.
#
#   ./install.sh              install everything
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --no-plugins skip the nvim/tmux plugin bootstrap

set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$REPO/home"
STAMP=$(date +%Y%m%d-%H%M%S)
DRY=0
PLUGINS=1

N_LINK=0; N_SKIP=0; N_BAK=0; N_WARN=0

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)    DRY=1 ;;
        --no-plugins) PLUGINS=0 ;;
        -h|--help)    usage; exit 0 ;;
        *) printf 'install.sh: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

# --- output ---------------------------------------------------------------

if [ -t 1 ]; then
    B=$(printf '\033[1m'); D=$(printf '\033[2m'); R=$(printf '\033[0m')
    GRN=$(printf '\033[32m'); YEL=$(printf '\033[33m'); CYN=$(printf '\033[36m')
else
    B=''; D=''; R=''; GRN=''; YEL=''; CYN=''
fi

section() { printf '\n%s%s%s\n' "$B" "$1" "$R"; }
say_link() { printf '  %slink%s    %s\n'   "$GRN" "$R" "$1"; N_LINK=$((N_LINK+1)); }
say_skip() { printf '  %sskip%s    %s\n'   "$D"   "$R" "$1"; N_SKIP=$((N_SKIP+1)); }
say_bak()  { printf '  %sbackup%s  %s\n'   "$YEL" "$R" "$1"; N_BAK=$((N_BAK+1)); }
say_warn() { printf '  %swarn%s    %s\n'   "$YEL" "$R" "$1"; N_WARN=$((N_WARN+1)); }
say_info() { printf '  %sinfo%s    %s\n'   "$CYN" "$R" "$1"; }

# Run a command unless --dry-run.
run() { if [ "$DRY" -eq 0 ]; then "$@"; fi }

# Display a path with $HOME collapsed to ~
tilde() { printf '%s' "$1" | sed "s|^$HOME|~|"; }

# --- linking --------------------------------------------------------------

# link_file <src> <dest>
link_file() {
    lf_src=$1
    lf_dest=$2
    lf_show=$(tilde "$lf_dest")

    if [ -L "$lf_dest" ] && [ "$(readlink "$lf_dest")" = "$lf_src" ]; then
        say_skip "$lf_show (already linked)"
        return 0
    fi

    if [ -L "$lf_dest" ] || [ -e "$lf_dest" ]; then
        lf_bak="$lf_dest.bak.$STAMP"
        say_bak "$lf_show -> $(basename "$lf_bak")"
        run mv -- "$lf_dest" "$lf_bak"
    fi

    lf_dir=$(dirname -- "$lf_dest")
    [ -d "$lf_dir" ] || run mkdir -p -- "$lf_dir"
    run ln -s -- "$lf_src" "$lf_dest"
    say_link "$lf_show"
}

section "Linking dotfiles"
if [ ! -d "$SRC" ]; then
    printf 'install.sh: missing %s\n' "$SRC" >&2
    exit 1
fi

TMPF=$(mktemp) || exit 1
trap 'rm -f "$TMPF"' EXIT INT TERM
find "$SRC" -type f -print > "$TMPF"

while IFS= read -r src; do
    [ -n "$src" ] || continue
    rel=${src#"$SRC"/}
    link_file "$src" "$HOME/$rel"
done < "$TMPF"

# --- bash: append, never replace ------------------------------------------

section "Wiring ~/.bashrc"
MARK='# >>> matbun/.dotfiles >>>'
BRC="$HOME/.bashrc"

if [ -f "$BRC" ] && grep -qF "$MARK" "$BRC" 2>/dev/null; then
    say_skip "~/.bashrc (already sources the fragment)"
else
    say_link "~/.bashrc (appending source block)"
    if [ "$DRY" -eq 0 ]; then
        cat >> "$BRC" <<'BLOCK'

# >>> matbun/.dotfiles >>>
# Managed by install.sh. Portable shell config, then per-host overrides.
[ -f "$HOME/.bashrc.d/matbun.sh" ] && . "$HOME/.bashrc.d/matbun.sh"
[ -f "$HOME/.bashrc.local" ]       && . "$HOME/.bashrc.local"
# <<< matbun/.dotfiles <<<
BLOCK
    fi
fi

# --- per-host escape hatches ----------------------------------------------

section "Per-host escape hatches"
for pair in "$HOME/.bashrc.local:shell" "$HOME/.gitconfig.local:git"; do
    f=${pair%:*}
    kind=${pair#*:}
    show=$(tilde "$f")
    if [ -e "$f" ]; then
        say_skip "$show (exists)"
    else
        say_link "$show (created empty)"
        if [ "$DRY" -eq 0 ]; then
            if [ "$kind" = git ]; then
                cat > "$f" <<'GLOCAL'
# Machine-specific git settings. Never committed.
# e.g. identity overrides, signing keys, credential helpers.
GLOCAL
            else
                cat > "$f" <<'BLOCAL'
# Machine-specific shell config. Never committed.
# e.g. secrets, absolute PATHs, pyenv/brew init, site completions.
BLOCAL
            fi
        fi
    fi
done

# --- nvim plugins ---------------------------------------------------------

section "nvim plugins"
LAZY="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
if [ "$PLUGINS" -eq 0 ]; then
    say_skip "--no-plugins given"
elif ! command -v nvim >/dev/null 2>&1; then
    say_warn "nvim not installed - config linked, plugins not bootstrapped"
elif ! command -v git >/dev/null 2>&1; then
    say_warn "git not installed - cannot bootstrap lazy.nvim"
else
    if [ -d "$LAZY" ]; then
        say_skip "lazy.nvim present"
    else
        say_link "cloning lazy.nvim"
        run git clone --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$LAZY"
    fi
    say_info "restoring plugins at pinned versions (:Lazy restore)"
    if [ "$DRY" -eq 0 ]; then
        nvim --headless "+Lazy! restore" +qa 2>/dev/null \
            || say_warn "':Lazy restore' failed - run it by hand inside nvim"
    fi
fi

# --- tmux plugins ---------------------------------------------------------

section "tmux plugins"
LOCK="$HOME/.tmux/plugins.lock"
[ -f "$LOCK" ] || LOCK="$SRC/.tmux/plugins.lock"
if [ "$PLUGINS" -eq 0 ]; then
    say_skip "--no-plugins given"
elif ! command -v tmux >/dev/null 2>&1; then
    say_warn "tmux not installed - config linked, plugins not bootstrapped"
elif ! command -v git >/dev/null 2>&1; then
    say_warn "git not installed - cannot bootstrap tmux plugins"
elif [ ! -f "$LOCK" ]; then
    say_warn "no plugins.lock found"
else
    while read -r name url commit; do
        case "$name" in ''|\#*) continue ;; esac
        dir="$HOME/.tmux/plugins/$name"
        if [ ! -d "$dir/.git" ]; then
            say_link "cloning $name"
            run git clone --quiet "$url" "$dir"
        fi
        if [ "$DRY" -eq 1 ]; then
            say_info "$name -> would pin to ${commit%"${commit#???????}"}"
            continue
        fi
        cur=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo none)
        if [ "$cur" = "$commit" ]; then
            say_skip "$name (pinned)"
        else
            git -C "$dir" fetch --quiet origin "$commit" 2>/dev/null \
                || git -C "$dir" fetch --quiet origin 2>/dev/null || true
            if git -C "$dir" checkout --quiet "$commit" 2>/dev/null; then
                say_link "$name pinned to ${commit%"${commit#???????}"}"
            else
                say_warn "$name: could not check out $commit"
            fi
        fi
    done < "$LOCK"
fi

# --- summary --------------------------------------------------------------

section "Summary"
printf '  %s linked, %s skipped, %s backed up, %s warnings\n' \
    "$N_LINK" "$N_SKIP" "$N_BAK" "$N_WARN"
if [ "$DRY" -eq 1 ]; then
    printf '  %sdry run - nothing was changed%s\n' "$YEL" "$R"
else
    printf '  Restart your shell (or: . ~/.bashrc) to pick up shell changes.\n'
fi
