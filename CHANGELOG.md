# Changelog

[Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) と [Semantic Versioning](https://semver.org/lang/ja/) に準拠する。

## [Unreleased]

### Added

- Python の型検査に pyright を導入（開発依存と `[tool.pyright]` の strict 設定）
- TypeScript の型検査を実行する `typecheck` スクリプト（`tsc --noEmit`）と `tsconfig.json`
- push 時にリポジトリ全体の型検査を実行するフック（ts は `.husky/pre-push`、python/c は pre-commit の pre-push ステージ）
- ruff の `select` と `ignore` の明示。既定の `E4,E7,E9,F` のみが有効で、ruff-format と競合する規則も整理されていなかった

### Changed

- `mixed/` を `c/` へリネーム。単独では成立せず `python/` へ重ねる C/C++ 向けの追加レイヤであるため
- `vitest run` に `--passWithNoTests` を追加。テストのないリポジトリで失敗しないようにするため
- pre-commit の各フックを最新へ更新（ruff `v0.16.5`、markdownlint-cli2 `v0.23.2`、pre-commit-hooks `v6.0.0`、clang-format `v23.1.0`）。ruff の hook id を `ruff-check` へ、開発依存の下限を `ruff>=0.16.5` へ揃えた
- README を展開作業に必要な情報へ整理し、検証の段を追加

### Removed

- 配布資産から issue/PR テンプレート（`general/.github/`）を削除。sakashita44/.github の既定が visibility を問わず全リポジトリへ適用されるため
- `docs/decisions.md` を削除。棄却理由はコミットログへ転記した
