--- @class playdate.Config.mod: playdate.Config
local M = {}

--- @class playdate.Config
--- @field playdate_sdk_path string
--- @field playdate_luacats_path string?
local defaults = {
	playdate_sdk_path = vim.env.PLAYDATE_SDK_PATH,
	playdate_luacats_path = vim.env.PLAYDATE_LUACATS_PATH,
	--- @class playdate.Config.build
	build = {
		source_dir = "src",
		output_dir = "build",
	},
	server_settings = {
		Lua = {
			completion = {
				requireSeparator = "/",
			},
			diagnostics = {
				disable = { "lowercase-global" },
				severity = {
					["duplicate-set-field"] = "Hint",
				},
			},
			runtime = {
				builtin = {
					io = "disable",
					os = "disable",
					package = "disable",
				},
				nonstandardSymbol = {
					"+=",
					"-=",
					"*=",
					"/=",
					"//=",
					"%=",
					"<<=",
					">>=",
					"&=",
					"|=",
					"^=",
				},
				special = { import = "require" },
			},
		},
	},
}

--- @type playdate.Config
local options

--- @param opts? playdate.Config
function M.setup(opts)
	options = vim.tbl_deep_extend("force", {}, defaults, opts or {})

	if options.playdate_sdk_path == nil then
		return
	end

	options.playdate_sdk_path = vim.fs.normalize(options.playdate_sdk_path)
	options.playdate_luacats_path = options.playdate_luacats_path and vim.fs.normalize(options.playdate_luacats_path)

	if not vim.uv.fs_stat(options.playdate_sdk_path) then
		local msg =
			"PLAYDATE_SDK_PATH is not valid. Set it or set the playdate_sdk_path option in the plugin configuration."
		vim.notify_once(msg, vim.log.levels.ERROR, { title = "playdate.nvim" })
		error(msg)
		return
	end

	if options.playdate_luacats_path ~= nil and not vim.uv.fs_stat(options.playdate_luacats_path) then
		local msg =
			"PLAYDATE_LUACATS_PATH is not valid. Set it or set the playdate_luacats_path option in the plugin configuration."
		vim.notify_once(msg, vim.log.levels.ERROR, { title = "playdate.nvim" })
		error(msg)
		return
	end

	options.build = {
		source_dir = vim.fs.normalize(vim.fs.joinpath(vim.uv.cwd() or ".", options.build.source_dir or ".")),
		output_dir = vim.fs.normalize(vim.fs.joinpath(vim.uv.cwd() or ".", options.build.output_dir or ".")),
	}

	options.server_settings = vim.tbl_deep_extend("force", options.server_settings, {
		Lua = {
			workspace = {
				library = {
					options.playdate_sdk_path,
					options.playdate_luacats_path,
				},
			},
		},
	})

	vim.api.nvim_create_user_command("PlaydateSetup", function()
		require("playdate.lspconfig").setup()
	end, { desc = "Setup the lua_ls for Playdate" })

	vim.api.nvim_create_user_command("PlaydateBuild", function(a)
		require("playdate.compile").build()
	end, { desc = "Compile the Playdate project" })

	vim.api.nvim_create_user_command("PlaydateRun", function()
		require("playdate.compile").run()
	end, { desc = "Compile and run Playdate project in the Simulator" })

	vim.api.nvim_create_user_command("PlaydateRunOnly", function()
		require("playdate.compile").run_only()
	end, { desc = "Compile and run Playdate project in the Simulator" })

	return options
end

return setmetatable(M, {
	__index = function(_, key)
		options = options or M.setup()
		return options[key]
	end,
})
