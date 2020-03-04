# fzf-tmux-pane

Using fzf to select the panes of tmux, like selecting buffer by using fzf in vim.

It's a alternative for `choose-tree` which is a native command of tmux.

<p align="center">
  <img width="1080px" src="https://user-images.githubusercontent.com/17562139/75963942-568e6500-5f01-11ea-8b9c-b14ca9f50dc1.gif">
</p>

## Requirements

1. [fzf](https://github.com/junegunn/fzf) (at least 0.19.0 version)
2. [tmux](https://github.com/tmux/tmux)

## Features

* Select a single pane quickly
* Show resources of every pane's process
* Combine multiple panes into a window
* Order by Most Recently Used (MRU) panes
* Join the current pane and the target pane
* Swap the current pane and the target pane
* Kill the target pane
* Display the path of the current buffer of vim dynamically in fzf field of cmd

## Installation

1. Install `fzf_panes.tmux` under the path where you like.
2. Put these code inside your `.tmux.conf`.

```tmux

set -s focus-events on

# replace ~/.local/bin/fzf_panes.tmux to your path of fzf_panes.tmux
if-shell '[[ -f ~/.local/bin/fzf_panes.tmux ]]' {
    set-hook -g pane-focus-in[10] \
    "run -b 'sh ~/.local/bin/fzf_panes.tmux update_mru_pane_ids'"
    bind w run -b 'sh ~/.local/bin/fzf_panes.tmux new_window'
} {
    set-hook -ug pane-focus-in[10]
    bind w choose-tree -Z
}
```

3. If you want to display the path of the current buffer of vim dynamically in fzf field of cmd, you should set the title configuration of vim like this:
```vim
set title
set titlestring=%(%m%)%(%{expand(\"%:~:.:h\")}%)\/%t
```

> The `ps` command only record startup command of vim, so I use title of vim to replace the argument of vim's cmd in `ps`.

## Usage

Using `prefix+w` to call the script in new window of tmux.

### Keymap for fzf

- `alt-p`: toggle the preview for detail of the pane
- `ctrl-r`: reload the source of fzf
- `ctrl-x`: kill the target pane
- `ctrl-v`: Join the current pane and the the target pane vertically
- `ctrl-s`: Join the current pane and the the target pane horizontally
- `ctrl-t`: Swap the current pane and the target pane

## Customization

Fucking the source code which only almost one hundred lines, and write down your loved script.

You will fall in love with the expandability of `fzf` and `tmux`.

> The expandability makes `shell script` bloated that is not cost-effective.

## Limitation

- [Can't capture pane with zoomed status](https://github.com/tmux/tmux/issues/2092)

## License

The project is licensed under a BSD-3-clause license. See [LICENSE](./LICENSE) file for details.
