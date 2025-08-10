" helpers {{{

function s:cbang(command, bang) abort
  return a:command.(a:bang ? "!" : "")
endfunction

function s:mod_argc(n) abort
  return (argc() + a:n % argc()) % argc()
endfunction

function s:check_var(name, scopes) abort
  for scope in a:scopes
    let l:var = scope.":".a:name
    if exists(l:var)
      return eval(l:var)
    endif
  endfor
  return 0
endfunction

function s:cescape(arg) abort
  return split(escape(a:arg, '<'), '[^\]\zs ')
endfunction

function s:escaped_args(args) abort
  let l:args = deepcopy(a:args)
  call map(l:args, 'fnameescape(v:val)')
  return l:args
endfunction

function s:instantiate(args) abort
  return join(s:escaped_args(a:args), " ")
endfunction

function s:set_if_not_exist(name, value) abort
    if !exists(a:name)
      exe "let ".a:name." = ".a:value
    endif
endfunction

function s:expand_args_loop(cmd, list) abort
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

function s:del_with_next(bang, func, ...) abort
  let l:args = deepcopy(a:000)
  let l:success = 0
  try
    call call(a:func, insert(l:args, a:bang))
    let l:success = 1
  endtry
  if !l:success
    return
  endif
  if argc() > 0
    call aplus#select(a:bang)
  else
    exe s:cbang("bnext", a:bang)
  endif
endfunction

function s:norm_apos(pos) abort
  " converts position from [1, argc()] and 0 for argidx() to [0, argc())
  if a:pos == 0
    return argidx()
  endif
  return a:pos - 1
endfunction

function s:norm_place(place) abort
  let l:place = a:place
  let l:place = a:place
  if l:place == -1
    if argidx() == -1
      let l:place = "$"
    else
      let l:place = argidx() + 1
    endif
  endif
  return l:place
endfunction

function s:arg_index(name) abort
  return index(argv(), a:name)
endfunction

function s:save_pos() abort
  let l:name = expand("%")
  let l:file = index(argv(), l:name)
  if l:file == -1
    return ""
  endif
  return l:name
endfunction

function s:restore_pos(saved) abort
  if a:saved != ""
    let l:file = index(argv(), a:saved)
    call aplus#select(0, l:file + 1)
  endif
endfunction

function aplus#complete(lead, cmdline, cursorpos) abort
  " Completes files from arglist
  let l:comps = deepcopy(getcompletion(a:lead, "arglist"))
  call map(l:comps, "fnameescape(v:val)")
  return l:comps
endfunction

" }}}

" settings {{{

if exists("g:loaded_aplus")
  finish
endif
let g:loaded_aplus = 1

call s:set_if_not_exist("g:aplus#dedupe_on_start", 1)
" on bufdelete remove buffer from all local arglists
call s:set_if_not_exist("g:aplus#buf_del_hook", 1)
" delete also from global list
call s:set_if_not_exist("g:aplus#buf_del_global", 1)

" Despite some utils and some attempts this plugin is mostly ignorant
" abount local/global arglist
" should new tab get it's local arglist
call s:set_if_not_exist("g:aplus#new_local", 1)
" should this arglist be copied from previous or global
call s:set_if_not_exist("g:aplus#new_copy", 0)

" }}}

" functions {{{

" information {{{

function aplus#arg_name() abort
  " returns filename of current argument
  let l:argv = argv()
  if len(l:argv) == 0
    return ""
  endif
  return l:argv[argidx()]
endfunction

function aplus#vert_list() abort
  " returns arglist representation with each argument on separate line
  let l:argv = argv()
  if len(l:argv) == 0
    return ""
  endif
  if argidx() >= 0 && argidx() < argc()
    let l:argv[argidx()] = "[ ".l:argv[argidx()]." ]"
  endif
  return join(l:argv, "\n")
endfunction

function aplus#horiz_list() abort
  " returns arglist representation with all elements next to
  " each other (and escaped)
  let l:argv = s:escaped_args(argv())
  if len(l:argv) == 0
    return ""
  endif
  if argidx() >= 0 && argidx() < argc()
    let l:argv[argidx()] = "[".l:argv[argidx()]."]"
  endif
  return join(l:argv, "  ")
endfunction

function aplus#list() abort
  " returns arglist reperesentation in horizontal format if it fits
  " on the screen and in vertical format otherwise
  let l:horizontal = aplus#horiz_list()
  if len(l:horizontal) <= &columns
    return l:horizontal
  endif
  return aplus#vert_list()
endfunction

function aplus#echo_output(bang, function) abort
  " if bang is given :echo a:funtion output otherwise
  " :echomsg it (with proper newline handling)
  if a:bang
    for line in split(call(a:function, []), "\n")
      echom line
    endfor
  else
    echo call(a:function, [])
  endif
endfunction

" }}}

" navigation {{{

function aplus#next(bang, n=1) abort
  " moves to n'th (wrapping around) next argument
  exe s:cbang("argument", a:bang)." ".(s:mod_argc(argidx() + a:n) + 1)
endfunction

function aplus#prev(bang, n=1) abort
  " moves to n'th (wrapping around) previous argument
  exe s:cbang("argument", a:bang)." ".(s:mod_argc(argidx() - a:n) + 1)
endfunction

function aplus#select(bang, n=0) abort
  " moves to n'th argument, 0 and -1 is current
  let l:n = a:n
  if l:n <= 0
    let l:n = ""
  endif
  exe l:n.s:cbang("argument", a:bang)
endfunction

function aplus#go(bang, name="") abort
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

function aplus#add(place, ...) abort
  " adds (only not already present) files to arglist
  let l:args = flatten(deepcopy(a:000))
  exe s:norm_place(a:place)."argadd ".join(l:args, " ")
  argdedupe
endfunction

function aplus#edit(place, bang, ...) abort
  " adds (only not already present) files to arglist and edits first
  let l:args = flatten(deepcopy(a:000))
  exe s:norm_place(a:place).s:cbang("argedit", a:bang)." ".join(l:args, " ")
  argdedupe
endfunction

function aplus#delete(bang, ...) abort
  " deletes arguments from list
  let l:args = flatten(deepcopy(a:000))
  exe s:cbang("argdelete", a:bang)." ".join(l:args, " ")
endfunction

function aplus#delete_buf(bang, ...) abort
  " deletes argument from list and it's corresponding buffer
  let l:files = flatten(deepcopy(a:000))
  call aplus#delete(a:bang, l:files)
  call s:expand_args_loop(s:cbang("bdelete", a:bang), l:files)
endfunction

function aplus#wipeout_buf(bang, ...) abort
  " deletes argument from list and wipes out it's corresponding buffer
  let l:files = flatten(deepcopy(a:000))
  call aplus#delete(a:bang, l:files)
  call s:expand_args_loop(s:cbang("bwipeout", a:bang), l:files)
endfunction

function aplus#move(from, to) abort
  " moves element at a:from position to a:to position in list
  let [l:from, l:to] = [s:norm_apos(a:from), s:norm_apos(a:to)]
  " echom l:from.." "..l:to
  if l:to == l:from
    return
  endif
  let l:saved = s:save_pos()
  let l:argv = s:escaped_args(argv())
  let l:arg = remove(l:argv, l:from)
  call insert(l:argv, l:arg, l:to)
  call aplus#define(l:argv)
  call s:restore_pos(l:saved)
endfunction

function aplus#swap(from, to) abort
  " swaps element at a:from with file at a:to position in list
  let [l:from, l:to] = [s:norm_apos(a:from), s:norm_apos(a:to)]
  let l:saved = s:save_pos()
  let l:argv = s:escaped_args(argv())
  if l:from == l:to
    return
  elseif l:from > l:to
    let [l:from, l:to] = [l:to, l:from]
  endif
  let l:f_to = remove(l:argv, l:to)
  let l:f_from = remove(l:argv, l:from)
  call insert(l:argv, l:f_to, l:from)
  call insert(l:argv, l:f_from, l:to)
  call aplus#define(l:argv)
  call s:restore_pos(l:saved)
endfunction

function aplus#replace(file, idx=0) abort
  " replaces argument (idx) with given file
  let l:argv = s:escaped_args(argv())
  call remove(l:argv, a:idx)
  call insert(l:argv, fnameescape(a:file), a:idx)
  call aplus#define(l:argv)
endfunction

" }}}

" operations on lists {{{

function aplus#define(...) abort
  " define list of currently used scope to be list given as parameter
  %argdel
  call aplus#add(0, a:000)
endfunction

function aplus#log_to_glob() abort
  " replaces global with copy of local
  if arglistid() == 0
    throw "Not using local arglist"
  endif
  exe "argglobal ".s:instantiate(argv())
endfunction

function aplus#glob_to_loc() abort
  " replaces local with copy of global
  arglocal
endfunction

function aplus#exchange() abort
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
" all commands use ranges like vim arglist commands for indexing

command! -nargs=0 -bang AName
      \ call aplus#echo_output(<bang>0, "aplus#arg_name")
command! -nargs=0 -bang AList
      \ call aplus#echo_output(<bang>0, "aplus#list")
command! -nargs=0 -bang AVertList
      \ call aplus#echo_output(<bang>0, "aplus#vert_list")
command! -nargs=0 -bang AHorizList
      \ call aplus#echo_output(<bang>0, "aplus#horiz_list")

command! -count=1 -nargs=0 -bang ANext
      \ call aplus#next(<bang>0, <count>)
command! -count=1 -nargs=0 -bang APrev
      \ call aplus#prev(<bang>0, <count>)

" Select n'th file
command! -range=% -addr=arguments -nargs=? -bang ASelect
      \ call aplus#select(<bang>0, len("<args>")?0<args>:<count>)
" Go to file by name
command! -nargs=? -bang -complete=arglist AGo
      \ call aplus#go(<bang>0, <q-args>)

" Add file(s) to arglist
command! -range=% -addr=arguments -nargs=+ -complete=file AAdd
      \ call aplus#add(<count>, <SID>cescape(<q-args>))
command! -range=% -addr=arguments -nargs=+ -complete=buffer AAddBuf
      \ call aplus#add(<count>, <SID>cescape(<q-args>))

" Add file(s) to arglist and edit (first)
command! -range=% -addr=arguments -nargs=+ -bang -complete=file AEdit
      \ call aplus#edit(<count>, <bang>0, <SID>cescape(<q-args>))
command! -range=% -addr=arguments -nargs=+ -bang -complete=buffer AEditBuf
      \ call aplus#edit(<count>, <bang>0, <SID>cescape(<q-args>))

" Remove file from arglist
command! -nargs=* -bang -complete=customlist,aplus#complete ADel
      \ call aplus#delete(<bang>0, <q-args>)
" Remove file from arglist and delete it's buffer
command! -nargs=* -bang -complete=customlist,aplus#complete ABufDel
      \ call aplus#delete_buf(<bang>0, <q-args>)
" Remove file from arglist and wipe out it's buffer
command! -nargs=* -bang -complete=customlist,aplus#complete ABufWipe
      \ call aplus#wipeout_buf(<bang>0, <q-args>)

" versions that argedit after deleting
command! -nargs=* -bang -complete=customlist,aplus#complete ADeln
      \ call <SID>del_with_next(<bang>0, "aplus#delete", <q-args>)
command! -nargs=* -bang -complete=customlist,aplus#complete ABufDeln
      \ call <SID>del_with_next(<bang>0, "aplus#delete_buf", <q-args>)
command! -nargs=* -bang -complete=customlist,aplus#complete ABufWipen
      \ call <SID>del_with_next(<bang>0, "aplus#wipeout_buf", <q-args>)

" Move current file to position of given file
command! -nargs=1 -complete=arglist AMoveCur
      \ call aplus#move(argidx()+1, <SID>arg_index(<q-args>)+1)
" Swap current file with given file
command! -nargs=1 -complete=arglist ASwapWith
      \ call aplus#swap(argidx()+1, <SID>arg_index(<q-args>)+1)

" Move current file to position given as count or argument
command! -range=% -addr=arguments -nargs=? AMoveCurN
      \ call aplus#move(argidx()+1, (len("<args>"))?0<args>:<count>)
" Swap current file with file at position given as count or argument
command! -range=% -addr=arguments -nargs=? ASwapWithN
      \ call aplus#swap(argidx()+1, (len("<args>"))?0<args>:<count>)

" Move file to position given in count
command! -range=% -addr=arguments -nargs=1 -complete=arglist AMove
      \ call aplus#move(
      \ <SID>arg_index(<q-args>)+1,
      \ (<count><=0)?argidx()+1:<count>
      \ )
" Swap file with file at position given as count
command! -range=% -addr=arguments -nargs=1 -complete=arglist ASwap
      \ call aplus#swap(<count>, <SID>arg_index(<q-args>)+1)

" Replace n'th argument with a given file
command! -range=% -addr=arguments -nargs=1 -complete=file AReplace
      \ call aplus#replace(<SID>cescape(<q-args>), <count>)
command! -range=% -addr=arguments -nargs=1 -complete=buffer AReplaceBuf
      \ call aplus#replace(<SID>cescape(<q-args>), <count>)

command! -nargs=* -complete=file ADefine
      \ call aplus#define(<SID>cescape(<q-args>))
command! -nargs=* -complete=buffer ADefineBuf
      \ call aplus#define(<SID>cescape(<q-args>))
command! -nargs=* -complete=customlist,aplus#complete ADefineArgs
      \ call aplus#define(<SID>cescape(<q-args>))

command! -nargs=* -bang -complete=file ADefineGo
      \ call aplus#define(<q-args>)|call aplus#select(<bang>0)
command! -nargs=* -bang -complete=buffer ADefineGoBuf
      \ call aplus#define(<q-args>)|call aplus#select(<bang>0)
command! -nargs=* -bang -complete=customlist,aplus#complete ADefineGoArgs
      \ call aplus#define(<q-args>)|call aplus#select(<bang>0)

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

map <Plug>AMoveCurN :AMoveCurN<CR>
map <Plug>ASwapWithN :ASwapWithN<CR>

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

" }}}

" setup {{{

function s:windo_stay(func, ...) abort
  let l:winnr = winnr()
  exe "windo call call('".a:func."', ".string(a:000).")"
  exe l:winnr."wincmd w"
endfunction

function s:tabdo_stay(func, ...) abort
  let l:tabnr = tabpagenr()
  exe "tabdo call call('".a:func."', ".string(a:000).")"
  exe "tabnext ".l:tabnr
endfunction

function s:tab_arglist() abort
  if !s:check_var("aplus#new_local", ["t", "g"])
    return
  endif
  if s:check_var("aplus#new_copy", ["t", "g"])
    exe "arglocal! ".s:instantiate(argv())
  else
    arglocal!
  endif
endfunction

function s:win_buf_del(file) abort
  if s:check_var("aplus#buf_del_hook", ["b", "w", "t", "g"])
    try
      exe "argdelete ".fnameescape(a:file)
    catch
    endtry
  endif
endfunction

function s:buf_del_hook(file) abort
  " Sometimes this is run with empty name when no buffer is deleted
  if a:file == "" || match(a:file, "^term://") != -1
    return
  endif
  if s:check_var("aplus#buf_del_global", ["g"])
    try
      let l:argv = s:escaped_args(argv())
      argglobal
      exe "argdelete ".fnameescape(a:file)
      call aplus#define(l:argv)
      exe "argdelete ".fnameescape(a:file)
    catch
    endtry
  endif
  let l:sid =  expand("<SID>")
  call s:tabdo_stay(l:sid.."windo_stay", l:sid.."win_buf_del", a:file)
endfunction

if s:check_var("aplus#dedupe_on_start", ["g"])
  argdedupe
endif

autocmd BufDelete * call s:buf_del_hook(expand("<afile>"))
" if session isn't being loaded
if s:check_var("aplus#new_local", ["g"]) && index(v:argv, "-S") == -1
  autocmd VimEnter * arglocal
endif
autocmd TabNew * call s:tab_arglist()

" }}}
