# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Personal development-environment dotfiles for the user `kekemoto`. It installs and configures bash, tmux, Neovim, git, and a toolchain managed via `asdf`. There is no application code, build step, or test suite — the "product" is the shell environment that `install.sh` materializes into `$HOME`.

Comments, commit messages, and user-facing prompts are written in Japanese; keep that convention when editing.

## Install / apply changes

`install.sh` is the single entry point. It is **idempotent** and must be run from `~/setup`:

```bash
cd ~/setup && ./install.sh
```

It copies `.bashrc`, `.tmux.conf`, and `nvim/` into `$HOME` (overwriting existing copies), installs `asdf` plugins pinned to exact versions, sets git config/aliases, and installs vim-plug + git-completion. There is no uninstall.

The `.bashrc` defines an `apply` alias that is the normal edit-test loop:

```bash
apply   # = cd ~/setup && ./install.sh && cd - && . ~/.bashrc
```

Editing aliases (`bashrc`, `vimrc`, `tmuxrc`, `install`) open the corresponding source file in `$HOME/setup` and run `apply` on save — so edits should be made to the files **in this repo**, never to the deployed copies in `$HOME`.

## Formatting

Shell scripts are formatted with `shfmt` (tabs for indentation — matches the existing files). Run via the `setup_fmt` bash function, or directly:

```bash
shfmt -w ~/setup/**/*.sh
```

`shfmt` is not installed by `install.sh` (add it with `asdf_add shfmt`); `setup_fmt` no-ops if it is missing.

## Layout and load order

`.bashrc` is the hub. At startup it sources, in order:

- `scripts/key-bindings.sh` — vendored fzf key bindings (upstream file; don't hand-edit)
- `scripts/csv_tool.sh` — `csv_*` functions (Python-backed CSV filters, see below)
- `scripts/trash.sh` — `trash` / `sudo_trash` (see below)
- `scripts/git_worktree.sh` — `gw*` git-worktree helpers

Two local, git-ignored escape hatches are sourced last and enforce `600` permissions before sourcing:
- `~/.bashrc_local` — machine-specific config (edit via `bashlo`)
- `~/.bashrc_project` — per-project config, discovered by walking up the directory tree (`find_up`) and re-sourced on every prompt via `PROMPT_COMMAND='load_project'`. Edit the nearest one with `bashpr`.

`bin/` holds two standalone executables (not sourced): `ssher` (run one command across many SSH hosts) and `sudoer` (an `expect` wrapper that feeds a sudo password to a spawned command, including `ssher`).

## Conventions that matter when editing

- **Private helpers are prefixed with `_` or `__`** (e.g. `__decrypt`, `_gw_repo_root`, `_trash_check`) and are not meant to be called directly.
- **The `llm` alias** points at `claude_code` (a headless `claude -p` invocation with hooks/MCP/slash-commands disabled). Several git functions pipe diffs into `llm` — `gcm` (generate a commit message), `g_code_review`, `make_git_commit_message`. `HAIKU`/`SONNET`/model names live at the top of the llm section in `.bashrc`; update them there.
- **Secret manager** (`secret_add`/`secret_get`, `.bashrc`): a single GPG-symmetric-encrypted file at `$SECRET_DATA_PATH` (`~/.secret_data.gpg`), keyed by space-separated `key value` lines. Requires `$GPG_PASSWORD` (set via `secret_init`) and enforces `600` on the data file. `anthropic_api` reads the `anthropic` key from it.
- **`trash` replaces `rm`** conceptually: files move to `~/trash` and are physically deleted after 30 days (pruned on shell startup by `trash.sh`). Prefer `trash` over `rm` for destructive operations; use `sudo_trash` when the parent dir isn't writable.
- **`csv_*` functions** are thin `python3 -c` wrappers reading CSV on stdin — they compose via pipes (e.g. `cat data.csv | csv_grep name 太郎 | csv_cut name city`). All set `SIGPIPE` to default so they behave in pipelines.
- **git worktrees** land under `$GW_ROOT/<repo>/<branch>` (default `~/worktrees`); `gwc` creates/attaches, `gws` switches via fzf, `gwd` deletes (the main checkout is protected from deletion).

## Toolchain versions

Pinned in `install.sh` via `install_asdf_plugin`: python 3.13.5, nvim 0.10.0, tmux 3.4, node 25.2.1, jq 1.7.1, fzf 0.53.0, fd 9.0.0, rg 14.1.0. Many bash functions assume `fzf`, `fd`, `rg`, `jq`, and `nvim` (`$EDITOR`) are present. When adding a dependency, pin it here rather than assuming it exists.

## Commit message format

`install.sh` sets `commit.template` to `.gitmessages`. Follow it: an emoji-prefixed one-line summary (≤50 chars), a blank line, then a Japanese body. See `.gitmessages` for the emoji legend (🔧 general, 🐛 bug, ♻️ refactor, ➕ add, ➖ remove, 📝 docs, etc.).
