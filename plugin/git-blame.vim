" vim-git-blame - Inline git blame for Vim
" Maintainer:   Your Name
" Version:      1.0.0
" License:      MIT

if exists('g:loaded_git_blame')
  finish
endif
let g:loaded_git_blame = 1

" Save user's cpoptions and set to Vim defaults
let s:save_cpo = &cpo
set cpo&vim

" Configuration
if !exists('g:git_blame_enabled')
  let g:git_blame_enabled = 1
endif

if !exists('g:git_blame_highlight_group')
  let g:git_blame_highlight_group = 'GitBlame'
endif

if !exists('g:git_blame_format')
  let g:git_blame_format = '%an · %ar · %s'
endif

" Define highlight
hi def link GitBlame Comment
hi def GitBlame guifg=#6a737d ctermfg=243

" Define text property type
if exists('*prop_type_add')
  call prop_type_add('GitBlame', #{
        \ highlight: g:git_blame_highlight_group,
        \ priority: 10,
        \ start_include: 0,
        \ end_include: 0
        \ })
endif

" Commands
command! -nargs=0 GitBlameToggle call gitblame#toggle()
command! -nargs=0 GitBlameEnable call gitblame#enable()
command! -nargs=0 GitBlameDisable call gitblame#disable()

" Autocommands
augroup git_blame
  autocmd!
  autocmd BufWinEnter * call gitblame#on_buffer_enter()
  autocmd BufWritePost * call gitblame#on_buffer_change()
  autocmd CursorMoved,CursorMovedI * call gitblame#on_cursor_moved()
  autocmd VimLeave * call gitblame#cleanup()
augroup END

" Restore user's cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
