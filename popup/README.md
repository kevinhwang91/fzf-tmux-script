# fzfp

Using tmux popup window to interact with fzf.

## Table of contents

* [Table of contents](#table-of-contents)
* [Requirements](#requirements)
* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [Variables](#variables)
  * [Example](#example)

## Requirements

1. bash
2. [fzf](https://github.com/junegunn/fzf)
3. [tmux](https://github.com/tmux/tmux) (**3.2 or later**)

## Features

- Compatible with raw fzf
- Support the newest tmux popup feature

## Installation

1. Make sure tmux's version is 3.2 or later.
2. Install `fzfp` under your `$PATH`.

## Usage

All options of `fzfp` is the same with fzf's except `--width` and `--height` which will transfer to
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

- Setup fzfp in zsh:

```zsh
if [[ -n $TMUX_PANE ]] && (( $+commands[tmux] )) && (( $+commands[fzfp] )); then
    # fallback to normal fzf if current session name is `floating`
    export TMUX_POPUP_NESTED_FB='test $(tmux display -pF "#{==:#S,floating}") == 1'

    export TMUX_POPUP_WIDTH=80%
fi
```
