#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

# ツール・エージェントを最新化（イメージキャッシュで stale になった分を補完）
PHASE=update bash ~/.dotfiles/profiles/devcontainer.sh

# Docker ビルド中に SSH 制約で失敗したプラグインを再試行
# （ビルド時と異なり SSH agent forwarding が有効な場合がある）
if command -v claude >/dev/null 2>&1; then
	zsh ~/.dotfiles/modules/agent-claude/setup.sh
fi

cat > /tmp/nvim-mason-install.lua << 'LUAEOF'
local to_install = { "clangd", "pyright", "rust-analyzer", "typescript-language-server" }
local registry = require("mason-registry")
local pending = {}
registry.refresh(function()
	for _, name in ipairs(to_install) do
		local ok, pkg = pcall(registry.get_package, name)
		if ok and not pkg:is_installed() then
			table.insert(pending, pkg)
			pkg:install()
		end
	end
	vim.wait(120000, function()
		for _, pkg in ipairs(pending) do
			if not pkg:is_installed() then return false end
		end
		return true
	end, 1000)
	vim.cmd("qa!")
end)
LUAEOF

# nvim plugin install runs in background; docker exec does not kill orphaned processes
nohup bash -c '
	nvim --headless "+Lazy! restore" +qa
	nvim --headless "+TSUpdateSync" +qa
	nvim --headless -c "luafile /tmp/nvim-mason-install.lua" 2>/dev/null || true
' > /tmp/nvim-install.log 2>&1 &
