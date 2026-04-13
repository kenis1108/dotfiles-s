
if status is-interactive
# Commands to run in interactive sessions can go here
end

# -------- variable --------
set -Ux EDITOR nvim
set -Ux VISUAL nvim

fish_add_path ~/.local/bin

# -------- vi mode --------
# set -g fish_key_bindings fish_vi_key_bindings

# -------- application --------
# if [ -f "/opt/homebrew/bin/brew" ]
#   /opt/homebrew/bin/brew shellenv | source
# end

if type -q jj
  jj util completion fish | source
end

if type -q starship
  starship init fish | source
end

set FNM_PATH "/data/data/com.termux/files/home/.local/share/fnm"
if [ -d "$FNM_PATH" ]
  set PATH $FNM_PATH $PATH
  fnm env | source
end
if type -q fnm
  fnm env --use-on-cd --shell fish | source
  fnm completions --shell fish | source
end

if type -q uv
  uv generate-shell-completion fish | source
  uvx --generate-shell-completion fish | source
end

if type -q zoxide
  zoxide init fish | source
end

if type -q glow
  glow completion fish | source
end

if not type -q nix
  set nix_daemon_fish_path '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
  if test -e "$nix_daemon_fish_path"
    source "$nix_daemon_fish_path"
  end
  set nix_completion_fish_path '/nix/var/nix/profiles/default/share/fish/vendor_completions.d/nix.fish'
  if test -e "$nix_completion_fish_path"
    source "$nix_completion_fish_path"
  end
end

# -------- alias --------
function c
  curl -LO $argv
end

function f
  fastfetch $argv
end

function g
  lazygit $argv
end

function l
  eza --color=always --icons --group-directories-first $argv
end

function ll
  eza -la --color=always --icons --group-directories-first $argv
end

function n
  nvim $argv
end

function o
  opencode $argv
end

function s
  shasum -a 256 $argv
end

function t
  tmux $argv
end

function y
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  yazi $argv --cwd-file="$tmp"
  if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    builtin cd -- "$cwd"
  end
  rm -f -- "$tmp"
end

function ze
  zellij $argv
end
