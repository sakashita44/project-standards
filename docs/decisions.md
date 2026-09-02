# 設計判断の記録

## 二層分離

issue/PR テンプレートと reusable workflow は sakashita44/.github に、コピーして使う設定ファイルは project-standards に置く。前者は GitHub が参照時に解決するため更新が全リポジトリへ即時に波及し、後者はコピー時点のスナップショットとして展開先で独立に育つ。性質の異なる 2 つの配布形態を 1 リポジトリに混在させると、どのファイルが波及しどれがコピーかの区別が付かなくなる。

## スナップショット配布

設定は展開時にコピーし、以後の自動更新は行わない。テンプレートリポジトリ方式（devcon シリーズ）は本家の改善が展開先に届かず、本家自体も陳腐化して停止した。この構造は避けられないものとして受け入れ、「本家に追従する」のでなく「展開先で育て、汎用的な改善を正本へ還流する」一方向の流れとする。

## 設定の .config/ 集約

prettier, markdownlint, ruff, clang-format 等の設定ファイルは展開先の `.config/` に集約する（MALO2 で実証済みの方式）。ルート直下にはツールが位置を強制するファイル（eslint.config.mjs, pyproject.toml, .pre-commit-config.yaml, package.json 等）のみを置く。エディタは `.config/` を自動解決しないため、`.vscode/settings.json` に `prettier.configPath` 等のパス指定を同梱する。

## フック機構の使い分け

- ts: husky + lint-staged。npm のみで完結し、Python への依存を持たない
- python/mixed: pre-commit framework。uv のみで完結する。多言語リポジトリ（prettier + clang-format + cmake-format + ruff）でも単一のフック設定で機能することは MALO2 で実証済み

依存は少ないほど良いという原則により、言語横断の単一機構への統一よりエコシステム内完結を優先する。

## prettier の pre-commit ミラー

pre-commit/mirrors-prettier はアーカイブ済みで、v4.0.0-alpha.8 が最終版である。現状動作しているためこの pin で運用を続け、破綻した時点で local フック（node 実行）へ切り替える。

## CI の構成

- ジョブの実体（reusable workflow）は sakashita44/.github に置く。public リポジトリの reusable workflow は private リポジトリからも呼び出せる
- caller は project-standards からコピーして配布する。starter workflow（workflow-templates）は組織アカウント限定の機能であり、個人アカウントでは新規 workflow 作成 UI に表示されないため採用しない
- `@main` 参照により reusable workflow の改善は自動で反映される。破壊的変更をしたくなった時点でタグ運用へ移行する

## テスト配置

- python: ルートの `tests/` ディレクトリ（pytest の標準）
- ts: `src/` 内に `*.test.ts` を併置（vitest の慣行）

既存リポジトリでは 4 方式が混在していたため、各エコシステムのベストプラクティスに揃える。

## 設定内容の統一

複数リポジトリ間で差異があった設定は次の基準で統一した。

- prettier: `tabWidth: 4, singleQuote: true, proseWrap: "preserve"`（Geonal/kancolle-scrap-manager の完全一致版）
- markdownlint: Geonal/kancolle-scrap-manager の詳細版
- ruff: `target-version = "py313"`（最新リポジトリの MALO2 に合わせ、`requires-python` も `>=3.13` で統一）
- eslint: `@eslint/js` + `typescript-eslint` の recommended 構成に未使用変数の `^_` 許可のみを加えた汎用形。フレームワーク固有プラグイン（react-hooks 等）は展開先で追加する
- pyproject の build-system: 既定でコメントアウト。uv_build は `src/<パッケージ名>/` レイアウトを要求するため、配布パッケージの場合のみ有効化する
- dependabot: github-actions エコシステムは常時有効、npm/uv は使用時に有効化する

## devcontainer の不採用

開発環境はリポジトリに焼き込まず、マシン単位の portable ツールチェーン（`Workspace/tools/` + Set-Env.ps1）に任せる。リポジトリ側は「uv / node が PATH にある」ことのみを前提とし、セットアップは `uv sync` や `npm install` 程度の薄い層に留める。環境をリポジトリに内包する方式はイメージが重く、テンプレートの陳腐化と一体で放棄された経緯がある。

## CLAUDE.md の対象外

CLAUDE.md は /init スキルの出力であり、本リポジトリでは正本を持たない。出力の調整が必要になった場合はグローバル CLAUDE.md への指示追記で対応する。
