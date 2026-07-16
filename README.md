# dotfiles

個人用 dotfiles リポジトリ。モジュール単位でツールチェイン導入と設定 symlink を一元管理する。

永続設計は [`docs/design/`](docs/design/)、判断履歴は [`docs/adr/`](docs/adr/) で管理する。具体的な導入・操作手順はこの README と各 module README が正本である。

## リポジトリ構造

```
modules/        各モジュール（{install,setup,env}.sh + 設定ファイル）
profiles/       環境別モジュール選択（下記プロファイル参照）
scripts/        PATH に追加されるユーティリティスクリプト
external/       git submodule（zsh プラグイン、lazyenv 等。直接編集禁止）
misc/           runtime テンプレート / WSL ヘルパ等のリソース
```

## デプロイメント

```sh
bash install.sh        # フルインストール（toolchain install + symlink）
bash setup.sh          # symlink のみ
bash update.sh         # ツール・エージェントの更新（PHASE=update）
```

`install.sh` / `setup.sh` は内部で platform を判定し、対応する `profiles/<env>.sh` を呼ぶ。profile が `modules/` 内のモジュール群を順次実行する。

各モジュールの責務:
- `install.sh` — 冪等インストーラ（apt/brew/npm 等）
- `setup.sh` — symlink 配置・設定マージ
- `env.sh` — PATH/環境変数（POSIX、bash/zsh 両対応）

## プロファイル

| profile | scope | platform |
|---|---|---|
| `host-wsl` | full | WSL（linux + Windows interop） |
| `host-darwin` | full | macOS |
| `host-ubuntu-server` | subset | linux（ヘッドレス + docker） |
| `devcontainer` | subset | linux |

## シークレット管理

`~/.secrets/shellenv` に環境変数を定義し、zshrc で存在確認してから source する。
このファイルは gitignore 対象外（ホームディレクトリ管理）のため、リポジトリには含まれない。

```sh
# ~/.secrets/shellenv
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
