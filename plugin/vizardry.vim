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
command! -nargs=? Unbanish call s:UnbanishCommand(<q-args>)
command! -nargs=? Scry call s:Scry(<q-args>)

function! s:Invoke(input)
  if a:input == ''
    source $MYVIMRC
    echo "Updated vim"
    return
  endif

  let inputNumber = str2nr(a:input)
  if inputNumber!=0 && inputNumber<10 || a:input=="0"
    let site=s:siteList[inputNumber]
    let description=s:descriptionList[inputNumber]
    echo "Index ".inputNumber.' from scry search for "'.s:lastScry.'":'
    let inputNice = substitute(s:lastScry, '\s\s*', '', 'g')
  else
    let inputPlus = substitute(a:input, '\s\s*', '+', 'g')
    let inputNice = substitute(a:input, '\s\s*', '', 'g')
    let exists = s:TestForBundle(inputNice)
    if exists
      let response = s:GetResponseFromPrompt('You already have a bundle called '.inputNice.'. Search anyway? (Yes/No)',['y','n'])
      if response == 'n'
        return
      endif
    endif
    "let banished = s:TestForBundle(inputNice.'~')
    "if banished
      "if s:GetResponseFromPrompt("Unbanish ".inputNice."? (y/n)", ['y', 'n']) == 'y'
        "call s:Unbanish(inputNice)
      "endif
    "endif
    redraw
    echo "Searching..."
    let curlResults = system('curl -silent https://api.github.com/search/repositories?q=vim+'.inputPlus.'\&sort=stars\&order=desc')

    let site = system('grep "full_name" | head -n 1', curlResults)

    if site==""
      echo '"'.a:input.'" not found'
      return
    endif
    let site = substitute(site, '\s*"full_name"[^"]*"\(.*\)".*', '\1', '')

    let description = system('grep "description" | head -n 1', curlResults)
    let description = substitute(description, '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)".*', '\1', '') "this includes escaped quotes
    let description = substitute(description, '\\"', '"', 'g')
  endif

  let matchingBundle = s:TestRepository(site)
  if matchingBundle != ""
    echo 'Found '.site
    echo '('.description.')'
    if(matchingBundle[len(matchingBundle)-1] == '~')
      let matchingBundle = strpart(matchingBundle, 0, strlen(matchingBundle)-1)
      echohl WarningMsg
      echo 'This is the repository for banished bundle "'.matchingBundle.'"'
      echohl None
      if( s:GetResponseFromPrompt("Unbanish it? (Yes/No)", ['y', 'n']) == 'y')
        call s:Unbanish(matchingBundle)
      endif
      redraw
      echo ""
    else
      echohl WarningMsg
      echo 'This has already been invoked as "'.matchingBundle.'"'
      echohl None
    endif
  else
    call s:HandleInvokePrompt(site, description, inputNice)
    redraw
    echo ""
  endif
endfunction

function! s:UnbanishCommand(bundle)
  let niceBundle = substitute(a:bundle, '\s\s*', '', 'g')
  if s:TestForBundle(niceBundle)
    echo 'Bundle "'.niceBundle.'" is not banished.'
  elseif !s:TestForBundle(niceBundle."~")
    echo 'Bundle "'.niceBundle.'" does not exist.'
  else
    if s:Unbanish(niceBundle) != ''
      echo "Failed to unbanish ".niceBundle.'"'
    else
      redraw
      echo ""
    endif
  endif
endfunction

function! s:Unbanish(bundle)
  let ret = system('mv ~/.vim/bundle/'.a:bundle.'~ ~/.vim/bundle/'.a:bundle)
  source $MYVIMRC
  return ret
endfunction

function! s:GetResponseFromPrompt(prompt, inputChoices)
  echo a:prompt
  while 1
    let choice = tolower(nr2char(getchar()))
    for inputChoice in a:inputChoices
      if inputChoice == choice
        return choice
      endif
    endfor
    echo "Invalid choice: Type ".s:ListChoices(a:inputChoices).": "
  endwhile
endfunction

function! s:ListChoices(choices)
  let length = len(a:choices)
  if length == 0
    return ""
  elseif length == 1
    return a:choices[0]
  elseif length == 2
    return a:choices[0]." or ".a:choices[1]
  endif

  let i = 0
  let ret=''
  while(i < length-1)
    ret = ret.a:choices[i].', '
  endwhile
  return ret.', or 'a:choices[length-1]
endfunction

function! s:HandleInvokePrompt(site, description, inputNice)
  let valid = 0
  let inputNice = s:FormValidBundle(a:inputNice)
  while valid == 0
    let response = s:GetResponseFromPrompt("Found ".a:site."\n(".a:description.")\n\nClone as \"".inputNice."\"? (Yes/No/Rename)", ['y','n','r'])
    if response == 'y'
      call system('git clone https://github.com/'.a:site.' ~/.vim/bundle/'.inputNice)
      source $MYVIMRC
      let valid=1
    elseif response == 'r'
      let newName = ""
      let inputting = 1
      while inputting
        redraw
        echo "Clone as: ".newName
        let oneChar=getchar()
        if nr2char(oneChar) == "\<CR>"
          let inputting=0
        elseif oneChar == "\<BS>"
          if newName!=""
            let newName = strpart(newName, 0, strlen(newName)-1)
            echo "gClone as: ".newName
          endif
        else
          let newName=newName.nr2char(oneChar)
        endif
      endwhile
      if s:TestForBundle(newName)
        redraw
        echo "Name already taken"
      else
        call system('git clone https://github.com/'.a:site.' ~/.vim/bundle/'.newName)
        source $MYVIMRC
        let valid = 1
      endif
    elseif response == 'n'
      let valid = 1
    endif
  endwhile
  redraw
  echo ""
endfunction

function! s:TestRepository(repository)
  redraw
  let bundleList = split(system('ls -d ~/.vim/bundle/* 2>/dev/null | sed -nr "s,.*bundle/(.*),\1,p"'),'\n')
  for bundle in bundleList
    if system('cd ~/.vim/bundle/'.bundle.' && git config --get remote.origin.url') == 'https://github.com/'.a:repository."\n"
      return bundle
    endif
  endfor
  return ""
endfunction

function! s:TestForBundle(bundle)
    return (system('ls -d ~/.vim/bundle/'.a:bundle.' >/dev/null')=='')
endfunction

function! s:FormValidBundle(bundle)
    if !s:TestForBundle(a:bundle) && !s:TestForBundle(a:bundle.'~')
      return a:bundle
    endif

    let counter = 0
    while s:TestForBundle(a:bundle.counter) || s:TestForBundle(a:bundle.counter.'~')
      let counter += 1
    endwhile
    return a:bundle.counter
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
    let s:lastScry = substitute(a:input, '\s\s*', '+', 'g')
    let lastScryPlus = substitute(a:input, '\s\s*', '', 'g')
    redraw
    echo "Searching..."
    let curlResults = system('curl -silent https://api.github.com/search/repositories?q=vim+'.lastScryPlus.'\&sort=stars\&order=desc')
    let site = system('grep "full_name" | head -n 10', curlResults)
    let site = substitute(site, '\s*"full_name"[^"]*"\([^"]*\)"[^\n]*', '\1', 'g')
    let s:siteList = split(site, '\n')

    let description = system('grep "description" | head -n 10', curlResults)
    let description = substitute(description, '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)"[^\n]*', '\1', 'g') "this includes escaped quotes
    let description = substitute(description, '\\"', '"', 'g')
    let s:descriptionList = split(description, '\n')
    let index=0
    let length=len(s:siteList)
    redraw
    while index<length
        echo index.": ".s:siteList[index]
        echo '('.s:descriptionList[index].')'
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
