# zsh 設定

構造・キーバインド・lazyenv 等の詳細は `README.md` を参照。

## 規約

- `_zsh.load <phase>` が `rc.d/<phase>/*` → `~/.local/config/<phase>/*` の順で source する
- 数字プレフィックスで読み込み順序を制御
- `.` プレフィックスでファイルを無効化

## プラグイン読み込み順序（厳守）

```
05_completion.zsh:  compinit → fzf-tab
95_modules.zsh:     zsh-autosuggestions → zsh-syntax-highlighting
```

- compinit は zlogin フェーズで実行（zshrc では使用不可）
- fzf-tab は compinit の後、autosuggestions/syntax-highlighting の前
- zsh-autosuggestions は zsh-syntax-highlighting の前
