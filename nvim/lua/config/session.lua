-- ============================================================
-- セッション管理設定（mini.sessions）
-- ============================================================
-- グローバルセッションの保存先は stdpath('data')/sessions であり、
-- リポジトリ外（OS 標準のデータディレクトリ）に保存される。
--   Windows : %LOCALAPPDATA%\nvim-data\sessions
--   Linux   : ~/.local/share/nvim/sessions
-- そのため、複数環境でこのリポジトリを共有しても干渉しない。
--
-- ローカルセッション（Session.vim）は cwd に生成されるため、
-- リポジトリ内で誤って作成された場合に備え .gitignore で除外している。

require('mini.sessions').setup({
  autowrite = true,                                   -- 終了時に現在のセッションを自動保存
  autoread  = true,                                   -- 起動時に最新のセッションを自動復元
  directory = vim.fn.stdpath('data') .. '/sessions',  -- グローバルセッション保存先（リポジトリ外）
  file      = 'Session.vim',                          -- ローカルセッション（cwd に配置）
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
