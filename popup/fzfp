#!/usr/bin/env bash

fail() {
    echo "$1" >&2
    exit 2
}

fzf=$(command -v fzf 2>/dev/null) || fzf=$(dirname $0)/fzf
[[ -x "$fzf" ]] || fail 'fzf executable not found'

if [[ -n $TMUX_POPUP_NESTED_FB ]]; then
    eval "$TMUX_POPUP_NESTED_FB" && exec fzf "$@"
fi

tmux -V | awk '{match($0, /[0-9]+\.[0-9]+/, m);exit m[0]<3.2}' || exec fzf "$@"

args=('--no-height')
while (($#)); do
    arg=$1
    case $arg in
    --height | --width)
        eval "${arg:2}=$2"
        shift
        ;;
    --height=* | --width=*)
        eval "${arg:2}"
        ;;
    *)
        args+=("$arg")
        ;;
    esac
    shift
done

opts=$(printf '%q ' "${args[@]}")

[[ -z $height ]] && height=${TMUX_POPUP_HEIGHT:-80%}
[[ -z $width ]] && width=${TMUX_POPUP_WIDTH:-80%}

envs="SHELL=$SHELL"
[[ -n $FZF_DEFAULT_OPTS ]] && envs="$envs FZF_DEFAULT_OPTS=$(printf %q "$FZF_DEFAULT_OPTS")"
[[ -n $FZF_DEFAULT_COMMAND ]] && envs="$envs FZF_DEFAULT_COMMAND=$(printf %q "$FZF_DEFAULT_COMMAND")"

id=$RANDOM
cmd_file="${TMPDIR:-/tmp}/fzf-cmd-file-$id"
pstdin="${TMPDIR:-/tmp}/fzf-pstdin-$id"
pstdout="${TMPDIR:-/tmp}/fzf-pstdout-$id"

clean_cmd="command rm -f $cmd_file $pstdin $pstdout"

cleanup() {
    eval "$clean_cmd"
}
trap 'cleanup' EXIT

mkfifo "$pstdout"

echo -n "trap '$clean_cmd' EXIT SIGINT SIGTERM SIGHUP;" >"$cmd_file"

if [[ -t 0 ]]; then
    echo -n "$fzf $opts > $pstdout" >>"$cmd_file"
else
    mkfifo "$pstdin"
    echo -n "$fzf $opts < $pstdin > $pstdout" >>"$cmd_file"
    cat <&0 >"$pstdin" &
fi
cat "$pstdout" &
tmux popup -d '#{pane_current_path}' -xC -yC -w$width -h$height -E "$envs bash $cmd_file"
