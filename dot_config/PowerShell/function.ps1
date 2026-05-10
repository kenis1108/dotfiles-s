#-----------------------------
# Custom PowerShell Functions
#-----------------------------
function helloWorld {
	Clear-Host
	Write-Output ""
	Write-Output "|\     /||\     /|(  ___  )( (    /|(  ____ \\__    _/|\     /|"
	Write-Output "| )   ( || )   ( || (   ) ||  \  ( || (    \/   )  (  | )   ( |"
	Write-Output "| (___) || |   | || (___) ||   \ | || |         |  |  | (___) |"
	Write-Output "|  ___  || |   | ||  ___  || (\ \) || | ____    |  |  |  ___  |"
	Write-Output "| (   ) || |   | || (   ) || | \   || | \_  )   |  |  | (   ) |"
	Write-Output "| )   ( || (___) || )   ( || )  \  || (___) ||\_)  )  | )   ( |"
	Write-Output "|/     \|(_______)|/     \||/    )_)(_______)(____/   |/     \|"
	Write-Output ""
	Write-Output " = = = = = = = = = = = = = 命令清单 = = = = = = = = = = = = = ="
  Write-Output " 导出scoop清单 ------ Export-ScoopApps"
	Write-Output " scrcpy查看usb连接是否成功 ------ adbusb"
	Write-Output " 息屏启动scrcpy-s ------ scrcpy"
	Write-Output " ffmpeg下载m3u8成mp4 ------ ffmpeg2mp4 url filename"
	Write-Output " 获取所有窗口的id,进程名,窗口标题 ------ gwp"
	Write-Output " "
}

# 获取所有窗口的id,进程名,窗口标题，以便配置glazewm的窗口规则
function Get-ProcessNameAndMainWindowTitle {
	Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Id, ProcessName, MainWindowTitle
}

<#
.SYNOPSIS
    使用 fzf 模糊查找并交互式终止进程

.DESCRIPTION
    该函数列出所有运行中的进程，通过 fzf 提供交互式模糊查找界面，
    支持多选进程并批量终止。包含进程预览功能，可查看详细信息。

.PARAMETER ShowSystemProcesses
    是否显示系统进程（默认不显示）

.EXAMPLE
    Kill-ProcessWithFzf
    交互式选择并终止用户进程

.EXAMPLE
    Kill-ProcessWithFzf -ShowSystemProcesses
    显示包括系统进程在内的所有进程

.NOTES
    需要提前安装 fzf (可通过 scoop install fzf 或 choco install fzf 安装)
    需要管理员权限才能终止某些系统进程
#>
function Kill-ProcessWithFzf {
    param(
        [switch]$ShowSystemProcesses
    )

    # 检查 fzf 是否安装
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Error "fzf 未安装，请先安装 fzf (scoop install fzf 或 choco install fzf)"
        return
    }

    # 获取进程列表，并根据参数决定是否过滤系统进程
    $processes = if (-not $ShowSystemProcesses) {
        Get-Process | Where-Object { $_.SessionId -ne 0 -and $_.Name -ne "Idle" }
    } else {
        Get-Process
    }

    # 使用 fzf 交互式选择进程
    $selected = $processes | ForEach-Object {
        # 格式化显示：[PID] 进程名 (CPU使用率 内存使用)
        $cpuUsage = if ($_.CPU) { "{0:N1}%" -f $_.CPU } else { "N/A" }
        $memUsage = "{0:N1} MB" -f ($_.WorkingSet64 / 1MB)
        "[$($_.Id)] $($_.Name) (CPU: $cpuUsage, MEM: $memUsage)"
    } | fzf --multi `
            --height 40% `
            --prompt="选择要终止的进程 (Tab多选)> " `
            --bind 'ctrl-a:select-all,ctrl-d:deselect-all'

    # 如果没有选择任何进程则退出
    if ([string]::IsNullOrEmpty($selected)) {
        Write-Host "没有选择任何进程。" -ForegroundColor Yellow
        return
    }

    # 显示确认提示
    Write-Host "`n即将终止以下进程：" -ForegroundColor Yellow
    $selected | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }

    $confirmation = Read-Host "`n确认终止以上进程？(y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "已取消操作。" -ForegroundColor Green
        return
    }

    # 终止选中的进程
    $killedCount = 0
    $selected | ForEach-Object {
        try {
            $pidToKill = ($_ -split ']')[0].Trim("[")
            Stop-Process -Id $pidToKill -Force -ErrorAction Stop
            Write-Host "[✓] 已终止 PID: $pidToKill" -ForegroundColor Green
            $killedCount++
        } catch {
            Write-Host "[×] 无法终止 PID: $pidToKill ($($_.Exception.Message))" -ForegroundColor Red
        }
    }

    # 显示结果摘要
    Write-Host "`n操作完成。成功终止 $killedCount 个进程。" -ForegroundColor Cyan
}

# 设置函数别名方便使用
Set-Alias -Name kpf -Value Kill-ProcessWithFzf

<#
.SYNOPSIS
    Win+L快捷键开关

.DESCRIPTION
    修改注册表启用/禁用Win+L快捷键
    需要管理员权限，立即生效
#>
function Set-WinLKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='Disable')]
        [switch]$Disable,

        [Parameter(Mandatory=$true, ParameterSetName='Enable')]
        [switch]$Enable
    )

    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $regValueName = "DisableLockWorkstation"
    $value = if ($Disable) { 1 } else { 0 }

    try {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name $regValueName -Value $value -Type DWord -Force
        if ($value -eq 1) {
            Write-Output "Win+L快捷键已禁用"
        } else {
            Write-Output "Win+L快捷键已启用"
        }
    }
    catch {
        Write-Error "修改失败: $_"
    }
}

Set-Alias swl Set-WinLKey


# 为文件创建符号链接，用于在Windows下复用和统一Linux的各种配置文件路径，需要以管理员身份运行这个函数
# ------------------------------
# 例如：
# 创建yazi的配置文件符号链接
# $target = "$env:USERPROFILE\AppData\Roaming\yazi\config\yazi.toml"
# $source = "$env:USERPROFILE\.config\yazi\yazi.toml"
# gsudo Create-SymbolicLinkIfNeeded -TargetPath $target -SourcePath $source
# --------------------------------
# 创建VSCode的配置文件符号链接
# $target = "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\persist\vscode\data\user-data\User\settings.json"
# $source = "$env:USERPROFILE\.config\vscode\settings.json"
# gsudo Create-SymbolicLinkIfNeeded -TargetPath $target -SourcePath $source
# $target = "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\persist\vscode\data\user-data\User\keybindings.json"
# $source = "$env:USERPROFILE\.config\vscode\keybindings.json"
# gsudo Create-SymbolicLinkIfNeeded -TargetPath $target -SourcePath $source
# --------------------------------
# 创建alacritty的配置文件符号链接
# $target = "$env:USERPROFILE\AppData\Roaming\alacritty\alacritty.yml"
# $source = "$env:USERPROFILE\.config\alacritty\alacritty.yml"
# gsudo Create-SymbolicLinkIfNeeded -TargetPath $target -SourcePath $source
function Create-SymbolicLinkIfNeeded {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    # 检查目标路径是否存在
    if (Test-Path -Path $TargetPath) {
        # 如果存在，删除它
        Remove-Item -Path $TargetPath -Force
    }else{
        # 如果不存在，创建父目录
        $parentDir = Split-Path -Path $TargetPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
    }

    # 创建符号链接
    New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath
}

# 导出Scoop安装的应用程序列表到JSON文件
function Export-ScoopApps {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $hostname = $env:COMPUTERNAME
    $filePath = "$HOME\scoop\scoop-app_${hostname}_$timestamp.json"
    scoop export > $filePath
    chezmoi add $filePath
    Write-Output "Scoop 应用列表已导出到: $filePath"
}

# 从JSON文件导入Scoop安装的应用程序
function Import-ScoopApps {
    # 定义存储 Scoop 导出文件的目录
    $scoopDir = "$HOME\scoop"
    $hostname = $env:COMPUTERNAME

    # 检查目录是否存在
    if (-not (Test-Path -Path $scoopDir)) {
        Write-Error "目录 $scoopDir 不存在，无法导入文件。"
        return
    }

    # 获取当前主机名相关的最新导出文件
    $latestFile = Get-ChildItem -Path $scoopDir -Filter "scoop-app_${hostname}_*.json" |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1

    # 检查是否找到文件
    if (-not $latestFile) {
        Write-Error "未找到与主机名 $hostname 相关的 Scoop 导出文件。"
        return
    }

    # 导入最新的文件
    scoop import $latestFile.FullName
    Write-Output "已成功导入文件: $($latestFile.FullName)"
}

# 启动/停止随处解压安装的sshd服务，需要先cd到sshd.exe所在目录
function Set-SSHD {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("start", "stop")]
        [string]$Action
    )

    if ($Action -eq "start") {
        Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden", "-Command", "./sshd.exe -f ./sshd_config"
    } elseif ($Action -eq "stop") {
        Get-Process sshd | Stop-Process -Force
    } else {
        Write-Host "Invalid action. Use 'start' or 'stop'."
    }
}

# 启动不同配置的nvim，参数是在$env:XDG_CONFIG_HOME目录下的配置文件夹名
# 例如：Start-Nvim-WithConfig -Config "nvim_lv"
function Start-Nvim-WithConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Config
    )

    # 定义配置文件夹路径
    $configPath = "$env:XDG_CONFIG_HOME\$Config"

    # 检查文件夹是否存在
    if (Test-Path -Path $configPath) {
        $env:NVIM_APPNAME = $Config # 也可以使用 "nvim -u 配置文件路径" 来指定配置文件
        Write-Host "已设置 NVIM_APPNAME=$Config"
        nvim
    } else {
        Write-Error "配置文件夹 '$configPath' 不存在，请检查参数是否正确。"
    }
}

# 代理
function setproxy {
  $proxyUrl = "http://192.168.243.14:7897"
  $env:HTTP_PROXY = $proxyUrl
  $env:HTTPS_PROXY = $proxyUrl
  Write-Output "proxy设置成功"
}

function unsetproxy { 
  $env:HTTP_proxy = ""
  $env:HTTPS_proxy = "" 
  Write-Output "proxy重置成功"
}

function Switch-MicrosoftInputMethod {
  <#
  .SYNOPSIS
  切换微软输入法的全拼和双拼模式（适配 Enable Double Pinyin 键名）
  #>
  [CmdletBinding()]
  param()

  $regPath = "HKCU:\SOFTWARE\Microsoft\InputMethod\Settings\CHS"
  $regKey = "Enable Double Pinyin"

  try {
    if (-not (Test-Path $regPath)) {
      throw "未找到微软输入法配置路径，请确保已安装并启用微软拼音输入法"
    }

    $currentValue = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $regKey -ErrorAction SilentlyContinue
    if (-not $currentValue) { $currentValue = 0 }

    $newValue = 1 - $currentValue

    Set-ItemProperty -Path $regPath -Name $regKey -Value $newValue -Type DWord -Force

    if ($newValue -eq 1) {
      Write-Host "已切换为双拼模式" -ForegroundColor Green
    }
    else {
      Write-Host "已切换为全拼模式" -ForegroundColor Green
    }
  }
  catch {
    Write-Error "操作失败: $_"
  }
}
