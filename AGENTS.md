# dotfiles

## 開発規約

- **インデント**: タブ（シェルスクリプト）
- **キーバインド**: `bindkey -v`（vi モード）
- **rc.d ファイル命名**: 数字プレフィックスで読み込み順序を制御（`00_` → `05_` → `95_` → `99_`）
- **`.` プレフィックス**: ファイル名先頭に `.` を付けると `_zsh.load` の glob に一致しなくなり無効化される
- **`.*.local` ファイル**: gitignore 済み。マシン固有の設定に使用
- **ローカルオーバーライド**: `~/.local/config/<phase>/*` に配置すると `_zsh.load` が最後に読み込む

## 注意事項

- `external/` は git submodule のみ。変更は上流リポジトリで行うこと
- **このリポジトリはユーザー環境定義リポジトリ**: ルートの `AGENTS.md` / `CLAUDE.md` はこのリポジトリでの作業用です
- **Claude Code 設定管理**: `modules/agent-claude/claude/` の設定が Claude Code のユーザー環境定義となります。Claude Code は `modules/agent-claude/claude/` を編集し、`~/.claude/CLAUDE.md` と `~/.claude/settings.json` は直接編集しません（`modules/agent-claude/setup.sh` で自動生成）

## モジュール構成

各モジュールは `modules/<name>/` に `install.sh`・`setup.sh`・`env.sh` の組み合わせを持つ。

```
modules/
  _lib/common.sh        # has_cmd, log, is_wsl/darwin/linux, link ヘルパ
  apt/install.sh        # ubuntu apt パッケージ
  brew/{install,env}.sh # Homebrew/Linuxbrew
  mise/{install,env}.sh # mise インストール + activate
  rust/{install,env}.sh # rustup インストール + cargo/env
  shell/{install,setup,env}.sh  # zsh/tmux/starship 等 + zsh config symlink
  editor-nvim/{install,setup}.sh
  vcs-git/{install,setup}.sh    # git + gitconfig symlink
  vcs-tig/{install,setup}.sh    # tig + tigrc symlink
  cli/setup.sh                  # atuin/bat/direnv/ripgrep/starship.toml symlink
  cli-gcloud/{install,env}.sh   # Google Cloud SDK
  roost/setup.sh                # settings.toml symlink
  agent-claude/{install,setup}.sh  # bwrap/socat + YAML→JSON merge
  agent-claude-lsp/install.sh   # LSP サーバー（clangd/pyright/gopls 等）
  agent-codex/{setup}.sh
  agent-gemini/{setup}.sh
  agent-mcp-servers/install.sh
  agent-shared/setup.sh         # AGENTS.md symlink
  agent-skills/{install,setup}.sh  # 同階層の skills/ を配置（存在時のみ）
  terminal-windows/setup.sh
  terminal-wezterm/setup.sh
  net-ssh/setup.sh              # ssh config symlink（鍵は触らない）
  sdk-{go,node,python,ruby,java}/install.sh  # mise 経由の言語 SDK
  docker/install.sh             # Docker CE (公式 apt) + docker グループ/サービス
  android-re/install.sh         # Android リバースエンジニアリングツール
  macos-defaults/setup.sh       # macOS システム設定（defaults write）
  devcontainer/setup.sh         # ~/.devcontainer symlink（Dockerfile + devcontainer.json）
  wsl-windows-bridge/setup.sh   # WSL ⇄ Windows interop
```

各モジュール規約:
- `install.sh` は冪等（`has_cmd` で既存確認してスキップ）
- `setup.sh` は `ln -snf` 冪等（`link()` ヘルパ使用）
- `env.sh` は POSIX 準拠、bash/zsh 両対応。コマンドが無ければ何もしない
- `update.sh` は `PHASE=update` でツール・エージェントを更新（`all` には含まれない）

## プロファイル管理

`profiles/<env>.sh` がモジュールの選択と実行順序を定義する（プロファイル一覧は `README.md` を参照）。`profiles/_run.sh` が共通 runner。`PHASE=install|setup|update|all` で段階実行可能（`update` は `all` に含まれない）。

### devcontainer との接点

`modules/devcontainer/` が `~/.devcontainer` の実体（Dockerfile + devcontainer.json）。`modules/devcontainer/setup.sh` が symlink を張る（host profile に含まれており `dotfiles.sh` 実行で自動配置）。
Dockerfile は `modules/` の install 段階を RUN で呼ぶ（context: dotfiles ルート）。
`.dockerignore` はリポジトリルートにコミット済み。

## Claude Code 設定の構成

`modules/agent-claude/claude/` が Claude Code のユーザー設定。`modules/agent-claude/setup.sh` で `~/.claude/` に適用される。

### settings.yaml

Claude Code の設定ファイル。YAML で管理し setup.sh で JSON に変換・マージされる。permissions, hooks, statusline 等を定義。

### hooks/

| ファイル | トリガー | 動作 |
|----------|----------|------|
| win-notify.sh | Stop, PermissionRequest, Notification | Windows 通知 |
| bash-audit.sh | PostToolUse (Bash) | コマンドをログに記録 |
| post-write-check.sh | PostToolUse (Write, Edit) | 500 行超ファイルの警告 |
| post-format.sh | PostToolUse (Write, Edit) | prettier/rustfmt 等で自動整形 |
| slack-notify.sh | （未使用） | Slack 通知 |
