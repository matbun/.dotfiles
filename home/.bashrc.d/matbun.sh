# matbun/.dotfiles — portable bash fragment.
#
# Sourced from ~/.bashrc by install.sh. This file is HOST-INDEPENDENT: it must
# work on any box. Machine-specific things (tokens, absolute PATHs, pyenv/brew
# init, site completions) belong in ~/.bashrc.local, which is gitignored.

# --- functions -------------------------------------------------------------

# Create a directory and cd into it
mkcdir ()
{
    mkdir -p -- "$1" &&
       cd -P -- "$1"
}

# Get size of a remote docker image from its manifest
dockersize ()
{
    docker manifest inspect -v "$1" | jq -c 'if type == "array" then .[] else . end' | jq -r '[ ( .Descriptor.platform | [ .os, .architecture, .variant, ."os.version" ] | del(..|nulls) | join("/") ), ( [ ( .OCIManifest // .SchemaV2Manifest ).layers[].size ] | add ) ] | join(" ")' | numfmt --to iec --format '%.2f' --field 2 | sort | column -t
}

# Start an ssh-agent and add the default keys.
# Host-specific keys go in ~/.bashrc.local, e.g.  ssh-add ~/.ssh/keys/vega
agent ()
{
    eval "$(ssh-agent)"
    ssh-add
}

# --- aliases ---------------------------------------------------------------

alias ll="ls -l"
alias cl=clear

alias k="kubectl"
alias kctx='kubectl config use-context'
alias kctxls='kubectl config get-contexts'
alias kcur='kubectl config current-context'

alias tnew="tmux new -s "
alias tatt="tmux attach -t "
alias tls="tmux ls"
alias tkill="tmux kill-session -t "

# --- prompt ----------------------------------------------------------------

# exit-code marker + kube context + cwd
__kube_ctx() {
  kubectl config current-context 2>/dev/null || echo "no-ctx"
}
if command -v kubectl >/dev/null 2>&1; then
    export PS1='$([[ $? == 0 ]] && echo "\[\e[32m\]o" || echo "\[\e[31m\]x") \[\e[33m\]<$(__kube_ctx)>\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\] \$ '
else
    export PS1='$([[ $? == 0 ]] && echo "\[\e[32m\]o" || echo "\[\e[31m\]x") \[\e[1;34m\]\W\[\e[0m\] \$ '
fi

# --- completion ------------------------------------------------------------

if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi

[ -f ~/.fzf.bash ] && . ~/.fzf.bash
