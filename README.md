# runner.nvim
A custom task runner for CMake, enhanced with Telescope for nice UI.

Note that this is more of a custom plugin and I won't really offer a lot of support for this at the moment
Feel free to fork, or send PR for more language 

# Why ?
Why would not I use [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim) or [Overseer](https://github.com/stevearc/overseer.nvim) ?
Overseer offer a complex api to create template, I mean it's just easier to create your own plugin at this point (+ its kinda ugly), and I don't like cmake-tools as
it don't integrate with other running tools, so you need some sketchy command to run cmake-tools, or something else if you work with anything else than CMake

# Supports

Terminal integration with Toggleterm

Currently only support CMake with :
- Project configuration
- Quick target selection
- Target building/running/debugging

TO-DO :
- Python
- OCaml
- C#
- Make (?)
