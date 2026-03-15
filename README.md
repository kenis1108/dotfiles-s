# Kenis DotFiles

📁 个人 dotfiles 配置管理仓库，使用 chezmoi 进行管理。

## 目录

- [Kenis DotFiles](#kenis-dotfiles)
  - [目录](#目录)
  - [如何使用](#如何使用)
  - [配置文件说明](#配置文件说明)
    - [编辑器配置](#编辑器配置)
      - [Neovim 注意事项](#neovim-注意事项)
      - [VSCode 说明](#vscode-说明)
      - [Cursor 说明](#cursor-说明)
    - [Shell 配置](#shell-配置)
    - [桌面环境配置](#桌面环境配置)
    - [窗口管理器配置](#窗口管理器配置)
    - [终端仿真器配置](#终端仿真器配置)
    - [终端文件管理器配置](#终端文件管理器配置)
    - [应用启动器配置](#应用启动器配置)
    - [其他工具配置](#其他工具配置)
      - [Quicker 注意事项](#quicker-注意事项)
      - [urxvt 快捷键](#urxvt-快捷键)
  - [特殊文件管理](#特殊文件管理)
  - [2026 New](#2026-new)
    - [macOS](#macos)
      - [homebrew](#homebrew)
      - [VSCode](#vscode)
      - [kitty](#kitty)
    - [Windows](#windows)
      - [PowerShell](#powershell)

## 如何使用

clone dotfiles仓库到本地

```bash
git clone https://github.com/{GITHUB_USERNAME}/dotfiles.git ~/.local/share/chezmoi
# or
chezmoi init {GITHUB_USERNAME}
# or
chezmoi init https://github.com/{GITHUB_USERNAME}/dotfiles.git
```

复制`chezmoi.toml`到`~/.config/chezmoi/chezmoi.toml`

```bash
mkdir ~/.config/chezmoi
cp ./chezmoi.yaml ~/.config/chezmoi/chezmoi.yaml
```

修改 chezmoi 配置，编辑 `~/.config/chezmoi/chezmoi.toml`

使用 `chezmoi apply` 应用所有配置

使用 `chezmoi edit --apply $FILE` 来编辑并自动apply dotfiles

## 配置文件说明

### 编辑器配置

| 配置文件          | 路径                                  | 说明                                                              |
| ----------------- | ------------------------------------- | ----------------------------------------------------------------- |
| Neovim（Windows） | `AppData/Local/nvim`                  | Neovim 配置文件                                                   |
| Neovim（Linux）   | `~/.config/nvim`                      | Neovim 配置文件                                                   |
| Neovide           | `AppData/Roaming/neovide/config.toml` | Neovide 配置文件                                                  |
| VSCode            | `~/.config/vscode`                    | VSCode 配置文件，不同平台通过创建符号链接来共用一个地方的配置文件 |
| Vim (Windows)     | `_vimrc`                              | Windows 下的 Vim 配置                                             |
| Vim (Linux)       | `.vimrc`                              | Linux 下的 Vim 配置                                               |

#### Neovim 注意事项

- 需要提前安装 gcc：`scoop install gcc`
- 需要提前安装 Node.js：`scoop install fnm`
- 需要提前安装 Python: `scoop install uv`

- $HOME/.config/nvim_nvchad/lua/origin_configs这个快捷方式在不同等操作系统需要重新生成，Linux/macOS使用`ln -s`，Windows使用`New-Item -ItemType SymbolicLink`
  - Linux/macOS `ln -s -f ~/.config/nvim/lua/configs ~/.config/nvim_nvchad/lua/origin_configs`

#### VSCode 说明

- 配置文件包括设置和快捷键
- 配合 VSCode 的同步功能一起使用
- 不同 Profile 的配置文件继承 Default 配置文件
- 创建符号链接：
  - Windows 使用 PowerShell `New-Item -ItemType SymbolicLink -Path “C:\Users\kenis\scoop\persist\vscode\data\user-data\User\settings.json” -Target “C:\Users\kenis\.config\vscode\settings.json”`
  - Linux/Mac 使用 `ln -s ~/.config/vscode/settings.json ~/.config/Code/User/settings.json`

#### Cursor 说明

- 复制 VSCode 的配置文件
- 可以通过 File->Preferences->Cursor Settings->General->VS Code Import 导入 VSCode 配置

### Shell 配置

| 配置文件     | 路径                                                           | 说明                      |
| ------------ | -------------------------------------------------------------- | ------------------------- |
| PowerShell 7 | `Documents/PowerShell/Microsoft.PowerShell_profile.ps1`        | PowerShell 7 配置         |
| PowerShell 5 | `Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | Windows PowerShell 5 配置 |
| Zsh          | `.zshrc`和`~/.config/zsh`                                      | Zsh 配置文件              |
| fish         | `~/.config/fish`                                               | Zsh 配置文件              |
| Bash         | `~/.config/bash`                                               | Zsh 配置文件              |

### 桌面环境配置

| 配置文件 | 路径             | 说明                                                    |
| -------- | ---------------- | ------------------------------------------------------- |
| COSMIC   | `.config/cosmic` | COSMIC 桌面环境配置，更新配置文件后需要重新登录才会生效 |

### 窗口管理器配置

| 配置文件 | 路径                        | 说明                       |
| -------- | --------------------------- | -------------------------- |
| GlazeWM  | `.glzr/glazewm/config.yaml` | GlazeWM 平铺窗口管理器配置 |
| i3wm     | `.config/.i3/config`        | i3wm 配置                  |
| i3status | `.config/i3status/config`   | i3status 配置              |
| swaywm   | `.config/sway`              | sway 配置                  |
| Hyprland | `.config/hypr`              | Hyprland 配置              |
| waybar   | `.config/waybar`            | waybar 配置                |

### 终端仿真器配置

| 配置文件 | 路径                        | 说明           |
| -------- | --------------------------- | -------------- |
| kitty    | `.config/kitty`             | kitty 配置     |
| foot     | `.config/foot`              | foot 配置      |
| Urxvt    | `.Xresources`               | Urxvt 终端配置 |
| termux   | `.termux/termux.properties` | termux 配置    |

### 终端文件管理器配置

| 配置文件 | 路径             | 说明        |
| -------- | ---------------- | ----------- |
| ranger   | `.config/ranger` | ranger 配置 |
| yazi     | `.config/yazi`   | yazi 配置   |

### 应用启动器配置

| 配置文件          | 路径                    | 说明                                       |
| ----------------- | ----------------------- | ------------------------------------------ |
| rofi/rofi-wayland | `.config/rofi`          | rofi 配置，基于 adi1090x/rofi 的配置修改的 |
| xdg-open          | `.config/mimeapps.list` | xdg-open 配置                              |

### 其他工具配置

| 配置文件   | 路径                                                         | 说明                                             |
| ---------- | ------------------------------------------------------------ | ------------------------------------------------ |
| Navi       | `AppData/Roaming/navi/config.yaml`                           | Navi 命令行备忘录配置                            |
| Quicker    | `Documents/Quicker/Ceastld/userdata.db`                      | Quicker 剪贴板数据文件                           |
| urxvt 插件 | `.urxvt/ext`                                                 | urxvt 终端插件                                   |
| rime       | IBus: `.config/ibus/rime` Fcitx5: `.local/share/fcitx5/rime` | rime 输入法配置，基于 oh-my-rime 修改的          |
| mpv        | `.config/mpv/mpv.conf`                                       | mpv 配置，基于 Garuda_i3wm 的 mpv.conf 修改的    |
| Xmodmap    | `.Xmodmap`                                                   | Xmodmap 配置                                     |
| picom      | `.config/picom.conf`                                         | picom 配置，基于 Garuda_i3wm 的 picom 配置修改的 |
| nix        | `.config/nix/nix.conf`                                       | nix 包管理器配置                                 |

#### Quicker 注意事项

- 在另一台电脑中粘贴 userdata.db 时，需要 Quicker 处于退出状态
- chezmoi apply 之前需要退出 Quicker

#### urxvt 快捷键

- 字体放大：Ctrl + +
- 字体缩小：Ctrl + -
- 字体重置：Ctrl + =
- 显示字体信息：Ctrl + ?

## 特殊文件管理

- `.reset_config`: 存放系统初始配置文件，方便回滚
- `.ssh`: SSH 配置文件
- `.zzsz`: zzsz 相关配置
- `Pictures`: Windows 系统用户目录的图片文件夹
- `scoop/persist`: 管理使用 scoop 安装的 espanso 和 win-vind 的配置文件数据, 其实他们也有默认的配置文件路径在用户目录下面, 但是使用 scoop 安装的话, 配置文件会安装到这里来
- `.chezmoiignore`: 管理不同操作系统下的配置文件
- `chezmoi_config_template.toml`: chezmoi 配置文件模板
- `.profile`: 修改 Linux 默认程序
- `.custom-scripts`: 存放自定义脚本，如获取网站 favicon
- `.config/nixos`: NixOS 系统的配置，使用`sh ~/.config/nixos/scripts/switch_xxx.sh`部署


---

## 2026 New

### macOS

#### homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew bundle --global
```

```bash
brew bundle dump --global --force --describe
```

#### VSCode
 
+ settings.json

```bash
mv ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json.bak
ln -s ~/.config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

mv ~/Library/Application\ Support/Code/User/mcp.json ~/Library/Application\ Support/Code/User/mcp.json.bak
ln -s ~/.config/vscode/mcp.json ~/Library/Application\ Support/Code/User/mcp.json
```

+ extensions

.Brewfile 也会导出 vscode extensions，macOS 可以不用单独管理 vscode extensions

```bash
code --list-extensions > extensions.txt
```

```bash
cat extensions.txt | xargs -n 1 code --install-extension
```

#### kitty

```bash
ln -s ./tokyo-night.conf ./theme.conf
```

### Windows

#### PowerShell

```pwsh
new-Item -ItemType SymbolicLink -Path ~/Documents/PowerShell -Target ~/.config/PowerShell
```
