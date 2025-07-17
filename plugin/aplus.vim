" settings {{{

if exists("g:loaded_aplus")
  finish
endif
let g:loaded_aplus = 1

" TODO local/global, fresh/copied
let g:aplus#tab_local = 1
let g:aplus#tab_empty = 0
let g:aplus#win_local = 0
let g:aplus#win_empty = 0

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

function aplus#AList()
  " return default list representation
  return execute("args")
endfunction

function aplus#AVList()
  " return list representation with each argument on separate line
  let l:args = argv()
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, "\n")
endfunction

function aplus#AHList()
  " return list representation that takes only one line
  let l:args = argv()
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, " ")
endfunction

function aplus#AAList()
  let l:horizontal = aplus#AHList()
  if len(l:horizontal) <= &columns
    return l:horizontal
  endif
  return aplus#AVList()
endfunction

" }}}

" navigation {{{

function aplus#ANext(bang, n)
  let l:n = (argidx() + a:n) % argc()
  exe s:cbang("argument", a:bang)." ".(l:n + 1)
endfunction

function aplus#APrev(bang, n)
  let l:n = (argc() + argidx() - a:n % argc()) % argc()
  exe s:cbang("argument", a:bang)." ".(l:n + 1)
endfunction

function aplus#ASel(bang, n=0)
  if a:n == 0
    exe s:cbang("argument", a:bang)
  else
    exe s:cbang("argument", a:bang)." ".a:n
  endif
endfunction

function aplus#AGo(bang, name="")
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

function aplus#AAdd(...)
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

function aplus#AEdit(bang, ...)
  " adds arguments to list and edits first
  let l:first = split(expand(a:1), "\n")[0]
  let l:idx = index(argv(), l:first)
  if l:idx == -1
    let l:idx = argc()
  endif
  call call("aplus#AAdd", a:000)
  exe s:cbang("argument", a:bang)." ".(l:idx + 1)
endfunction

function aplus#ADel(bang, ...)
  " deletes argument from list
  " TODO
endfunction

function aplus#ABufDel(bang, ...)
  " deletes argument from list and it's corresponding buffer
  " TODO
endfunction

function aplus#AFileDel(bang, ...)
  " deletes argument from list, it's corresponding buffer and file
  " TODO
endfunction

" }}}

" operations on lists {{{

function aplus#ALtoG()
  " replaces global with copy of local
  if arglistid() == 0
    throw "Not using local arglist"
  endif
  exe "argglobal ".s:instantiate(argv())
endfunction

function aplus#AGtoL()
  " replaces local with copy of global
  arglocal
endfunction

function aplus#AExchange()
  " exchanges global and local
  if arglistid() == 0
    throw "Alist isn't local, there is nothing to exchange"
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

command! -count=1 -bang ANext
      \ call aplus#ANext(<bang>0, <count>)
command! -count=1 -bang APrev
      \ call aplus#APrev(<bang>0, <count>)
command! -count=0 -bang ASel
      \ call aplus#ASel(<bang>0, <count>)
command! -nargs=? -bang ASelN
      \ call aplus#ASel(<bang>0, 0<f-args>)
command! -nargs=? -bang -complete=arglist AGo
      \ call aplus#AGo(<bang>0, <f-args>)

" TODO counts
command! -nargs=+ -complete=file AAdd
      \ call aplus#AAdd(<f-args>)
command! -nargs=+ -complete=buffer AAddBuf
      \ call aplus#AAdd(<f-args>)
command! -nargs=+ -bang -complete=file AEdit
      \ call aplus#AEdit(<bang>0, <f-args>)
command! -nargs=+ -bang -complete=buffer AEditBuf
      \ call aplus#AEdit(<bang>0, <f-args>)

command! -nargs=* -bang -complete=arglist ADel
      \ call aplus#ADel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ABufDel
      \ call aplus#ABufDel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist AFileDel
      \ call aplus#AFileDel(<bang>0, <f-args>)

command! -nargs=0 AList echo aplus#AList()
command! -nargs=0 AVList echo aplus#AVList()
command! -nargs=0 AHList echo aplus#AHList()
command! -nargs=0 AAList echo aplus#AAList()

command! -nargs=0 AGtoL call aplus#AGtoL()
command! -nargs=0 ALtoG call aplus#ALtoG()
command! -nargs=0 AExchange call aplus#AExchange()

" }}}

" maps {{{

" basic {{{

map <Plug>ANext :ANext<CR>
map <Plug>APrev :APrev<CR>
map <Plug>ASel :ASel<CR>
map <Plug>AGo :<C-u>AGo<CR>
map <Plug>A!Next :ANext!<CR>
map <Plug>A!Prev :APrev!<CR>
map <Plug>A!Sel :ASel!<CR>
map <Plug>A!Go :<C-u>AGo!<CR>

map <Plug>AAdd :<C-u>AAdd<CR>
map <Plug>AEdit :<C-u>AEdit<CR>
map <Plug>A!Edit :<C-u>AEdit<CR>

map <Plug>ADel :<C-u>ADel<CR>
map <Plug>ADelBuf :<C-u>ADelBuf<CR>
map <Plug>A!Del :<C-u>ADel<CR>
map <Plug>A!DelBuf :<C-u>ADelBuf<CR>

map <Plug>AList :<C-u>AList<CR>
map <Plug>AVList :<C-u>AVList<CR>
map <Plug>AHList :<C-u>AHList<CR>
map <Plug>AAList :<C-u>AAList<CR>

map <Plug>AGtoL :<C-u>AGtoL<CR>
map <Plug>ALtoG :<C-u>ALtoG<CR>

" }}}

" predefined numbers {{{

map <Plug>ASel1 :<C-u>ASelN 1<CR>
map <Plug>ASel2 :<C-u>ASelN 2<CR>
map <Plug>ASel3 :<C-u>ASelN 3<CR>
map <Plug>ASel4 :<C-u>ASelN 4<CR>
map <Plug>ASel5 :<C-u>ASelN 5<CR>
map <Plug>ASel6 :<C-u>ASelN 6<CR>
map <Plug>ASel7 :<C-u>ASelN 7<CR>
map <Plug>ASel8 :<C-u>ASelN 8<CR>
map <Plug>ASel9 :<C-u>ASelN 9<CR>

map <Plug>A!Sel1 :<C-u>ASelN! 1<CR>
map <Plug>A!Sel2 :<C-u>ASelN! 2<CR>
map <Plug>A!Sel3 :<C-u>ASelN! 3<CR>
map <Plug>A!Sel4 :<C-u>ASelN! 4<CR>
map <Plug>A!Sel5 :<C-u>ASelN! 5<CR>
map <Plug>A!Sel6 :<C-u>ASelN! 6<CR>
map <Plug>A!Sel7 :<C-u>ASelN! 7<CR>
map <Plug>A!Sel8 :<C-u>ASelN! 8<CR>
map <Plug>A!Sel9 :<C-u>ASelN! 9<CR>

" }}}

" }}}

" setup {{{

" TODO how to properly copy when needed
" function s:tab_arglist()
"   if s:check_var("aplus#tab_local", ["t", "g"])
"     arglocal
"     if s:check_var("aplus#tab_empty", ["t", "g"])
"       %argd
"     endif
"   endif
" endfunction

" autocmd TabNew * call s:tab_arglist()
" autocmd WinNew * call s:win_arglist()

" }}}
