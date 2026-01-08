" autoload/gitblame.vim - Git blame implementation

" Cache for blame info
let s:blame_cache = {}
let s:current_bufnr = -1
let s:current_lnum = -1
let s:timer_id = -1

" Check if buffer is in a git repo
function! gitblame#is_git_buffer(bufnr) abort
  let l:filename = expand('#' . a:bufnr . ':p')
  if empty(l:filename) || !filereadable(l:filename)
    return 0
  endif

  " Check if file is in git repo
  let l:dir = fnamemodify(l:filename, ':p:h')
  let l:git_dir = finddir('.git', l:dir . ';')
  return !empty(l:git_dir)
endfunction

" Get git blame for a specific line
function! s:get_blame_info(bufnr, lnum) abort
  let l:filename = expand('#' . a:bufnr . ':p')
  let l:cache_key = l:filename . ':' . a:lnum

  " Check cache first
  if has_key(s:blame_cache, l:cache_key)
    return s:blame_cache[l:cache_key]
  endif

  " Run git blame
  let l:cmd = 'git blame -p -L ' . a:lnum . ',+1 ' . shellescape(l:filename)
  let l:result = systemlist(l:cmd)

  if v:shell_error || empty(l:result)
    let s:blame_cache[l:cache_key] = ''
    return ''
  endif

  " Parse git blame -p output
  let l:info = {}
  let l:info.sha = matchstr(l:result[0], '^\x\+')
  let l:info.original_lnum = matchstr(l:result[0], '\x\+ \zs\d\+')
  let l:info.final_lnum = matchstr(l:result[0], '\d\+ \zs\d\+')

  " Parse additional info
  let l:i = 1
  while l:i < len(l:result)
    let l:line = l:result[l:i]
    if l:line =~ '^author '
      let l:info.author = l:line[7:]
    elseif l:line =~ '^author-mail '
      let l:info.author_mail = l:line[12:]
    elseif l:line =~ '^author-time '
      let l:info.author_time = str2nr(l:line[12:])
    elseif l:line =~ '^author-tz '
      let l:info.author_tz = l:line[11:]
    elseif l:line =~ '^summary '
      let l:info.summary = l:line[8:]
    elseif l:line =~ '^\t'
      " End of info
      break
    endif
    let l:i += 1
  endwhile

  " Format the output
  let l:blame_text = s:format_blame(l:info)

  " Cache it
  let s:blame_cache[l:cache_key] = l:blame_text
  return l:blame_text
endfunction

" Format blame info according to user config
function! s:format_blame(info) abort
  if empty(a:info)
    return ''
  endif

  let l:result = g:git_blame_format

  " Replace placeholders (escape special chars for substitute)
  let l:result = substitute(l:result, '%an', escape(get(a:info, 'author', ''), '&\'), 'g')
  let l:result = substitute(l:result, '%ae', escape(get(a:info, 'author_mail', ''), '&\'), 'g')

  " Format relative time
  if has_key(a:info, 'author_time')
    let l:relative_time = s:relative_time(a:info.author_time)
    let l:result = substitute(l:result, '%ar', escape(l:relative_time, '&\'), 'g')
  endif

  let l:result = substitute(l:result, '%s', escape(get(a:info, 'summary', ''), '&\'), 'g')
  let l:result = substitute(l:result, '%h', escape(a:info.sha[0:7], '&\'), 'g')

  " Add padding for alignment
  if !empty(l:result)
    let l:result = ' ' . l:result . ' '
  endif

  return l:result
endfunction

" Calculate relative time
function! s:relative_time(timestamp) abort
  let l:current = localtime()
  let l:diff = l:current - a:timestamp

  if l:diff < 60
    return 'just now'
  elseif l:diff < 3600
    let l:mins = l:diff / 60
    return l:mins . ' min' . (l:mins > 1 ? 's' : '') . ' ago'
  elseif l:diff < 86400
    let l:hours = l:diff / 3600
    return l:hours . ' hour' . (l:hours > 1 ? 's' : '') . ' ago'
  elseif l:diff < 604800
    let l:days = l:diff / 86400
    return l:days . ' day' . (l:days > 1 ? 's' : '') . ' ago'
  elseif l:diff < 2629746
    let l:weeks = l:diff / 604800
    return l:weeks . ' week' . (l:weeks > 1 ? 's' : '') . ' ago'
  elseif l:diff < 31556952
    let l:months = l:diff / 2629746
    return l:months . ' month' . (l:months > 1 ? 's' : '') . ' ago'
  else
    let l:years = l:diff / 31556952
    return l:years . ' year' . (l:years > 1 ? 's' : '') . ' ago'
  endif
endfunction

" Clear blame display for current buffer
function! s:clear_blame() abort
  if !exists('*prop_remove')
    return
  endif

  silent! call prop_remove({'type': 'GitBlame'}, 1, line('$'))
endfunction

" Display blame for current line
function! s:show_blame(lnum, blame_text) abort
  if !exists('*prop_add') || empty(a:blame_text)
    return
  endif

  " Get window width
  let l:window_width = winwidth(0)

  " Get the actual line content
  let l:line = getline(a:lnum)

  " Calculate the byte column where we should add the property (end of line + 1)
  let l:col = len(l:line) + 1

  " Get display width to check for virtual text (inlay hints)
  let l:line_display_width = strdisplaywidth(l:line)

  " Try to get virtual column at end of line to detect inlay hints
  try
    let l:virtual_col = virtcol([a:lnum, '$'])
  catch
    let l:virtual_col = l:line_display_width
  endtry

  " Calculate available display width (accounting for inlay hints)
  let l:actual_display_width = max([l:virtual_col, l:line_display_width])
  let l:available_width = l:window_width - l:actual_display_width

  " Don't display if line is already at or beyond window width
  if l:actual_display_width >= l:window_width
    return
  endif

  " Truncate blame text if it exceeds available width
  let l:text_to_display = a:blame_text
  if strdisplaywidth(a:blame_text) > l:available_width
    " Need at least 7 characters (1 + 3 for ellipsis + 3 safety margin)
    if l:available_width < 7
      return
    endif

    " Truncate to fit, leaving room for ellipsis and safety margin
    let l:max_content_width = l:available_width - 6

    " Truncate character by character
    let l:text_to_display = ''
    let l:current_width = 0
    for l:char in split(a:blame_text, '\zs')
      let l:char_width = strdisplaywidth(l:char)
      " Stop if adding this character would exceed max_content_width
      if l:current_width + l:char_width > l:max_content_width
        break
      endif
      let l:text_to_display .= l:char
      let l:current_width += l:char_width
    endfor

    " Only add ellipsis if we actually truncated something
    if l:text_to_display !=# a:blame_text
      let l:text_to_display .= '...'
    endif
  endif

  " Add text property
  call prop_add(a:lnum, l:col, {
        \ 'type': 'GitBlame',
        \ 'text': l:text_to_display
        \ })
endfunction

" Update blame display
function! s:update_blame() abort
  " Clear previous blame
  call s:clear_blame()

  if !g:git_blame_enabled
    return
  endif

  let l:bufnr = bufnr('%')

  if !gitblame#is_git_buffer(l:bufnr)
    return
  endif

  let l:lnum = line('.')

  " Get blame info
  let l:blame_text = s:get_blame_info(l:bufnr, l:lnum)

  " Display it
  if !empty(l:blame_text)
    call s:show_blame(l:lnum, l:blame_text)
  endif
endfunction

" Debounced update (to avoid too frequent updates)
function! gitblame#update() abort
  " Cancel existing timer
  if s:timer_id != -1
    call timer_stop(s:timer_id)
  endif

  " Set new timer (debounce: 100ms)
  let s:timer_id = timer_start(100, {-> s:update_blame()})
endfunction

" Autocmd handlers
function! gitblame#on_buffer_enter() abort
  if !g:git_blame_enabled
    return
  endif

  " Clear cache for new buffer
  let s:current_bufnr = bufnr('%')
  call gitblame#update()
endfunction

function! gitblame#on_buffer_change() abort
  " Invalidate cache on save
  let s:blame_cache = {}
  call gitblame#update()
endfunction

function! gitblame#on_cursor_moved() abort
  let l:bufnr = bufnr('%')
  let l:lnum = line('.')

  " Only update if buffer or line changed
  if l:bufnr != s:current_bufnr || l:lnum != s:current_lnum
    let s:current_bufnr = l:bufnr
    let s:current_lnum = l:lnum
    call gitblame#update()
  endif
endfunction

" Toggle functions
function! gitblame#enable() abort
  let g:git_blame_enabled = 1
  call gitblame#update()
  echo 'Git blame enabled'
endfunction

function! gitblame#disable() abort
  let g:git_blame_enabled = 0
  call s:clear_blame()
  echo 'Git blame disabled'
endfunction

function! gitblame#toggle() abort
  if g:git_blame_enabled
    call gitblame#disable()
  else
    call gitblame#enable()
  endif
endfunction

" Cleanup on Vim exit
function! gitblame#cleanup() abort
  call s:clear_blame()
  let s:blame_cache = {}
endfunction
