" helpers {{{

function s:cbang(command, bang)
  return a:command.(a:bang ? "!" : "")
endfunction

function s:mod_argc(n)
  return (argc() + a:n % argc()) % argc()
endfunction

function s:check_var(name, scopes)
  for scope in a:scopes
    let l:var = scope.":".a:name
    if exists(l:var)
      return eval(l:var)
    endif
  endfor
  return v:false
endfunction

function s:instantiate(args)
  return join(map(a:args, 'fnameescape(v:val)'), " ")
endfunction

function s:set_if_not_exist(name, value)
    if !exists(a:name)
      exe "let ".a:name." = ".a:value
    endif
endfunction

function s:expand_args_loop(cmd, list)
  if len(a:list) == 0
    exe a:cmd." ".fnameescape(expand("%"))
    return
  endif
  for arg in a:list
    for file in split(expand(arg), "\n")
      exe a:cmd." ".fnameescape(file)
    endfor
  endfor
endfunction

function s:windo_stay(expr)
  let l:winnr = winnr()
  exe "windo ".a:expr
  exe l:winnr."wincmd w"
endfunction

function s:tabdo_stay(expr)
  let l:tabnr = tabpagenr()
  exe "tabdo ".a:expr
  exe "tabnext ".l:tabnr
endfunction

" }}}

" settings {{{

if exists("g:loaded_aplus")
  finish
endif
let g:loaded_aplus = 1

call s:set_if_not_exist("g:aplus#dedupe_on_start", 1)
" on bufdelete remove buffer from all arglists
call s:set_if_not_exist("g:aplus#buf_del_hook", 1)
" tab/win
call s:set_if_not_exist("g:aplus#new_tab", 0)
" local/global
call s:set_if_not_exist("g:aplus#new_local", 1)
" fresh/copied
call s:set_if_not_exist("g:aplus#new_copy", 0)

" }}}

" functions {{{

" information {{{

function aplus#arg_name()
  " returns filename of current argument
  let l:args = argv()
  if len(l:args) == 0
    return ""
  endif
  return l:args[argidx()]
endfunction

function aplus#vert_list()
  " returns arglist representation with each argument on separate line
  let l:args = argv()
  if len(l:args) == 0
    return ""
  endif
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, "\n")
endfunction

function aplus#horiz_list()
  " returns arglist representation with all elements next to each other
  let l:args = argv()
  if len(l:args) == 0
    return ""
  endif
  let l:args[argidx()] = "[".l:args[argidx()]."]"
  return join(l:args, " ")
endfunction

function aplus#list()
  " returns arglist reperesentation in horizontal format if it fits
  " on the screen and in vertical format otherwise
  let l:horizontal = aplus#horiz_list()
  if len(l:horizontal) <= &columns
    return l:horizontal
  endif
  return aplus#vert_list()
endfunction

" }}}

" navigation {{{

function aplus#next(bang, n)
  " moves to n'th (wrapping around) next argument
  exe s:cbang("argument", a:bang)." ".(s:mod_argc(argidx() + a:n) + 1)
endfunction

function aplus#prev(bang, n)
  " moves to n'th (wrapping around) previous argument
  exe s:cbang("argument", a:bang)." ".(s:mod_argc(argidx() - a:n) + 1)
endfunction

function aplus#select(bang, n=0)
  " moves to n'th argument
  if a:n == 0
    exe s:cbang("argument", a:bang)
  else
    exe s:cbang("argument", a:bang)." ".a:n
  endif
endfunction

function aplus#go(bang, name="")
  " moves to argument with given name
  if a:name == ""
    exe s:cbang("argument", a:bang)
  else
    " avoid duplication of entries
    " version with argdedupe doesn't work sometimes ?
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

function aplus#add(place, ...)
  " adds (only not already present) files to arglist
  exe a:place."argadd ".join(a:000, " ")
  argdedupe
endfunction

function aplus#edit(place, bang, ...)
  " adds (only not already present) files to arglist and edits first
  exe a:place.s:cbang("argedit", a:bang)." ".join(a:000, " ")
  argdedupe
endfunction

function aplus#delete(bang, ...)
  " deletes argument from list
  exe s:cbang("argdelete", a:bang)." ".join(a:000, " ")
endfunction

function aplus#delete_buf(bang, ...)
  " deletes argument from list and it's corresponding buffer
  call call("aplus#delete", insert(deepcopy(a:000), a:bang))
  call s:expand_args_loop(s:cbang("bdelete", a:bang), a:000)
endfunction

function aplus#wipeout_buf(bang, ...)
  " deletes argument from list and wipes out it's corresponding buffer
  call call("aplus#delete", insert(deepcopy(a:000), a:bang))
  call s:expand_args_loop(s:cbang("bwipeout", a:bang), a:000)
endfunction

function aplus#move(from, to)
  " moves element at a:from to given a:to position in list
  let l:argv = argv()
  " TODO
  call aplus#define(l:argv)
endfunction

function aplus#swap(from, to)
  " swaps element at a:from with file at a:to position in list
  let l:argv = argv()
  " TODO
  call aplus#define(l:argv)
endfunction

function aplus#replace(file, idx=-1)
  " replaces argument (idx) with given file
  " TODO
endfunction

" }}}

" operations on lists {{{

function aplus#define(...)
  " define list of currently used scope to be list given as parameter
  %argdel
  call call("aplus#add", a:000)
endfunction

function aplus#log_to_glob()
  " replaces global with copy of local
  if arglistid() == 0
    throw "Not using local arglist"
  endif
  exe "argglobal ".s:instantiate(argv())
endfunction

function aplus#glob_to_loc()
  " replaces local with copy of global
  arglocal
endfunction

function aplus#exchange()
  " exchanges global and local
  if arglistid() == 0
    throw "Not using local arglist, there is nothing to exchange"
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

command! -nargs=0 AName echo aplus#arg_name()
command! -nargs=0 AList echo aplus#list()
command! -nargs=0 AVertList echo aplus#vert_list()
command! -nargs=0 AHorizList echo aplus#horiz_list()

command! -count=1 -nargs=0 -bang ANext
      \ call aplus#next(<bang>0, <count>)
command! -count=1 -nargs=0 -bang APrev
      \ call aplus#prev(<bang>0, <count>)

" Select n'th (indexed from 1) file
command! -count=0 -nargs=? -bang ASelect
      \ call aplus#select(<bang>0, [<count>, <f-args>][0])
" Go to file by name
command! -nargs=? -bang -complete=arglist AGo
      \ call aplus#go(<bang>0, <f-args>)

" Add file(s) to arglist
command! -range=% -addr=arguments -nargs=+ -complete=file AAdd
      \ call aplus#add(<count>, <f-args>)
command! -range=% -addr=arguments -nargs=+ -complete=buffer AAddBuf
      \ call aplus#add(<count>, <f-args>)

" Add file(s) to arglist and edit (first)
command! -range=% -addr=arguments -nargs=+ -bang -complete=file AEdit
      \ call aplus#edit(<count>, <bang>0, <f-args>)
command! -range=% -addr=arguments -nargs=+ -bang -complete=buffer AEditBuf
      \ call aplus#edit(<count>, <bang>0, <f-args>)

" Remove file from arglist
command! -nargs=* -bang -complete=arglist ADel
      \ call aplus#delete(<bang>0, <f-args>)
" Remove file from arglist and delete it's buffer
command! -nargs=* -bang -complete=arglist ABufDel
      \ call aplus#delete_buf(<bang>0, <f-args>)
" Remove file from arglist and wipe out it's buffer
command! -nargs=* -bang -complete=arglist ABufWipe
      \ call aplus#wipeout_buf(<bang>0, <f-args>)

" " Move current file to position of given file
" command! -nargs=1 -complete=arglist AMoveTo
"       \ call aplus#move(argidx(), <f-args>)
" " Swap current file with given file
" command! -nargs=1 -complete=arglist ASwapWith
"       \ call aplus#swap(argidx(), <f-args>)

" " Move current file to position given as count or argument
" command! -count=0 -nargs=? AMoveToN
"       \ call aplus#move(argidx(), <count> || 0<f-args>)
" " Swap current file with file at position given as count or argument
" command! -count=0 -nargs=? ASwapWithN
"       \ call aplus#swap(argidx(), <count> || 0<f-args>)

" " Move file to position given as count or argument
" command! -count=1 -nargs=1 AMoveN
"       \ call aplus#move(<count>, <f-args>)
" " Move first file to position of second file
" command! -nargs=+ -complete=arglist AMove
"       \ call aplus#move(<f-args>)
" " Swap current file with file at position given as count or argument
" command! -nargs=+ -complete=arglist ASwap
"       \ call aplus#swap(<f-args>)

command! -nargs=* -complete=file ADefine
      \ call aplus#define(<f-args>)
command! -nargs=* -complete=buffer ADefineBuf
      \ call aplus#define(<f-args>)
command! -nargs=* -complete=arglist ADefineArgs
      \ call aplus#define(<f-args>)

command! -nargs=0 AGlobToLoc call aplus#glob_to_loc()
command! -nargs=0 ALocToGlob call aplus#log_to_glob()
command! -nargs=0 AExchange call aplus#exchange()

" }}}

" maps {{{

" basic {{{

map <Plug>AName :<C-u>AName<CR>
map <Plug>AList :<C-u>AList<CR>
map <Plug>AVertList :<C-u>AVertList<CR>
map <Plug>AHorizList :<C-u>AHorizList<CR>

map <Plug>ANext :ANext<CR>
map <Plug>APrev :APrev<CR>
map <Plug>ASelect :ASelect<CR>
map <Plug>AGo :<C-u>AGo<CR>
map <Plug>!ANext :ANext!<CR>
map <Plug>!APrev :APrev!<CR>
map <Plug>!ASelect :ASelect!<CR>
map <Plug>!AGo :<C-u>AGo!<CR>

map <Plug>!ANext :ANext!<CR>
map <Plug>!APrev :APrev!<CR>
map <Plug>!ASelect :ASelect!<CR>
map <Plug>!AGo :<C-u>AGo!<CR>

map <Plug>AAdd :<C-u>AAdd<CR>
map <Plug>AEdit :<C-u>AEdit<CR>
map <Plug>!AEdit :<C-u>AEdit!<CR>

map <Plug>ADel :<C-u>ADel<CR>
map <Plug>ABufDel :<C-u>ABufDel<CR>
map <Plug>ABufWipe :<C-u>ABufWipe<CR>
map <Plug>!ADel :<C-u>ADel!<CR>
map <Plug>!ABufDel :<C-u>ABufDel!<CR>
map <Plug>!ABufWipe :<C-u>ABufWipe!<CR>

map <Plug>AGlobToLoc :<C-u>AGlobToLoc<CR>
map <Plug>ALocToGlob :<C-u>ALocToGlob<CR>
map <Plug>AExchange :<C-u>AExchange<CR>

" }}}

" predefined numbers {{{

map <Plug>ASelect1 :<C-u>1ASelect<CR>
map <Plug>ASelect2 :<C-u>2ASelect<CR>
map <Plug>ASelect3 :<C-u>3ASelect<CR>
map <Plug>ASelect4 :<C-u>4ASelect<CR>
map <Plug>ASelect5 :<C-u>5ASelect<CR>
map <Plug>ASelect6 :<C-u>6ASelect<CR>
map <Plug>ASelect7 :<C-u>7ASelect<CR>
map <Plug>ASelect8 :<C-u>8ASelect<CR>
map <Plug>ASelect9 :<C-u>9ASelect<CR>
map <Plug>!ASelect1 :<C-u>1ASelect!<CR>
map <Plug>!ASelect2 :<C-u>2ASelect!<CR>
map <Plug>!ASelect3 :<C-u>3ASelect!<CR>
map <Plug>!ASelect4 :<C-u>4ASelect!<CR>
map <Plug>!ASelect5 :<C-u>5ASelect!<CR>
map <Plug>!ASelect6 :<C-u>6ASelect!<CR>
map <Plug>!ASelect7 :<C-u>7ASelect!<CR>
map <Plug>!ASelect8 :<C-u>8ASelect!<CR>
map <Plug>!ASelect9 :<C-u>9ASelect!<CR>

map <Plug>ASelect-1 :<C-u>exe "ASelect ".<SID>mod_argc(-1)<CR>
map <Plug>ASelect-2 :<C-u>exe "ASelect ".<SID>mod_argc(-2)<CR>
map <Plug>ASelect-3 :<C-u>exe "ASelect ".<SID>mod_argc(-3)<CR>
map <Plug>ASelect-4 :<C-u>exe "ASelect ".<SID>mod_argc(-4)<CR>
map <Plug>ASelect-5 :<C-u>exe "ASelect ".<SID>mod_argc(-5)<CR>
map <Plug>ASelect-6 :<C-u>exe "ASelect ".<SID>mod_argc(-6)<CR>
map <Plug>ASelect-7 :<C-u>exe "ASelect ".<SID>mod_argc(-7)<CR>
map <Plug>ASelect-8 :<C-u>exe "ASelect ".<SID>mod_argc(-8)<CR>
map <Plug>ASelect-9 :<C-u>exe "ASelect ".<SID>mod_argc(-9)<CR>
map <Plug>!ASelect-1 :<C-u>exe "ASelect! ".<SID>mod_argc(-1)<CR>
map <Plug>!ASelect-2 :<C-u>exe "ASelect! ".<SID>mod_argc(-2)<CR>
map <Plug>!ASelect-3 :<C-u>exe "ASelect! ".<SID>mod_argc(-3)<CR>
map <Plug>!ASelect-4 :<C-u>exe "ASelect! ".<SID>mod_argc(-4)<CR>
map <Plug>!ASelect-5 :<C-u>exe "ASelect! ".<SID>mod_argc(-5)<CR>
map <Plug>!ASelect-6 :<C-u>exe "ASelect! ".<SID>mod_argc(-6)<CR>
map <Plug>!ASelect-7 :<C-u>exe "ASelect! ".<SID>mod_argc(-7)<CR>
map <Plug>!ASelect-8 :<C-u>exe "ASelect! ".<SID>mod_argc(-8)<CR>
map <Plug>!ASelect-9 :<C-u>exe "ASelect! ".<SID>mod_argc(-9)<CR>

" }}}

" }}}

" setup {{{

function s:local_arglist(scopes)
  if s:check_var("aplus#new_local", a:scopes)
    " TODO
    " arglocal
    if s:check_var("aplus#new_copy", a:scopes)
      " TODO
      " echom winnr("#").
    endif
"     if s:check_var("aplus#tab_empty", ["t", "g"])
"       %argd
"     endif
  endif
endfunction

function s:tab_arglist()
  if !s:check_var("aplus#new_tab", ["t", "g"]) ||
        \ arglistid() != 0
    return
  endif
  call s:local_arglist(["t", "g"])
endfunction

function s:win_arglist()
  if s:check_var("aplus#new_tab", ["t", "g"]) ||
        \ arglistid() != 0
    return
  endif
  call s:local_arglist(["w", "t", "g"])
endfunction

function s:win_buf_del(file)
  if s:check_var("aplus#buf_del_hook", ["b", "w", "t", "g"])
    echo "Deleting ".a:file." in ".win_getid()
  endif
endfunction

function s:buf_del_hook(file)
  " Sometimes this is run with empty name when no buffer is deleted
  if a:file == ""
    return
  endif
  call <SID>tabdo_stay("call s:windo_stay(\"call s:win_buf_del('".a:file."')\")")
endfunction

if s:check_var("aplus#dedupe_on_start", ["g"])
  argdedupe
endif

autocmd BufDelete * call
      \ s:buf_del_hook(fnameescape(expand("<afile>")))
autocmd TabNew * call s:tab_arglist()
autocmd WinNew * call s:win_arglist()
if s:check_var("aplus#new_local", ["g"])
  autocmd VimEnter * arglocal
endif

" }}}
