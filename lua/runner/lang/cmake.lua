-- Treesitter
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local themes = require("telescope.themes")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Terminal  = require('toggleterm.terminal').Terminal
local default_options = themes.get_dropdown({})

local M = {}
M.type = "debug"
M.target = "all"
M.target_executable = false
M.target_executable_path = ""

local function get_main_directory ()
	return require('plenary.path'):new(vim.fn.getcwd())
end

local function get_build_directory ()
	if M.type == "debug" then
		return get_main_directory() / ".build" / "debug"
	else
		return get_main_directory() / ".build" / "release"
	end
end

local function get_reply_dir ()
	return get_build_directory() / '.cmake' / 'api' / 'v1' / 'reply'
end

local function is_cmake_configured ()
    local scandir = require('plenary.scandir')
    local Path = require('plenary.path')
    local found_files = scandir.scan_dir(get_reply_dir().filename, { search_pattern = 'codemodel*' })

	return #found_files > 0
end

local function get_all_targets ()
    local scandir = require('plenary.scandir')
    local Path = require('plenary.path')
    local found_files = scandir.scan_dir(get_reply_dir().filename, { search_pattern = 'codemodel*' })

    local codemodel = Path:new(found_files[1])
    local codemodel_json = vim.json.decode(codemodel:read())
    local configurations = codemodel_json['configurations']
    local selectedConfiguration = configurations[1]

    if #configurations > 1 then
        for _, conf in ipairs(configurations) do
            if M.type == conf['name'] then
                selectedConfiguration = conf
                break
            end
        end
    end

    return selectedConfiguration['targets']
end

function get_target_info(codemodel_target)
    return vim.json.decode((get_reply_dir() / codemodel_target['jsonFile']):read())
end

function M.cmake_configure (auto_close, callback)
	-- TODO arg
	local query_dir = get_build_directory() / '.cmake' / 'api' / 'v1' / 'query'
	query_dir:mkdir({ parents = true })
	local codemodel_file = query_dir / 'codemodel-v2'
	if not codemodel_file:is_file() then
		codemodel_file:touch()
	end

	local term = Terminal:new({
		cmd = "cmake -S . -B .build/" .. M.type .. " -GNinja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
		dir = vim.fn.getcwd(),
		hidden = false,
		auto_scroll = true,
		close_on_exit = auto_close,
		direction = "horizontal",
		on_open = function(term)
			vim.cmd("startinsert!")
			vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<Esc>", "<cmd>close<CR>", {noremap = true, silent = true})
		end,
		on_exit = function(t, j , e, nb, name)
			print("cmake configured !")
			if callback then
				callback()
			end
		end
		})
	term:toggle()
end
-- Generate the cmake project of the selected type
function M.cmake_configure_prompt (opts)
	opts = opts or default_options
	local arg = "none"

	pickers.new(opts, 
	{
		prompt_title = "CMake Configure",
		finder = finders.new_table {
			results = { "Debug", "Release" }
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection["index"] == 1 then
					M.type = "debug"
					arg = "-DCMAKE_BUILD_TYPE=Debug"
				else
					M.type = "release"
					arg = "-DCMAKE_BUILD_TYPE=Release"
				end

				M.cmake_configure(false, nil)
			end)
			return true
		end
	}):find()
end

-- Choose a target to build/run 
function M.cmake_choose_target (opts, exe_only)
	opts = opts or default_options
	if not get_build_directory():exists() then
		M.cmake_configure(true, M.cmake_choose_target)
		return nil
	end

	local codemodel_targets = get_all_targets()

	local targets = {}
	local targets_info = {}
	local targets_path = {}
	for _, target in ipairs(codemodel_targets) do 
		local target_info = get_target_info(target)

		if not exe_only or target_info["type"] == "EXECUTABLE" then
			table.insert(targets, target_info["name"])
			targets_info[target_info["name"]] = target_info
		end
	end

	pickers.new(opts, 
	{
		prompt_title = "CMake Select Target",
		finder = finders.new_table {
			results = targets
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				M.target = selection[1]
				if targets_info[selection[1]]["type"] == "EXECUTABLE" then
					M.target_executable = true
					M.target_executable_path = targets_info[selection[1]]["paths"]["build"] .. "/" .. targets_info[selection[1]]["nameOnDisk"]
				end
			end)
			return true
		end
	}):find()
end

function M.cmake_build_prompt (opts)
	opts = opts or default_options
	if not get_build_directory():exists() then
		M.cmake_configure(true, M.cmake_build_prompt)
		return nil
	end
	
	local term = Terminal:new({
		cmd = "cmake --build " .. get_build_directory() .. " --target " .. M.target,
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal"
	})
	term:toggle()
end


function M.cmake_run_prompt (opts)
	opts = opts or default_options
	if not get_build_directory():exists() then
		M.cmake_configure(true, M.cmake_run_prompt)
		return nil
	end
	
	-- check if selected target is actually executable
	if not M.target_executable then
		 M.cmake_choose_target(opts, true)
	end
	
	local term = Terminal:new({
		cmd = "cmake --build " .. get_build_directory() .. " --target " .. M.target .. " ; " .. get_build_directory() .. "/" .. M.target_executable_path,
		dir = vim.fn.getcwd(),
		hidden = true,
		auto_scroll = true,
		close_on_exit = false,
		direction = "horizontal",
	})
	term:toggle()
end


function M.prompt (opts)
	opts = opts or default_options
	pickers.new(opts, 
	{
		prompt_title = "CMake",
		finder = finders.new_table {
			results = { "Run", "Debug", "Build", "Type", "Target", }
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			    actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()

					if selection["index"] == 5 then
						M.cmake_choose_target(opts)
					elseif selection["index"] == 4 then
						M.cmake_configure_prompt(opts)
					elseif selection["index"] == 3 then
						M.cmake_build_prompt(opts)
					elseif selection["index"] == 2 then
						--
					elseif selection["index"] == 1 then
						M.cmake_run_prompt(opts)
					end
				end)
			return true
		end
	}):find()
end

function M.get_status ()
	if M.target_executable then
		return M.target .. " [" .. M.type .. "] " .. ""
	else
		return M.target .. " [" .. M.type .. "] " .. ""
	end
end

return M
