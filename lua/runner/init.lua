local Path = require('plenary.path')

-- CMake
local cmake_lang = require("runner.lang.cmake")

-- Currently loaded lang 
-- Lang should implement these functions :
-- valid() : check if the lang should be actually used
-- prompt() : a general prompt which list all possible action (run; build; debug etc...)
-- run() : should run the project without any prompt (i.e: for cmake it run the selected target)
-- build(): should build the project, but not run (for non-compiled project, you can redirect to run, or do nothing)
-- debug() : same as run, but with debug capabilities
-- get_status() : return a string that expose status, to be displayed in Lualine
-- 
--
--
-- All other actions belong in the prompt(), like CMake target selection etc...
-- TODO Lang caching
local lang = nil

local function setup(opts)
	local cmakelists = Path:new(vim.loop.cwd(), "CMakeLists.txt")
	if cmakelists:is_file() then
		lang = cmake_lang
	end

	vim.api.nvim_create_user_command(
		'RunnerPrompt',
		function()
			lang.prompt()
		end,
		{ bang = true }
	)

	vim.api.nvim_create_user_command(
		'RunnerRun',
		function ()
			lang.run()
		end,
		{ bang = true }
	)

	vim.api.nvim_create_user_command(
		'RunnerBuild',
		function ()
			lang.build()
		end,
		{ bang = true }
	)

	vim.api.nvim_create_user_command(
		'RunnerDebug',
		function ()
			lang.debug()
		end,
		{ bang = true }
	)
end

return {
	setup = setup,
	get_status = function() return lang.get_status() end
}

