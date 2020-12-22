#!/usr/bin/env bash

new_window() {
    [[ -x $(command -v fzf 2>/dev/null) ]] || return
    local win_id
    win_id=$(tmux show -gqv '@fzf_pane_id')
    [[ -n $win_id ]] && tmux kill-pane -t $win_id >/dev/null 2>&1
    tmux new-window "bash $0 do_action" >/dev/null 2>&1
}

# invoked by pane-focus-in event
update_mru_pane_ids() {
    local o_data n_data cur_id
    o_data=($(tmux show -gqv '@mru_pane_ids'))
    cur_id=$(tmux display-message -p '#D')
    n_data=($cur_id)
    for data in "${o_data[@]}"; do
        [[ $cur_id != "$data" ]] && n_data+=("$data")
    done

    tmux set -g '@mru_pane_ids' "${n_data[*]}"
}

do_action() {
    local cur_id selected
    trap 'tmux set -gu @fzf_pane_id' EXIT SIGINT SIGTERM
    cur_id=$(tmux display-message -p '#D')
    tmux set -g @fzf_pane_id $cur_id

    local cmd="bash $0 panes_src $cur_id"
    set -- 'tmux capture-pane -pe -S' \
        '$(start=$(( $(tmux display-message -t {1} -p "#{pane_height}")' \
        '- $FZF_PREVIEW_LINES ));' \
        '(( start>0 )) && echo $start || echo 0) -t {1}'
    local preview_cmd=$*
    selected=$(FZF_DEFAULT_COMMAND=$cmd SHELL=$(command -v bash) fzf -m --preview="$preview_cmd" \
        --preview-window='down:80%' --height=100% --reverse --info=inline --header-lines=1 \
        --delimiter='\s{2,}' --with-nth=2..-1 --nth=1,2,8,9 --cycle --exact \
        --bind="alt-p:toggle-preview" \
        --bind="alt-n:execute(tmux new-window)+cancel" \
        --bind="ctrl-r:reload($cmd)" \
        --bind="ctrl-x:execute-silent(tmux kill-pane -t {1})+reload($cmd)" \
        --bind="ctrl-v:execute(tmux move-pane -h -t ! -s {1})+accept" \
        --bind="ctrl-s:execute(tmux move-pane -v -t ! -s {1})+accept" \
        --bind="ctrl-t:execute-silent(tmux swap-pane -t ! -s {1})+reload($cmd)") ||
        return

    local m_id m_ids ids pane_info pane_id
    m_ids=($(tmux show -gqv '@mru_pane_ids'))
    ids=()
    for m_id in "${m_ids[@]}"; do
        while read -r pane_line; do
            pane_info=($pane_line)
            pane_id=${pane_info[0]}
            [[ $m_id == "$pane_id" ]] && ids+=($m_id)
        done <<<$selected
    done

    while read -r pane_line; do
        pane_info=($pane_line)
        pane_id=${pane_info[0]}
        if _match_in_args $pane_id "${ids[@]}"; then
            continue
        fi
        ids+=($pane_id)
    done <<<$selected

    local id_cnt=${#ids[@]}
    local id0=${ids[0]}
    if (( id_cnt == 1 )); then
        tmux switch-client -Z -t$id0
    elif (( id_cnt > 1 )); then
        tmux break-pane -s$id0
        local i=1
        local tmux_cmd='tmux '
        while (( i < id_cnt )); do
            tmux_cmd+="move-pane -t${ids[i-1]} -s${ids[i]} \; select-layout -t$id0 'tiled' \; "
            (( i++ ))
        done

        # my personally configuration
        if (( id_cnt == 2 )); then
            local w_size=($(tmux display-message -p '#{window_width} #{window_height}'))
            local w_wid=${w_size[0]}
            local w_hei=${w_size[1]}
            local layout
            if (( 9*w_wid > 16*w_hei )); then
                layout='even-horizontal'
            else
                layout='even-vertical'
            fi
        else
            layout='titled'
        fi

        tmux_cmd+="switch-client -t$id0 \; select-layout -t$id0 $layout \; "
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
    local cur_path=${pane_info[4]}
    local title=${pane_info[@]:5}
    local ps_line
    while read -r ps_line; do
        local pane_info=($ps_line)
        if [[ $tty == ${pane_info[5]} ]]; then
            local cmd=${pane_info[@]:6}
            local cmd_arr=($cmd)
            # vim path of current buffer if it setted the title
            if [[ $cmd =~ ^n?vim && $title != $(hostname) ]]; then
                cmd="${cmd_arr[0]} $title"
            fi
            # get shell current path
            if [[ $cmd =~ ^[^'/ ']*sh ]] && (( ${#cmd_arr[@]} == 1 )); then
                cmd="${cmd_arr[0]} ${cur_path/#$HOME/'~'}"
            fi
            if [[ -z $first ]]; then
                first=$(printf "%-6s  %-9s  %5s%s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
                    $pane_id "${session:0:8}%" "${pane:0:-1}" "${pane: -1}" ${pane_info[@]::6} "$cmd")
            else
                if (( ${#session} > 8 )); then
                    session="${session:0:8}…"
                fi
                printf "%-6s  %-9s  %5s%s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
                    $pane_id "$session" "${pane:0:-1}" "${pane: -1}" ${pane_info[@]::6} "$cmd"
            fi
            break
        fi
    done <<<$ps_info
}

panes_src() {
    local cur_id="$1"
    printf "%-6s  %-9s  %6s  %8s  %4s  %4s  %5s  %-8s  %-7s  %s\n" \
        'PANEID' 'SESSION' 'PANE' 'PID' '%CPU' '%MEM' 'THCNT' 'TIME' 'TTY' 'CMD'
    panes_info=$(tmux list-panes -aF \
        '#D #{s| |_|:session_name} #I.#P#{?window_zoomed_flag,⬢,❄} #{pane_tty} #{pane_current_path} #T' |
        sed -E "/^$cur_id /d")
    ttys=$(awk '{printf("%s,", $4)}' <<<$panes_info | sed 's/,$//')
    ps_info=$(ps -t$ttys -o stat,pid,pcpu,pmem,thcount,time,tname,cmd |
        awk '$1~/\+/ {$1="";print $0}')
    ids=()
    hostname=$(hostname)
    first=''
    local ex_session=$(tmux show -gqv '@fzf_panes_ex_session_pat')
    for m_id in $(tmux show -gqv '@mru_pane_ids'); do
        while read -r pane_line; do
            pane_info=($pane_line)
            pane_id=${pane_info[0]}
            session=${pane_info[1]}
            if [[ $m_id == "$pane_id" ]]; then
                ids+=($m_id)
                if [[ -n $ex_session && $session =~ $ex_session ]]; then
                    continue
                fi
                _print_src_line "$pane_line" "$ps_info"
            fi
        done <<<$panes_info
    done

    while read -r pane_line; do
        pane_info=($pane_line)
        pane_id=${pane_info[0]}
        session=${pane_info[1]}
        if _match_in_args $pane_id "${ids[@]}"; then
            continue
        fi
        if [[ -n $ex_session && $session =~ $ex_session ]]; then
            continue
        fi
        _print_src_line "$pane_line" "$ps_info"
    done <<<$panes_info

    if [[ -n $first ]]; then
        printf '%s' "$first"
    fi
    tmux set -g '@mru_pane_ids' "${ids[*]}"
}

_match_in_args() {
    local match="$1"
    shift
    for element in "$@"; do
        if [[ $element == "$match" ]]; then
            return 0
        fi
    done
    return 1
}

select_last_pane() {
    local m_ids=($(tmux show -gqv '@mru_pane_ids'))
    local ids_str last_id cur_id
    ids_str=$(tmux list-panes -a -F '#D')
    cur_id=$(tmux display-message -p '#D')
    for last_id in "${m_ids[@]}"; do
        if [[ $cur_id == "$last_id" ]]; then
            continue
        fi
        if _match_in_args $last_id $ids_str; then
            tmux switch-client -Z -t$last_id
            return
        fi
    done
}

"$@"
