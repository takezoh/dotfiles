local map = vim.keymap.set

-- disable dangerous keys
map("n", "Q", "<Nop>")
map("n", "ZZ", "<Nop>")
map("n", "ZQ", "<Nop>")

-- clear search highlight
map("n", "<Esc><Esc>", "<Cmd>nohlsearch<CR>")

-- window navigation (bug fix: was <C-k>j etc.)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- insert mode navigation
map("i", "<C-e>", "<End>")
map("i", "<C-a>", "<Home>")
map("i", "<C-j>", "<Down>")
map("i", "<C-k>", "<Up>")
map("i", "<C-h>", "<Left>")
map("i", "<C-l>", "<Right>")

-- mark navigation
map("n", "gb", "'[")
map("n", "gp", "']")

-- bracket jump
map("n", "[", "%")
map("n", "]", "%")

-- yank word under cursor
map("n", "vy", "vawy")

-- undoable delete in insert mode
map("i", "<C-u>", "<C-g>u<C-u>")
map("i", "<C-w>", "<C-g>u<C-w>")

-- terminal mode escape (typo fix: was <slent>)
map("t", "<Esc>", [[<C-\><C-n>]])

-- insert mode IME off
map("i", "<Esc>", "<Esc><Cmd>set iminsert=0<CR>")

-- yank word under cursor to register
map("n", "ye", function()
	vim.fn.setreg('"', vim.fn.expand("<cword>"))
end)

-- fzf-lua (mapped here, requires fzf-lua plugin)
map("n", "<C-p>", "<Cmd>FzfLua files<CR>")
map("n", "<leader>ff", "<Cmd>FzfLua files<CR>")
map("n", "<leader>fg", "<Cmd>FzfLua live_grep<CR>")
map("n", "<leader>fw", "<Cmd>FzfLua grep_cword<CR>")
map("n", "<leader>fb", "<Cmd>FzfLua buffers<CR>")
map("n", "<leader>fs", "<Cmd>FzfLua blines<CR>")
map("n", "<leader>fr", "<Cmd>FzfLua resume<CR>")
map("n", "<leader>fo", "<Cmd>FzfLua lsp_document_symbols<CR>")
