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

# 残りの install フェーズ（mise/rust/sdk-go/shell/editor-nvim/cli-*/cli/agent-*）
# ここで初めて全モジュールを配置。_lib/apt/brew は前段から継承済み
COPY --parents \
        modules/*/install.sh \
        modules/*/env.sh \
        /opt/dotfiles/
COPY profiles /opt/dotfiles/profiles
# 各 install.sh は冪等なので、再 RUN しても has_cmd でスキップされる
RUN PHASE=install bash /opt/dotfiles/profiles/devcontainer.sh

# --------------------------------------------------------------------------- #
FROM install AS setup

# dotfiles を image に焼き込む（インストール層より後ろに置いてキャッシュ効率を保つ）
ARG USERNAME=ubuntu
COPY --chown=${USERNAME}:${USERNAME} . ${HOME}/.dotfiles

# claude plugin install が SSH URL を組み立てるケースに備え、HTTPS に強制リライト
# （イメージ内 gitconfig のみに反映、ホスト環境には影響しない）
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# setup フェーズ: symlink 配置・設定マージ
RUN PHASE=setup bash ${HOME}/.dotfiles/profiles/devcontainer.sh

# --------------------------------------------------------------------------- #
FROM setup AS updated

# update フェーズ: ツール・エージェント最新化（setup までのキャッシュを温存）
# 使い方: docker build --build-arg UPDATE_DATE=$(date +%Y-%V) --target updated .
ARG UPDATE_DATE
RUN PHASE=update bash ${HOME}/.dotfiles/profiles/devcontainer.sh
