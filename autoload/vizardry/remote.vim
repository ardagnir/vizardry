" Vim plugin for installing other vim plugins.
" Last Change: August 22 2015
" Maintainer: David Beniamine
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

if !exists("g:loaded_vizardry")
  echoerr "Vizardry not loaded"
  finish
endif

" Settings {{{1

" Number of results displayed by Scry
if !exists("g:VizardryNbScryResults")
  let g:VizardryNbScryResults=10
endif

" How to read Readme files
if !exists("g:VizardryReadmeReader")
  let g:VizardryReadmeReader='view -c "set ft=markdown" -'
endif

" Git api search options see
" https://developer.github.com/v3/search/#search-repositories
if !exists("g:VizardrySearchOptions")
  let g:VizardrySearchOptions='fork:true'
endif

let g:vizardry#remote#EvolveVimOrgPath = g:vizardry#scriptDir.'/plugin/EvolveVimOrgPlugins.sh'
" Functions {{{1

" Clone a Repo {{{2
function! vizardry#remote#grabRepo(site, name)
  call vizardry#echo("grab repo ".a:site. " name ".a:name,'s')
  if exists("g:VizardryGitBaseDir")
    let l:commit=' && git commit -m "'.g:VizardryCommitMsgs['Invoke'].' '.
          \ a:name.'" '.g:vizardry#relativeBundleDir.'/'.a:name.' .gitmodules'
    let l:precmd=':!cd '.g:VizardryGitBaseDir.' && '
    let l:path=g:vizardry#relativeBundleDir
  else
    let l:commit=''
    let l:precmd=':!'
    let l:path=g:vizardry#bundleDir
  endif
  execute l:precmd.' git '.g:VizardryGitMethod.' https://github.com/'.
        \ a:site.' '.l:path.'/'.a:name.l:commit
endfunction

" Test existing repo {{{2
function! vizardry#remote#testRepo(repository)
  redraw
  let bundleList = split(system('ls -d '.g:vizardry#bundleDir.
        \ '/* 2>/dev/null | sed -n "s,.*bundle/\(.*\),\1,p"'),'\n')
  for bundle in bundleList
    if system('cd '.g:vizardry#bundleDir.'/'.bundle.
          \ ' && git config --get remote.origin.url') ==
          \ 'https://github.com/'.a:repository."\n"
      return bundle
    endif
  endfor
  return ""
endfunction

" Invoke helper {{{2
function! vizardry#remote#handleInvokation(site, description, inputNice, index)
  let valid = 0
  let bundle=substitute(a:site, '.*/','','')
  let inputNice = vizardry#formValidBundle(bundle)
  let ret=-1
  let idx=a:index+1
  while valid == 0
    call vizardry#echo("Result ".idx."/".len(g:vizardry#siteList).
          \ ": ".a:site."\n(".a:description.")\n\n",'')
    let response = vizardry#doPrompt("Clone as \"".inputNice.
          \ "\"? (Yes/Rename/DisplayMore/Next/Previous/Abort)",
          \ ['y','r','d','n','p','a'])
    if response == 'y'
      call vizardry#remote#grabRepo(a:site, inputNice)
      call vizardry#ReloadScripts()
      let valid=1
    elseif response == 'r'
      let newName = ""
      let inputting = 1
      while inputting
        redraw
        call vizardry#echo("Clone as: ".newName,'')
        let oneChar=getchar()
        if nr2char(oneChar) == "\<CR>"
          let inputting=0
        elseif oneChar == "\<BS>"
          if newName!=""
            let newName = strpart(newName, 0, strlen(newName)-1)
            call vizardry#echo("gClone as: ".newName,'')
          endif
        else
          let newName=newName.nr2char(oneChar)
        endif
      endwhile
      if vizardry#testBundle(newName)
        redraw
        call vizardry#echo("Name already taken",'w')
      else
        call vizardry#remote#grabRepo(a:site, newName)
        call vizardry#ReloadScripts()
        let valid = 1
      endif
    elseif response == 'n'
      let ret=a:index+1
      let valid = 1
    elseif response == 'd'
      call vizardry#echo("Looking for README url",'s')
      let readmeurl=system('curl -silent https://api.github.com/repos/'.
            \ a:site.'/readme | grep download_url')
      let readmeurl=substitute(readmeurl,
            \ '\s*"download_url"[^"]*"\(.*\)",.*','\1','')
      call vizardry#echo("Retrieving README",'s')
      if readmeurl == ""
        echohl WarningMsg
        call vizardry#echo("No readme found",'e')
        echohl None
      else
        execute ':!curl -silent '.readmeurl.' | sed "1,/^$/ d" | '.
              \ g:VizardryReadmeReader
      endif
    elseif response == 'a'
      let valid=1
    elseif response == 'p'
      let ret=a:index-1
      let valid=1
    endif
  endwhile
  redraw
  echo ret
  return ret
endfunction

" Query github {{{2
function! vizardry#remote#InitLists(input)
  " Sanitize input / prepare query
    let user=substitute(a:input, '.*-u\s\s*\(\S*\).*','\1','')
    let l:input=substitute(substitute(a:input, '-u\s\s*\S*','',''),
          \'^\s\s*','','')
    let g:vizardry#lastScry = substitute(l:input, '\s\s*', '', 'g')
    let lastScryPlus = substitute(l:input, '\s\s*', '+', 'g')
    let query=lastScryPlus
    if match(a:input, '-u') != -1
      call vizardry#echo("match",'')
      let query=substitute(query,'+$','','') "Remove useless '+' if no keyword
      let query.='+user:'.user
    endif
    call vizardry#echo("Searching for ".query."...",'s')
    let query.='+language:viml+'.g:VizardrySearchOptions
    call vizardry#echo("(actual query: '".query."')",'')
    " Do query
    let curlResults = system(
          \ 'curl -silent https://api.github.com/search/repositories?q='.query)
    " Prepare list (sites and descriptions)
    let curlResults = substitute(curlResults, 'null,','"",','g')
    let site = system('grep "full_name" | head -n '.g:VizardryNbScryResults,
          \ curlResults)
    let site = substitute(site, '\s*"full_name"[^"]*"\([^"]*\)"[^\n]*','\1','g')
    let g:vizardry#siteList = split(site, '\n')

    let description = system('grep "description" | head -n '.
          \ g:VizardryNbScryResults, curlResults)
    let description = substitute(description,
          \ '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)"[^\n]*','\1','g')
    let description = substitute(description, '\\"', '"', 'g')
    let g:vizardry#descriptionList = split(description, '\n')
endfunction


" Commands {{{ 1

" Invoke {{{2
" Install or unBannish a plugin
function! vizardry#remote#Invoke(input)
  if a:input == '' " No input, reload plugins
    call vizardry#ReloadScripts()
    call vizardry#echo("Updated scripts",'')
    return
  endif

  let inputNumber = str2nr(a:input)
  if inputNumber!=0
    " Input is a number search from previous search results
    if exists("g:vizardry#siteList") && inputNumber < len(g:vizardry#siteList)
          \|| a:input=="0"
      let l:index=inputNumber
      call vizardry#echo("Index ".inputNumber.' from scry search for "'.
            \g:vizardry#lastScry.'":','s')
      let inputNice = g:vizardry#lastScry
    else
      call vizardry#echo("Invalid command :'Invoke ".a:input.
            \"' numeric argument can only be used after an actual search ".
            \ "(Scry or invoke)",'e')
      return
    endif
  else
    " Actual query
    let inputNice = substitute(substitute(a:input, '\s*-u\s\s*\S*\s*','',''),
          \ '\s\s*', '', 'g')
    let exists = vizardry#testBundle(inputNice)
    if exists
      let response = vizardry#doPrompt('You already have a bundle called '
            \ .inputNice.'. Search anyway? (Yes/No)',['y','n'])
      if response == 'n'
        return
      endif
    endif
    call vizardry#remote#InitLists(a:input)
    let l:index=0
  endif

  " Installation prompt / navigation trough results
  while( l:index >= 0 && l:index < len(g:vizardry#siteList))
    let site=g:vizardry#siteList[l:index]
    let description=g:vizardry#descriptionList[l:index]
  let matchingBundle = vizardry#remote#testRepo(site)
    if matchingBundle != ""
      call vizardry#echo('Found '.site,'s')
      call vizardry#echo('('.description.')','')
      if(matchingBundle[len(matchingBundle)-1] == '~')
        let matchingBundle = strpart(matchingBundle,0,strlen(matchingBundle)-1)
        call vizardry#echo('This is the repository for banished bundle "'.
              \matchingBundle.'"','w')
        if( vizardry#doPrompt("Unbanish it? (Yes/No)", ['y', 'n'])== 'y')
          call vizardry#local#Unbanish(matchingBundle, 1)
          execute ':Helptags'
        endif
        redraw
      else
        call vizardry#echo('This has already been invoked as "'.
              \matchingBundle.'"','w')
      endif
      return
    else
      let l:index=vizardry#remote#handleInvokation(site, description, inputNice,index)
      redraw
    endif
  endwhile
endfunction

" Evolve {{{2

" Upgrade a specific plugin (git repo)
function s:GitEvolve(path)
  let l:ret=system('cd '.a:path.' && git pull origin master')
  call vizardry#echo(l:ret,'')
  if l:ret=~'Already up-to-date'
    return ''
  endif
  return a:path
endfunction

" Upgrade a specific plugin (vim.org)
function s:VimOrgEvolve(path)
  let l:ret=system(g:vizardry#remote#EvolveVimOrgPath.' '.a:path)
  call vizardry#echo(l:ret,'')
  if l:ret=~'upgrading .*'
    return a:path
  endif
  return ''
endfunction

" Upgrade one or every plugins
function! vizardry#remote#Evolve(input, rec)
  if a:input==""
    " Try evolve every plugins
    let invokedList = split(vizardry#ListInvoked('*'),'\n')
    let l:files=''
    for plug in invokedList
      let l:files.=' '.vizardry#remote#Evolve(plug,1)
    endfor
  else
    " Try evolve a particular plugin
    let inputNice = substitute(a:input, '\s\s*', '', 'g')
    let exists = vizardry#testBundle(inputNice)
    if !exists
      call vizardry#echo("No plugin named '".inputNice."', aborting upgrade",'e')
      return
    endif
    if glob(g:vizardry#bundleDir.'/'.inputNice.'/.git')!=""
      let l:files=s:GitEvolve(g:vizardry#bundleDir.'/'.inputNice)
    else
      let l:files=s:VimOrgEvolve(g:vizardry#bundleDir.'/'.inputNice)
    endif
  endif
  let l:files=substitute(l:files,'^\s*$','','')
  if a:rec==0
    " Commit / echo result
    if l:files!=""
      let l:basefiles=substitute(
            \ substitute(l:files,g:vizardry#bundleDir.'/','','g'),'\s\s*', ' ','g')
      if exists("g:VizardryGitBaseDir")
        execute ':!'.'cd '.g:VizardryGitBaseDir.' && git commit -m"'.
              \ g:VizardryCommitMsgs['Evolve'].' '.l:basefiles.'" '.
              \ l:files.' .gitmodules'
      else
        call vizardry#echo("Evolved plugins: ".l:files,'')
      endif
    else
      call vizardry#echo("No plugin upgraded",'w')
    endif
  else
    return l:files
  endif
endfunction

" Scry {{{2
function! vizardry#remote#Scry(input)
  if a:input == ''
    call vizardry#DisplayInvoked()
    echo "\n"
    call vizardry#DisplayBanished()
  else
    call vizardry#remote#InitLists(a:input)
    let index=0
    let length=len(g:vizardry#siteList)
    redraw
    while index<length
      call vizardry#echo(index.": ".g:vizardry#siteList[index],'')
      call vizardry#echo('('.g:vizardry#descriptionList[index].')','')
      let index=index+1
      if index<length
        echo "\n"
      endif
    endwhile
  endif
endfunction

" vim:set et sw=2:
