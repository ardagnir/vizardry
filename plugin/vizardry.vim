" Vim plugin for automatically sharing registers between vim instances.
" Last Change: Dec 29 2013
" Maintainer: James Kolb
"
" Copyright (C) 2013, James Kolb. All rights reserved.
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU Affero General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU Affero General Public License for more details.
" 
" You should have received a copy of the GNU Affero General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.

let g:save_cpo = &cpo
set cpo&vim
if exists("g:loaded_vizardry")
  finish
endif
let g:loaded_vizardry = 1

command! -nargs=? Invoke call s:Invoke(<q-args>)
command! -nargs=? Banish call s:Banish(<q-args>)
command! -nargs=? Scry call s:Scry(<q-args>)

function! s:Invoke(input)
  if a:input == ''
    source $MYVIMRC
    echo "Updated vim"
    return
  endif
  let inputPlus = substitute(a:input, '\s\s*', '+', 'g')
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let exists = (system('ls -d ~/.vim/bundle/'.inputNice.' >/dev/null')=='')
  if exists
    echo inputNice.' is already invoked'
  else
    let banished = (system('ls -d ~/.vim/bundle/'.inputNice.'~ >/dev/null')=='')
    if banished
      echo "Unbanish ".inputNice."? (y/n)"
      let response=nr2char(getchar())
      if response=='y' || response=='Y'
        call system('mv ~/.vim/bundle/'.inputNice.'~ ~/.vim/bundle/'.inputNice)
        source $MYVIMRC
      endif
      redraw
      echo ""
    else
      let curlResults = system('curl -silent https://api.github.com/search/repositories?q=vim+'.inputPlus.'\&sort=stars\&order=desc')

      let site = system('grep "full_name" | head -n 1', curlResults)

      if site==""
        echo '"'.a:input.'" not found'
      else
        let site = substitute(site, '\s*"full_name"[^"]*"\(.*\)".*', '\1', '')

        let description = system('grep "description" | head -n 1', curlResults)
        let description = substitute(description, '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)".*', '\1', '') "this includes escaped quotes
        let description = substitute(description, '\\"', '"', 'g')

        echo "Found ".site."\n(".description.")\n\nClone as \"".inputNice."\"? (Yes/No/Rename)"
        let response=nr2char(getchar())
        if response=='y' || response=='Y'
          call system('git clone https://github.com/'.site.' ~/.vim/bundle/'.inputNice)
          source $MYVIMRC
        elseif response=='r' || response=='R'
          let newName=""
          let inputting=1
          while inputting
            redraw
            echo "Clone as: ".newName
            let oneChar=getchar()
            if nr2char(oneChar)=="\<CR>"
              let inputting=0
            elseif oneChar=="\<BS>"
              if newName!=""
                let newName = strpart(newName, 0, strlen(newName)-1)
                echo "gClone as: ".newName
              endif
            else
              let newName=newName.nr2char(oneChar)
            endif
          endwhile
          call system('git clone https://github.com/'.site.' ~/.vim/bundle/'.newName)
          source $MYVIMRC
        endif
        redraw
        echo ""
      endif
    endif
  endif
endfunction

function! s:Banish(input)
  if a:input == ''
    echo 'Banish what?'
    return
  endif
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let error=system('mv ~/.vim/bundle/'.inputNice.' ~/.vim/bundle/'.inputNice.'~ >/dev/null')

  if error==''
    echo "Banished ".inputNice
  elseif match(error, "No such file") !=-1
    let error=system('ls ~/.vim/bundle/'.inputNice.'~ >/dev/null')
    if error!=''
      echo 'There is no plugin named "'.inputNice.'"'
    else
      echo '"'.inputNice.'" has already been banished'
    endif
  else
    "remove trailing newline
    let error = strpart(error, 0, strlen(error)-1)
    echo "Error renaming file: ".error
  endif
endfunction

function! s:Scry(input)
  if a:input == ''
    call s:DisplayInvoked()
    echo "\n"
    call s:DisplayBanished()
  else
    let inputPlus = substitute(a:input, '\s\s*', '+', 'g')
    let inputNice = substitute(a:input, '\s\s*', '', 'g')
    let curlResults = system('curl -silent https://api.github.com/search/repositories?q=vim+'.inputPlus.'\&sort=stars\&order=desc')
    let site = system('grep "full_name" | head -n 10', curlResults)
    let site = substitute(site, '\s*"full_name"[^"]*"\([^"]*\)"[^\n]*', '\1', 'g')
    let siteList = split(site, '\n')

    let description = system('grep "description" | head -n 10', curlResults)
    let description = substitute(description, '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)"[^\n]*', '\1', 'g') "this includes escaped quotes
    let description = substitute(description, '\\"', '"', 'g')
    let descriptionList = split(description, '\n')
    let index=0
    let length=len(siteList)
    while index<length
        echo index.": ".siteList[index]
        echo '('.descriptionList[index].')'
        let index=index+1
        if index<length
          echo "\n"
        endif
    endwhile
  endif
endfunction

function! s:DisplayInvoked()
  let invokedList = split(system('ls -d ~/.vim/bundle/*[^~] 2>/dev/null | sed -nr "s,.*bundle/(.*),\1,p"'),'\n')
  if len(invokedList) == ''
    echo "No plugins invoked"
  else
    echohl Define
    echo "Invoked: "
    echohl None
    let maxlen=0
    for invoked in invokedList
      if len(invoked)>maxlen
        let maxlen=len(invoked)
      endif
    endfor
    for invoked in invokedList
      let origin = system('(cd ~/.vim/bundle/'.invoked.'&& git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        echo invoked
      else
        echo invoked.repeat(' ',maxlen-len(invoked)+3)."(".origin.")"
      endif
    endfor
  endif
endfunction

function! s:DisplayBanished()
  let banishedList = split(system('ls -d ~/.vim/bundle/*~ 2>/dev/null | sed -nr "s,.*bundle/(.*)~,\1,p"'),'\n')
  if len(banishedList) == ''
    echo "No plugins banished"
  else
    echohl Define
    echo "Banished: "
    echohl None
    let maxlen=0
    for banished in banishedList
      if len(banished)>maxlen
        let maxlen=len(banished)
      endif
    endfor
    for banished in banishedList
      let origin = system('(cd ~/.vim/bundle/'.banished.'~ && git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        echo banished
      else
        echo banished.repeat(' ',maxlen-len(banished)+3)."(".origin.")"
      endif
    endfor
  endif
endfunction

let &cpo = g:save_cpo
unlet g:save_cpo
