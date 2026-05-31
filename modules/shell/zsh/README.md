# zsh 設定

最も複雑なサブシステム。3つのフェーズで段階的に読み込む。

## 起動シーケンス

```
~/.zshenv（シンボリックリンク → config/zsh/.zshenv）
  ├─ source _lib/bootstrap.sh  # DOTFILES_DIR / XDG 変数 / is_wsl・is_darwin
  ├─ ZDOTDIR=$XDG_CONFIG_HOME/zsh/
  ├─ _zsh.load() 関数定義
  └─ _zsh.load zshenv

$ZDOTDIR/.zshrc
  ├─ source external/lazyenv/lazyenv.bash
  ├─ lazyenv.shell.loadstart
  ├─ _zsh.load zshrc
  └─ lazyenv.shell.loadfinish

$ZDOTDIR/.zlogin
  └─ _zsh.load zlogin
```

## `_zsh.load` の仕組み

`_zsh.load <phase>` は以下の順で source する:

1. `rc.d/<phase>/*` — 共通ファイル（`/bin/ls` 順 = 数字順）
2. `~/.local/config/<phase>/*` — マシン固有のローカルオーバーライド

`.` プレフィックスのファイルは `/bin/ls` の glob `*` に一致しないためスキップされる。

## フェーズの役割

| フェーズ | 実行タイミング | 用途 |
|---------|--------------|------|
| zshenv  | 全シェル（非対話含む） | PATH、環境変数、LANG |
| zshrc   | 対話シェル | setopt、alias、キーバインド、lazyenv による言語ランタイム |
| zlogin  | ログインシェル | compinit、補完、プロンプト、fzf、プラグイン |

## ファイル番号体系

| 番号帯 | 用途 | 例 |
|--------|------|-----|
| 00_    | 基盤設定 | `00_init.zsh`（PATH、setopt） |
| 01_-03_ | 基本ツール | `01_ssh.zsh`、`02_alias.zsh`、`03_grep.zsh` |
| 05_    | 各種設定 | `05_python.zsh`、`05_completion.zsh` |
| 07_-10_ | 追加ツール | `07_asdf.zsh`、`10_android.zsh` |
| 95_    | モジュール | `95_modules.zsh`（zsh プラグイン読み込み） |
| 99_    | 最終設定 | `99_fzf.zsh`、`99_notification.zsh` |

## 重要な変数

| 変数 | 内容 |
|------|------|
| `$ZDOTDIR` | `~/.config/zsh/`（= `modules/shell/zsh/` へのシンボリックリンク先） |
| `$DOTFILES_EXTERNAL_DIR` | `external/` ディレクトリへの絶対パス（`bootstrap.sh` で定義） |

## lazyenv パターン

言語ランタイム（pyenv, rbenv, nodenv, goenv, jenv）の `eval "$(xxx init -)"` は遅い。lazyenv でコマンド初回呼び出しまで遅延する:

```zsh
_pyenv_init() {
    export PYENV_ROOT=$HOME/.local/env/pyenv
    eval "$(pyenv init -)"
}
eval "$(lazyenv.load _pyenv_init pyenv python pip)"
```

`lazyenv.load <init_func> <cmd>...` は各コマンドのスタブ関数を定義し、初回実行時に `init_func` を呼んでから本物のコマンドに委譲する。

`lazyenv.shell.loadstart` / `loadfinish` の間（.zshrc 読み込み中）はスタブがバイパスされ、直接 `command $cmd` が呼ばれる。

## プラグイン読み込み順序（重要）

zlogin フェーズ内で以下の順序を守ること:

```
05_completion.zsh:  compinit → fzf-tab
95_modules.zsh:     zsh-autosuggestions → zsh-syntax-highlighting
```

制約:
- **compinit は zlogin フェーズ**で実行（zshrc では使用不可）
- **fzf-tab** は compinit の後、autosuggestions/syntax-highlighting の前
- **zsh-autosuggestions** は zsh-syntax-highlighting の前

## キーバインド

### コマンド履歴検索

- `Ctrl + p` / `Ctrl + n` — 入力文字列と前方一致するコマンド履歴
- `Ctrl + r` — インクリメンタルサーチ

### ディレクトリ移動

- ディレクトリ名だけ入力すれば `cd` なしで移動
- `popd` / `pd` — 一つ前のディレクトリに戻る
- `j` — 利用したことのあるディレクトリをインクリメンタルサーチ

### ファイル検索

- `Ctrl + f` — カレントディレクトリ以下のファイルをインクリメンタルサーチ
- `Ctrl + gf` — git 管理されているファイルをインクリメンタルサーチ

## 新規ファイル追加手順

1. 適切なフェーズの `rc.d/<phase>/` に配置
2. 数字プレフィックスで順序を制御（既存ファイルの番号体系に従う）
3. プラットフォーム固有なら `rc.d/<phase>/<platform>/` に配置
4. 無効化したい場合は `.` プレフィックスを付ける
