# fzfp

Using tmux popup window to interact with fzf.

## Requirements

1. bash
2. [fzf](https://github.com/junegunn/fzf)
3. [tmux](https://github.com/tmux/tmux) (**latest version**)

> popup feature hasn't released in a stable tmux version.

## Features

- Compatible with raw fzf
- Support the newest tmux popup feature

## Installation

1. `git clone https://github.com/tmux/tmux && cd tmux`
2. `sh autogen.sh && ./configure && make install`
3. Restart tmux server `tmux kill-server 2>/dev/null; tmux start-server`
4. Install `fzfp` under your `$PATH`.

## Usage

All options of `fzfp` is the same with fzf's except `--width` and `--height` which will tranfer to
`tmux popup -w -h`.

## Variables

- `TMUX_POPUP_HEIGHT`: height of tmux popup window, default value is `80%`,
  disabled when `--height`
  is existed.
- `TMUX_POPUP_WIDTH`: width of tmux popup window, it's similar to `TMUX_POPUP_HEIGHT`.
- `TMUX_POPUP_NESTED_FB`: check whether current pane is nested in popup,
  fallback to fzf if the return code of `eval "$TMUX_POPUP_NESTED_FB"` is true.

### Example

- Use `ls` as the source for fzfp:

`ls --color=always | fzfp --ansi --width=50% --height=50%`

- Override fzf to fzfp in zsh:

```zsh
if [[ -n $TMUX_PANE ]] && (( $+commands[tmux] )) && (( $+commands[fzfp] )); then
    # fallback to normal fzf if current session name is `floating`
    export TMUX_POPUP_NESTED_FB='test $(tmux display -pF "#{==:#S,floating}") == 1'

    export TMUX_POPUP_WIDTH=80%
    commands[fzf]=$commands[fzfp]
fi
```
