# fzf-tmux-popup

Using tmux popup window to interact with fzf.

<p align="center">
  <img width="960px" src="https://user-images.githubusercontent.com/17562139/77829950-406e7000-7160-11ea-85aa-0f966feeb237.gif">
</p>

## Requirements

1. bash
2. [fzf](https://github.com/junegunn/fzf)
3. [tmux](https://github.com/tmux/tmux) (**latest version**)

> popup feature hasn't released in a stable tmux version.

## Features

* Compatible with raw fzf
* Support the newest tmux popup feature

## Installation

1. `git clone https://github.com/tmux/tmux && cd tmux`
2. `sh autogen.sh && ./configure && make install`
3. Restart tmux server `tmux kill-server 2>/dev/null; tmux start-server`
4. Install `fzf-tmux-popup` under your `$PATH`.

## Usage

All options of `fzf-tmux-popup` is the same with fzf's except `--width` and `--height` which will tranfer to `tmux popup -w -h`.

### Example

`ls --color=always | fzf-tmux-popup --ansi --width=50% --height=50%`

## Environment

- `TMUX_POPUP_HEIGHT`: height of tmux popup window, default value is `80%`, disabled when `--height` is existed.
- `TMUX_POPUP_WIDTH`: width of tmux popup window, it's similar to `TMUX_POPUP_HEIGHT`.
