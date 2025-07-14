" settings {{{

if exists("g:loaded_arglist_plus")
  finish
endif
let g:loaded_arglist_plus = 1

" TODO local/global, copy/not copy
let g:arglist_plus#tab_local = 1
let g:arglist_plus#tab_copy_local = 1
let g:arglist_plus#win_local = 1
let g:arglist_plus#win_copy_local = 1

" }}}

" functions {{{

" helpers {{{

" }}}

" information {{{

function arglist_plus#ArgList()
  " return default list representation
  return execute("args")
endfunction

function arglist_plus#ArgListV()
  " return list representation with each argument on separate line
  " TODO
endfunction

function arglist_plus#ArgListH()
  " return list representation that takes only one line
  " TODO
endfunction

" }}}

" navigation {{{

function arglist_plus#ArgNext(bang, n)
  " TODO
endfunction

function arglist_plus#ArgPrev(bang, n)
  " TODO
endfunction

function arglist_plus#ArgSel(bang, n)
  " TODO
endfunction

function arglist_plus#ArgGo(bang, name)
  " TODO
endfunction

" }}}

" operations on list elements {{{

function arglist_plus#ArgAdd(bang, ...)
  " adds argument to list
  " TODO
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
  " TODO
endfunction

function arglist_plus#ArgGtoL()
  " replaces local with copy of global
  " TODO
endfunction

function arglist_plus#ArgExchange()
  " exchanges global and local 
  " TODO
endfunction

" }}}

" }}}

" commands {{{

command! -count=1 -bang ArgSel call arglist_plus#ArgSel(<bang>0, <count>)
command! -nargs=1 -bang ArgGo call arglist_plus#ArgGo(<bang>0, <f-args>)
command! -count=1 -bang ArgNext call arglist_plus#ArgNext(<bang>0, <count>)
command! -count=1 -bang ArgPrev call arglist_plus#ArgPrev(<bang>0, <count>)

command! -nargs=* -bang -complete=file ArgAdd call arglist_plus#ArgAdd(<bang>0, <f-args>)
command! -nargs=* -bang -complete=buffer ArgAddBuf call arglist_plus#ArgAdd(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ArgDel call arglist_plus#ArgDel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ArgBufDel call arglist_plus#ArgBufDel(<bang>0, <f-args>)
command! -nargs=* -bang -complete=arglist ArgFileDel call arglist_plus#ArgFileDel(<bang>0, <f-args>)

command! -nargs=0 ArgList echo arglist_plus#ArgList()
command! -nargs=0 ArgListV echo arglist_plus#ArgListV()
command! -nargs=0 ArgListH echo arglist_plus#ArgListH()

command! -nargs=0 ArgGtoL call arglist_plus#ArgGtoL()
command! -nargs=0 ArgLtoG call arglist_plus#ArgLtoG()
command! -nargs=0 ArgExchange call arglist_plus#ArgExchange()

" }}}

" maps {{{

map <Plug>ArgNext :ArgNext<CR>
map <Plug>ArgPrev :ArgPrev<CR>

map <Plug>ArgDel :<C-u>ArgDel<CR>
map <Plug>ArgDelBuf :<C-u>ArgDelBuf<CR>
map <Plug>ArgList :<C-u>ArgList<CR>

map <Plug>ArgList :<C-u>ArgList<CR>
map <Plug>ArgListV :<C-u>ArgListV<CR>
map <Plug>ArgListH :<C-u>ArgListH<CR>
map <Plug>ArgGtoL :<C-u>ArgGtoL<CR>
map <Plug>ArgLtoG :<C-u>ArgLtoG<CR>

" }}}

" setup {{{

" autocmd TabNew
" TODO option for copying current list for new tab

" }}}
