function Linemode:size_and_mtime()
  local time = math.floor(self._file.cha.mtime or 0)
  if time == 0 then
    time = ""
  elseif os.date("%Y", time) == os.date("%Y") then
    time = os.date("%y-%m-%d %H:%M", time)
  else
    time = os.date("%y-%m-%d", time)
  end

  local size = self._file:size()
  return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

function ensure_flavor(flavor_name, download_url)
	local home = os.getenv("HOME")
	local flavor_path = home .. "/.config/yazi/flavors/" .. flavor_name .. "/flavor.toml"

	if not os.execute([[test -f "]] .. flavor_path .. [["]]) then
		os.execute([[mkdir -p "$(dirname "]] .. flavor_path .. [[")"]])
		os.execute([[curl -fLo "]] .. flavor_path .. [[" "]] .. download_url .. [["]])
		os.execute([[echo >> "]] .. flavor_path .. [["]])
		os.execute([[echo "# copy from ]] .. download_url .. [[" >> "]] .. flavor_path .. [["]])
	end
end

function ensure_plugin(plugin)
	local ok = pcall(require, plugin)
	if not ok then
		os.execute("ya pkg add " .. plugin .. " >/dev/null 2>&1")
	end
end

-- 更新到最新的yazi 26.5.6 后，schema不兼容了，该主题会报错
-- ensure_flavor(
-- 	"tokyonight_night.yazi",
-- 	"https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/yazi/tokyonight_night.toml"
-- )

ensure_plugin("yazi-rs/plugins:full-border")
ensure_plugin("Rolv-Apneseth/starship")
ensure_plugin("AnirudhG07/plugins-yazi:copy-file-contents")
ensure_plugin("yazi-rs/plugins:vcs-files")
ensure_plugin("yazi-rs/plugins:git")
ensure_plugin("AminurAlam/yazi-plugins:preview-git")
ensure_plugin("Lil-Dank/lazygit")

-- install via "ya pkg add yazi-rs/plugins:full-border"
require("full-border"):setup()

-- install via "ya pkg add Rolv-Apneseth/starship"
require("starship"):setup({
    -- Hide flags (such as filter, find and search). This can be beneficial for starship themes
    -- which are intended to go across the entire width of the terminal.
    hide_flags = false,
    -- Whether to place flags after the starship prompt. False means the flags will be placed before the prompt.
    flags_after_prompt = true,
    -- Custom starship configuration file to use
    config_file = "~/.config/starship.toml", -- Default: nil
    -- Whether to enable support for starship's right prompt (i.e. `starship prompt --right`).
    show_right_prompt = false,
    -- Whether to hide the count widget, in case you want only your right prompt to show up. Only has
    -- an effect when `show_right_prompt = true`
    hide_count = false,
    -- Separator to place between the right prompt and the count widget. Use `count_separator = ""`
    -- to have no space between the widgets.
    count_separator = " ",
})

-- install via "ya pkg add AnirudhG07/plugins-yazi:copy-file-contents"
require("copy-file-contents"):setup({
	append_char = "\n",
	notification = true,
})

-- install via "ya pkg add yazi-rs/plugins:git"
require("git"):setup {
	-- Order of status signs showing in the linemode
	order = 1500,
}
