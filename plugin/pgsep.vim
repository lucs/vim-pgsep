" Plugin for handling custom page separator strings
" Maintainer:    Luc St-Louis <lucs@pobox.com>
" License:       Same terms as Vim itself
" Documentation: See ../doc/pgsep.txt

" --------------------------------------------------------------------
    " Holds the defined page separators.
    " g:PgSep_defs[｢nick｣] = {'patt':｢patt｣, 'line':｢line｣}
let g:PgSep_defs = {}

let g:_hPgSep = 'Help.Add.Rem.Line.Only.Main.inSr'

    " The page separators used in the current buffer. Keys are nicks,
    " and if a given key is present, that page separator is currently
    " used.
let b:PgSep_use_patt = {}

    " The page separator pattern used in the current buffer. It is a ｢|｣
    " concatenated list of the ｢b:PgSep_use_patt｣ patterns.
let b:PgSep_patt = ''

    " The line inserted by PgSep_insert().
let b:PgSep_line = ''

" --------------------------------------------------------------------
" Add (or replace) a pgsep to g:PgSep_defs.

func! PgSep_New (nick, patt, line)
    let g:PgSep_defs[a:nick] = {'patt':a:patt, 'line':a:line}
endfunc

" --------------------------------------------------------------------
" Add a pgsep definition to the current buffer.

func! PgSep_AddPatt (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    let b:PgSep_use_patt[a:nick] = 1
    call s:build_sep_patt()
endfunc

" --------------------------------------------------------------------
" Remove a pgsep definition from the current buffer.

func! PgSep_RemPatt (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    unlet b:PgSep_use_patt[a:nick]
    call s:build_sep_patt()
endfunc

" --------------------------------------------------------------------
" Make the nick's line be the one to get inserted by PgSep_insert().

func! PgSep_SetLine (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    let b:PgSep_line = g:PgSep_defs[a:nick]['line']
endfunc

" --------------------------------------------------------------------
" Make a pgsep the only one defined for the current buffer.

func! PgSep_OnlyPatt (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    let b:PgSep_use_patt = {}
    let b:PgSep_patt = ''
    call PgSep_AddPatt(a:nick)
    call PgSep_SetLine(a:nick)
endfunc

" --------------------------------------------------------------------
func! PgSep_Main (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    call PgSep_AddPatt(a:nick)
    call PgSep_SetLine(a:nick)
endfunc

" --------------------------------------------------------------------
" Insert the pgsep line separator for the current buffer.
" FIXME

func! PgSep_InsertLine (nick)
    if ! exists("g:PgSep_defs[a:nick]")
        echo "No such PgSep nick: '" . a:nick . "'."
        return
    endif
    call append(line(".") - 1, g:PgSep_defs[a:nick]['line'])
    normal k
endfunc

" --------------------------------------------------------------------
" Construct the pgsep pattern for all the pgseps set for the current
" buffer.

func! s:build_sep_patt ()
    if len(b:PgSep_use_patt) == 0
        return
    endif
    let l:patt = ""
    for [l:nick, l:dont_care] in items(b:PgSep_use_patt)
        let l:patt .= g:PgSep_defs[l:nick]['patt'] . '\|'
    endfor
        " Chop trailing spurious '\|'.
    let l:patt = substitute(l:patt, '..$', '', '')
    let b:PgSep_patt = l:patt
endfunc

" --------------------------------------------------------------------
" Insert the pgsep line separator for the current buffer.

func! PgSep_insert ()
    if b:PgSep_line == ''
        echo "PgSep line has not been set."
        return
    endif
    call append(line(".") - 1, b:PgSep_line)
    normal k
endfunc

" --------------------------------------------------------------------
" Make all requested pgseps the ones for the current buffer.

func! PgSep_All (...)
    let b:PgSep_use_patt = {}
    if a:0 == 0
        return
    endif
    for l:nick in a:000
        if exists("g:PgSep_defs[l:nick]")
            call PgSep_AddPatt(l:nick)
        endif
    endfor
    call PgSep_SetLine(a:1)
endfunc

" --------------------------------------------------------------------
func! PgSep_up ()
    call PgSep_move('k')
endfunc

func! PgSep_dn ()
    call PgSep_move('j')
endfunc

" --------------------------------------------------------------------
func! PgSep_move(j_or_k)
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

func! _makePgSep (params)
    let l:what = a:params[0]
    let l:nick = a:params[1]
        " If 1, have a space between l:open and l:midl, else don't.
    let l:spac = a:params[2]
    let l:open = a:params[3]
    let l:midl = a:params[4]
    let l:clos = exists("a:params[5]") ? a:params[5] : ''

    let g:_hPgSep .= ':' . l:what

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

    exec 'menu pgsep.add.'  . l:nick . " :call PgSep_AddPatt('"     . l:nick . "')<cr>"
    exec 'menu pgsep.rem.'  . l:nick . " :call PgSep_RemPatt('"     . l:nick . "')<cr>"
    exec 'menu pgsep.line.' . l:nick . " :call PgSep_SetLine('"     . l:nick . "')<cr>"
    exec 'menu pgsep.only.' . l:nick . " :call PgSep_OnlyPatt('"    . l:nick . "')<cr>"
    exec 'menu pgsep.main.' . l:nick . " :call PgSep_Main('"        . l:nick . "')<cr>"
    exec 'menu pgsep.insr.' . l:nick . " :call PgSep_InsertLine('"  . l:nick . "')<cr>"

    if l:spac == 1
        call PgSep_New(
          \ l:nick,
          \ '^\(\V' . l:open . '\m \)\+\V' . repeat(l:midl, 10) . '\m',
          \ l:PgSep
        \)
    else
        call PgSep_New(
          \ l:nick,
          \ '\V' . repeat(l:midl, 10) . '\m',
          \ l:PgSep
        \)
    endif
endfunc

" --------------------------------------------------------------------
func! _MakePgSeps ()
    call _makePgSep(['Bash',    'b', 1, '#',    '-'])
    call _makePgSep(['C',       'c', 1, '/*',   '-', '*/'])
    call _makePgSep(['Dos',     'd', 1, ':-',   '-'])
    call _makePgSep(['tExt',    'e', 1, '-',    '-'])
    call _makePgSep(['Html',    'h', 1, '<!--', '·', '-->'])
    call _makePgSep(['vImhelp', 'i', 0, '=',    '='])
    call _makePgSep(['Java',    'j', 1, '//',   '-'])
    call _makePgSep(['Lisp',    'l', 1, ';',    '-'])
    call _makePgSep(['vrOomx',  'o', 1, '#%',   '-'])
    call _makePgSep(['sQl',     'q', 1, '--',   '-'])
    call _makePgSep(['Tt2',     't', 1, '[%#-', '-', '-%]'])
    call _makePgSep(['Vim',     'v', 1, '"',    '-'])
    call _makePgSep(['teX',     'x', 1, '%',    '-'])
    call _makePgSep(['dZil',    'z', 1, ';-',   '-'])
endfunc
call _MakePgSeps()

" --------------------------------------------------------------------
" Default mappings.

if ! hasmapto('<Plug>pg_sepUp')
    map <leader>k <plug>pg_sepUp
endif
if ! hasmapto('<Plug>pg_sepDn')
    map <leader>j <plug>pg_sepDn
endif
if ! hasmapto('<Plug>pg_sepInsert')
    map <leader>i <plug>pg_sepInsert
endif

map <plug>pg_sepUp     :call PgSep_up()<cr>
map <plug>pg_sepDn     :call PgSep_dn()<cr>
map <plug>pg_sepInsert :call PgSep_insert()<cr>

map <leader>h :echo g:_hPgSep<cr>
map <leader>a :emenu pgsep.add.
map <leader>r :emenu pgsep.rem.
map <leader>l :emenu pgsep.line.
map <leader>o :emenu pgsep.only.
map <leader>m :emenu pgsep.main.
map <leader>s :emenu pgsep.insr.

