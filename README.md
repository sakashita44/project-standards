# project-standards

新規リポジトリへコピーして使用する設定ファイルの管理元である。コピー後の変更は展開先の裁量に委ね、汎用的な改善は本リポジトリへ還元する。本リポジトリから展開済みのリポジトリは更新しない。

## ディレクトリ構成

```text
general/       # 全プロジェクト種別で共用する設定と共通の品質ゲート
ts/            # TypeScript/Node プロジェクト用
python/        # Python プロジェクト用
c/             # C/C++, CMake の整形資産。python/ に重ねる追加レイヤ
verification/  # 配布物自身へ品質ゲートを掛けるための検証対象
```

`general/` だけで品質ゲートが成立する。実装言語を持たないリポジトリには `general/` のみを展開する。言語別レイヤは、共通ゲートへ固有の検査を追加する差分のみを含む。

issue/PR テンプレートは [sakashita44/.github](https://github.com/sakashita44/.github) が全リポジトリへ既定として適用するため、本リポジトリでは配布しない。

ルート直下の設定ファイルと `.github/workflows/ci.yml` は、本リポジトリ自身へ `general/` を展開した構成となっている。配布する設定が自身の検査を通ることを品質ゲートで保つため、`general/` を変更した際はルート直下へも反映する。反映漏れは CI による `general/` との突き合わせで検出する。ルート固有の調整がある場合は、各ファイル内に理由とともに記載する。

突き合わせの対象から除外するファイルは次の 3 つである。

- `.gitignore`: 展開手順どおり、本リポジトリ固有の内容へ差し替えてある
- `.prettierignore`: `general/` から削除したため突き合わせの対象とならない。ルート直下には、追記用フラグメントを整形対象から除外する本リポジトリ固有の設定のみを置く
- `.github/workflows/ci.yml`: `general/github-workflows/ci.yml` の内容に加え、突き合わせを実行するステップを含む

## 展開手順

### 開始条件

- 展開先のリポジトリを作成済みであること
- 全種別: uv が PATH に通っていること
- ts: 加えて Node.js が PATH に通っていること

### 手順

1. `general/` の内容をリポジトリルートへコピーする
1. プロジェクト種別に応じたディレクトリの内容をルートへ重ねてコピーする。ts は `ts/`、python は `python/`、C/C++ を含む場合は `python/` の上へ `c/` を重ねてコピーする。実装言語を持たないリポジトリでは本手順を省略する
1. 言語別レイヤの追加フックを共通ゲートへ合成する。`.pre-commit-config.<種別>.yaml` の内容を `.pre-commit-config.yaml` の末尾へ追記し、追記元ファイルを削除する。c の場合は python の追記に続けて c の追記を行う

    ```bash
    cat .pre-commit-config.python.yaml >> .pre-commit-config.yaml && rm .pre-commit-config.python.yaml
    ```

    この追記は bash で実行する。PowerShell の `cat` は UTF-16LE で書き出すため、`.pre-commit-config.yaml` が読み込めなくなる

    この追記は展開時の一度きりの操作である。設定を取り込み直す目的で `general/` を再コピーすると、追記済みの内容が失われるか二重に追記される。取り込み直しでは言語別レイヤの再コピーも必要になるため、合成前にはコミットせず、合成結果を目視で確認のこと

1. `*.template` から拡張子 `.template` を外し、`PLACEHOLDER_` で始まる値を実際の値へ置換する
1. `.gitignore` を [github/gitignore](https://github.com/github/gitignore) のテンプレートで置き換え、`mise.local.toml` を含むリポジトリ固有の除外設定を追加する

    `mise.local.toml.example` は、mise の設定をホストごとに上書きする任意の設定例である。次の 2 つの用途を示す。使用しない場合は削除する

    - 外部 CLI の場所の差し替え: mise が版を管理しない外部 CLI について、このホストだけ別の実体を使う。使用する場合も、共有するスクリプトや文書では標準のコマンド名を用いることを推奨する
    - 宣言されたツールの無視: プロジェクトの `mise.toml` が宣言したツールのうち、このホストの mise で解決できないものを `disable_tools` に指定し、警告や `mise install` の失敗を防ぐ

1. `github-workflows/ci.yml` を `.github/workflows/ci.yml` へ移動する
1. `dependabot.yml` を `.github/dependabot.yml` へ移動し、使用するエコシステムのコメントアウトを解除する
1. フックを有効化する
    - 実装言語なし: `bash scripts/setup.sh`
    - ts: `bash scripts/setup.sh`（`npm install` を含む）
    - python, c: `bash scripts/setup.sh`（`uv sync --dev` を含む）

### 動作確認

- 実装言語なし, ts: `uvx pre-commit run --all-files` を実行した際に、全フックを通過すること
- python, c: `uv run pre-commit run --all-files` を実行した際に、全フックを通過すること
- ts, python, c: push した際に型検査が実行されること
- 全種別: main への pull request を作成した際に、`ci.yml` のジョブが起動されること
- Windows 固有スクリプトを含む場合: 「改行コードの確認」の手順に従い、規約どおりであることを確認すること

## 検証の段

判定に何が必要かによって実行タイミングを分ける。単一ファイルで判定できる検査はコミット時、リポジトリ全体を走査しなければ判定できない検査は push 時、手元では再現しない条件の検査は CI に配置する。

| タイミング   | 内容                                         | 応答                     |
| ------------ | -------------------------------------------- | ------------------------ |
| コミット時   | 整形、単一ファイルのリント、シークレット検出 | 自動修正、またはブロック |
| push 時      | 型検査                                       | ブロックのみ             |
| pull request | クリーン環境での全ファイル検査               | ブロックのみ             |

CI でしか失敗しない項目が増えた場合は、より手前の検証段階へ移すべき検査が含まれている兆候として扱う。

### 共通の品質ゲート

フックの実行基盤は全種別で pre-commit framework に統一する。実装言語ごとのフック実行環境（Node.js、Go など）は pre-commit が自前で用意するため、共通ゲートは展開先の実装言語を問わない。

`general/.pre-commit-config.yaml` がコミット時の共通検査を定める。

| 検査              | 対象                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------- |
| gitleaks          | ステージ済みの差分に含まれるシークレット                                                |
| prettier          | Markdown、JSON、YAML の整形                                                             |
| markdownlint-cli2 | Markdown のリント                                                                       |
| pre-commit-hooks  | 末尾空白、ファイル末尾の改行、改行コードの混在、YAML 構文、競合マーカー、大容量ファイル |

競合マーカーの検出はマージ、リベース、チェリーピックの実行時に機能する。改行コードの扱いについては「改行コード」節を参照のこと。

### プロジェクト種別ごとの追加

| プロジェクト種別 | コミット時に加わる検査      | push 時        | 追加のランタイム |
| ---------------- | --------------------------- | -------------- | ---------------- |
| 実装言語なし     | なし                        | なし           | なし             |
| ts               | prettier（ts, tsx）、eslint | `tsc --noEmit` | Node.js          |
| python           | ruff                        | pyright        | なし             |
| c                | clang-format、cmake-format  | pyright        | なし             |

言語別の検査では、pre-commit の隔離環境内ではプロジェクトの依存関係を解決できない。そのため、npm や uv の環境を直接使用する local フックとして実行する。

テストの実行枠は、push 時のフック設定内にコメントとして用意してある。テストを作成した段階でコメントアウトを解除する。CI ではテストが存在する場合にのみ実行される。

## 改行コード

Git インデックスのテキストは LF で正規化する。working tree では、通常のファイルを LF、Windows 固有スクリプト（`.bat`、`.cmd`、`.ps1`）を CRLF とする。

| 設定                              | 担う範囲                                                                                               |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `.gitattributes`                  | 改行コード規約の規定元。index への正規化と、checkout で working tree へ書き出す改行コードを定める      |
| `.editorconfig`                   | エディタで新規作成または保存する際に用いる改行コードを指定する。対象の分類は `.gitattributes` と揃える |
| pre-commit の `mixed-line-ending` | 単一ファイル内での改行コードの混在を検出する。`--fix=no` で実行し、ファイルを書き換えない              |

`--fix=lf` は working tree を CRLF とする Windows 固有スクリプトまで LF へ書き換え、`.gitattributes` の指定を打ち消すため使用しない。この結果、ファイル全体が規約と異なる改行コードで統一されている場合はフックを通過する。その状態でも、`git add` の実行時に `.gitattributes` が index を LF へ正規化する。working tree は該当パスを次回 checkout した際に規約どおりの状態へ復元される（コミットしただけでは復元されない）。

### 改行コードの確認

通常のファイルと Windows 固有スクリプトをそれぞれ 1 つ選択し、次の点を確認する。本リポジトリでは `README.md` と `verification/windows-script.ps1` を対象とする。

- `git check-attr eol <通常ファイル> <Windows 固有スクリプト>` を実行し、前者に `lf`、後者に `crlf` が返されること
- `git ls-files --eol` を実行した際、通常のファイルが `i/lf w/lf`、Windows 固有スクリプトが `i/lf w/crlf` と表示されること。`w/crlf` となっている通常ファイルは working tree のみが規約から外れており、`git status` には表示されない。該当パスを削除して checkout し直すことで正常な状態に戻る
- LF の行と CRLF の行が混在するファイルを作成して `uvx pre-commit run --all-files` を実行した際、`mixed line ending` によって検査が失敗し、該当ファイルが書き換えられないこと。確認後は作成したファイルを削除すること
- 混在の確認を終えた後に、`git status` で意図しない差分が表示されないこと

## CI

- 実装言語なし: `general/github-workflows/ci.yml` が uv をセットアップし、`uvx pre-commit run --all-files` を実行する
- python, c: `ci.yml` で sakashita44/.github の reusable-python-ci を呼び出す。このワークフローには `pre-commit run --all-files` が含まれるため、共通検査と言語別検査の両方が実行される
- ts: `ci.yml` で sakashita44/.github の reusable-node-ci を呼び出す。このワークフローでは npm の依存関係を解決した後に `pre-commit run --all-files` を実行し、続けて型検査、テスト、ビルドを実行する

reusable workflow のジョブ内容を変更するときは参照先を編集する。トリガーは main への pull request で、main へ直接 push する運用では push トリガーを追加する。

配布素材内で使用する GitHub Actions のメジャーバージョンは、定期保守またはリリース準備時に upstream release と照合する。

## ランタイムの版

Python と Node.js の版は、展開先の `.python-version` と `.nvmrc` で指定する。reusable workflow はこれらのファイルが存在すればその値を使用し、存在しない場合のみワークフロー側の既定値を使用する。本リポジトリが配布する値は初期値であり、展開先は本リポジトリの更新を待たずに書き換えてよい。

共通ゲートの pre-commit は uv が管理する Python 上で動作する。実装言語なしと ts では `uvx pre-commit` として実行し、展開先へ Python の版を固定するファイルを配置しない。

Python では `pyproject.toml` の `requires-python` が下限を定める。ruff の対象版はこの指定から推論されるため、`ruff.toml` へ `target-version` は記述しない。
