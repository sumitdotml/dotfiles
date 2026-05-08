" ============================================================================
" Kanagawa (Wave) Colorscheme for Vim
" Inspired by https://github.com/rebelot/kanagawa.nvim (Wave variant)
" Author: menisadi
" ============================================================================
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "kanagawa"

" Ensure true color is enabled if possible
if has("termguicolors")
  set termguicolors
endif

set background=dark
hi clear

hi Boolean gui=bold term=bold cterm=bold guifg=#ffa066 guibg=NONE ctermfg=215 ctermbg=NONE
hi Added   gui=NONE term=NONE cterm=NONE guifg=#98bb6c guibg=NONE ctermfg=114 ctermbg=NONE
hi Changed gui=NONE term=NONE cterm=NONE guifg=#7fb4ca guibg=NONE ctermfg=110 ctermbg=NONE
hi Removed gui=NONE term=NONE cterm=NONE guifg=#e46876 guibg=NONE ctermfg=203 ctermbg=NONE
hi link Character String
hi ColorColumn gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#2a2a37 ctermfg=NONE ctermbg=235
hi Comment gui=NONE term=italic cterm=NONE guifg=#727169 guibg=NONE ctermfg=242 ctermbg=NONE
hi Conceal gui=bold term=bold cterm=bold guifg=#938aa9 guibg=NONE ctermfg=103 ctermbg=NONE
hi link Conditional Statement
hi Constant gui=NONE term=NONE cterm=NONE guifg=#ffa066 guibg=NONE ctermfg=215 ctermbg=NONE
hi CurSearch gui=bold term=bold cterm=bold guifg=#dcd7ba guibg=#2d4f67 ctermfg=187 ctermbg=238
hi Cursor gui=NONE term=NONE cterm=NONE guifg=#1f1f28 guibg=#dcd7ba ctermfg=234 ctermbg=187
hi link CursorColumn CursorLine
hi link CursorIM Cursor
hi CursorLine gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#363646 ctermfg=NONE ctermbg=237
hi link CursorLineFold FoldColumn
hi CursorLineNr gui=bold term=bold cterm=bold guifg=#ff9e3b guibg=#2a2a37 ctermfg=215 ctermbg=235
hi link CursorLineSign SignColumn
hi link Debug Special
hi link Define PreProc
hi Delimiter gui=NONE term=NONE cterm=NONE guifg=#9cabca guibg=NONE ctermfg=248 ctermbg=NONE
hi DiffAdd gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#2b3328 ctermfg=NONE ctermbg=236
hi DiffChange gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#252535 ctermfg=NONE ctermbg=235
hi DiffDelete gui=NONE term=NONE cterm=NONE guifg=#c34043 guibg=#43242b ctermfg=131 ctermbg=235
hi DiffText gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#49443c ctermfg=NONE ctermbg=238
hi Directory gui=NONE term=NONE cterm=NONE guifg=#7e9cd8 guibg=NONE ctermfg=246 ctermbg=NONE
hi EndOfBuffer gui=NONE term=NONE cterm=NONE guifg=#1f1f28 guibg=NONE ctermfg=234 ctermbg=NONE
hi Error gui=NONE term=NONE cterm=NONE guifg=#e82424 guibg=NONE ctermfg=160 ctermbg=NONE
hi ErrorMsg gui=NONE term=NONE cterm=NONE guifg=#e82424 guibg=NONE ctermfg=160 ctermbg=NONE
hi Exception gui=NONE term=NONE cterm=NONE guifg=#e46876 guibg=NONE ctermfg=168 ctermbg=NONE
hi link Float Number
hi FoldColumn gui=NONE term=NONE cterm=NONE guifg=#54546d guibg=#2a2a37 ctermfg=240 ctermbg=235
hi Folded gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=#2a2a37 ctermfg=103 ctermbg=235
hi Function gui=NONE term=NONE cterm=NONE guifg=#7e9cd8 guibg=NONE ctermfg=246 ctermbg=NONE
hi Identifier gui=NONE term=NONE cterm=NONE guifg=#e6c384 guibg=NONE ctermfg=251 ctermbg=NONE
hi link Ignore NonText
hi IncSearch gui=NONE term=NONE cterm=NONE guifg=#223249 guibg=#ff9e3b ctermfg=236 ctermbg=215
hi link Include PreProc
hi Keyword gui=italic term=italic cterm=italic guifg=#957fb8 guibg=NONE ctermfg=103 ctermbg=NONE
hi link Label Statement
hi LineNr gui=NONE term=NONE cterm=NONE guifg=#54546d guibg=#2a2a37 ctermfg=240 ctermbg=235
hi link LineNrAbove LineNr
hi link LineNrBelow LineNr
hi link Macro PreProc
hi MatchParen gui=bold term=bold cterm=bold guifg=#ff9e3b guibg=NONE ctermfg=215 ctermbg=NONE
hi ModeMsg gui=bold term=bold cterm=bold guifg=#ff9e3b guibg=NONE ctermfg=215 ctermbg=NONE
hi MoreMsg gui=NONE term=NONE cterm=NONE guifg=#658594 guibg=NONE ctermfg=66 ctermbg=NONE
hi NonText gui=NONE term=NONE cterm=NONE guifg=#54546d guibg=NONE ctermfg=240 ctermbg=NONE
hi Normal gui=NONE term=NONE cterm=NONE guifg=#dcd7ba guibg=#1f1f28 ctermfg=187 ctermbg=234
hi Number gui=NONE term=NONE cterm=NONE guifg=#d27e99 guibg=NONE ctermfg=174 ctermbg=NONE
hi Operator gui=NONE term=NONE cterm=NONE guifg=#c0a36e guibg=NONE ctermfg=143 ctermbg=NONE
hi Pmenu gui=NONE term=NONE cterm=NONE guifg=#dcd7ba guibg=#223249 ctermfg=187 ctermbg=236
hi PmenuExtra gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=#223249 ctermfg=103 ctermbg=236
hi PmenuExtraSel gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=#2d4f67 ctermfg=103 ctermbg=238
hi PmenuKind gui=NONE term=NONE cterm=NONE guifg=#c8c093 guibg=#223249 ctermfg=7 ctermbg=236
hi PmenuKindSel gui=NONE term=NONE cterm=NONE guifg=#c8c093 guibg=#2d4f67 ctermfg=7 ctermbg=238
hi PmenuMatch gui=bold term=bold cterm=bold guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi PmenuMatchSel gui=bold term=bold cterm=bold guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE
hi PmenuSbar gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#223249 ctermfg=NONE ctermbg=236
hi PmenuSel gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#2d4f67 ctermfg=NONE ctermbg=238
hi PmenuThumb gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#2d4f67 ctermfg=NONE ctermbg=238
hi link PreCondit PreProc
hi PreProc gui=NONE term=NONE cterm=NONE guifg=#e46876 guibg=NONE ctermfg=168 ctermbg=NONE
hi link Question MoreMsg
hi QuickFixLine gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#2a2a37 ctermfg=NONE ctermbg=235
hi link Repeat Statement
hi Search gui=NONE term=NONE cterm=NONE guifg=#dcd7ba guibg=#2d4f67 ctermfg=187 ctermbg=238
hi SignColumn gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=#2a2a37 ctermfg=103 ctermbg=235
hi Special gui=NONE term=NONE cterm=NONE guifg=#7fb4ca guibg=NONE ctermfg=110 ctermbg=NONE
hi link SpecialChar Special
hi link SpecialComment Special
hi SpecialKey gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=NONE ctermfg=103 ctermbg=NONE
hi SpellBad gui=undercurl term=undercurl cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=#e82424
hi SpellCap gui=undercurl term=undercurl cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=#ff9e3b
hi SpellLocal gui=undercurl term=undercurl cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=#ff9e3b
hi SpellRare gui=undercurl term=undercurl cterm=undercurl guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE guisp=#ff9e3b
hi Statement gui=bold term=bold cterm=bold guifg=#957fb8 guibg=NONE ctermfg=103 ctermbg=NONE
hi StatusLine gui=NONE term=NONE cterm=NONE guifg=#c8c093 guibg=#16161d ctermfg=7 ctermbg=233
hi StatusLineNC gui=NONE term=NONE cterm=NONE guifg=#54546d guibg=#16161d ctermfg=240 ctermbg=233
hi link StatusLineTerm StatusLine
hi link StatusLineTermNC StatusLineNC
hi link StorageClass Type
hi String gui=NONE term=NONE cterm=NONE guifg=#98bb6c guibg=NONE ctermfg=107 ctermbg=NONE
hi link Structure Type
hi TabLine gui=NONE term=NONE cterm=NONE guifg=#938aa9 guibg=#16161d ctermfg=103 ctermbg=233
hi TabLineFill gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#1f1f28 ctermfg=NONE ctermbg=234
hi TabLineSel gui=NONE term=NONE cterm=NONE guifg=#c8c093 guibg=#2a2a37 ctermfg=7 ctermbg=235
hi link Tag Special
hi Title gui=bold term=bold cterm=bold guifg=#7e9cd8 guibg=NONE ctermfg=246 ctermbg=NONE
hi Todo gui=bold term=bold cterm=bold guifg=#223249 guibg=#658594 ctermfg=236 ctermbg=66
hi Type gui=NONE term=NONE cterm=NONE guifg=#7aa89f guibg=NONE ctermfg=109 ctermbg=NONE
hi link Typedef Type
hi Underlined gui=underline term=underline cterm=underline guifg=#7fb4ca guibg=NONE ctermfg=110 ctermbg=NONE
hi link VertSplit WinSeparator
hi Visual gui=NONE term=NONE cterm=NONE guifg=NONE guibg=#223249 ctermfg=NONE ctermbg=236
hi link VisualNOS Visual
hi WarningMsg gui=NONE term=NONE cterm=NONE guifg=#ff9e3b guibg=NONE ctermfg=215 ctermbg=NONE
hi link WildMenu Pmenu
hi link lCursor Cursor
hi WinSeparator gui=NONE term=NONE cterm=NONE guifg=#16161d guibg=NONE ctermfg=233 ctermbg=NONE

" ============================================================================
" End of kanagawa (Wave) Colorscheme
" ============================================================================
