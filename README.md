# runner.nvim
A custom task runner, enhanced with Telescope for nice UI.

Note that this is more of a custom plugin for myself and I won't really offer a lot of support for this at the moment
Feel free to fork, or send PR for more language.

Currently only support CMake, but I will expand it quickly.

## Why ?
Why would not I use [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim) or [Overseer](https://github.com/stevearc/overseer.nvim) ?
Overseer offer a complex api to create template, I mean it's just easier to create your own plugin at this point (+ its kinda ugly), and I don't like cmake-tools as
it don't integrate with other running tools, so you need some sketchy command to run cmake-tools, or something else if you work with anything else than CMake

## Installation & Dependencies
This project require [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim#getting-started) for the UI prompts, and [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for utility (which is also a Telescope dependencie anyway).
You'll also need [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), it's the plugin I use for managing my terminal,
so naturally runner.nvim plug nicely into it.

Using [lazy.nvim](https://github.com/folke/lazy.nvim) :
```lua
{
  'Carbone13/runner.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim'
    'akinsho/toggleterm.nvim'
  }
}
```

## Features

Terminal integration with Toggleterm

CMake support :
- Project configuration
- Quick target selection
- Target building/running/debugging

TO-DO :
- Python
- OCaml
- C#
- Make (?)
