#!/bin/bash
# 仕様コメント: ラボコンテナの起動スクリプト（v6 / Azure Container Apps用）
# 役割:
#   1. fork bomb対策としてプロセス数上限(ulimit)を設定
#   2. 教材データのコピー（Lab Controllerが発行する短命SAS付きURLを環境変数で受け取る）
#      - LAB_MATERIAL_URL     : URLをそのまま渡す場合
#      - LAB_MATERIAL_URL_B64 : URLをBase64で渡す場合（Windowsのaz CLIで & を含むURLを安全に渡すため）
#      - 取得・展開に失敗しても終了せず、ワークスペースに失敗の旨を記したファイルを置いてエディタを起動する
#        （Container Appsはコンテナが終了すると再起動するため、終了させると失敗の繰り返しになる）
#   3. code-serverを起動（--authはパスワードの有無で自動切り替え）
# v5からの変更:
#   - 状況確認用サーバー(8081)と段階記録を廃止（エディタの応答開始はcode-serverの /healthz で確認する）
#   - アイドル終了・最大セッション時間の監視処理を廃止
#     （アイドル時はContainer Appsのゼロへの縮小、最大時間はLab Controllerが管理する想定）
set -uo pipefail

# ---- 1. プロセス数上限（fork bomb対策） ----
ulimit -u 128

# ---- 2. 教材データのコピー（任意） ----
MATERIAL_URL="${LAB_MATERIAL_URL:-}"
if [ -z "${MATERIAL_URL}" ] && [ -n "${LAB_MATERIAL_URL_B64:-}" ]; then
  MATERIAL_URL="$(echo "${LAB_MATERIAL_URL_B64}" | base64 -d)"
fi

if [ -n "${MATERIAL_URL}" ]; then
  echo "[entrypoint] 教材データを取得しています..."
  if curl -fsSL "${MATERIAL_URL}" -o /tmp/material.tar.gz \
     && tar -xzf /tmp/material.tar.gz -C /home/student/workspace; then
    echo "[entrypoint] 教材データの展開が完了しました"
  else
    echo "[entrypoint] 教材データの取得または展開に失敗しました"
    echo "教材の取得に失敗しました。講師またはサポートに連絡してください。" \
      > /home/student/workspace/教材取得エラー.txt
  fi
  rm -f /tmp/material.tar.gz
else
  echo "[entrypoint] 教材URL未指定のため教材コピーをスキップします"
fi

# ---- 3. code-server起動 ----
if [ -n "${CODE_SERVER_PASSWORD:-}" ]; then
  export PASSWORD="${CODE_SERVER_PASSWORD}"
  AUTH_MODE="password"
else
  echo "[entrypoint] 警告: CODE_SERVER_PASSWORD未指定のため無認証で起動します（検証用途以外では使用しないこと）"
  AUTH_MODE="none"
fi

exec code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth "${AUTH_MODE}" \
  --disable-telemetry \
  --disable-update-check \
  --locale ja \
  /home/student/workspace
