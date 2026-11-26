# セッションダッシュボード

2 台のサーバーに散らばった Claude Code のセッションを一覧し、「自分の番」のものを優先度順に並べる。

- 記録: 各サーバーの hook が `~/.local/state/session-dashboard/<session_id>.md` に状態を書き、応答が終わるたびに記録係（Haiku）が目的・結果・優先度・経緯を更新する
- 表示: `session-dashboard --peer <相手のホスト>` が、自分と相手（ssh）の記録をまとめて表示する
- 記録には仕事の情報が入るので、リポジトリや同期ツールの対象に入れない

```sh
session-dashboard --peer dev2              # 一覧
session-dashboard --peer dev2 a1b2         # 経緯
session-dashboard --peer dev2 --rm a1b2    # 停止中の記録を消す
watch -n5 session-dashboard --peer dev2    # 常時表示
```

## セットアップ（AI 向けの手順）

各サーバーで setup リポジトリをプルしたあと、Claude Code にこの節を読ませて「セットアップして」と頼む。

1. `~/setup/bin` が PATH に入っていることを確かめる（`.bashrc` が入れる）。コマンドは `~/setup/bin/session-dashboard`（このディレクトリへのシンボリックリンク）なので、追加の作業は要らない
2. `~/.claude/settings.json` の `hooks` に、次を**既存の設定を残したまま**マージする（同じ command の登録が既にあれば足さない）。herdr などが入れた他の hook は消さない

   ```json
   {
     "SessionStart":     [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "PreToolUse":       [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "PostToolUse":      [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "PostToolUseFailure": [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "Notification":     [{"matcher": "permission_prompt|elicitation_dialog|idle_prompt", "hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "StopFailure":      [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}],
     "Stop":             [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10},
                                     {"type": "command", "command": "~/setup/session-dashboard/session-dashboard _record", "async": true}]}],
     "SessionEnd":       [{"hooks": [{"type": "command", "command": "~/setup/session-dashboard/session-dashboard _hook", "timeout": 10}]}]
   }
   ```

3. 相手のサーバーに鍵で ssh できること（パスワードを聞かれないこと）と、相手側に `python3` があることを確かめる
4. 失敗は `~/.local/state/session-dashboard/error.log` に残る

以後の更新はプルだけで反映される。`settings.json` の変更が要るときだけ、この手順を頼み直す。
