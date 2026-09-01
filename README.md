# .dotfiles

Portable config for `tmux`, `vim`, `nvim`, `git` and `bash`, installed by symlink
so edits to the live file land straight back in this repo.

## What's here

```
home/                        mirrors $HOME — home/X is linked to ~/X
├── .bashrc.d/matbun.sh      portable shell fragment (sourced, never replaces ~/.bashrc)
├── .config/nvim/init.lua    neovim config
├── .config/nvim/lazy-lock.json  pinned plugin versions
├── .gitconfig               portable git config
├── .tmux.conf               tmux config
├── .tmux/plugins.lock       pinned tmux plugin versions
└── .vimrc                   vim config
install.sh                   idempotent installer (POSIX sh, no sudo)
update-tmux-lock.sh          re-pin tmux plugins after an update
```

The layout has one rule: **`home/X` is symlinked to `~/X`**. That covers plain
dotfiles and XDG paths with no manifest and no `stow` dependency.

## Install on a new host

One command:

```sh
git clone --depth=1 https://github.com/matbun/.dotfiles ~/.dotfiles && ~/.dotfiles/install.sh
```

HTTPS on purpose — a fresh box has no ssh key in the agent yet. To push from
that host later: `git -C ~/.dotfiles remote set-url origin git@github.com:matbun/.dotfiles.git`

Useful flags:

```sh
./install.sh --dry-run      # print what would happen, change nothing
./install.sh --no-plugins   # skip the nvim/tmux plugin bootstrap
```

Re-running is always safe: existing correct links are skipped, and any real file
in the way is moved to `<name>.bak.<timestamp>` before it is replaced. Missing
tools are not an error — configs still get linked, only the plugin bootstrap is
skipped, with a warning.

## Per-host escape hatches

Nothing machine-specific belongs in this repo. `install.sh` creates two files
that are **never committed**:

| File | For |
|---|---|
| `~/.bashrc.local` | secrets, absolute PATHs, pyenv/brew init, site completions |
| `~/.gitconfig.local` | identity overrides, GPG signing keys, credential helpers |

`~/.bashrc` is **appended to**, not replaced — the site's own `.bashrc` keeps
working. The added block sources the repo fragment and then `~/.bashrc.local`.
`.gitconfig` uses `[include]`, and because a later include wins, anything in
`~/.gitconfig.local` overrides the tracked file.

## Pushing changes back

Every tracked file in `$HOME` is a symlink into this repo, so editing
`~/.tmux.conf` *is* editing `home/.tmux.conf`:

```sh
cd ~/.dotfiles
git diff                     # your live edits, already staged as repo changes
git add -A && git commit -m "..." && git push
```

## Adding a new dotfile

Move it into the mirror and re-run the installer:

```sh
cd ~/.dotfiles
mkdir -p home/.config/foo
mv ~/.config/foo/config home/.config/foo/config
./install.sh                 # links it back into place
git add -A && git commit -m "Track foo config"
```

Scan it for tokens and internal hostnames first. If it can't be made
host-independent, it belongs in `~/.bashrc.local` instead.

## Updating plugin pins deliberately

Pins only move when you move them — that is the point.

**neovim.** `lazy-lock.json` is symlinked, so lazy writes updates directly into
the repo:

```sh
nvim +"Lazy update" +qa      # or :Lazy update inside nvim
cd ~/.dotfiles && git diff home/.config/nvim/lazy-lock.json
git commit -am "Bump nvim plugins"
```

To install a *new* plugin, add it to `home/.config/nvim/init.lua` (also
symlinked), start nvim, and lazy records the pin for you.

To go back to the committed versions on any host: `./install.sh`, which runs
`:Lazy restore`.

**tmux.** tpm has no lockfile of its own, so re-pin explicitly:

```sh
# prefix + U inside tmux to update, then:
cd ~/.dotfiles && ./update-tmux-lock.sh
git diff home/.tmux/plugins.lock
git commit -am "Bump tmux plugins"
```

`./install.sh` checks out exactly the commits in `plugins.lock`.
