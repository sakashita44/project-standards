# Changelog

変更を日付ごとに記録する。分類は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に倣う。

設定はコピーした時点のスナップショットであり、展開先へは伝搬しない。展開先が現在の正本との差分を知るには、そのリポジトリを作成した日付以降の項目を読む。

## 2026-09-03

### Added

- Python の型検査に pyright を導入（開発依存と `[tool.pyright]` の strict 設定）
- TypeScript の型検査を実行する `typecheck` スクリプト（`tsc --noEmit`）と `tsconfig.json`
- push 時にリポジトリ全体の型検査を実行するフック（ts は `.husky/pre-push`、python/c は pre-commit の pre-push ステージ）
- ruff の `select` と `ignore` の明示。既定の `E4,E7,E9,F` のみが有効で、ruff-format と競合する規則も整理されていなかった
- シークレット検出のフック gitleaks（python, c）。ts は pre-commit framework に載らず配布手段が無いため、GitHub の secret scanning push protection に委ねる
- 展開先へ配布する `.gitignore`（general）。従来は展開手順を実行しても展開先へ `.gitignore` が入らなかった。内容はプロジェクトごとに変わるため、github/gitignore のテンプレートで差し替える旨のコメントだけを置いたプレースホルダとした
- ランタイムの版を固定する `.python-version` と `.nvmrc`。sakashita44/.github の reusable workflow はこれらがあればその値を使うため、CI の版がワークフロー側の既定値に固定されなくなった
- pre-commit-hooks の `check-merge-conflict`、`check-yaml`、`check-added-large-files`
- dependabot の `groups`。major を含む全更新をエコシステムごとに 1 つの pull request へ集約する。あわせて特定の依存で更新を止める `ignore` の雛形をコメントで置いた

### Changed

- `mixed/` を `c/` へリネーム。単独では成立せず `python/` へ重ねる C/C++ 向けの追加レイヤであるため
- `vitest run` に `--passWithNoTests` を追加。テストのないリポジトリで失敗しないようにするため
- pre-commit の各フックを最新へ更新（ruff `v0.16.5`、markdownlint-cli2 `v0.23.2`、pre-commit-hooks `v6.0.0`、clang-format `v23.1.0`）。ruff の hook id を `ruff-check` へ、開発依存の下限を `ruff>=0.16.5` へ揃えた
- 設定ファイルを `.config/` から、展開先でリポジトリルートへ並ぶ位置へ移動。各ツールは対象ファイルから上位ディレクトリへ遡る探索しか行わず、`.config/` は全呼び出しでの `--config` 指定とエディタ側への経路指定を要求していた。約 20 箇所の設定パス指定が不要になった
- markdownlint の設定を `.markdownlint-cli2.jsonc` へ集約し、除外指定を `gitignore` オプションへ移した
- prettier の対象から toml を外し、`prettier-plugin-toml` への依存を削除。Prettier 3 はプラグインを自動読み込みせず、`--plugin` や設定の `plugins` で指定してもプラグインを対象ファイル側から解決するため、pre-commit の隔離環境へ入れたプラグインは読み込めない。`types_or` の `toml` は依存に入っていても機能しておらず、明示指定するとフック自体が失敗する
- 配布する設定ファイル自身を prettier の整形結果へ揃えた（`dependabot.yml`、`.markdownlint-cli2.jsonc`、`.pre-commit-config.yaml`、`.cmake-format.yaml`）。`.prettierrc` の `singleQuote` に対して二重引用符のまま配布しており、展開直後の検査で整形差分が出ていた
- prettier と markdownlint-cli2 の版を層をまたいで統一（prettier `3.9.6`、markdownlint-cli2 `0.23.2`）。同じ設定を共有しながら実行される版が層ごとに違い、同じファイルの整形結果がぶれていた
- `ruff.toml` から `target-version` を削除。設定ファイルを `--config` で渡さなくなったため `requires-python` から推論され、Python の版の記述が一箇所に収まる
- `c/.pre-commit-config.yaml` へ、python 側との同期方法を示すコメントと C/C++ 固有部分の境界を追加。pre-commit に設定の include/extends が無く、全文複製が避けられないため
- `.lintstagedrc.json` の対象へ yaml を追加
- README を展開作業に必要な情報へ整理し、検証の段とランタイムの版を追加

### Removed

- 配布資産から issue/PR テンプレート（`general/.github/`）を削除。sakashita44/.github の既定が visibility を問わず全リポジトリへ適用されるため
- `docs/decisions.md` を削除。棄却理由はコミットログへ転記した
- `.markdownlintignore` を削除。markdownlint-cli2 はこのファイルを読まず、どの呼び出しからも渡されていなかった
- prettier と markdownlint の設定パスを指す `.vscode/settings.json` の記述を削除。設定がルートへ移り、エディタが自力で探索できるようになったため
