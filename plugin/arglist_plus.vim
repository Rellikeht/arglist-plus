" settings {{{

if exists("g:loaded_arglist_plus")
  finish
endif
let g:loaded_arglist_plus = 1

" TODO local/global, fresh/copied
let g:arglist_plus#tab_local = 1
let g:arglist_plus#tab_empty = 0
let g:arglist_plus#win_local = 0
let g:arglist_plus#win_empty = 0

" }}}

" functions {{{

" helpers {{{

function s:cbang(command, bang)
  return a:command.(a:bang ? "!" : "")
endfunction

function s:check_var(name, scopes)
  for scope in a:scopes
    let l:var = scope.":".a:name
    if exists(l:var) && eval(l:var)
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:instantiate(args)
  return join(map(a:args, 'fnameescape(v:val)'), " ")
endfunction

" }}}

" information {{{

function arglist_plus#ArgList()
  " return default list representation
  return execute("args")
endfunction

function arglist_plus#ArgVList()
  " return list representation with each argument on separate line
  let l:args = argv()
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, "\n")
endfunction

function arglist_plus#ArgHList()
  " return list representation that takes only one line
  let l:args = argv()
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, " ")
endfunction

function arglist_plus#ArgAList()
  let l:horizontal = arglist_plus#ArgHList()
  if len(l:horizontal) <= &columns
    return l:horizontal
  endif
  return arglist_plus#ArgVList()
endfunction

" }}}

" navigation {{{

function arglist_plus#ArgNext(bang, n)
  let l:n = (argidx() + a:n) % argc()
  exe s:cbang("argument", a:bang)." ".(l:n + 1)
endfunction

function arglist_plus#ArgPrev(bang, n)
  let l:n = (argc() + argidx() - a:n % argc()) % argc()
  exe s:cbang("argument", a:bang)." ".(l:n + 1)
endfunction

function arglist_plus#ArgSel(bang, n=0)
  if a:n == 0
    exe s:cbang("argument", a:bang)
  else
    exe s:cbang("argument", a:bang)." ".a:n
  endif
endfunction

function arglist_plus#ArgGo(bang, name="")
  if a:name == ""
    exe s:cbang("argument", a:bang)
  else
    " avoid duplication of entries
    " version with argdedupe doesn't work sometimes
    let l:idx = index(argv(), a:name)
    if l:idx == -1
      exe s:cbang("argedit", a:bang)." ".a:name
    else
      exe s:cbang("argument", a:bang)." ".(l:idx + 1)
    endif
  endif
endfunction

" }}}

" operations on list elements {{{

function arglist_plus#ArgAdd(...)
  let l:cmd = "argadd "
  for arg in a:000
    for file in split(expand(arg), "\n")
      if index(argv(), file) == -1
        let l:cmd = l:cmd." ".fnameescape(file)
      endif
    endfor
  endfor
  exe l:cmd
endfunction

function arglist_plus#ArgEdit(bang, ...)
  " adds arguments to list and edits first
  let l:first = split(expand(a:1), "\n")[0]
  let l:idx = index(argv(), l:first)
  if l:idx == -1
    let l:idx = argc()
  endif
  call call("arglist_plus#ArgAdd", a:000)
  exe s:cbang("argument", a:bang)." ".(l:idx + 1)
endfunction

function arglist_plus#ArgDel(bang, ...)
  " deletes argument from list
  " TODO
endfunction

function arglist_plus#ArgBufDel(bang, ...)
  " deletes argument from list and it's corresponding buffer
  " TODO
endfunction

function arglist_plus#ArgFileDel(bang, ...)
  " deletes argument from list, it's corresponding buffer and file
  " TODO
endfunction

" }}}

" operations on lists {{{

function arglist_plus#ArgLtoG()
  " replaces global with copy of local
  if arglistid() == 0
    throw "Not using local arglist"
  endif
  exe "argglobal ".s:instantiate(argv())
endfunction

function arglist_plus#ArgGtoL()
  " replaces local with copy of global
  arglocal
endfunction

function arglist_plus#ArgExchange()
  " exchanges global and local
  if arglistid() == 0
    throw "Arglist isn't local, there is nothing to exchange"
  endif
  let l:local_copy = argv()
  arglocal
  let l:global_copy = argv()
  exe "argglobal ".s:instantiate(l:local_copy)
  exe "arglocal ".s:instantiate(l:global_copy)
endfunction

" }}}

" }}}

" commands {{{

command! -count=1 -bang ArgNext
      \ call arglist_plus#ArgNext(<bang>0, <count>)
command! -count=1 -bang ArgPrev
      \ call arglist_plus#ArgPrev(<bang>0, <count>)
command! -count=0 -bang ArgSel
      \ call arglist_plus#ArgSel(<bang>0, <count>)
command! -nargs=? -bang ArgSelN
      \ call arglist_plus#ArgSel(<bang>0, 0<f-args>)
command! -nargs=? -bang -complete=arglist ArgGo
      \ call arglist_plus#ArgGo(<bang>0, <f-args>)

" TODO counts
command! -nargs=+ -complete=file ArgAdd
      \ call arglist_plus#ArgAdd(<f-args>)
command! -nargs=+ -complete=buffer ArgAddBuf
      \ call arglist_plus#ArgAdd(<f-args>)
command! -nargs=+ -bang -complete=file ArgEdit
      \ call arglist_plus#ArgEdit(<bang>0, <f-args>)
command! -nargs=+ -bang -complete=buffer ArgEditBuf
      \ call arglist_plus#ArgEdit(<bang>0, <f-args>)

command! -nargs=* -bang -complete=arglist ArgDel
      \ call arglist_plus#ArgDel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ArgBufDel
      \ call arglist_plus#ArgBufDel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ArgFileDel
      \ call arglist_plus#ArgFileDel(<bang>0, <f-args>)

command! -nargs=0 ArgList echo arglist_plus#ArgList()
command! -nargs=0 ArgVList echo arglist_plus#ArgVList()
command! -nargs=0 ArgHList echo arglist_plus#ArgHList()
command! -nargs=0 ArgAList echo arglist_plus#ArgAList()

command! -nargs=0 ArgGtoL call arglist_plus#ArgGtoL()
command! -nargs=0 ArgLtoG call arglist_plus#ArgLtoG()
command! -nargs=0 ArgExchange call arglist_plus#ArgExchange()

" }}}

" maps {{{

" basic {{{

map <Plug>ArgNext :ArgNext<CR>
map <Plug>ArgPrev :ArgPrev<CR>
map <Plug>ArgSel :ArgSel<CR>
map <Plug>ArgGo :<C-u>ArgGo<CR>
map <Plug>Arg!Next :ArgNext!<CR>
map <Plug>Arg!Prev :ArgPrev!<CR>
map <Plug>Arg!Sel :ArgSel!<CR>
map <Plug>Arg!Go :<C-u>ArgGo!<CR>

map <Plug>ArgAdd :<C-u>ArgAdd<CR>
map <Plug>ArgEdit :<C-u>ArgEdit<CR>
map <Plug>Arg!Edit :<C-u>ArgEdit<CR>

map <Plug>ArgDel :<C-u>ArgDel<CR>
map <Plug>ArgDelBuf :<C-u>ArgDelBuf<CR>
map <Plug>Arg!Del :<C-u>ArgDel<CR>
map <Plug>Arg!DelBuf :<C-u>ArgDelBuf<CR>

map <Plug>ArgList :<C-u>ArgList<CR>
map <Plug>ArgVList :<C-u>ArgVList<CR>
map <Plug>ArgHList :<C-u>ArgHList<CR>
map <Plug>ArgAList :<C-u>ArgAList<CR>

map <Plug>ArgGtoL :<C-u>ArgGtoL<CR>
map <Plug>ArgLtoG :<C-u>ArgLtoG<CR>

" }}}

" predefined numbers {{{

map <Plug>ArgSel1 :<C-u>ArgSelN 1<CR>
map <Plug>ArgSel2 :<C-u>ArgSelN 2<CR>
map <Plug>ArgSel3 :<C-u>ArgSelN 3<CR>
map <Plug>ArgSel4 :<C-u>ArgSelN 4<CR>
map <Plug>ArgSel5 :<C-u>ArgSelN 5<CR>
map <Plug>ArgSel6 :<C-u>ArgSelN 6<CR>
map <Plug>ArgSel7 :<C-u>ArgSelN 7<CR>
map <Plug>ArgSel8 :<C-u>ArgSelN 8<CR>
map <Plug>ArgSel9 :<C-u>ArgSelN 9<CR>

map <Plug>Arg!Sel1 :<C-u>ArgSelN! 1<CR>
map <Plug>Arg!Sel2 :<C-u>ArgSelN! 2<CR>
map <Plug>Arg!Sel3 :<C-u>ArgSelN! 3<CR>
map <Plug>Arg!Sel4 :<C-u>ArgSelN! 4<CR>
map <Plug>Arg!Sel5 :<C-u>ArgSelN! 5<CR>
map <Plug>Arg!Sel6 :<C-u>ArgSelN! 6<CR>
map <Plug>Arg!Sel7 :<C-u>ArgSelN! 7<CR>
map <Plug>Arg!Sel8 :<C-u>ArgSelN! 8<CR>
map <Plug>Arg!Sel9 :<C-u>ArgSelN! 9<CR>

" }}}

" }}}

" setup {{{

" TODO how to properly copy when needed
" function s:tab_arglist()
"   if s:check_var("arglist_plus#tab_local", ["t", "g"])
"     arglocal
"     if s:check_var("arglist_plus#tab_empty", ["t", "g"])
"       %argd
"     endif
"   endif
" endfunction

" autocmd TabNew * call s:tab_arglist()
" autocmd WinNew * call s:win_arglist()

" }}}
