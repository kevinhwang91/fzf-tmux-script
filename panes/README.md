# fzf-tmux-pane

Using fzf to select the panes of tmux, like selecting buffer by using fzf in vim.

It's a alternative for `choose-tree` which is a native command of tmux.

## Requirements

1. bash
2. [fzf](https://github.com/junegunn/fzf) (at least 0.19.0 version)
3. [tmux](https://github.com/tmux/tmux) (at least 3.0 version)

## Features

- Select a single pane quickly
- Show resources of every pane's process
- Combine multiple panes into a window
- Order by Most Recently Used (MRU) panes
- Join the current pane and the target pane
- Swap the current pane and the target pane
- Kill the target pane
- Display the path of the current buffer of vim dynamically in fzf field of cmd
- Display the current path of shell in fzf field of cmd
- Select last pane across windows and sessions

## Installation

1. Install `fzf-panes.tmux` under the path where you like.
2. Put these code inside your `.tmux.conf`.

```tmux

set -s focus-events on

# replace ~/.local/bin/fzf-panes.tmux to your path of fzf-panes.tmux
if-shell '[ -f ~/.local/bin/fzf-panes.tmux ]' {
#   if you want to exclude specified session, please set @fzf_panes_ex_session_pat
#   for example, value equal to '^(floating)$', will exclude panes in session named 'floating'
#    set -g '@fzf_panes_ex_session_pat' '^(floating)$'
    set-hook -g pane-focus-in[10] \
    "run -b 'bash ~/.local/bin/fzf-panes.tmux update_mru_pane_ids'"
    bind w run -b 'bash ~/.local/bin/fzf-panes.tmux new_window'
    bind \; run -b 'bash ~/.local/bin/fzf-panes.tmux select_last_pane'
} {
    set-hook -ug pane-focus-in[10]
    bind w choose-tree -Z
}
```

<!-- markdownlint-disable MD029 -->

3. If you want to display the path of the current buffer of vim dynamically in fzf field of cmd, you
should set the title configuration of vim like this:
<!-- markdownlint-enable MD013 -->

```vim
set title
set titlestring=%(%m%)%(%{expand(\"%:~\")}%)
```

> The `ps` command only record startup command of vim, so I use title of vim to replace the argument
> of vim's cmd in `ps`.

## Usage

1. Using `prefix+w` to call the script in new window of tmux.
2. Using `prefix+;` to select last pane across windows and sessions

### Keymap for fzf

- `alt-p`: toggle the preview for detail of the pane
- `alt-n`: craete new window
- `ctrl-r`: reload the source of fzf
- `ctrl-x`: kill the target pane
- `ctrl-v`: join the current pane and the the target pane vertically
- `ctrl-s`: join the current pane and the the target pane horizontally
- `ctrl-t`: swap the current pane and the target pane

## Limitation

- [Can't capture pane with zoomed status](https://github.com/tmux/tmux/issues/2092)
