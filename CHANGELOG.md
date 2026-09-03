# Changelog

[Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) と [Semantic Versioning](https://semver.org/lang/ja/) に準拠する。

## [Unreleased]

### Added

- pyright を Python の開発依存へ追加し、`[tool.pyright]` で strict を既定にした
- TypeScript に `typecheck` スクリプト（`tsc --noEmit`）と `tsconfig.json` を追加
- push 時に型検査を実行するフックを追加（ts は `.husky/pre-push`、python/c は pre-commit の pre-push ステージ）
- ruff の `select` を明示（既定の `E4,E7,E9,F` のみが有効な状態だった）

### Changed

- README を展開作業の完了に必要な情報へ整理し、動作確認の手順と検証の段を追加
- `mixed/` を `c/` へリネーム。単独では成立せず `python/` へ重ねる C/C++ 向けの追加レイヤであるため
- `vitest run` に `--passWithNoTests` を追加。テストのないリポジトリで失敗しないようにするため
- pyright フックを `always_run` にした。`types` で絞ると Python ファイルを含まない push でスキップされ、依存やロックファイルだけを変えた push で型検査が走らなかったため
- `tsconfig.json` の `include` を既定へ戻し、`src/` 外の TypeScript も型検査の対象にした
- ruff の `ignore` に `W191`、`E111`、`E114`、`E117` を追加。ruff-format が整形する内容でリントが先に失敗するため
- pre-commit の各フックを最新へ更新（ruff `v0.16.5`、markdownlint-cli2 `v0.23.2`、pre-commit-hooks `v6.0.0`、clang-format `v23.1.0`）。あわせて ruff の hook id を `ruff` から `ruff-check` へ変更し、開発依存の下限も `ruff>=0.16.5` に揃えた

### Removed

- 配布資産から issue/PR テンプレート（`general/.github/`）を削除。sakashita44/.github の既定が visibility を問わず全リポジトリへ適用されるため
- `docs/decisions.md` を削除。棄却理由はコミットログへ転記した
