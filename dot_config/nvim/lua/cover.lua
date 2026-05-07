local function safe_require(module)
	local ok, mod = pcall(require, module)
	if not ok then
		local msg = "Module not found: " .. module
		vim.cmd("echomsg '" .. msg .. "'")
		return nil
	end
	return mod
end

safe_require("origin_configs.configs.options")
safe_require("origin_configs.configs.autocmds")

vim.schedule(function()
	safe_require("origin_configs.configs.keymaps")
end)
