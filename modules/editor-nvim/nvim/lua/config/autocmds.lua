local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- cursorline toggle
local cch = augroup("cch", { clear = true })
autocmd("WinLeave", {
	group = cch,
	callback = function() vim.opt_local.cursorline = false end,
})
autocmd({ "WinEnter", "BufRead" }, {
	group = cch,
	callback = function() vim.opt_local.cursorline = true end,
})

-- restore cursor position
autocmd("BufReadPost", {
	group = augroup("restore_cursor", { clear = true }),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- strip trailing whitespace (exclude markdown)
autocmd("BufWritePre", {
	group = augroup("strip_whitespace", { clear = true }),
	callback = function()
		if vim.bo.filetype == "markdown" then return end
		local save = vim.fn.winsaveview()
		vim.cmd([[%s/\s\+$//ge]])
		vim.fn.winrestview(save)
	end,
})

-- language-specific indent
autocmd("FileType", {
	group = augroup("indent_by_ft", { clear = true }),
	pattern = { "python", "cs" },
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
	end,
})
autocmd("FileType", {
	group = augroup("indent_web", { clear = true }),
	pattern = { "html", "javascript", "css", "sass", "vue", "jsx", "php", "typescript", "typescriptreact" },
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
	end,
})

-- vue syntax sync
autocmd("FileType", {
	group = augroup("vue_sync", { clear = true }),
	pattern = "vue",
	command = "syntax sync fromstart",
})

-- HLSL/USF filetype
autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("hlsl_ft", { clear = true }),
	pattern = { "*.usf", "*.ush" },
	callback = function() vim.bo.filetype = "hlsl" end,
})

-- binary file xxd display
local binary = augroup("Binary", { clear = true })
autocmd("BufReadPre", {
	group = binary,
	pattern = "*.bin",
	callback = function() vim.b.binary = true end,
})
autocmd("BufReadPost", {
	group = binary,
	callback = function()
		if vim.b.binary then
			vim.cmd("%!xxd")
			vim.bo.filetype = "xxd"
		end
	end,
})
autocmd("BufWritePre", {
	group = binary,
	callback = function()
		if vim.b.binary then vim.cmd("%!xxd -r") end
	end,
})
autocmd("BufWritePost", {
	group = binary,
	callback = function()
		if vim.b.binary then
			vim.cmd("%!xxd")
			vim.bo.modified = false
		end
	end,
})

-- japanese encoding recheck
autocmd("BufReadPost", {
	group = augroup("recheck_fenc", { clear = true }),
	callback = function()
		if vim.bo.fileencoding:match("iso%-2022%-jp") and vim.fn.search("[^\x01-\x7e]", "n") == 0 then
			vim.bo.fileencoding = vim.o.encoding
		end
	end,
})

-- C# BOM
autocmd("BufWritePre", {
	group = augroup("cs_bom", { clear = true }),
	pattern = "*.cs",
	callback = function()
		vim.bo.fileencoding = "utf-8"
		vim.bo.bomb = true
	end,
})
