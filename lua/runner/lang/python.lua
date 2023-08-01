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
	return vim.bo.filetype == "python"
end

function M.prompt()
	pickers
		.new(themes.get_dropdown({}), {
			prompt_title = "Python",
			finder = finders.new_table({
				results = { "Run", "Debug" },
			}),
			sorter = conf.generic_sorter(themes.get_dropdown({})),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection["index"] == 2 then -- Debug
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
		cmd = "python3 " .. vim.api.nvim_buf_get_name(0),
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end

function M.build()
	M.run()
end

function M.debug()
	require("dap").run({
		type = "python",
		request = "launch",
		program = vim.api.nvim_buf_get_name(0),
		args = {},
		stopOnEntry = false,
		runInTerminal = false,
		console = "integratedTerminal",
	})
end

function M.get_status()
	return "PYTHON"
end

return M
