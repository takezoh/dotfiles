# scripts — ユーティリティスクリプト

## PATH への追加

`config/zsh/rc.d/zshenv/00_init.zsh` で PATH の先頭に追加される:

- `$HOME/.dotfiles/scripts/` — 全プラットフォーム
- `$HOME/.dotfiles/scripts/wsl/` — WSL 環境のみ（scripts/ より優先）

PATH の先頭に追加されるため、同名のシステムコマンドをラップできる。

## PATH オーバーライドパターン

`scripts/git` のように、同名のシステムコマンドを透過的にラップする:

```bash
#!/bin/bash
# WSL 環境で Windows パスなら git.exe を使い、それ以外は /usr/bin/git に委譲
```

実体コマンドの呼び出しには `command git` や絶対パスを使用し、再帰呼び出しを避ける。

## プラットフォーム分岐

`bootstrap.sh`（`~/.zshenv` 経由で読み込み済み）の `is_wsl` / `is_darwin` で判定:

```zsh
if is_wsl; then
    # WSL 固有の処理
fi
```

## WSL 専用スクリプト

`scripts/wsl/` に配置する。WSL 環境では `scripts/` より優先される。

- `open` / `wstart` — Windows の `start` コマンドラッパー
- `wcmd` — `cmd.exe` ラッパー
- `wpath` — `wslpath`/`cygpath` ラッパー

## 新規スクリプト追加時

1. shebang 行を付ける（`#!/bin/bash` または `#!/usr/bin/env python3` 等）
2. 実行権限を付与する（`chmod +x`）
3. WSL 専用なら `scripts/wsl/` に配置
