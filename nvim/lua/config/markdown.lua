-- ============================================================
-- markdown 編集支援（mkdnflow.nvim）
-- ============================================================
-- リスト自動継続・チェックボックストグル・リンク化・見出しレベル操作を
-- mkdnflow に任せ、md の手打ちを減らす。
--
-- 方針: modules.maps=false で「自動マップを全無効化」し、必要な機能だけを
-- markdown バッファローカルで明示登録する。理由は2つ。
--   1) mkdnflow のデフォルトは Normal の `<CR>`（→リンク follow）・`-`/`+`（→見出し
--      レベル）・`<Tab>`/`]]` 等の標準キーを md バッファで潰す。意図せぬ操作感の
--      変化を避けるため、潰すキーを自分で選びたい。
--   2) この設定群の「explicit に記述する」方針（一括フラグに頼らず必要分だけ明示）に合わせる。
-- 全マップ無効化後の機能呼び出しは ex コマンド（:Mkdn...）で行う（mkdnflow は
-- <Plug> インターフェースを持たないため）。

require('mkdnflow').setup({
  -- 自動マップを全無効化（必要分は下の FileType autocmd で明示登録）
  modules = { maps = false },
  -- 対象を markdown filetype に限定（mkdnflow は Neovim の filetype 名で指定する。
  -- 拡張子キー 'md' は 'markdown' へ自動移行される旨の警告が出るため filetype 名で書く）
  filetypes = { markdown = true },
  -- リンク解決の基準を vault ルートにする。ノート集約dir（MarkDownNoteHome 等）に
  -- root_marker（.root）を1個置くと、どのノート（daily サブフォルダ内含む）から開いても
  -- 常にそのルート基準で [note](note.md) を解決する。先頭 './' も root 基準で解釈される。
  -- デフォルト 'first'（最初に開いたファイルのdir基準）では、daily を最初に開いて起動すると
  -- 平置きノートへ届かず auto_create で新規ファイルが作られてしまうため 'root' にする。
  -- 標準 Vim の gf が cwd も探索して届いていた挙動を、vault ルート固定で取り戻す形。
  -- root_marker が無い場所（dotfiles 内の md 等）では fallback='current'（現ファイルのdir基準）。
  path_resolution = {
    primary     = 'root',
    root_marker = '.root',
    fallback    = 'current',
  },
  links = {
    -- リンク作成時のパス変換を無効化。デフォルトは「小文字化＋空白をダッシュ化＋
    -- 日付 prefix（YYYY-MM-DD_）付与」で、() の中が "日付_ラベル.md" になる。
    -- false にすると選択文字そのままの "ラベル.md" になる（日本語ラベルも保たれる）。
    transform_on_create = false,
    -- implicit_extension は設定しない（デフォルト nil＝拡張子は明示必須）。
    -- リンクは "note.md" のように拡張子付きで書く運用。将来 Obsidian 等の他プラット
    -- フォームへ移す際の互換性を担保するため、.md 省略補完にはあえて頼らない。
  },
})

-- markdown バッファに入ったときだけ buffer-local キーマップを張る。
-- mkdnflow は ft='markdown' で遅延ロードされ、lazy.nvim がロード後に現バッファの
-- FileType を再発火するため、最初に開いた md バッファにもこの autocmd が効く。
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('MkdnflowKeymaps', { clear = true }),
  pattern = 'markdown',
  callback = function(ev)
    local function map(mode, lhs, cmd, desc)
      vim.keymap.set(mode, lhs, '<Cmd>' .. cmd .. '<CR>',
        { buffer = ev.buf, silent = true, desc = desc })
    end

    -- リスト継続（o/O 方式）: リスト上では新規リスト項目を作って挿入へ、
    -- リスト外では通常の o/O として振る舞う。番号リストの番号も自動付与される。
    map('n', 'o', 'MkdnNewListItemBelowInsert', 'リスト項目を下に追加（リスト外は通常 o）')
    map('n', 'O', 'MkdnNewListItemAboveInsert', 'リスト項目を上に追加（リスト外は通常 O）')

    -- リスト項目のインデント増減（Insert）。md 限定で標準の <C-t>/<C-d> を上書きする。
    map('i', '<C-t>', 'MkdnIndentListItem', 'リスト項目をインデント')
    map('i', '<C-d>', 'MkdnDedentListItem', 'リスト項目をデデント')

    -- 番号リストの振り直し（途中挿入・削除で崩れた連番を直す）
    map('n', '<Leader>nn', 'MkdnUpdateNumbering', '番号リストを振り直す')

    -- チェックボックスのトグル（- [ ] ↔ - [x]）。<C-Space> は端末/IME に取られがちなため <Leader>x へ。
    map({ 'n', 'x' }, '<Leader>x', 'MkdnToggleToDo', 'チェックボックスをトグル')

    -- リンク化。クリップボードの URL から / ビジュアル選択文字をリンク化する。
    map('n', '<Leader>p', 'MkdnCreateLinkFromClipboard', 'クリップボードからリンク化')
    map('x', '<Leader>p', 'MkdnCreateLinkFromClipboard', 'クリップボードからリンク化')
    map('x', '<Leader>l', 'MkdnCreateLink', '選択文字をリンク化')

    -- リンク follow（gf の進化）。標準 gf は「カーソル直下のファイル名」を要求するため
    -- 毎回 () の中へ移動する必要があったが、MkdnFollowLink はリンク行にカーソルが
    -- あれば括弧外からでも飛べる。Normal `<CR>` は潰さず gf に割り当てて操作感を温存する。
    map('n', 'gf', 'MkdnFollowLink', 'リンクを開く（行内のリンクへ）')
    -- 飛んだ先から元のバッファへ戻る / 進む（Zettelkasten のリンク徘徊で前後移動）。
    -- 標準 Normal `<BS>`（左移動）を md バッファローカルで上書きするが、md では
    -- リンク往復の方が有用。左移動は h で代替できる。
    -- 進む側は <S-BS> が端末で <BS> と区別できず競合しうるため、mkdnflow 既定でもある
    -- <Del> を使う（標準の1文字削除を md バッファ内のみ上書き。削除は x で代替できる）。
    map('n', '<BS>', 'MkdnGoBack', 'リンク履歴を戻る')
    map('n', '<Del>', 'MkdnGoForward', 'リンク履歴を進む')

    -- 見出しレベル操作。標準の `+`/`-`（行移動）を潰さないよう <Leader> 系へ退避。
    -- Increase=ハッシュを減らす（重要度↑）/ Decrease=ハッシュを増やす（重要度↓）。
    map('n', '<Leader>=', 'MkdnIncreaseHeading', '見出しレベルを上げる（# を減らす）')
    map('n', '<Leader>-', 'MkdnDecreaseHeading', '見出しレベルを下げる（# を増やす）')
  end,
})
