# syntax=docker/dockerfile:1.7-labs
FROM ubuntu:24.04 AS base

ARG USERNAME=ubuntu

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    DEVCONTAINER=1 \
    SHELL=/usr/bin/zsh

# 最小ブートストラップ: sudo / zsh（user の login shell）/ locale / ca 証明書
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo zsh ca-certificates locales tzdata \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 base 既存の ubuntu(uid=1000) ユーザに passwordless sudo を付与し
# login shell を zsh に変更
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
 && chmod 0440 /etc/sudoers.d/$USERNAME \
 && usermod -s /usr/bin/zsh $USERNAME

# --------------------------------------------------------------------------- #
FROM base AS apt

# root: apt モジュール経由で残りのシステムパッケージ
USER root
# _lib/ + apt/ のみ。他モジュールを編集しても apt キャッシュを保つ
COPY --parents \
        modules/_lib/ \
        modules/apt/ \
        /opt/dotfiles/
RUN bash /opt/dotfiles/modules/apt/install.sh \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #
FROM apt AS brew

# 以降は非 root (brew は root 実行を拒否するため)
ARG USERNAME=ubuntu
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
ENV PATH="/home/ubuntu/.local/bin:/home/ubuntu/.local/share/mise/shims:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# brew は単独 RUN（重いので分離してキャッシュ）
COPY --parents modules/brew/ /opt/dotfiles/
RUN bash /opt/dotfiles/modules/brew/install.sh

# --------------------------------------------------------------------------- #
FROM brew AS install

# 各ステージは dotfiles → agent-module の順に閉じる。
# install: ツール本体のインストール（claude CLI 公式 installer 等もここ）。

# (1) dotfiles install — 残り全モジュール（mise/rust/sdk-go/shell/editor-nvim/cli）
COPY --parents \
        modules/*/install.sh \
        modules/*/env.sh \
        /opt/dotfiles/
COPY profiles /opt/dotfiles/profiles
# 各 install.sh は冪等なので、再 RUN しても has_cmd でスキップされる
RUN PHASE=install bash /opt/dotfiles/profiles/devcontainer.sh

# (2) agent-module install — claude / codex / gemini / mcp-servers / skills 等の本体。
# キャッシュ効率のため、install フェーズに必要な最小集合のみ COPY する
# (modules/<m>/setup.sh や設定アセットは setup ステージで ~/agent-module へフル COPY)。
# build.sh が --build-context agent-module=... を渡す（不在時は空コンテキストでスキップ）。
COPY --from=agent-module --parents \
        _lib/ \
        profiles/ \
        modules/*/install.sh \
        modules/*/env.sh \
        /opt/agent-module/
RUN DOTFILES_DIR=/opt/dotfiles AGENT_MODULE_DIR=/opt/agent-module \
    PHASE=install bash /opt/agent-module/profiles/devcontainer.sh

# --------------------------------------------------------------------------- #
FROM install AS setup

# dotfiles と agent-module を image に焼き込む（インストール層より後ろに置いてキャッシュ効率を保つ）。
# 配置先 ~/agent-module は ~/.dotfiles/../agent-module と一致するため、
# 他 profile (host-*) のシム `$DOTFILES_DIR/../agent-module` 参照とも整合する。
# .git は不要（dotfiles と同様コピーのみ。git 操作はホスト側で行う）。
ARG USERNAME=ubuntu
COPY --chown=${USERNAME}:${USERNAME} . ${HOME}/.dotfiles
COPY --from=agent-module --exclude=.git --chown=${USERNAME}:${USERNAME} . ${HOME}/agent-module

# claude plugin install が SSH URL を組み立てるケースに備え、HTTPS に強制リライト
# （イメージ内 gitconfig のみに反映、ホスト環境には影響しない）
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# setup フェーズ: symlink 配置・設定マージ
# (1) dotfiles setup
RUN PHASE=setup bash ${HOME}/.dotfiles/profiles/devcontainer.sh
# (2) agent-module setup — claude plugin / settings.json マージなど
RUN DOTFILES_DIR=${HOME}/.dotfiles AGENT_MODULE_DIR=${HOME}/agent-module \
    PHASE=setup bash ${HOME}/agent-module/profiles/devcontainer.sh

# nvim プラグインを焼き込む（~/.config/nvim symlink が張られた後）
# lazy-lock.json が変わるまで layer キャッシュが効く
RUN nvim --headless "+Lazy! restore" +qa \
 && nvim --headless "+TSUpdateSync" +qa

# --------------------------------------------------------------------------- #
FROM setup AS updated

# update フェーズ: ツール・エージェント最新化（setup までのキャッシュを温存）
# 使い方: docker build --build-arg UPDATE_DATE=$(date +%Y-%V) --target updated .
ARG UPDATE_DATE
# (1) dotfiles update
RUN PHASE=update bash ${HOME}/.dotfiles/profiles/devcontainer.sh
# (2) agent-module update
RUN DOTFILES_DIR=${HOME}/.dotfiles AGENT_MODULE_DIR=${HOME}/agent-module \
    PHASE=update bash ${HOME}/agent-module/profiles/devcontainer.sh
