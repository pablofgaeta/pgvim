local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
	end
end

local function assert_mapping(lhs)
	if vim.fn.maparg(lhs, "n") == "" then
		error(("missing normal-mode mapping: %s"):format(lhs))
	end
end

local function assert_no_errors(stage)
	assert_equal(vim.v.errmsg, "", stage .. " errors")
end

local function check_common_interfaces()
	assert_equal(vim.fn.exists(":Neotree"), 2, ":Neotree must be available at startup")
	assert_equal(vim.fn.exists(":PackSync"), 2, ":PackSync must be available at startup")

	local health_ok, health = pcall(require, "pgvim.health")
	assert_equal(health_ok, true, "pgvim health module must be discoverable")
	assert_equal(type(health.check), "function", "pgvim health module must expose check()")

	for _, lhs in ipairs({ " sf", "\\", "-", "<D-p>", " f", "<F5>" }) do
		assert_mapping(lhs)
	end
	assert_no_errors("startup")
end

local function check_extension()
	if vim.env.PGVIM_SMOKE_EXTENSION ~= "1" then
		return
	end

	assert_equal(vim.g.pgvim_smoke_before, "runtime-loaded", "extension before hook")
	assert_equal(vim.g.pgvim_smoke_after, "configured", "extension after hook")
	assert_equal(vim.g.pgvim_smoke_pack_stub_called, true, "isolated plugin fixture")
	assert_equal(vim.g.pgvim_smoke_supermaven_setup, true, "eager Supermaven setup")
end

local function check_empty_session()
	assert_equal(type(package.loaded.telescope), "table", "Telescope must load during startup")
	assert_equal(type(package.loaded.avante), "table", "AI must load during startup")
	vim.api.nvim_feedkeys(vim.keycode(" sf"), "xt", false)
	assert_equal(vim.bo.filetype, "TelescopePrompt", "<leader>sf")
	assert_no_errors("<leader>sf")
end

local function check_file_session()
	assert_equal(vim.bo.filetype, "lua", "filetype detection")
	assert_equal(vim.fn.exists(":ConformInfo"), 2, "development plugins must load for files")
	assert_equal(vim.fn.exists(":Neogit"), 2, "development commands must load for files")
	assert_no_errors("file startup")
end

local function run()
	if not vim.g.pgvim_root then
		error("vim.g.pgvim_root must identify the active distribution")
	end

	check_common_interfaces()
	check_extension()

	local scenario = assert(vim.env.PGVIM_SMOKE_SCENARIO, "PGVIM_SMOKE_SCENARIO is required")
	if scenario == "empty" then
		check_empty_session()
	elseif scenario == "file" then
		check_file_session()
	else
		error("unknown smoke scenario: " .. scenario)
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			local ok, failure = xpcall(run, debug.traceback)
			if not ok then
				io.stderr:write(failure .. "\n")
				vim.cmd.cquit(1)
				return
			end
			vim.cmd.qa({ bang = true })
		end)
	end,
})
