local Config = require "playdate.config"
local Util = require "playdate.util"

local M = {
	term = { buf = nil, win = nil, chan = nil },
	playdate_simulator_pid = nil
}

function M.open_console()
	if M.term.win ~= nil and M.term.chan ~= nil then
		vim.api.nvim_set_current_win(M.win)
		return
	end

	-- open terminal window
	local buf = vim.api.nvim_create_buf(true, false)
	local win = vim.api.nvim_open_win(buf, false, { split = "below" })
	local chan = vim.api.nvim_open_term(buf, {})

	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = buf,
		callback = function()
			M.term = { buf = nil, win = nil, chan = nil }
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		buffer = buf,
		callback = function()
			M.term = { buf = nil, win = nil, chan = nil }
		end,
	})

	M.term = { buf = buf, win = win, chan = chan }
end

---@param src string?
---@param out string?
function M._build(src, out)
	if src == nil then
		src = Config.build.source_dir
	else
		src = vim.fs.joinpath(vim.uv.cwd() or ".", src)
	end

	if not vim.uv.fs_stat(src) then
		Util.notify("Source dir " .. src .. " not found.", vim.log.levels.WARN)
		return false
	end

	if out == nil then
		out = Config.build.output_dir
	else
		out = vim.fs.joinpath(vim.uv.cwd() or ".", out)
	end

	-- M.open_console()

	local pdc = vim.fs.joinpath(Config.playdate_sdk_path, "/bin/pdc")

	-- local log = vim.schedule_wrap(function(err, data)
	-- 	if err == nil and data ~= nil then
	-- 		vim.api.nvim_chan_send(M.term.chan, data)
	-- 	end
	-- end)

	local obj = vim.system({ pdc, src, out }, { text = true }):wait()

	if obj.code ~= 0 then
		Util.notify("Build failed: " .. obj.stderr, vim.log.levels.ERROR)
		return false
	end

	Util.notify("Build successful 🎉", vim.log.levels.INFO)
	return true
end

---@param out string?
function M._run(out)
	if out == nil then
		out = Config.build.output_dir
	else
		out = vim.fs.joinpath(vim.uv.cwd() or ".", out)
	end

	local playdate_simulator
	if vim.fn.has("mac") == 1 then
		playdate_simulator = vim.fs.joinpath(Config.playdate_sdk_path,
			"/bin/Playdate Simulator.app/Contents/MacOS/Playdate Simulator")
	else
		playdate_simulator = vim.fs.joinpath(Config.playdate_sdk_path, "/bin/PlaydateSimulator")
	end

	if not vim.uv.fs_stat(playdate_simulator) then
		Util.notify("Playdate Simulator executable not found at " .. playdate_simulator, vim.log.levels.ERROR)
		return
	end

	-- If Simulator is already running, close it
	if M.playdate_simulator_pid ~= nil then
		vim.system({ "kill", "-QUIT", tostring(M.playdate_simulator_pid) }):wait()
		M.playdate_simulator_pid = nil
	end

	M.playdate_simulator_pid = vim.system({ playdate_simulator, out }, {
		text = true,
		stdout = false,
		stderr = false,
	}, function(out)
		if out.code ~= 0 then
			Util.notify("Playdate Simulator exited with error code: " .. out.code, vim.log.levels.ERROR)
		end
	end).pid
end

---@param src string?
---@param out string?
function M.build(src, out)
	if not is_ready() then
		return
	end

	M._build(src, out)
end

---@param src string?
---@param out string?
function M.build_and_run(src, out)
	if not is_ready() then
		return
	end

	if M._build(src, out) then
		M._run(out)
	end
end

---@param out string?
function M.run(out)
	if not is_ready() then
		return
	end

	M._run(out)
end

function is_ready()
	if not vim.g.playdate_ready then
		Util.notify("Not ready. Try running :PlaydateSetup first.", vim.log.levels.WARN)
		return false
	end

	return true
end

return M
