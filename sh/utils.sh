function copy { pbcopy "$@" }

function mkcd {
    mkdir $1 && cd $1
}

function cd {
    builtin cd "$@" && ls -F
}

function abs {
    realpath --no-symlinks "$1" | tr -d "\n" | copy
}

function share-cmd {
    local cmd="$@"
    exec 5>&1 
    output=$(eval $cmd 2>&1 | tee /dev/fd/5)
    echo "\$ $cmd
$output" | copy
}

function isotime { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
function ymd { date -u +"%Y-%m-%d"; }
function ymdi { date -u +"%Y%m%d"; }

function stdouttime {
  tp="$(date +%s%N)"
  while read line; do
    tc="$(date +%s%N)"
    echo "$(((tc - tp) / 1000000000))s: $line"
  done
}

function nvim-server {
    mkdir -p $HOME/.cache/nvim 
    nvim --listen $HOME/.cache/nvim/server.pipe "$@"
}

function v {
    nvim --server $HOME/.cache/nvim/server.pipe --remote "$(realpath $1)"
}
