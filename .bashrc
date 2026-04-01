# Create dir and move to it
mkcdir ()
{
    mkdir -p -- "$1" &&
       cd -P -- "$1"
}

# Get size of a remote docker image from its Manifest
dockersize ()
{
    docker manifest inspect -v "$1" | jq -c 'if type == "array" then .[] else . end' | jq -r '[ ( .Descriptor.platform | [ .os, .architecture, .variant, ."os.version" ] | del(..|nulls) | join("/") ), ( [ ( .OCIManifest // .SchemaV2Manifest ).layers[].size ] | add ) ] | join(" ")' | numfmt --to iec --format '%.2f' --field 2 | sort | column -t
}

# Start SSH agent manually
agent ()
{
    eval $(ssh-agent)
    # TODO: give your keys
    # ssh-add PATH/TO/YOUR/SSH/KEY_1
    # ssh-add PATH/TO/YOUR/SSH/KEY_2
}

# Aliases
alias ll="ls -l"
alias k="kubectl"

# PS1: Directory + exit code indicator (green ok, red fail)
export PS1='$([[ $? == 0 ]] && echo "\[\e[32m\]o" || echo "\[\e[31m\]x") \[\e[1;34m\]\W\[\e[0m\] \$ '
# PS1 with k8s cluster name prepended
# __kube_ctx() {
#   local cfg="${KUBECONFIG:-$HOME/.kube/config}"
#   local ctx
#   ctx=$(grep 'current-context:' "$cfg" 2>/dev/null | cut -d' ' -f2)
#   echo "${ctx:-no-ctx}"
# }
# export PS1='$([[ $? == 0 ]] && echo "\[\e[32m\]o" || echo "\[\e[31m\]x") \[\e[33m\]<$(__kube_ctx)>\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\] \$ '
