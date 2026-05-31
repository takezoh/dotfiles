return {
	"milanglacier/minuet-ai.nvim",
	enabled = false,
	cond = vim.fn.filereadable(os.getenv("HOME") .. "/.secrets/anthropic_key") == 1,
	init = function()
		local key_file = os.getenv("HOME") .. "/.secrets/anthropic_key"
		local f = io.open(key_file, "r")
		if f then
			vim.env.ANTHROPIC_API_KEY = f:read("*a"):gsub("\n$", "")
			f:close()
		end
	end,
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		provider = "claude",
		notify = "warn",
		provider_options = {
			claude = {
				max_tokens = 512,
				model = "claude-sonnet-4-20250514",
				system = {
					type = "text",
					text = "You are a coding assistant. Complete the code concisely.",
				},
			},
		},
		blink = {
			enable_auto_complete = false,
		},
	},
}
