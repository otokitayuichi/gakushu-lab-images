# 仕様コメント: Python基礎ラボ用イメージ（v7 / Azure Container Apps用）
# 目的: code-server(OSS版VS Code) + Python3 実行環境
# 実行基盤: Azure Container Apps（従量課金プラン、HTTPSの入口はContainer Apps標準機能を使用）
# イメージ保管: GitHub Container Registry（公開）。ビルドはGitHub Actionsで実施
# code-server固定理由: 日本語言語パック(1.131系)と内蔵VS Code(4.131.0=1.131.0)のバージョンを一致させるため
# v5からの変更: 状況確認用サーバー(8081)を廃止。Container AppsのHTTPの入口は1ポートのみ転送のため
# v6からの変更: ターミナルのプロンプトを短縮（Container Appsの長いコンテナ名を表示しない）
# ベース: Ubuntu 22.04 LTS

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CODE_SERVER_VERSION=4.131.0

# ---- ロケール・タイムゾーン ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
        tzdata \
    && locale-gen en_US.UTF-8 ja_JP.UTF-8 \
    && ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=Asia/Tokyo

# ---- 最小限のツールチェーン（python3 + pip） ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        python3 \
        python3-pip \
        git \
    && rm -rf /var/lib/apt/lists/*

# ---- code-server本体（GitHub Releasesから取得） ----
RUN curl -fsSL -o /tmp/code-server.tar.gz \
        "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" \
    && mkdir -p /opt/code-server \
    && tar -xzf /tmp/code-server.tar.gz -C /opt/code-server --strip-components=1 \
    && rm /tmp/code-server.tar.gz \
    && ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server

# ---- 非rootユーザー ----
RUN useradd -m -s /bin/bash student
USER student
WORKDIR /home/student

RUN mkdir -p /home/student/workspace

# ターミナルのプロンプトを短縮（例: student@lab:~/workspace$）
# ホスト名にはContainer Appsの長いコンテナ名が入るため、表示しない
RUN printf '\n# 受講者向けにプロンプトを短縮（コンテナ名を表示しない）\nPS1='"'"'\\[\\e[32m\\]\\u@lab\\[\\e[0m\\]:\\[\\e[34m\\]\\w\\[\\e[0m\\]\\$ '"'"'\n' >> /home/student/.bashrc

# gitのデフォルトID（教材でgit commitを使わせても落ちないようにする仮設定）
RUN git config --global user.name "student" \
    && git config --global user.email "student@lab.local" \
    && git config --global init.defaultBranch main

# ---- code-serverの設定 ----
RUN mkdir -p /home/student/.local/share/code-server/User
COPY --chown=student:student settings.json /home/student/.local/share/code-server/User/settings.json
COPY --chown=student:student argv.json /home/student/.local/share/code-server/User/argv.json

# ---- 拡張機能（すべてOpen VSXから取得。4.131.0で実機確認済み） ----
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension MS-CEINTL.vscode-language-pack-ja@1.131.0

# 言語パックの登録情報
# CLIでのインストールでは生成されない（coder/code-server Issue #4735、4.131.0で実機確認済み）ため、
# 画面からインストールした際に生成された実ファイルを組み込む（実機で日本語表示を確認済み）
COPY --chown=student:student languagepacks.json /home/student/.local/share/code-server/languagepacks.json

# ---- 起動スクリプト ----
COPY --chown=student:student entrypoint.sh /home/student/entrypoint.sh
USER root
RUN sed -i 's/\r$//' /home/student/entrypoint.sh \
    && chmod +x /home/student/entrypoint.sh
USER student

EXPOSE 8080

ENTRYPOINT ["/home/student/entrypoint.sh"]
