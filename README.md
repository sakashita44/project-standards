# project-standards

新規リポジトリへコピーして使う設定ファイルの正本。コピー後の変更は展開先の裁量とし、汎用的な改善は本リポジトリへ戻す。本リポジトリは展開済みのリポジトリを更新しない。

## ディレクトリ構成

```text
general/       # 全プロジェクト種別で共用する設定と共通の品質ゲート
ts/            # TypeScript/Node プロジェクト用
python/        # Python プロジェクト用
c/             # C/C++, CMake の整形資産。python/ に重ねる追加レイヤ
verification/  # 配布物自身へ品質ゲートを掛けるための検証対象
```

`general/` だけで品質ゲートが成立する。実装言語を持たないリポジトリは `general/` のみを展開する。言語別レイヤは、共通ゲートへ自身の検査を追加する差分だけを持つ。

issue/PR テンプレートは [sakashita44/.github](https://github.com/sakashita44/.github) が全リポジトリへ既定として適用するため、本リポジトリでは配布しない。

ルート直下の設定ファイルと `.github/workflows/ci.yml` は、本リポジトリ自身へ `general/` を展開した結果である。配布する設定が自身の検査を通ることを品質ゲートで保つため、`general/` を変更したときはルートへも反映する。ルート固有の調整は各ファイルへ理由とともに書く。

## 展開手順

### 開始条件

- 展開先のリポジトリを作成済み
- 全種別: uv が PATH にある
- ts: 加えて Node.js が PATH にある

### 手順

1. `general/` の内容をリポジトリルートへコピーする
1. プロジェクト種別の内容をルートへ重ねてコピーする。ts は `ts/`、python は `python/`、C/C++ を含む場合は `python/` の上へ `c/` を重ねる。実装言語を持たないリポジトリはこの手順を飛ばす
1. 言語別レイヤの追加フックを共通ゲートへ合成する。`.pre-commit-config.<種別>.yaml` の内容を `.pre-commit-config.yaml` の末尾へ追記し、追記元を削除する。c は python の追記に続けて c の追記を行う

    ```bash
    cat .pre-commit-config.python.yaml >> .pre-commit-config.yaml && rm .pre-commit-config.python.yaml
    ```

    この追記は展開時の一度きりの操作である。設定を取り込み直す目的で `general/` を再コピーすると、追記済みの内容が失われるか二重に追記される。再コピー後は合成結果を目視で確認のこと

1. `*.template` から拡張子 `.template` を外し、`PLACEHOLDER_` で始まる値を実値へ置換する
1. `.gitignore` を [github/gitignore](https://github.com/github/gitignore) のテンプレートで置き換え、リポジトリ固有の除外を追加する
1. `github-workflows/ci.yml` を `.github/workflows/ci.yml` へ移す
1. `dependabot.yml` を `.github/dependabot.yml` へ移し、使用するエコシステムのコメントアウトを解除する
1. フックを有効化する
    - 実装言語なし: `bash scripts/setup.sh`
    - ts: `bash scripts/setup.sh`（`npm install` を含む）
    - python, c: `bash scripts/setup.sh`（`uv sync --dev` を含む）

### 動作確認

- 実装言語なし, ts: `uvx pre-commit run --all-files` が全フックを通過する
- python, c: `uv run pre-commit run --all-files` が全フックを通過する
- ts, python, c: push すると型検査が走る
- 全種別: main への pull request を作成し、`ci.yml` のジョブが起動する
- Windows 固有スクリプトを含む場合: 「改行コードの確認」の手順で規約どおりであることを確かめる

## 検証の段

判定に何が必要かで実行タイミングを分ける。単一ファイルで判定できるものをコミット時、リポジトリ全体を見ないと判定できないものを push 時、手元では再現しない条件を CI に置く。

| タイミング   | 内容                                         | 応答                     |
| ------------ | -------------------------------------------- | ------------------------ |
| コミット時   | 整形、単一ファイルのリント、シークレット検出 | 自動修正、またはブロック |
| push 時      | 型検査                                       | ブロックのみ             |
| pull request | クリーン環境での全ファイル検査               | ブロックのみ             |

CI でしか落ちない項目が増えたら、前段へ下ろすべきものが混ざっている合図として扱う。

### 共通の品質ゲート

フックの実行基盤は全種別で pre-commit framework に統一する。実装言語ごとのフック実行環境（node、go など）は pre-commit が自前で用意するため、共通ゲートは展開先の実装言語を問わない。

`general/.pre-commit-config.yaml` がコミット時の共通検査を定める。

| 検査              | 対象                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------- |
| gitleaks          | ステージ済みの差分に含まれるシークレット                                                |
| prettier          | Markdown、JSON、YAML の整形                                                             |
| markdownlint-cli2 | Markdown のリント                                                                       |
| pre-commit-hooks  | 末尾空白、ファイル末尾の改行、改行コードの混在、YAML 構文、競合マーカー、大容量ファイル |

競合マーカーの検出はマージ、リベース、チェリーピックの最中に働く。改行コードの扱いは「改行コード」に記す。

### プロジェクト種別ごとの追加

| プロジェクト種別 | コミット時に加わる検査      | push 時        | 追加のランタイム |
| ---------------- | --------------------------- | -------------- | ---------------- |
| 実装言語なし     | なし                        | なし           | なし             |
| ts               | prettier（ts, tsx）、eslint | `tsc --noEmit` | Node.js          |
| python           | ruff                        | pyright        | なし             |
| c                | clang-format、cmake-format  | pyright        | なし             |

言語別の検査は、pre-commit の隔離環境ではプロジェクトの依存を解決できない。npm と uv の環境をそのまま使う local フックとして実行する。

テストは push 時の枠をフック設定にコメントとして用意してある。テストを書いた時点でコメントを外す。CI はテストが存在する場合だけ実行する。

## 改行コード

Git index のテキストは LF で正規化する。working tree は、通常のファイルを LF、Windows 固有スクリプト（`.bat`、`.cmd`、`.ps1`）を CRLF とする。

| 設定                              | 担う範囲                                                                                       |
| --------------------------------- | ---------------------------------------------------------------------------------------------- |
| `.gitattributes`                  | 規約の正本。index への正規化と、checkout で working tree へ書き出す改行コードを定める          |
| `.editorconfig`                   | エディタが新規作成と保存で用いる改行コードを指示する。対象の分け方は `.gitattributes` と揃える |
| pre-commit の `mixed-line-ending` | 一つのファイル内での改行コードの混在を検出する。`--fix=no` で実行し、ファイルを書き換えない    |

`--fix=lf` は working tree を CRLF とする Windows 固有スクリプトまで LF へ書き換え、`.gitattributes` の指定を打ち消すため用いない。この結果、ファイル全体が規約と異なる改行コードで統一されている場合はフックが通過する。その状態は `git add` の時点で `.gitattributes` が index を LF へ正規化し、次の checkout で working tree が規約どおりへ戻る。

### 改行コードの確認

- `git check-attr eol README.md verification/windows-script.ps1` が、前者へ `lf`、後者へ `crlf` を返す
- working tree で `verification/windows-script.ps1` が CRLF、他のテキストファイルが LF である
- LF の行と CRLF の行を併せ持つファイルを作ると `uvx pre-commit run --all-files` が `mixed line ending` で失敗し、そのファイルを書き換えない。確認後はこのファイルを削除する
- 混在の確認を終えた後に `git status` が意図しない差分を示さない

## CI

- 実装言語なし: `general/github-workflows/ci.yml` が uv を導入し、`uvx pre-commit run --all-files` を実行する
- python, c: `ci.yml` が sakashita44/.github の reusable-python-ci を呼ぶ。このワークフローは `pre-commit run --all-files` を含むため、共通検査と言語別検査の両方が走る
- ts: `ci.yml` が sakashita44/.github の reusable-node-ci を呼ぶ。このワークフローは npm の依存を入れてから `pre-commit run --all-files` を実行し、続けて型検査、テスト、ビルドを実行する

reusable workflow のジョブ内容を変えるときは参照先を編集する。トリガーは main への pull request で、main へ直接 push する運用では push トリガーを追加する。

配布素材内で使用する GitHub Actions の major は、定期保守またはリリース準備時に upstream release と照合する。

## ランタイムの版

Python と Node.js の版は、展開先の `.python-version` と `.nvmrc` が定める。reusable workflow はこれらのファイルがあればその値を使い、無い場合だけワークフロー側の既定値を使う。本リポジトリが配布する値は開始時点のものであり、展開先は正本の更新を待たずに書き換えてよい。

共通ゲートの pre-commit は uv が管理する Python 上で動く。実装言語なしと ts では `uvx pre-commit` として実行し、展開先へ Python の版を固定するファイルを置かない。

Python では `pyproject.toml` の `requires-python` が下限を定める。ruff の対象版はここから推論されるため、`ruff.toml` へ `target-version` を書かない。
