#!/usr/bin/env bash

new_window() {
    [[ -x $(command -v fzf 2>/dev/null) ]] || return
    pane_id=$(tmux show -gqv '@fzf_pane_id')
    [[ -n $pane_id ]] && tmux kill-pane -t $pane_id >/dev/null 2>&1
    tmux new-window "bash $0 do_action" >/dev/null 2>&1
}

# invoked by pane-focus-in event
update_mru_pane_ids() {
    o_data=($(tmux show -gqv '@mru_pane_ids'))
    current_pane_id=$(tmux display-message -p '#D')
    n_data=($current_pane_id)
    for data in "${o_data[@]}"; do
        [[ $current_pane_id != "$data" ]] && n_data+=("$data")
    done
    tmux set -g '@mru_pane_ids' "${n_data[*]}"
}

do_action() {
    trap 'tmux set -gu @fzf_pane_id' EXIT SIGINT SIGTERM
    current_pane_id=$(tmux display-message -p '#D')
    tmux set -g @fzf_pane_id $current_pane_id

    cmd="bash $0 panes_src"
    set -- 'tmux capture-pane -pe -S' \
        '$(start=$(( $(tmux display-message -t {1} -p "#{pane_height}")' \
        '- $FZF_PREVIEW_LINES ));' \
        '(( start>0 )) && echo $start || echo 0) -t {1}'
    preview_cmd=$*
    selected=$(FZF_DEFAULT_COMMAND=$cmd SHELL=$(command -v bash) fzf -m --preview="$preview_cmd" \
        --preview-window='down:80%' --reverse --info=inline --header-lines=1 \
        --delimiter='\s{2,}' --with-nth=2..-1 --nth=1,2,8,9 \
        --bind="alt-p:toggle-preview" \
        --bind="alt-n:execute(tmux new-window)+cancel" \
        --bind="ctrl-r:reload($cmd)" \
        --bind="ctrl-x:execute-silent(tmux kill-pane -t {1})+reload($cmd)" \
        --bind="ctrl-v:execute(tmux move-pane -h -t ! -s {1})+accept" \
        --bind="ctrl-s:execute(tmux move-pane -v -t ! -s {1})+accept" \
        --bind="ctrl-t:execute-silent(tmux swap-pane -t ! -s {1})+reload($cmd)") ||
        return

    ids_o=($(tmux show -gqv '@mru_pane_ids'))
    ids=()
    for id in "${ids_o[@]}"; do
        while read -r pane_line; do
            pane_info=($pane_line)
            pane_id=${pane_info[0]}
            [[ $id == "$pane_id" ]] && ids+=($id)
        done <<<$selected
    done

    id_n=${#ids[@]}
    id1=${ids[0]}
    if (( id_n == 1 )); then
        tmux switch-client -Z -t$id1
    elif (( id_n > 1 )); then
        tmux break-pane -s$id1
        i=1
        tmux_cmd="tmux "
        while (( i < id_n )); do
            tmux_cmd+="move-pane -t${ids[i-1]} -s${ids[i]} \; select-layout -t$id1 'tiled' \; "
            (( i++ ))
        done

        # my personally configuration
        if (( id_n == 2 )); then
            w_size=($(tmux display-message -p '#{window_width} #{window_height}'))
            w_wid=${w_size[0]}
            w_hei=${w_size[1]}
            if (( 9*w_wid > 16*w_hei )); then
                layout='even-horizontal'
            else
                layout='even-vertical'
            fi
        else
            layout='titled'
        fi

        tmux_cmd+="switch-client -t$id1 \; select-layout -t$id1 $layout \; "
        eval $tmux_cmd
    fi
}

_print_src_line() {
    local ps_info="$2"
    local pane_info=($1)
    local pane_id=${pane_info[0]}
    local session=${pane_info[1]}
    local pane=${pane_info[2]}
    local tty=${pane_info[3]#/dev/}
    local current_path=${pane_info[4]}
    local title=${pane_info[@]:5}
    while read -r ps_line; do
        local p_info=($ps_line)
        if [[ $tty == ${p_info[5]} ]]; then
            local cmd=${p_info[@]:6}
            local cmd_arr=($cmd)
            # vim path of current buffer if it setted the title
            if [[ $cmd =~ ^n?vim && $title != "$hostname" ]]; then
                cmd="${cmd_arr[0]} $title"
            fi
            # get shell current path
            if [[ $cmd =~ ^[^'/ ']*sh ]] && (( ${#cmd_arr[@]} == 1 )); then
                cmd="${cmd_arr[0]} ${current_path/#$HOME/'~'}"
            fi
            if [[ -z $first ]]; then
                first=$(printf "%-6s  %-7s  %5s%s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
                    $pane_id "${session:0:6}%" "${pane:0:-1}" "${pane: -1}" ${p_info[@]::6} "$cmd")
            else
                printf "%-6s  %-7s  %5s%s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
                    $pane_id "$session" "${pane:0:-1}" "${pane: -1}" ${p_info[@]::6} "$cmd"
            fi
            break
        fi
    done <<<$ps_info
}

panes_src() {
    printf "%-6s  %-7s  %6s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
        'PANEID' 'SESSION' 'PANE' 'PID' '%CPU' '%MEM' 'THCNT' 'TIME' 'TTY' 'CMD'
    panes_info=$(tmux list-panes -aF \
        '#D #{=|6|…:session_name} #I.#P#{?window_zoomed_flag,⬢,❄} #{pane_tty} #{pane_current_path} #T' |
        sed -E "/^$TMUX_PANE /d")
    ttys=$(awk '{printf("%s,", $4)}' <<<$panes_info | sed 's/,$//')
    ps_info=$(ps -t$ttys -o stat,pid,pcpu,pmem,thcount,time,tname,cmd |
        awk '$1~/\+/ {$1="";print $0}')
    ids=()
    hostname=$(hostname)
    first=''
    for id in $(tmux show -gqv '@mru_pane_ids'); do
        while read -r pane_line; do
            pane_info=($pane_line)
            pane_id=${pane_info[0]}
            if [[ $id == "$pane_id" ]]; then
                ids+=($id)
                _print_src_line "$pane_line" "$ps_info"
            fi
        done <<<$panes_info
    done

    while read -r pane_line; do
        pane_info=($pane_line)
        pane_id=${pane_info[0]}
        if [[ ${ids[*]} =~ $pane_id ]]; then
            continue
        fi
        _print_src_line "$pane_line" "$ps_info"
    done <<<$panes_info

    if [[ -n $first ]]; then
        printf '%s' "$first"
    fi
    tmux set -g '@mru_pane_ids' "${ids[*]}"
}

select_last_pane() {
    mru_pane_ids=($(tmux show -gqv '@mru_pane_ids'))
    current_pane_id=$(tmux display-message -p '#D')
    if [[ ${mru_pane_ids[0]} != "$current_pane_id" ]]; then
        return
    fi
    pane_ids=($(tmux list-panes -a -F '#D'))
    for last_pane_id in "${mru_pane_ids[@]:1}"; do
        for pane_id in "${pane_ids[@]}" ; do
            if [[ $last_pane_id = "$pane_id" ]]; then
                tmux switch-client -Z -t$last_pane_id
                return
            fi
        done
    done
}

"$@"
