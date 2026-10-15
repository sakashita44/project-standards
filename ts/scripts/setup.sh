#!/usr/bin/env bash
# ホスト環境の初期セットアップ
set -euo pipefail
npm install
# uvx の一時環境は cache 削除で消え、フックが記録する Python の絶対パスが失われるため永続環境へ導入する
uv tool install pre-commit
# uv の tool の bin ディレクトリは PATH に含まれない環境があるため uvx で呼ぶ。uvx は上で導入した永続環境の pre-commit を使う
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
