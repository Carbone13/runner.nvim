local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local themes = require("telescope.themes")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Terminal = require("toggleterm.terminal").Terminal
local cache = require("runner.cache")

--------
-- UTILS
--------

local function get_main_directory()
	return require("plenary.path"):new(vim.fn.getcwd())
end

local function get_build_directory(type)
	if type == "debug" then
		return get_main_directory() / ".build" / "debug"
	else
		return get_main_directory() / ".build" / "release"
	end
end

local function get_reply_dir(type)
	return get_build_directory(type) / ".cmake" / "api" / "v1" / "reply"
end

local function get_all_targets(type)
	local scandir = require("plenary.scandir")
	local Path = require("plenary.path")
	local found_files = scandir.scan_dir(get_reply_dir(type).filename, { search_pattern = "codemodel*" })

	local codemodel = Path:new(found_files[1])
	local codemodel_json = vim.json.decode(codemodel:read())
	local configurations = codemodel_json["configurations"]
	local selectedConfiguration = configurations[1]

	if #configurations > 1 then
		for _, conf in ipairs(configurations) do
			if type == conf["name"] then
				selectedConfiguration = conf
				break
			end
		end
	end

	return selectedConfiguration["targets"]
end

function get_target_info(codemodel_target, type)
	return vim.json.decode((get_reply_dir(type) / codemodel_target["jsonFile"]):read())
end

local function is_project_configured(type)
	return get_build_directory(type):exists()
end

local function cmake_configure(type, silent, callback)
	local query_dir = get_build_directory(type) / ".cmake" / "api" / "v1" / "query"
	query_dir:mkdir({ parents = true })
	local codemodel_file = query_dir / "codemodel-v2"
	if not codemodel_file:is_file() then
		codemodel_file:touch()
	end

	local arg = "-DCMAKE_BUILD_TYPE=Debug"
	if type == "release" then
		arg = "-DCMAKE_BUILD_TYPE=Release"
	end

	os.execute("rm ./compile_commands.json")

	local term = Terminal:new({
		cmd = "cmake -S . -B .build/"
			.. type
			.. " -GNinja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
			.. arg
			.. " ; ln -s "
			.. ".build/"
			.. type
			.. "/compile_commands.json ./compile_commands.json",
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = silent,
		direction = "horizontal",
		on_open = function(term)
			vim.cmd("startinsert!")
			vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
		end,
		on_exit = function(t, j, e, nb, name)
			if callback then
				callback()
			end
			vim.cmd("LspRestart")
		end,
	})
	term:toggle()
end

-------
-- IMPL
-------

local M = {}

M.cache = true
M.type = "debug"
M.target = "all"
M.target_executable = false
M.target_executable_path = ""

function M.cmake_select_target(exe_only, callback)
	if not is_project_configured(M.type) then
		cmake_configure(M.type, true, M.cmake_select_target)
		return
	end

	local codemodel_targets = get_all_targets(M.type)

	local targets = {}
	local targets_info = {}
	local targets_path = {}
	for _, target in ipairs(codemodel_targets) do
		local target_info = get_target_info(target, M.type)

		if not exe_only or target_info["type"] == "EXECUTABLE" then
			table.insert(targets, target_info["name"])
			targets_info[target_info["name"]] = target_info
		end
	end

	pickers
		.new(themes.get_dropdown({}), {
			prompt_title = "CMake Select Target",
			finder = finders.new_table({ results = targets }),
			sorter = conf.generic_sorter(themes.get_dropdown({})),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					M.target = selection[1]
					if targets_info[selection[1]]["type"] == "EXECUTABLE" then
						M.target_executable = true
						M.target_executable_path = targets_info[selection[1]]["paths"]["build"]
							.. "/"
							.. targets_info[selection[1]]["nameOnDisk"]
					end

					M.serialize()

					if callback then
						callback()
					end
				end)
				return true
			end,
		})
		:find()
end

function M.cmake_select_type()
	pickers
		.new(themes.get_dropdown({}), {
			prompt_title = "CMake Configure",
			finder = finders.new_table({ results = { "Debug", "Release" } }),
			sorter = conf.generic_sorter(themes.get_dropdown({})),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection["index"] == 1 then
						M.type = "debug"
					else
						M.type = "release"
					end

					cmake_configure(M.type, false, nil)
					M.serialize()
				end)
				return true
			end,
		})
		:find()
end

function M.valid()
	local cmakelists = require("plenary.path"):new(vim.loop.cwd(), "CMakeLists.txt")
	return cmakelists:is_file()
end

function M.prompt()
	pickers
		.new(themes.get_dropdown({}), {
			prompt_title = "CMake",
			finder = finders.new_table({
				results = { "Run", "Debug", "Build", "Type", "Target" },
			}),
			sorter = conf.generic_sorter(themes.get_dropdown({})),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()

					if selection["index"] == 5 then -- Target
						M.cmake_select_target(false)
					elseif selection["index"] == 4 then -- Type
						M.cmake_select_type()
					elseif selection["index"] == 3 then -- Build
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
	if not is_project_configured(M.type) then
		cmake_configure(M.type, true, M.run)
		return
	end

	if not M.target_executable then
		M.cmake_select_target(true, M.run)
		return
	end

	local term = Terminal:new({
		cmd = "cmake --build "
			.. get_build_directory()
			.. " --target "
			.. M.target
			.. " ; "
			.. get_build_directory()
			.. "/"
			.. M.target_executable_path,
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end

function M.build()
	if not is_project_configured(M.type) then
		cmake_configure(M.type, true, M.build)
		return
	end

	local term = Terminal:new({
		cmd = "cmake --build " .. get_build_directory(M.type) .. " --target " .. M.target,
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end

function M.debug()
	if not is_project_configured("debug") then
		M.type = "debug"
		cmake_configure(M.type, true, M.debug)
		return
	end

	if not M.target_executable then
		M.cmake_select_target(true, M.debug)
		return
	end

	local term = Terminal:new({
		cmd = "cmake --build " .. get_build_directory(M.type) .. " --target " .. M.target,
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = true,
		direction = "horizontal",
		on_exit = function()
			require("dap").run({
				type = "codelldb",
				request = "launch",
				program = get_build_directory(M.type) .. "/" .. M.target_executable_path,
				args = {},
				stopOnEntry = false,
				runInTerminal = false,
				console = "integratedTerminal",
			})
		end,
	})
	term:toggle()
end

function M.get_status()
	if M.target_executable then
		return M.target .. " [" .. M.type .. "] " .. ""
	else
		return M.target .. " [" .. M.type .. "] " .. ""
	end
end

function M.serialize()
	cache.save({
		type = M.type,
		target = M.target,
		target_executable = M.target_executable,
		target_executable_path = M.target_executable_path,
	})
end

function M.deserialize()
	local t = cache.load()
	if t == -1 then
		return
	end

	M.type = t["type"]
	M.target = t["target"]
	M.target_executable = t["target_executable"]
	M.target_executable_path = t["target_executable_path"]
end

return M
