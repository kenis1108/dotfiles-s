--- 自动加载指定目录下的所有 Lua 模块（排除 init.lua）
-- 该函数会扫描 `lua/{dir}/` 目录下的所有 `.lua` 文件，并通过 `require` 动态加载每个模块。
-- 加载失败时会打印错误信息，但不会中断执行。
--
-- @param dir string 要加载的目录名（相对于 `lua/` 目录），例如 "config" 会加载 `lua/config/` 下的模块
-- @return nil
--
-- @usage
-- 目录结构示例：
--   ~/.config/nvim/lua/
--   ├── config/
--   │   ├── settings.lua    --> require("config.settings")
--   │   └── keymaps.lua     --> require("config.keymaps")
--   └── init.lua
--
-- 调用示例：
--   require_dir("config")   -- 加载 lua/config/ 下的所有模块
local function require_dir(dir)
	-- 获取 lua 目录的完整路径
	local lua_dir = vim.fn.stdpath("config") .. "/lua"
	local dir_path = lua_dir .. "/" .. dir

	-- 检查目录是否存在
	local handle = vim.loop.fs_scandir(dir_path)
	if not handle then
		-- print("⚠️ 目录不存在:", dir_path)
		return
	end

	-- print("🔄 正在加载目录:", dir_path)

	while true do
		local name, typ = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end

		if typ == "file" and name:match("%.lua$") and name ~= "init.lua" then
			local modname = dir .. "." .. name:gsub("%.lua$", "")
			-- print("📦 尝试加载模块:", modname)

			local ok, err = pcall(require, modname)
			if not ok then
				print("❌ 加载失败:", modname, "错误:", err)
				-- else
				-- print("✅ 成功加载:", modname)
			end
		end
	end
end

-- main
if vim.g.vscode then
	require("vscode").notify("Hello Neovim")
else
	require_dir("configs") -- 加载 lua/config/*.lua
end
