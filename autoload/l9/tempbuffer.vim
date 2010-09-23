"=============================================================================
" Copyright (C) 2009-2010 Takeshi NISHIDA
"
"=============================================================================
" LOAD GUARD {{{1

if !l9#guardScriptLoading(expand('<sfile>:p'), 702, l9#getVersion())
  finish
endif

" }}}1
"=============================================================================
" TEMPORARY BUFFER {{{1

" each key is a buffer name.
let s:dataMap = {}

"
function s:onBufDelete(bufname)
  if exists('s:dataMap[a:bufname].listener.onClose')
    call s:dataMap[a:bufname].listener.onClose(s:dataMap[a:bufname].written)
  endif
  if bufnr('%') == s:dataMap[a:bufname].bufNr && winnr('#') != 0
    " if winnr('#') returns 0, "wincmd p" causes ringing the bell.
    wincmd p
  endif
endfunction

"
function s:onBufWriteCmd(bufname)
  if !exists('s:dataMap[a:bufname].listener.onWrite') ||
        \ s:dataMap[a:bufname].listener.onWrite(getline(1, '$'))
    setlocal nomodified
    let s:dataMap[a:bufname].written = 1
    call l9#tempbuffer#close(a:bufname)
  else
  endif
endfunction

" a:bufname:
" a:height: Window height. If 0, default height is used.
"           If less than 0, the window becomes full-screen. 
function l9#tempbuffer#openScratch(bufname, filetype, lines, topleft, vertical, height)
  let openCmdPrefix = (a:topleft ? 'topleft ' : '')
        \           . (a:vertical ? 'vertical ' : '')
        \           . (a:height > 0 ? a:height : '')
  if !exists('s:dataMap[a:bufname]') || !bufexists(s:dataMap[a:bufname].bufNr)
    execute openCmdPrefix . 'new'
  else
    call l9#tempbuffer#close(a:bufname)
    execute openCmdPrefix . 'split'
    execute 'silent ' . s:dataMap[a:bufname].bufNr . 'buffer'
  endif
  if a:height < 0
    only
  endif
  setlocal buflisted noswapfile bufhidden=delete modifiable noreadonly buftype=nofile
  let &l:filetype = a:filetype
  silent file `=a:bufname`
  call setline(1, a:lines)
  setlocal nomodified
  let s:dataMap[a:bufname] = {
        \   'bufNr': bufnr('%'),
        \ }
endfunction

" a:bufname:
" a:height: Window height. If 0, default height is used.
"           If less than 0, the window becomes full-screen. 
" a:listener:
"   a:listener.onClose(written)
"   a:listener.onWrite(lines)
function l9#tempbuffer#openReadOnly(bufname, filetype, lines, topleft, vertical, height)
  call l9#tempbuffer#openScratch(a:bufname, a:filetype, a:lines, a:topleft, a:vertical, a:height)
  setlocal nomodifiable readonly
endfunction

" a:listener:
"   a:listener.onClose(written)
"   a:listener.onWrite(lines)
function l9#tempbuffer#openWritable(bufname, filetype, lines, topleft, vertical, height, listener)
  call l9#tempbuffer#openScratch(a:bufname, a:filetype, a:lines, a:topleft, a:vertical, a:height)
  setlocal buftype=acwrite
  let s:dataMap[a:bufname].listener = a:listener
  let s:dataMap[a:bufname].written = 0
  augroup L9TempBuffer
    autocmd! * <buffer>
    execute printf('autocmd BufDelete   <buffer>        call s:onBufDelete  (%s)', string(a:bufname))
    execute printf('autocmd BufWriteCmd <buffer> nested call s:onBufWriteCmd(%s)', string(a:bufname))
  augroup END
endfunction

" makes specified temp buffer current.
function l9#tempbuffer#moveTo(bufname)
  return l9#moveToBufferWindowInCurrentTabpage(s:dataMap[a:bufname].bufNr) ||
        \ l9#moveToBufferWindowInOtherTabpage(s:dataMap[a:bufname].bufNr)
endfunction

"
function l9#tempbuffer#close(bufname)
  if !l9#tempbuffer#isOpen(a:bufname)
    return
  endif
  execute printf('%dbdelete!', s:dataMap[a:bufname].bufNr)
endfunction

"
function l9#tempbuffer#isOpen(bufname)
  return exists('s:dataMap[a:bufname]') && bufloaded(s:dataMap[a:bufname].bufNr)
endfunction

" }}}1
"=============================================================================
" vim: set fdm=marker:

