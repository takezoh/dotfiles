local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_domain = 'WSL:Ubuntu-22.04'

config.wsl_domains = {
  {
    name = 'WSL:Ubuntu-22.04',
    distribution = 'Ubuntu-22.04',
    username = 'take',
    default_cwd = '/home/take',
    default_prog = { 'zsh', '-l' },
  },
}

config.launch_menu = {
  { label = 'WSL Ubuntu', domain = { DomainName = 'WSL:Ubuntu-22.04' } },
  { label = 'PowerShell', args = { 'powershell.exe', '-NoLogo' } },
  { label = 'CMD', args = { 'cmd.exe' } },
}

return config
