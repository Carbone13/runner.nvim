local Path = require("plenary.path")

local session = {
	dir = {
		unix = vim.fn.expand("~") .. "/.cache/nvim/runner/",
		mac = vim.fn.expand("~") .. "/.cache/nvim/runner/",
		win = vim.fn.expand("~") .. "/AppData/Local/nvim/runner/",
	},
}
local M = {}

local function get_cache_path()
	if vim.fn.has("linux") == 1 then
		return session.dir.unix
	elseif vim.fn.has("mac") == 1 then
		return session.dir.mac
	elseif vim.fn.has("wsl") == 1 then
		return session.dir.unix
	elseif vim.fn.has("win32") == 1 then
		return session.dir.win
	end
end

local function get_current_path()
	local current_path = vim.loop.cwd()
	local clean_path = current_path:gsub("/", "")
	clean_path = clean_path:gsub("\\", "")
	clean_path = clean_path:gsub(":", "")
	return get_cache_path() .. clean_path .. ".lua"
end

function M.init_cache()
	local cache_path = get_cache_path()
	local plenary_path = Path:new(cache_path)
	if not plenary_path:exists() then
		plenary_path:mkdir({ parents = true, exists_ok = true })
	end
end

local function init_session()
	init_cache()

	local path = get_current_path()
	if not utils.file_exists(path) then
		local file = io.open(path, "w")
		if file then
			file:close()
		end
	end
end

function M.load(table)
	local path = get_current_path()
	local plenary_path = Path:new(path)
	if plenary_path:exists() then
		local config = dofile(path)
		return config
	end

	return -1
end

function M.save(table)
	local path = get_current_path()
	local file = io.open(path, "w")

	if file then
		file:write(tostring("return " .. vim.inspect(table)))
		file:close()
	end
end

return M
