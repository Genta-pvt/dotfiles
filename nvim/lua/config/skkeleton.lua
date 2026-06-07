-- ============================================================
-- skkeleton 設定
-- skkeleton は Neovim 上で動作する SKK 日本語入力プラグイン。
-- 動作には denops.vim (Deno ランタイム) が必要。
-- ============================================================

-- 'skkeleton-initialize-pre' イベントで設定を注入する。
-- プラグインロード後・初期化前に実行されるため、設定が確実に反映される。
vim.api.nvim_create_autocmd('User', {
  pattern  = 'skkeleton-initialize-pre',
  callback = function()
    -- AZIK かなテーブルを登録（skkeleton_azik.lua で定義）
    local azik = require('config.skkeleton_azik')
    vim.fn['skkeleton#register_kanatable']('azik', azik, true)

    -- function マッピング（azik テーブルは create=true で空生成のためデフォルト rom の
    -- function が引き継がれない。必要なものをここで明示的に追加する）
    vim.fn['skkeleton#register_kanatable']('azik', {
      [' '] = 'henkanFirst', -- スペースで変換開始（▽モード → ▼モード）
      ['/'] = 'abbrev',      -- 欧文変換モード（/で英字変換開始）
      [';'] = 'henkanPoint', -- 送り仮名マーカー（l→っ 移行により ; が解放された）
      q     = 'katakana',    -- カタカナモード（q 単独は AZIK 拡張の後置キーのみ使用）
      jj    = 'escape',      -- jj で skkeleton を無効化（j 単独は AZIK の じ行に使用済みのため衝突しない）
    })

    -- グローバル設定
    vim.fn['skkeleton#config']({
      globalDictionaries = { '~/.skk/SKK-JISYO.L' }, -- SKK 辞書ファイル
      eggLikeNewline     = true,                      -- 変換確定後に改行しない（egg ライク）
      kanaTable          = 'azik',                    -- 上で登録した AZIK テーブルを使用
    })
  end,
})

-- Insert / Command モードで <C-j> により IME のオン・オフをトグルする
vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton: IME トグル' })
vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton: IME トグル' })
