-- ============================================================
-- セッション管理設定（mini.sessions）
-- ============================================================
-- グローバルセッションの保存先は mini.sessions のデフォルト
-- （stdpath('data')/session、単数形）をそのまま使う。
--   Windows : %LOCALAPPDATA%\nvim-data\session
--   Linux   : ~/.local/share/nvim/session
-- リポジトリ外（OS 標準のデータディレクトリ）なので、
-- 複数環境でこのリポジトリを共有しても干渉しない。
-- ※ directory を明示指定しないのは意図的。デフォルト運用の環境
--   （職場など）と保存先を揃え、環境間でセッションが見えなくなる
--   事故を防ぐため。
--
-- ローカルセッション（Session.vim）は cwd に生成されるため、
-- リポジトリ内で誤って作成された場合に備え .gitignore で除外している。

-- セッションの運用方針（揮発デフォルト＋意図的保管、なぜ false にするか）は CLAUDE.md に集約。
require('mini.sessions').setup({
  autowrite = false,            -- 終了時に自動保存しない（保存は手動 :SessionWrite のみ）
  autoread  = false,            -- 起動時に自動復元しない（復元は手動 :SessionSelect のみ）
  file      = 'Session.vim',    -- ローカルセッション名（手動 :SessionWrite/Read で使用）
})

-- -------------------------------------------------------
-- ユーザーコマンド
-- -------------------------------------------------------

-- 保存済みセッション名の Tab 補完
local function session_complete(arglead)
  return vim.tbl_filter(
    function(name) return vim.startswith(name, arglead) end,
    vim.tbl_keys(MiniSessions.detected)
  )
end

-- :SessionWrite <name> - グローバルセッションを指定名で保存
vim.api.nvim_create_user_command('SessionWrite', function(opts)
  MiniSessions.write(opts.args)
end, { nargs = 1, complete = session_complete, desc = 'セッションを保存' })

-- :SessionRead <name> - グローバルセッションを読み込み
vim.api.nvim_create_user_command('SessionRead', function(opts)
  MiniSessions.read(opts.args)
end, { nargs = 1, complete = session_complete, desc = 'セッションを読み込み' })

-- :SessionDelete <name> - グローバルセッションを削除
vim.api.nvim_create_user_command('SessionDelete', function(opts)
  MiniSessions.delete(opts.args)
end, { nargs = 1, complete = session_complete, desc = 'セッションを削除' })

-- :SessionSelect - 保存済みセッションを一覧から選択して読み込み
vim.api.nvim_create_user_command('SessionSelect', function()
  MiniSessions.select()
end, { nargs = 0, desc = 'セッションを選択して読み込み' })
