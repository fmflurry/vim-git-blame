" Example configuration for vim-git-blame
" Add these settings to your ~/.vimrc

" =============================================================================
" BASIC CONFIGURATION
" =============================================================================

" Enable git blame on startup (default: enabled)
let g:git_blame_enabled = 1

" Custom format string
" Available placeholders:
"   %an - author name
"   %ae - author email
"   %ar - author date (relative)
"   %s - commit summary
"   %h - abbreviated commit hash
let g:git_blame_format = '%an · %ar · %s'

" =============================================================================
" CUSTOM HIGHLIGHTING
" =============================================================================

" Option 1: Subtle gray (default)
hi GitBlame guifg=#6a737d ctermfg=243

" Option 2: Match line numbers
" hi link GitBlame LineNr

" Option 3: Custom colors with background
" hi GitBlame guifg=#586069 guibg=#f6f8fa ctermfg=242 ctermbg=255

" Option 4: Muted blue
" hi GitBlame guifg=#5a7e9c ctermfg=67

" =============================================================================
" KEY MAPPINGS
" =============================================================================

" Toggle git blame with leader key
nnoremap <leader>gb :GitBlameToggle<CR>

" Quick enable/disable
nnoremap <leader>gbe :GitBlameEnable<CR>
nnoremap <leader>gbd :GitBlameDisable<CR>

" =============================================================================
" ADVANCED USAGE
" =============================================================================

" Example: Use shorter format for narrower screens
" let g:git_blame_format = '%an · %ar'

" Example: Include commit hash
" let g:git_blame_format = '%h · %an · %ar'

" Example: Show email instead of name
" let g:git_blame_format = '%ae · %ar'

" =============================================================================
" INTEGRATION WITH OTHER PLUGINS
" =============================================================================

" If you use vim-gitgutter, you might want to adjust priorities
" This is done in plugin/git-blame.vim, modify the 'priority' value:
"   priority: 10  (lower = shown first)
"   priority: 100 (higher = shown last)

" Example: Auto-disable git blame for certain file types
augroup git_blame_filetypes
  autocmd!
  autocmd FileType gitcommit,gitrebase let g:git_blame_enabled = 0
  autocmd FileType gitcommit,gitrebase call s:clear_blame()
augroup END
