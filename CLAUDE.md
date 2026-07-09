# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの概要

`kekemoto` 個人の開発環境 dotfiles。bash・tmux・Neovim・git、および `mise` で管理するツールチェインをインストール・設定する。アプリケーションコード・ビルド手順・テストスイートは存在せず、「成果物」は `install.sh` が `$HOME` に展開するシェル環境そのものである。

コメント・コミットメッセージ・ユーザー向けプロンプトはすべて日本語で書かれている。編集時もこの慣習を守ること。

## インストール / 変更の適用

`install.sh` が唯一のエントリポイント。**冪等**であり、`~/setup` から実行する必要がある:

```bash
cd ~/setup && ./install.sh
```

`.bashrc`・`.tmux.conf`・`nvim/` を `$HOME` にコピーし（既存コピーは上書き）、`mise` でツールチェインをインストールし、git の config/alias を設定し、vim-plug と git-completion を導入する。アンインストール手段はない。

旧環境から移行する場合は `uninstall_asdf.sh` で既存の asdf を削除できる（削除前に asdf 管理下のツール一覧を表示し、`~/.tool-versions` はバックアップとして退避する）。

`.bashrc` には通常の編集・テストループとなる `apply` エイリアスが定義されている:

```bash
apply   # = cd ~/setup && ./install.sh && cd - && . ~/.bashrc
```

編集用エイリアス（`bashrc`・`vimrc`・`tmuxrc`・`install`）は `$HOME/setup` 内の対応するソースファイルを開き、保存後に `apply` を実行する。したがって編集は**このリポジトリ内のファイル**に対して行い、`$HOME` に展開済みのコピーには決して触れないこと。

## フォーマット

シェルスクリプトは `shfmt` で整形する（インデントはタブ ── 既存ファイルに合わせる）。`setup_fmt` bash 関数経由、または直接実行する:

```bash
shfmt -w ~/setup/**/*.sh
```

`shfmt` は `install.sh` ではインストールされない（`mise_add shfmt` で追加する）。`setup_fmt` は `shfmt` が無ければ何もしない。

## 構成と読み込み順

`.bashrc` がハブとなる。起動時に以下の順でソースする:

- `scripts/key-bindings.sh` ── fzf のキーバインド（上流のベンダーファイル。手で編集しない）
- `scripts/csv_tool.sh` ── `csv_*` 関数（Python 製の CSV フィルタ。後述）
- `scripts/trash.sh` ── `trash` / `sudo_trash`（後述）
- `scripts/git_worktree.sh` ── `gw*` git-worktree ヘルパー

ローカル用・git 管理外の 2 つのエスケープハッチが最後にソースされ、ソース前に `600` 権限を検証する:
- `~/.bashrc_local` ── マシン固有の設定（`bashlo` で編集）
- `~/.bashrc_project` ── プロジェクト単位の設定。ディレクトリツリーを遡って探索し（`find_up`）、`PROMPT_COMMAND='load_project'` によりプロンプトごとに再ソースされる。最も近いものを `bashpr` で編集する。

`bin/` には（ソースされない）スタンドアロン実行ファイルが 2 つある: `ssher`（複数の SSH ホストで同一コマンドを実行）と `sudoer`（spawn したコマンド ── `ssher` を含む ── に sudo パスワードを渡す `expect` ラッパー）。

## 編集時に重要な規約

- **プライベートヘルパーは `_` または `__` を接頭辞に持つ**（例: `__decrypt`・`_gw_repo_root`・`_trash_check`）。直接呼ぶことを想定していない。
- **`llm` エイリアス**は `claude_code`（hooks/MCP/slash-commands を無効化したヘッドレスな `claude -p` 呼び出し）を指す。いくつかの git 関数は diff を `llm` にパイプする ── `gcm`（コミットメッセージ生成）・`g_code_review`・`make_git_commit_message`。`HAIKU`/`SONNET` などのモデル名は `.bashrc` の llm セクション先頭にあるので、そこで更新する。
- **秘密情報マネージャ**（`secret_add`/`secret_get`、`.bashrc`）: `$SECRET_DATA_PATH`（`~/.secret_data.gpg`）にある GPG 対称暗号化された単一ファイルで、スペース区切りの `key value` 行をキーにする。`$GPG_PASSWORD`（`secret_init` で設定）が必要で、データファイルには `600` を強制する。`anthropic_api` はここから `anthropic` キーを読む。
- **`trash` は概念上 `rm` を置き換える**: ファイルは `~/trash` に移動し、30 日後に物理削除される（`trash.sh` がシェル起動時に整理する）。破壊的操作では `rm` より `trash` を優先し、親ディレクトリに書き込めない場合は `sudo_trash` を使う。
- **`csv_*` 関数**は標準入力から CSV を読む薄い `python3 -c` ラッパーで、パイプで合成できる（例: `cat data.csv | csv_grep name 太郎 | csv_cut name city`）。すべて `SIGPIPE` をデフォルトに設定し、パイプライン中でも正しく動作する。
- **git worktree** は `$GW_ROOT/<repo>/<branch>`（デフォルト `~/worktrees`）配下に作られる。`gwc` で作成/アタッチ、`gws` で fzf 切り替え、`gwd` で削除（メインのチェックアウトは削除から保護される）。

## ツールチェインのバージョン

`install.sh` の `mise use --global` で導入: python・neovim・tmux・node・jq・fzf・fd・ripgrep（いずれも `@latest` 指定で最新安定版を取得）。多くの bash 関数は `fzf`・`fd`・`rg`・`jq`・`nvim`（`$EDITOR`）の存在を前提にしている。依存を追加するときは、`install.sh` の `mise use` 行に追記すること（バージョンを固定したい場合は `@latest` を具体的なバージョンに置き換える）。

## コミットメッセージ形式

`install.sh` が `commit.template` を `.gitmessages` に設定する。これに従うこと: 絵文字を接頭辞にした 1 行要約（50 文字以内）、空行、その後に日本語の本文。絵文字の凡例は `.gitmessages` を参照（🔧 通常、🐛 バグ、♻️ リファクタリング、➕ 追加、➖ 削除、📝 ドキュメント など）。
