#!/usr/bin/env bash
# ホスト環境の初期セットアップ
set -euo pipefail
npm install
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
