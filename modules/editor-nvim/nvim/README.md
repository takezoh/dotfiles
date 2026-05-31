# nvim config

nvim 0.11+ 向け Lua ベース設定。lazy.nvim でプラグイン管理。

## ファイル構成

```
init.lua                    lazy.nvim bootstrap + require
lua/config/
  options.lua               vim.opt 設定
  keymaps.lua               キーバインド（プラグイン非依存 + fzf-lua）
  autocmds.lua              autocmd（カーソル復元、空白除去、FT 別インデント等）
lua/plugins/
  colorscheme.lua           zenbones.nvim
  lsp.lua                   mason + mason-lspconfig + nvim-lspconfig
  completion.lua            blink.cmp
  copilot.lua               GitHub Copilot (AI インライン補完: ghost text)
  ai.lua                    minuet-ai.nvim (無効化済み・参照用)
  fzf.lua                   fzf-lua
  treesitter.lua            nvim-treesitter
  editor.lua                nvim-surround, Comment.nvim, which-key.nvim, trouble.nvim
  formatter.lua             conform.nvim + mason-tool-installer.nvim
  dap.lua                   nvim-dap + nvim-dap-ui + mason-nvim-dap.nvim
  ui.lua                    lualine.nvim
  snippets.lua              LuaSnip + friendly-snippets
```

## キーバインド一覧

Leader: `<Space>`

| キー | モード | 動作 |
|------|--------|------|
| `<C-h/j/k/l>` | n | ウィンドウ移動 |
| `<C-h/j/k/l>` | i | カーソル移動 |
| `<Esc><Esc>` | n | 検索ハイライト消去 |
| `<C-p>` | n | ファイル検索 (fzf-lua) |
| `<leader>ff` | n | ファイル検索 |
| `<leader>fg` | n | live grep |
| `<leader>fw` | n | カーソル位置の単語 grep |
| `<leader>fb` | n | バッファ一覧 |
| `<leader>fs` | n | 現バッファ行検索 |
| `<leader>fr` | n | 前回の検索を再開 |
| `<leader>fo` | n | ドキュメントシンボル (LSP) |
| `gd` | n | 定義ジャンプ (LSP) |
| `gr` | n | 参照検索 (LSP) |
| `K` | n | ホバー情報 (LSP) |
| `<leader>ca` | n | コードアクション (LSP) |
| `<leader>cr` | n | リネーム (LSP) |
| `<leader>cd` | n | 診断一覧 (Trouble) |
| `<leader>xx` | n | 全診断トグル (Trouble) |
| `<leader>xd` | n | バッファ診断 (Trouble) |
| `<leader>cf` | n | フォーマット (conform.nvim) |
| `gcc` | n | 行コメントトグル (Comment.nvim) |
| `gbc` | n | ブロックコメントトグル |
| `gc` / `gb` | v | 行 / ブロックコメント |
| `<F5>` | n | デバッグ: 続行 (DAP) |
| `<F10>` | n | デバッグ: step over (DAP) |
| `<F11>` | n | デバッグ: step into (DAP) |
| `<S-F11>` | n | デバッグ: step out (DAP) |
| `<leader>db` | n | ブレークポイント (DAP) |
| `<leader>du` | n | DAP UI トグル |
| `<Tab>/<S-Tab>` | i | 補完候補移動 (blink.cmp) |
| `<CR>` | i | 補完確定 (blink.cmp) |
| `<A-y>` | i | Copilot 候補を確定 |
| `<A-]>` / `<A-[>` | i | Copilot 次/前の候補 |
| `<A-e>` | i | Copilot 候補を消去 |

## LSP 対象言語

mason-lspconfig の `ensure_installed` で自動インストール:
- clangd (C/C++), pyright (Python), rust_analyzer (Rust), ts_ls (TypeScript)
- gopls (Go) はコメントアウト中（`go` コマンドが必要）

## フォーマッター (conform.nvim)

保存時自動フォーマット (BufWritePre)。mason-tool-installer.nvim でツール自動インストール:
- C/C++: clang-format
- Python: ruff_format
- Rust: rustfmt (cargo 付属)
- TypeScript/JS/JSON/YAML/HTML/CSS: prettier

## AI 補完 (GitHub Copilot / copilot.lua)

- ghost text 方式（グレー文字で先読み表示、キーで確定）。blink.cmp の補完メニューとは独立
- 前提: GitHub Copilot サブスクリプション + Node.js v22+（`copilot.lua` のデフォルト nodejs server mode）
- 初回のみ `:Copilot auth` で GitHub サインインが必要
- キー: `<A-y>` 確定 / `<A-]>`・`<A-[>` 次・前 / `<A-e>` 消去
- minuet-ai.nvim (Claude API) は `ai.lua` で `enabled = false` の参照用として残置。戻す場合は copilot.lua を無効化し、completion.lua に minuet ソースを復帰する

## デバッグ (nvim-dap)

mason-nvim-dap.nvim でアダプター自動インストール: codelldb (C/C++/Rust), debugpy (Python), js-debug-adapter (JS/TS)

## プラグイン追加方法

`lua/plugins/` に新しい `.lua` ファイルを作り、lazy.nvim spec を return する。
`init.lua` の `import = "plugins"` で自動読み込みされる。

## 注意事項

- `lazy-lock.json` はプラグインのバージョン固定ファイル。コミット対象
- treesitter パーサーは初回の対話的起動時に自動インストールされる（`UIEnter` イベント）
- nvim-lspconfig は `require("lspconfig")` ではなく `vim.lsp.config()` API を使うこと（0.11+）

---

## VimScript からの移行メモ

VimScript (dein.vim) 時代から操作が変わった点のまとめ。

### Leader キー

`,` → `<Space>` に変更。

### コメントアウト

**`<leader>` は使わない。** `g` から始まるキーに変更。

| 旧 (NERDCommenter) | 現在 (Comment.nvim) |
|---|---|
| `<leader>c<Space>` (トグル) | `gcc` |
| `<leader>cs` (sexy comment) | `gbc` |
| Visual + `<leader>c<Space>` | `gc` (行) / `gb` (ブロック) |

例: 3行コメントアウト → `3gcc` または Visual 選択して `gc`

### ファイル検索・grep

| 旧 (denite/unite) | 現在 (fzf-lua) |
|---|---|
| `:Denite file_rec` | `<C-p>` / `<leader>ff` |
| `:Denite grep` | `<leader>fg` (live grep) |
| `:Denite buffer` | `<leader>fb` |
| unite-outline | `<leader>fo` (LSP) |

### 補完

| 旧 (neocomplete/deoplete) | 現在 (blink.cmp) |
|---|---|
| `<C-n>` / `<C-p>` | `<Tab>` / `<S-Tab>` (+ `<C-n>` / `<C-p>`) |
| `<C-y>` 確定 | `<CR>` |
| `<C-e>` キャンセル | `<C-e>` (変更なし) |

### LSP / 定義ジャンプ

| 旧 (OmniSharp) | 現在 (nvim-lspconfig) |
|---|---|
| `<leader>g` | `gd` |
| `<leader>l` (参照) | `gr` |
| `<leader>act` | `<leader>ca` |

### プラグインマネージャ

dein.vim (TOML) → lazy.nvim (Lua)。設定は `rc.d/*.vim` + `bundle/*.toml` → `lua/plugins/*.lua`

### カラースキーム

zenburn → zenbones.nvim

### 廃止された機能

- **VimShell** → `:terminal`
- **airline** → lualine.nvim
- **NERDCommenter** → Comment.nvim
- **denite / unite** → fzf-lua
- **neocomplete / deoplete** → blink.cmp
- **OmniSharp** → nvim-lspconfig (LSP)
- **バイナリ編集 (xxd)** → 削除
