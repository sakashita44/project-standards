#!/usr/bin/env bash
# ホスト環境の初期セットアップ
set -euo pipefail
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
