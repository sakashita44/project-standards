#!/usr/bin/env bash
# ホスト環境の初期セットアップ
set -euo pipefail
npm install
# uvx の一時環境は cache 削除で消え、フックが記録する Python の絶対パスが失われるため永続環境へ導入する
uv tool install pre-commit
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
