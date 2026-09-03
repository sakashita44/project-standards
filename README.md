# project-standards

新規リポジトリへコピーして使う設定ファイルの正本。コピー後の変更は展開先の裁量とし、汎用的な改善は本リポジトリへ戻す。

## ディレクトリ構成

```text
general/    # 全プロジェクト種別で共用する設定
ts/         # TypeScript/Node プロジェクト用
python/     # Python プロジェクト用
c/          # C/C++, CMake の整形資産。python/ に重ねる追加レイヤ
```

issue/PR テンプレートは [sakashita44/.github](https://github.com/sakashita44/.github) が全リポジトリへ既定として適用するため、本リポジトリでは配布しない。

## 展開手順

### 開始条件

- 展開先のリポジトリを作成済み
- ts: Node.js が PATH にある
- python, c: uv が PATH にある

### 手順

1. `general/` の内容をリポジトリルートへコピーする
1. プロジェクト種別の内容をルートへ重ねてコピーする。ts は `ts/`、python は `python/`、C/C++ を含む場合は `python/` の上へ `c/` を重ねる
1. `*.template` から拡張子 `.template` を外し、`PLACEHOLDER_` で始まる値を実値へ置換する
1. `.gitignore` を [github/gitignore](https://github.com/github/gitignore) のテンプレートで置き換え、リポジトリ固有の除外を追加する
1. `github-workflows/ci.yml` を `.github/workflows/ci.yml` へ移す
1. `dependabot.yml` を `.github/dependabot.yml` へ移し、使用するエコシステムのコメントアウトを解除する
1. フックを有効化する
    - ts: `npm install`（`prepare` スクリプトが husky を有効化する）
    - python, c: `bash scripts/setup.sh`

### 動作確認

- ts: ファイルを変更してコミットし、lint-staged が prettier と eslint を実行する
- python, c: `uv run pre-commit run --all-files` が全フックを通過する
- 全種別: push すると型検査が走る
- 全種別: main への pull request を作成し、`ci.yml` のジョブが起動する

## 検証の段

判定に何が必要かで実行タイミングを分ける。単一ファイルで判定できるものをコミット時、リポジトリ全体を見ないと判定できないものを push 時、手元では再現しない条件を CI に置く。

| タイミング   | 内容                                       | 応答                     |
| ------------ | ------------------------------------------ | ------------------------ |
| コミット時   | 整形、単一ファイルのリント、シークレット検出 | 自動修正、またはブロック |
| push 時      | 型検査                                     | ブロックのみ             |
| pull request | クリーン環境での全ファイル検査             | ブロックのみ             |

CI でしか落ちない項目が増えたら、前段へ下ろすべきものが混ざっている合図として扱う。

### プロジェクト種別ごとの実装

| プロジェクト種別 | コミット時           | push 時        | 実行基盤 |
| ---------------- | -------------------- | -------------- | -------- |
| ts               | husky + lint-staged  | `tsc --noEmit` | npm      |
| python, c        | pre-commit framework | pyright        | uv       |

pyright は pre-commit の隔離環境ではプロジェクトの依存を解決できないため、uv の仮想環境を使う local フックとして実行する。

シークレット検出には gitleaks を使う。pre-commit framework に載る python と c では、コミット時のフックとしてステージ済みの差分を検査する。ts は pre-commit framework に載らず、gitleaks を導入するにはバイナリを PATH へ置く前提にするか信頼性の低い npm ラッパーへ依存するかになるため配布しない。public リポジトリでは GitHub の secret scanning push protection が push の時点で同じ役割を担う。

テストは push 時の枠をフック設定にコメントとして用意してある。テストを書いた時点でコメントを外す。CI はテストが存在する場合だけ実行する。

## CI

`ci.yml` は sakashita44/.github の reusable workflow を呼び出す。ジョブの内容を変えるときは参照先を編集する。

- トリガーは main への pull request。main へ直接 push する運用では push トリガーを追加する

## ランタイムの版

Python と Node.js の版は、展開先の `.python-version` と `.nvmrc` が定める。reusable workflow はこれらのファイルがあればその値を使い、無い場合だけワークフロー側の既定値を使う。本リポジトリが配布する値は開始時点のものであり、展開先は正本の更新を待たずに書き換えてよい。

Python では `pyproject.toml` の `requires-python` が下限を定める。ruff の対象版はここから推論されるため、`ruff.toml` へ `target-version` を書かない。
