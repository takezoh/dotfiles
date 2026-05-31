local opt = vim.opt

-- basic
opt.scrolloff = 5
opt.textwidth = 0
opt.wrap = false
opt.backup = false
opt.autoread = true
opt.swapfile = false
opt.hidden = true
opt.backspace = { "indent", "eol", "start" }
opt.formatoptions = "lmoq"
opt.visualbell = true
opt.showcmd = true
opt.showmode = true
-- clipboard provider: $TMUX も外部ツールも無い環境 (devcontainer 等) では
-- Neovim 同梱の OSC52 provider にフォールバック。tmux 側は
-- set-clipboard external + allow-passthrough on で透過済み。
local function has_native_provider()
	if vim.env.TMUX and vim.env.TMUX ~= "" then
		return true
	end
	for _, exe in ipairs({
		"pbcopy", "wl-copy", "xclip", "xsel",
		"lemonade", "doitclient", "win32yank.exe",
	}) do
		if vim.fn.executable(exe) == 1 then
			return true
		end
	end
	return false
end

if not has_native_provider() then
	local osc52 = require("vim.ui.clipboard.osc52")
	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
	}
end

opt.clipboard = "unnamedplus"
opt.suffixes = ".bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc"

-- search
opt.wrapscan = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- appearance
opt.termguicolors = true
opt.showmatch = true
opt.number = true
opt.list = true
opt.listchars = { tab = "» ", trail = "-", extends = "»", precedes = "«", nbsp = "%", eol = "↲" }
opt.display = "uhex"
opt.cursorline = true
opt.lazyredraw = true
opt.backupskip = "/tmp/*,/private/tmp/*"

-- encoding
opt.encoding = "utf-8"
opt.fileformats = { "unix", "dos", "mac" }
if vim.fn.exists("&ambiwidth") == 1 then
	opt.ambiwidth = "double"
end

-- indent
opt.autoindent = true
opt.smartindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 0
opt.expandtab = false

-- edit
opt.virtualedit = "block"

-- ime
opt.imdisable = false
opt.iminsert = 0
opt.imsearch = 0

-- shell
opt.shell = "zsh"

-- encoding commands
vim.api.nvim_create_user_command("Cp932", "edit ++enc=cp932", {})
vim.api.nvim_create_user_command("Sjis", "edit ++enc=shift_jis", {})
vim.api.nvim_create_user_command("Eucjp", "edit ++enc=euc-jp", {})
vim.api.nvim_create_user_command("Jis", "edit ++enc=iso-2022-jp", {})
vim.api.nvim_create_user_command("Utf8", "edit ++enc=utf-8", {})
