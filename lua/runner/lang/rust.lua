local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local themes = require("telescope.themes")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Terminal = require("toggleterm.terminal").Terminal

local M = {}
M.cache = false

function M.valid()
	local cargo_toml = require("plenary.path"):new(vim.loop.cwd(), "Cargo.toml")
	return cargo_toml:is_file()
end

function M.prompt()
	pickers
		.new(themes.get_dropdown({}), {
			prompt_title = "Cargo",
			finder = finders.new_table({
				results = { "Run", "Debug", "Build", "Check", "Test", "Publish", "Update"},
			}),
			sorter = conf.generic_sorter(themes.get_dropdown({})),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection["index"] == 3 then -- Build
						M.build()
					elseif selection["index"] == 2 then -- Debug
						M.debug()
					elseif selection["index"] == 1 then -- Run
						M.run()
					end
				end)
				return true
			end,
		})
		:find()
end

function M.run()
	local term = Terminal:new({
		cmd = "cargo run",
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end

function M.build()
	local term = Terminal:new({
		cmd = "cargo build",
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end

function M.debug()
end

function M.get_status()
	return ""
end

return M
