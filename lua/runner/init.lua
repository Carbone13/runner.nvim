local Path = require('plenary.path')
-- CMake
local cmake_lang = require("runner.lang.cmake")

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
end

return {
	setup = setup,
	get_status = function() return lang.get_status() end
}

