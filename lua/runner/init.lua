local cache = require("runner.cache")

-- Lang should implement these functions :
-- valid() : check if the lang should be actually used
-- prompt() : a general prompt which list all possible action (run; build; debug etc...)
-- run() : should run the project without any prompt (i.e: for cmake it run the selected target)
-- build(): should build the project, but not run (for non-compiled project, you can redirect to run, or do nothing)
-- debug() : same as run, but with debug capabilities
-- get_status() : return a string that expose status, to be displayed in Lualine
-- cache:bool : do we use cache
-- serialize() -> Table : serialize current settings
-- deserialize() : deserialize from previous session
-- All other actions belong in the prompt(), like CMake target selection etc...
local langs = {
	require("runner.lang.cmake"),
	require("runner.lang.python"),
}
local lang = nil

local function reload()
	-- Parse lang
	for _, potential_lang in pairs(langs) do
		if potential_lang.valid() then
			lang = potential_lang
		end
	end

	if not lang then
		return
	end

	if lang.cache then
		lang.deserialize()
	end
end

-- opts look like :
-- {
-- 	  langs = { }, (Actually TO-DO!)
-- }
local function setup(opts)
	-- init cache
	cache.init_cache()
	-- Parse lang
	reload()

	vim.api.nvim_create_user_command("RunnerPrompt", function()
		if lang then
			lang.prompt()
		else
			print("Runner: Language is not supported !")
		end
	end, { bang = true })

	vim.api.nvim_create_user_command("RunnerRun", function()
		if lang then
			lang.run()
		else
			print("Runner: Language is not supported !")
		end
	end, { bang = true })

	vim.api.nvim_create_user_command("RunnerBuild", function()
		if lang then
			lang.build()
		else
			print("Runner: Language is not supported !")
		end
	end, { bang = true })

	vim.api.nvim_create_user_command("RunnerDebug", function()
		if lang then
			lang.debug()
		else
			print("Runner: Language is not supported !")
		end
	end, { bang = true })

	vim.api.nvim_create_user_command("RunnerReload", function()
		reload()
	end, { bang = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		callback = function()
			reload()
		end,
	})
end

return {
	setup = setup,
	reload = reload(),
	get_status = function()
		return lang.get_status()
	end,
}
