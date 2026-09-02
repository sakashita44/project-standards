# project-standards

新規プロジェクトのセットアップに使う設定ファイルの正本を管理するリポジトリ。新規リポジトリ作成時にコピーして使う。

## 前提

- uv と Node.js が PATH にあること
- issue/PR テンプレートの既定値は [sakashita44/.github](https://github.com/sakashita44/.github) が public リポジトリに自動適用する

## 二層モデル

セットアップ資産は役割の異なる 2 つのリポジトリに分かれる。

| リポジトリ                        | 役割                                                | 更新の伝搬                                   |
| --------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| sakashita44/.github               | issue/PR テンプレートの既定提供と reusable workflow | 参照時に常に最新が使われる                   |
| project-standards（本リポジトリ） | コピーして使う設定ファイルの正本                    | 伝搬しない（コピー後は各リポジトリで育てる） |

コピーした設定はスナップショットであり、以後の変更は展開先リポジトリの裁量で行う。展開先で生まれた改善が汎用的なら本リポジトリへ還流させる。

## ディレクトリ構成

```text
project-standards/
├── general/    # 全プロジェクト種別で共用する設定
├── ts/         # TypeScript/Node プロジェクト用
├── python/     # Python プロジェクト用
└── mixed/      # 多言語混在プロジェクト用（C/C++, CMake を含む）
```

general/ の `.config/` 配下（prettier, markdownlint 等）は全種別の正本である。TS 系のフック（lint-staged）と Python/複合系のフック（pre-commit）はいずれも同じ `.config/` のファイルを参照するため、展開先でも設定の実体は 1 部で済む。

## 展開手順

1. general/ の内容をリポジトリルートへコピーする
1. プロジェクト種別のディレクトリ（ts/, python/, mixed/ のいずれか）の内容を重ねてコピーする
1. `*.template` ファイルは拡張子 `.template` を外し、`PLACEHOLDER_` で始まる値を実値に置換する
1. `github-workflows/ci.yml` を `.github/workflows/ci.yml` へ移動する
1. `dependabot.yml` を `.github/dependabot.yml` へ移動し、使用するエコシステムのコメントアウトを解除する
1. フックを有効化する
    - ts: `npm install`（`prepare` スクリプトで husky が有効化される）
    - python/mixed: `bash scripts/setup.sh`
1. public リポジトリでは `general/.github/`（issue/PR テンプレート）のコピーを省略できる。sakashita44/.github の既定が適用される。private リポジトリには既定が適用されないためコピーが必要

## フック機構

| プロジェクト種別 | フック機構           | 実行基盤 |
| ---------------- | -------------------- | -------- |
| ts               | husky + lint-staged  | npm      |
| python, mixed    | pre-commit framework | uv       |

各エコシステム内で完結させ、TS プロジェクトに Python を要求しない。両者が適用するフォーマット・リント規則は `.config/` の共通設定により一致する。

## CI

`ci.yml`（caller）は各リポジトリにコピーされ、ジョブの実体は sakashita44/.github の reusable workflow を参照する。

- トリガーは main への pull request。main へ直接 push する運用のリポジトリでは push トリガーを追加する
- reusable workflow の内容更新は参照側の変更なしに反映される。固定したい場合は `@main` をタグ参照に変える
