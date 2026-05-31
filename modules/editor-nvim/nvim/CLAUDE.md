# nvim config

nvim 0.11+ 向け Lua ベース設定。lazy.nvim でプラグイン管理。

## 設計方針

- **Leader**: `<Space>`
- **プラグイン仕様**: `lua/plugins/` 配下の各ファイルが lazy.nvim spec を return する
- **LSP**: nvim 0.11 の `vim.lsp.config()` / `vim.lsp.enable()` API を使用
- **LSP キーバインド**: `lsp.lua` の `LspAttach` autocmd 内で buffer-local に設定
- **fzf-lua キーバインド**: `keymaps.lua` にグローバル定義
- **インデント**: タブ（Lua ファイルもタブ。リポジトリ全体の規約に合わせる）

## ファイル構成・キーバインド・プラグイン詳細

`README.md` を参照。

## 注意事項

- nvim-lspconfig は `require("lspconfig")` ではなく `vim.lsp.config()` API を使うこと（0.11+）
- treesitter パーサーは初回の対話的起動時に自動インストールされる（`UIEnter` イベント）
- `lazy-lock.json` はプラグインのバージョン固定ファイル。コミット対象
