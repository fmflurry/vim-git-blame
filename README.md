# vim-git-blame

Inline git blame plugin for Vim. Shows git blame information for the current line using text properties.

## Features

- Inline git blame display using Vim's text properties
- CoC/LSP compatible - does not override inline diagnostics
- Caching for performance
- Relative time display (e.g., "2 hours ago")
- Customizable format and highlight
- Toggle on/off with commands

## Requirements

- Vim 8.2 or higher (for text properties support)
- Git installed and available in PATH
- File must be in a git repository

## Installation

### Using vim-plug

Add to your `.vimrc`:

```vim
Plug 'fmflurry/vim-git-blame'
```

### Using Vundle

Add to your `.vimrc`:

```vim
Plugin 'fmflurry/vim-git-blame'
```

### Manual Installation

Copy the plugin files to your `~/.vim` directory:

```bash
cp -r vim-git-blame/plugin ~/.vim/
cp -r vim-git-blame/autoload ~/.vim/
```

## Usage

Once installed, the plugin automatically displays git blame information for the current line.

### Commands

- `:GitBlameToggle` - Toggle git blame on/off
- `:GitBlameEnable` - Enable git blame
- `:GitBlameDisable` - Disable git blame

### Configuration

Add to your `.vimrc` to customize:

```vim
" Enable/disable (default: 1)
let g:git_blame_enabled = 1

" Highlight group (default: 'GitBlame')
let g:git_blame_highlight_group = 'GitBlame'

" Format string (default: '%an · %ar · %s')
" Available placeholders:
"   %an - author name
"   %ae - author email
"   %ar - author date (relative)
"   %s - commit summary
"   %h - abbreviated commit hash
let g:git_blame_format = '%an · %ar · %s'
```

### Custom Colors

To customize the highlight color, add to your `.vimrc`:

```vim
" Using specific colors
hi GitBlame guifg=#6a737d guibg=NONE ctermfg=243 ctermbg=NONE

" Or link to an existing highlight group
hi link GitBlame Comment
hi link GitBlame LineNr
```

## How It Works

The plugin uses Vim's [text properties](https://vimhelp.org/text_prop.txt.html) feature (available in Vim 8.2+) to display inline text without modifying the actual buffer content.

### CoC/LSP Compatibility

This plugin is designed to work alongside CoC and other LSP plugins:

1. **Different property type**: Uses `GitBlame` property type, distinct from CoC's virtual text
2. **Lower priority**: Set to priority 10, while LSP diagnostics typically use higher priorities
3. **End-of-line placement**: Blame info appears after line content, avoiding conflicts with inline diagnostics

The blame information appears as:

```
your code here                     John Doe · 2 hours ago · Fix the bug
```

## Performance

- Blame information is cached per file and line
- Debounced cursor movement (100ms) to prevent excessive updates
- Cache is automatically invalidated when buffer is saved

## Troubleshooting

### Blame not showing

1. Check if file is in a git repository
2. Ensure you're using Vim 8.2+: `:version` should show 8.2 or higher
3. Check if text properties are available: `:echo exists('*prop_add')` should return `1`
4. Verify git blame works: `:!git blame -p -L 5,5 %` in Vim

### Conflicts with CoC diagnostics

If you see conflicts, adjust the priority in `plugin/git-blame.vim`:

```vim
" Lower priority (shown before diagnostics)
call prop_type_add('GitBlame', #{priority: 10})

" Higher priority (shown after diagnostics)
call prop_type_add('GitBlame', #{priority: 1000})
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
