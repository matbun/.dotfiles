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
    ssh-add PATH/TO/YOUR/SSH/KEY_1
    ssh-add PATH/TO/YOUR/SSH/KEY_2
}

# Aliases
alias ll="ls -l"
