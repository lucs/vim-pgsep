" Plugin for handling custom page separator strings
" Maintainer:    Luc St-Louis <lucs@pobox.com>
" License:       Same terms as Vim itself
" Documentation: See ../doc/pgsep.txt

" --------------------------------------------------------------------
if exists("g:loaded_pgsep") || &cp || v:version < 700
    finish
endif
let g:loaded_pgsep = 1

" --------------------------------------------------------------------
    " Holds the defined page separators.
    " g:PgSep_defs[⟨tag⟩] = {'patt':⟨patt⟩, 'line':⟨line⟩}
let g:PgSep_defs = {}

let g:PgSep_help = 'Help.Add.Rem.Line.Only.Main.Insr'

    " The page separators used in the current buffer. Keys are tags,
    " and if a given key is present, that page separator is currently
    " used.
let b:PgSep_use_patt = {}

    " The page separator pattern used in the current buffer. It is a ‹|›
    " concatenated list of the ‹b:PgSep_use_patt› patterns.
let b:PgSep_patt = ''

    " The line inserted by PgSep_Insr().
let b:PgSep_line = ''

" --------------------------------------------------------------------
func! PgSep_New (tag, patt, line)
    let g:PgSep_defs[a:tag] = {'patt':a:patt, 'line':a:line}
endfunc

" --------------------------------------------------------------------
func! PgSep_Add (tag)
    if ! exists("g:PgSep_defs[a:tag]")
        echo "No such PgSep tag: '" . a:tag . "'."
        return
    endif
    let b:PgSep_use_patt[a:tag] = 1
    call s:build_pgsep_patt()
endfunc

" --------------------------------------------------------------------
func! PgSep_Rem (tag)
    if ! exists("g:PgSep_defs[a:tag]")
        echo "No such PgSep tag: '" . a:tag . "'."
        return
    endif
    let b:PgSep_use_patt[a:tag] = 0
   " unlet b:PgSep_use_patt[a:tag]
    call s:build_pgsep_patt()
endfunc

" --------------------------------------------------------------------
" Construct the pgsep pattern for all the pgseps set for the current
" buffer.

func! s:build_pgsep_patt ()
    if len(b:PgSep_use_patt) == 0
        return
    endif
    let l:patt = ""
    for [l:tag, l:dont_care] in items(b:PgSep_use_patt)
        if b:PgSep_use_patt[l:tag] == 1
            let l:patt .= g:PgSep_defs[l:tag]['patt'] . '\|'
        endif
    endfor
        " Chop trailing spurious '\|'.
    let l:patt = substitute(l:patt, '..$', '', '')
    let b:PgSep_patt = l:patt
endfunc

" --------------------------------------------------------------------
func! PgSep_Only (tag)
    if ! exists("g:PgSep_defs[a:tag]")
        echo "No such PgSep tag: '" . a:tag . "'."
        return
    endif
    let b:PgSep_use_patt = {}
    let b:PgSep_patt = ''
    call PgSep_Add(a:tag)
    call PgSep_Line(a:tag)
endfunc

" --------------------------------------------------------------------
func! PgSep_Line (tag)
    if ! exists("g:PgSep_defs[a:tag]")
        echo "No such PgSep tag: '" . a:tag . "'."
        return
    endif
    let b:PgSep_line = g:PgSep_defs[a:tag]['line']
endfunc

" --------------------------------------------------------------------
func! PgSep_Main (tag)
    if ! exists("g:PgSep_defs[a:tag]")
        echo "No such PgSep tag: '" . a:tag . "'."
        return
    endif
    call PgSep_Add(a:tag)
    call PgSep_Line(a:tag)
endfunc

" --------------------------------------------------------------------
func! PgSep_All (...)
    let b:PgSep_use_patt = {}
    if a:0 == 0
        return
    endif
    for l:tag in a:000
        if exists("g:PgSep_defs[l:tag]")
            call PgSep_Add(l:tag)
        endif
    endfor
    call PgSep_Line(a:1)
endfunc

" --------------------------------------------------------------------
func! PgSep_Insr (...)
    if a:0 == 0
        if b:PgSep_line == ''
            echo "PgSep line has not been set."
            return
        endif
        call append(line(".") - 1, b:PgSep_line)
        normal k
    elseif ! exists("g:PgSep_defs[a:1]")
        echo "No such PgSep tag: '" . a:1 . "'."
        return
    else
        call append(line(".") - 1, g:PgSep_defs[a:1]['line'])
        normal k
    endif
endfunc

" --------------------------------------------------------------------
func! PgSep_Move(j_or_k)
    let l:last_line = line(".")
    while (1)
        exec 'normal ' . a:j_or_k
        let l:curr_line = line(".")
        if (l:curr_line == l:last_line)
            break
        endif
        let l:last_line = l:curr_line
        let Text = getline(l:curr_line)
        if (match(Text, b:PgSep_patt) != -1)
                " We found a page separator.
            normal zt
            echo ""
            return
        endif
    endwhile
    if (a:j_or_k == 'j')
            " No more page separators follow.
        echo "End of file."
    elseif (a:j_or_k == 'k')
            " No more page separators precede.
        echo "Top of file."
    endif
endfunc

" --------------------------------------------------------------------
func! s:make_pgsep (params)
    let l:name = a:params[0]
    let l:tag = a:params[1]
        " If 1, have a space between l:open and l:midl, else don't.
    let l:spac = a:params[2]
    let l:open = a:params[3]
    let l:midl = a:params[4]
    let l:clos = exists("a:params[5]") ? a:params[5] : ''

    let g:PgSep_help .= ':' . l:name

    let l:len_open = strlen(l:open)
    let l:len_clos = strlen(l:clos)

    let l:nb_midl = 70 - (l:spac ? 1 : 0) - l:len_open
    if l:len_clos != 0
        let l:nb_midl -= l:len_clos + 1
    endif
    let l:PgSep = l:open . (l:spac ? ' ' : '') . repeat(l:midl, l:nb_midl)
    if l:len_clos != 0
        let l:PgSep .= ' ' . l:clos
    endif

    exec 'menu pgsep.add.'  . l:tag . " :call PgSep_Add('"  . l:tag . "')<cr>"
    exec 'menu pgsep.rem.'  . l:tag . " :call PgSep_Rem('"  . l:tag . "')<cr>"
    exec 'menu pgsep.only.' . l:tag . " :call PgSep_Only('" . l:tag . "')<cr>"
    exec 'menu pgsep.line.' . l:tag . " :call PgSep_Line('" . l:tag . "')<cr>"
    exec 'menu pgsep.main.' . l:tag . " :call PgSep_Main('" . l:tag . "')<cr>"
    exec 'menu pgsep.insr.' . l:tag . " :call PgSep_Insr('" . l:tag . "')<cr>"

        " Allow whitespace at the beginning of a separator line.
        " Added ‹^\s*› in front.
    if l:spac == 1
        call PgSep_New(
          \ l:tag,
          \ '^\s*\(\V' . l:open . '\m \)\+\V' . repeat(l:midl, 10) . '\m',
          \ l:PgSep
        \)
    else
        call PgSep_New(
          \ l:tag,
          \ '^\s*\V' . repeat(l:midl, 10) . '\m',
          \ l:PgSep
        \)
    endif
endfunc

" --------------------------------------------------------------------
func! s:make_pgseps ()
    call s:make_pgsep(['!',    '!', 1, '!',    '-'])
    call s:make_pgsep(['Bash',    'b', 1, '#',    '-'])
    call s:make_pgsep(['C',       'c', 1, '/*',   '-', '*/'])
    call s:make_pgsep(['Dos',     'd', 1, ':-',   '-'])
    call s:make_pgsep(['tExt',    'e', 1, '-',    '-'])
    call s:make_pgsep(['Html',    'h', 1, '<!--', '·', '-->'])
    call s:make_pgsep(['vImhelp', 'i', 0, '=',    '='])
    call s:make_pgsep(['Java',    'j', 1, '//',   '-'])
    call s:make_pgsep(['Lisp',    'l', 1, ';',    '-'])
    call s:make_pgsep(['!map',    '!', 1, '!',    '-'])
    call s:make_pgsep(['tMplmojo','m', 1, '%#',   '-'])
    call s:make_pgsep(['vrOomx',  'o', 1, '#%',   '-'])
    call s:make_pgsep(['sQl',     'q', 1, '--',   '-'])
    call s:make_pgsep(['xRes',    'r', 1, '!',    '-'])
    call s:make_pgsep(['Tt2',     't', 1, '[%#-', '-', '-%]'])
    call s:make_pgsep(['Vim',     'v', 1, '"',    '-'])
    call s:make_pgsep(['teX',     'x', 1, '%',    '-'])
    call s:make_pgsep(['dZil',    'z', 1, ';-',   '-'])
endfunc
call s:make_pgseps()

" --------------------------------------------------------------------
nnoremap <silent> <plug>pgsepUp  :call  PgSep_Move('k')<cr>
nnoremap <silent> <plug>pgsepDn  :call  PgSep_Move('j')<cr>
nnoremap <silent> <plug>pgsepIn  :call  PgSep_Insr()<cr>
nnoremap          <plug>menuHelp :echo  g:PgSep_help<cr>
nnoremap          <plug>menuAdd  :emenu pgsep.add.
nnoremap          <plug>menuRem  :emenu pgsep.rem.
nnoremap          <plug>menuLine :emenu pgsep.line.
nnoremap          <plug>menuOnly :emenu pgsep.only.
nnoremap          <plug>menuMain :emenu pgsep.main.
nnoremap          <plug>menuInsr :emenu pgsep.insr.

if ! exists("g:PgSep_no_mappings") || ! g:PgSep_no_mappings
    nmap <space>k  <plug>pgsepUp
    nmap <space>j  <plug>pgsepDn
    nmap <space>i  <plug>pgsepIn
    nmap yuh       <plug>menuHelp
    nmap yua       <plug>menuAdd
    nmap yur       <plug>menuRem
    nmap yul       <plug>menuLine
    nmap yuo       <plug>menuOnly
    nmap yum       <plug>menuMain
    nmap yui       <plug>menuInsr
endif

