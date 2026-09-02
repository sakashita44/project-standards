# project-standards

新規リポジトリへコピーして使う設定ファイルの正本。コピー後の変更は展開先の裁量とし、汎用的な改善は本リポジトリへ戻す。

## ディレクトリ構成

```text
general/    # 全プロジェクト種別で共用する設定
ts/         # TypeScript/Node プロジェクト用
python/     # Python プロジェクト用
mixed/      # 多言語混在プロジェクト用（C/C++, CMake を含む。python/ に重ねて使う）
```

`general/.config/` に prettier、markdownlint 等の共通設定を置く。ts、python、mixed のいずれもこの設定を参照する。

issue/PR テンプレートは [sakashita44/.github](https://github.com/sakashita44/.github) が全リポジトリへ既定として適用する。

## 展開手順

### 開始条件

- 展開先のリポジトリを作成済み
- ts: Node.js が PATH にある
- python, mixed: uv が PATH にある

### 手順

1. `general/` の内容をリポジトリルートへコピーする
1. プロジェクト種別の内容をルートへ重ねてコピーする。ts は `ts/`、python は `python/`、mixed は `python/` の上へ `mixed/` を重ねる
1. `*.template` から拡張子 `.template` を外し、`PLACEHOLDER_` で始まる値を実値へ置換する
1. `github-workflows/ci.yml` を `.github/workflows/ci.yml` へ移す
1. `dependabot.yml` を `.github/dependabot.yml` へ移し、使用するエコシステムのコメントアウトを解除する
1. フックを有効化する
    - ts: `npm install`（`prepare` スクリプトが husky を有効化する）
    - python, mixed: `bash scripts/setup.sh`

### 動作確認

- ts: ファイルを変更してコミットし、lint-staged が prettier と eslint を実行する
- python, mixed: `uv run pre-commit run --all-files` が全フックを通過する
- 全種別: main への pull request を作成し、`ci.yml` のジョブが起動する

## フック機構

| プロジェクト種別 | フック機構           | 実行基盤 |
| ---------------- | -------------------- | -------- |
| ts               | husky + lint-staged  | npm      |
| python, mixed    | pre-commit framework | uv       |

## CI

`ci.yml` は sakashita44/.github の reusable workflow を呼び出す。ジョブの内容を変えるときは参照先を編集する。

- トリガーは main への pull request。main へ直接 push する運用では push トリガーを追加する
