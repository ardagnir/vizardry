" Vim plugin for installing other vim plugins.
" Last Change: August 07 2015
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

let g:save_cpo = &cpo
set cpo&vim
if exists("g:loaded_vizardry")
  finish
endif
let g:loaded_vizardry = 1

" Plugin Settings {{{1

" Installation method simple clone / submodules
if !exists("g:VizardryGitMethod")
  let g:VizardryGitMethod = "clone"
elseif (g:VizardryGitMethod =="submodule add")
  " Commit message for submodule method
  if !exists("g:VizardryCommitMsgs")
    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \}
  endif
  " Git root directory for submodules
  if !exists("g:VizardryGitBaseDir")
    echoerr "g:VizardryGitBaseDir must be set when VizardryGitMethod is submodule"
    echoerr "Vizardry not loaded"
    unlet g:loaded_vizardry
    finish
  endif
endif

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

" A few path
let s:scriptDir = expand('<sfile>:p:h')
let s:bundleDir = substitute(s:scriptDir, '/[^/]*/[^/]*$', '', '')
let s:EvolveVimOrgPath = s:scriptDir.'/EvolveVimOrgPlugins.sh'
if exists("g:VizardryGitBaseDir")
  let s:relativeBundleDir=substitute(s:bundleDir,g:VizardryGitBaseDir,'','')
  let s:relativeBundleDir=substitute(s:relativeBundleDir,'^/','','')
endif

" Commands definitions {{{1
command! -nargs=? Invoke call s:Invoke(<q-args>)
command! -nargs=? -complete=custom,s:ListAllInvoked Banish
      \ call s:Banish(<q-args>, 'Banish')
command! -nargs=? -complete=custom,s:ListAllInvoked Vanish
      \ call s:Banish(<q-args>, 'Vanish')
command! -nargs=? -complete=custom,s:ListAllBanished Unbanish
      \ call s:UnbanishCommand(<q-args>)
command! -nargs=? -complete=custom,s:ListAllBanished Evolve
      \ call s:Evolve(<q-args>,0)
command! -nargs=? Scry
      \ call s:Scry(<q-args>)
command! -nargs=? -complete=custom,s:ListAllInvoked Magic
      \ call s:Magic(<q-args>)
command! -nargs=? -complete=custom,s:ListAllInvoked Magicedit
      \ call s:MagicEdit(<q-args>)
command! -nargs=? -complete=custom,s:ListAllInvoked Magicsplit
      \ call s:MagicSplit(<q-args>)
command! -nargs=? -complete=custom,s:ListAllInvoked Magicvsplit
      \ call s:MagicVSplit(<q-args>)

" Functions {{{1

" Utils {{{2

" Prompts {{{3

" Colored echo
function! VizardryEcho(msg,type)
  if a:type=='e'
    let group='ErrorMsg'
  elseif a:type=='w'
    let group='WarningMsg'
  elseif a:type=='q'
    let group='Question'
  elseif a:type=='s'
    let group='Define'
  else
    let group='Normal'
  endif
  execute 'echohl '.group
  echo a:msg
  echohl None
endfunction

function! s:GetResponseFromPrompt(prompt, inputChoices)
  call VizardryEcho(a:prompt,'q')
  while 1
    let choice = tolower(nr2char(getchar()))
    for inputChoice in a:inputChoices
      if inputChoice == choice
        return choice
      endif
    endfor
    call VizardryEcho("Invalid choice: Type ".s:ListChoices(a:inputChoices).
          \": ",'w')
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
    let ret = ret.a:choices[i].', '
    let i+=1
  endwhile
  return ret.'or '.a:choices[length-1]
endfunction

function! s:HandleInvokePrompt(site, description, inputNice, index)
  let valid = 0
  let bundle=substitute(a:site, '.*/','','')
  let inputNice = s:FormValidBundle(bundle)
  let ret=-1
  let idx=a:index+1
  while valid == 0
    call VizardryEcho("Result ".idx."/".len(s:siteList).
          \ ": ".a:site."\n(".a:description.")\n\n",'')
    let response = s:GetResponseFromPrompt("Clone as \"".inputNice.
          \ "\"? (Yes/Rename/DisplayMore/Next/Previous/Abort)",
          \ ['y','r','d','n','p','a'])
    if response == 'y'
      call s:GrabRepository(a:site, inputNice)
      call s:ReloadScripts()
      let valid=1
    elseif response == 'r'
      let newName = ""
      let inputting = 1
      while inputting
        redraw
        call VizardryEcho("Clone as: ".newName,'')
        let oneChar=getchar()
        if nr2char(oneChar) == "\<CR>"
          let inputting=0
        elseif oneChar == "\<BS>"
          if newName!=""
            let newName = strpart(newName, 0, strlen(newName)-1)
            call VizardryEcho("gClone as: ".newName,'')
          endif
        else
          let newName=newName.nr2char(oneChar)
        endif
      endwhile
      if s:TestForBundle(newName)
        redraw
        call VizardryEcho("Name already taken",'w')
      else
        call s:GrabRepository(a:site, newName)
        call s:ReloadScripts()
        let valid = 1
      endif
    elseif response == 'n'
      let ret=a:index+1
      let valid = 1
    elseif response == 'd'
      call VizardryEcho("Looking for README url",'s')
      let readmeurl=system('curl -silent https://api.github.com/repos/'.
            \ a:site.'/readme | grep download_url')
      let readmeurl=substitute(readmeurl,
            \ '\s*"download_url"[^"]*"\(.*\)",.*','\1','')
      call VizardryEcho("Retrieving README",'s')
      if readmeurl == ""
        echohl WarningMsg
        call VizardryEcho("No readme found",'e')
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
  return ret
endfunction

" Repositories management {{{3
" Clone a Repo
function! s:GrabRepository(site, name)
  call VizardryEcho("grab repo ".a:site. " name ".a:name,'s')
  if exists("g:VizardryGitBaseDir")
    let l:commit=' && git commit -m "'.g:VizardryCommitMsgs['Invoke'].' '.
          \ a:name.'" '.s:relativeBundleDir.'/'.a:name.' .gitmodules'
    let l:precmd=':!cd '.g:VizardryGitBaseDir
    let l:path=s:relativeBundleDir
  else
    let l:commit=''
    let l:precmd=''
    let l:path=s:bundleDir
  endif
  execute l:precmd.' && git '.g:VizardryGitMethod.' https://github.com/'.
        \ a:site.' '.l:path.'/'.a:name.l:commit
endfunction

" Test existing repo
function! s:TestRepository(repository)
  redraw
  let bundleList = split(system('ls -d '.s:bundleDir.
        \ '/* 2>/dev/null | sed -n "s,.*bundle/\(.*\),\1,p"'),'\n')
  for bundle in bundleList
    if system('cd '.s:bundleDir.'/'.bundle.
          \ ' && git config --get remote.origin.url') ==
          \ 'https://github.com/'.a:repository."\n"
      return bundle
    endif
  endfor
  return ""
endfunction

" Test existing bundle
function! s:TestForBundle(bundle)
  if a:bundle!=""
    return system('ls -d '.s:bundleDir.'/'.a:bundle.' 2>/dev/null')!=''
  endif
endfunction

function! s:FormValidBundle(bundle)
  if !s:TestForBundle(a:bundle) && !s:TestForBundle(a:bundle.'~')
    return a:bundle
  endif

  let counter = 0
  while s:TestForBundle(a:bundle.counter)||s:TestForBundle(a:bundle.counter.'~')
    let counter += 1
  endwhile
  return a:bundle.counter
endfunction

" List Invoked / Banished plugins {{{3
function! s:ListAllInvoked(A,L,P)
  return s:ListInvoked('*')
endfunction

function! s:ListAllBanished(A,L,P)
  return s:ListBanished('*')
endfunction

function! s:ListInvoked(match)
  let invokedList = system('ls -d '.s:bundleDir.'/'.a:match.
        \ ' 2>/dev/null | grep -v "~$" | sed -n "s,.*/\(.*\),\1,p"')
  return invokedList
endfunction

function! s:ListBanished(match)
  let banishedList = system('ls -d '.s:bundleDir.'/'.a:match.
        \ '~ 2>/dev/null | sed -n "s,.*/\(.*\)~,\1,p"')
  return banishedList
endfunction

function! s:DisplayInvoked()
  let invokedList = split(s:ListInvoked('*'),'\n')
  if len(invokedList) == ''
    echohl Define
    call VizardryEcho("No plugins invoked",'w')
    echohl None
  else
    echohl Define
    call VizardryEcho("Invoked: ",'')
    echohl None
    let maxlen=0
    for invoked in invokedList
      if len(invoked)>maxlen
        let maxlen=len(invoked)
      endif
    endfor
    for invoked in invokedList
      let origin = system('(cd '.s:bundleDir.'/'.invoked.
            \ '&& git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        call VizardryEcho(invoked,'')
      else
        call VizardryEcho(invoked.repeat(' ',maxlen-len(invoked)+3).
              \"(".origin.")",'')
      endif
    endfor
  endif
endfunction

function! s:DisplayBanished()
  let banishedList = split(s:ListBanished('*'),'\n')
  if len(banishedList) == ''
    echohl Define
    call VizardryEcho("No plugins banished",'w')
    echohl None
  else
    echohl Define
    call VizardryEcho("Banished: ",'')
    echohl None
    let maxlen=0
    for banished in banishedList
      if len(banished)>maxlen
        let maxlen=len(banished)
      endif
    endfor
    for banished in banishedList
      let origin = system('(cd '.s:bundleDir.'/'.banished.
            \ '~ && git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        call VizardryEcho(banished,'')
      else
        call VizardryEcho(banished.repeat(' ',maxlen-len(banished)+3).
              \"(".origin.")",'')
      endif
    endfor
  endif
endfunction

" Reload scripts {{{3
function! s:ReloadScripts()
  source $MYVIMRC
  let files=[]
  for plugin in split(&runtimepath,',')
    for file in split(system ("find ".plugin.
          \ '/plugin -name "*.vim" 2>/dev/null'),'\n')
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
    for file in split(system ("find ".plugin.
          \ '/autoload -name "*.vim" 2>/dev/null'),'\n')
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
  endfor
  execute ':Helptags'
endfunction

" Query github {{{3
function! s:InitLists(input)
  " Sanitize input / prepare query
    let user=substitute(a:input, '.*-u\s\s*\(\S*\).*','\1','')
    let l:input=substitute(substitute(a:input, '-u\s\s*\S*','',''),
          \'^\s\s*','','')
    let s:lastScry = substitute(l:input, '\s\s*', '', 'g')
    let lastScryPlus = substitute(l:input, '\s\s*', '+', 'g')
    let query=lastScryPlus
    if match(a:input, '-u') != -1
      call VizardryEcho("match",'')
      let query=substitute(query,'+$','','') "Remove useless '+' if no keyword
      let query.='+user:'.user
    endif
    call VizardryEcho("Searching for ".query."...",'s')
    let query.='+language:viml+'.g:VizardrySearchOptions
    call VizardryEcho("(actual query: '".query."')",'')
    " Do query
    let curlResults = system(
          \ 'curl -silent https://api.github.com/search/repositories?q='.query)
    " Prepare list (sites and descriptions)
    let curlResults = substitute(curlResults, 'null,','"",','g')
    let site = system('grep "full_name" | head -n '.g:VizardryNbScryResults,
          \ curlResults)
    let site = substitute(site, '\s*"full_name"[^"]*"\([^"]*\)"[^\n]*','\1','g')
    let s:siteList = split(site, '\n')

    let description = system('grep "description" | head -n '.
          \ g:VizardryNbScryResults, curlResults)
    let description = substitute(description,
          \ '\s*"description"[^"]*"\([^"\\]*\(\\.[^"\\]*\)*\)"[^\n]*','\1','g')
    let description = substitute(description, '\\"', '"', 'g')
    let s:descriptionList = split(description, '\n')
endfunction

" Commands {{{2

" Evolve {{{3

" Upgrade a specific plugin (git repo)
function s:GitEvolve(path)
  let l:ret=system('cd '.a:path.' && git pull origin master')
  call VizardryEcho(l:ret,'')
  if l:ret=~'Already up-to-date'
    return ''
  endif
  return a:path
endfunction

" Upgrade a specific plugin (vim.org)
function s:VimOrgEvolve(path)
  let l:ret=system(s:EvolveVimOrgPath.' '.a:path)
  call VizardryEcho(l:ret,'')
  if l:ret=~'upgrading .*'
    return a:path
  endif
  return ''
endfunction

" Upgrade one or every plugins
function! s:Evolve(input, rec)
  if a:input==""
    " Try evolve every plugins
    let invokedList = split(s:ListInvoked('*'),'\n')
    let l:files=''
    for plug in invokedList
      let l:files.=' '.s:Evolve(plug,1)
    endfor
  else
    " Try evolve a particular plugin
    let inputNice = substitute(a:input, '\s\s*', '', 'g')
    let exists = s:TestForBundle(inputNice)
    if !exists
      call VizardryEcho("No plugin named '".inputNice."', aborting upgrade",'e')
      return
    endif
    if glob(s:bundleDir.'/'.inputNice.'/.git')!=""
      let l:files=s:GitEvolve(s:bundleDir.'/'.inputNice)
    else
      let l:files=s:VimOrgEvolve(s:bundleDir.'/'.inputNice)
    endif
  endif
  let l:files=substitute(l:files,'^\s*$','','')
  if a:rec==0
    " Commit / echo result
    if l:files!=""
      let l:basefiles=substitute(
            \ substitute(l:files,s:bundleDir.'/','','g'),'\s\s*', ' ','g')
      if exists("g:VizardryGitBaseDir")
        execute ':!'.'cd '.g:VizardryGitBaseDir.' && git commit -m"'.
              \ g:VizardryCommitMsgs['Evolve'].' '.l:basefiles.'" '.
              \ l:files.' .gitmodules'
      else
        call VizardryEcho("Evolved plugins: ".l:files,'')
      endif
    else
      call VizardryEcho("No plugin upgraded",'w')
    endif
  else
    return l:files
  endif
endfunction

" Invoke {{{3
" Install or unBannish a plugin
function! s:Invoke(input)
  if a:input == '' " No input, reload plugins
    call s:ReloadScripts()
    call VizardryEcho("Updated scripts",'')
    return
  endif

  let inputNumber = str2nr(a:input)
  if inputNumber!=0
    " Input is a number search from previous search results
    if exists("s:siteList") && inputNumber < len(s:siteList) || a:input=="0"
      let l:index=inputNumber
      call VizardryEcho("Index ".inputNumber.' from scry search for "'.
            \s:lastScry.'":','s')
      let inputNice = s:lastScry
    else
      call VizardryEcho("Invalid command :'Invoke ".a:input.
            \"' numeric argument can only be used after an actual search ".
            \ "(Scry or invoke)",'e')
      return
    endif
  else
    " Actual query
    let inputNice = substitute(substitute(a:input, '\s*-u\s\s*\S*\s*','',''),
          \ '\s\s*', '', 'g')
    let exists = s:TestForBundle(inputNice)
    if exists
      let response = s:GetResponseFromPrompt('You already have a bundle called '
            \ .inputNice.'. Search anyway? (Yes/No)',['y','n'])
      if response == 'n'
        return
      endif
    endif
    call s:InitLists(a:input)
    let l:index=0
  endif

  " Installation prompt / navigation trough results
  while( l:index >= 0 && l:index < len(s:siteList))
    let site=s:siteList[l:index]
    let description=s:descriptionList[l:index]
  let matchingBundle = s:TestRepository(site)
    if matchingBundle != ""
      call VizardryEcho('Found '.site,'s')
      call VizardryEcho('('.description.')','')
      if(matchingBundle[len(matchingBundle)-1] == '~')
        let matchingBundle = strpart(matchingBundle,0,strlen(matchingBundle)-1)
        call VizardryEcho('This is the repository for banished bundle "'.
              \matchingBundle.'"','w')
        if( s:GetResponseFromPrompt("Unbanish it? (Yes/No)", ['y', 'n'])== 'y')
          call s:Unbanish(matchingBundle, 1)
          execute ':Helptags'
        endif
        redraw
      else
        call VizardryEcho('This has already been invoked as "'.
              \matchingBundle.'"','w')
      endif
      return
    else
      let l:index=s:HandleInvokePrompt(site, description, inputNice,index)
      redraw
    endif
  endwhile
endfunction

" UnBannish {{{3
function! s:UnbanishCommand(bundle)
  let niceBundle = substitute(a:bundle, '\s\s*', '', 'g')
  let matches = s:ListBanished(a:bundle)
  if matches!=''
    let matchList = split(matches, "\n")
    let success=0
    for aMatch in matchList
      if s:Unbanish(aMatch, 0) != ''
        call VizardryEcho('Failed to unbanish "'.aMatch.'"','e')
      else
        call VizardryEcho("Unbanished ".aMatch,'')
      endif
    endfor
    call s:ReloadScripts()
  else
    if s:ListInvoked(a:bundle)!=''
     let msg='Bundle "'.niceBundle.'" is not banished.'
    else
     let msg='Bundle "'.niceBundle.'" does not exist.'
    endif
    call VizardryEcho(msg,'w')
  endif
endfunction

function! s:Unbanish(bundle, reload)
  if exists("g:VizardryGitBaseDir")
    let l:commit=' && git commit -m "'.g:VizardryCommitMsgs['Invoke'].' '.
          \ a:bundle.'" '.s:relativeBundleDir.'/'.a:bundle.' '.
          \ s:relativeBundleDir.'/'.a:bundle.'~ .gitmodules'
    let l:cmd='cd '.g:VizardryGitBaseDir.' && git mv '.s:relativeBundleDir.'/'.
          \ a:bundle.'~ '.s:relativeBundleDir.'/'.a:bundle.l:commit
  else
    let l:cmd='mv '.s:bundleDir.'/'.a:bundle.'~ '.s:bundleDir.'/'.a:bundle
  endif
  let ret = system(l:cmd)
  call s:UnbanishMagic(a:bundle)
  if a:reload
    call s:ReloadScripts()
  endif
  return ret
endfunction

" Banish {{{3
" Temporarily deactivate a plugin
function! s:Banish(input, type)
  if a:input == ''
    call VizardryEcho('Banish what?','w')
    return
  endif
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let matches = s:ListInvoked(inputNice)
  if matches == ''
    if ListBanished(inputNice) != ''
      call VizardryEcho('"'.inputNice.'" has already been banished','w')
    else
      call VizardryEcho('There is no plugin named "'.inputNice.'"','e')
    endif
  else
    let matchList = split(matches,'\n')
    for aMatch in matchList
      if exists("g:VizardryGitBaseDir")
        let l:commit=' && git commit -m "'.g:VizardryCommitMsgs[a:type].' '.
              \ aMatch.'" '.s:relativeBundleDir.'/'.aMatch.' .gitmodules'
        if a:type== 'Banish'
          let l:commit.=' '.s:relativeBundleDir.'/'.aMatch.'~'
          let l:cmd='cd '.g:VizardryGitBaseDir.' && git mv '.
                \ s:relativeBundleDir.'/'.aMatch.' '.s:relativeBundleDir.'/'.
                \ aMatch.'~'.l:commit
        else
          let l:cmd='cd '.g:VizardryGitBaseDir.' && git submodule deinit -f '.
                \ s:relativeBundleDir.'/'.aMatch.' && git rm -rf '.
                \ s:relativeBundleDir.'/'.aMatch.l:commit
        endif
      else
        if a:type== 'Banish'
          let l:cmd='mv '.s:bundleDir.'/'.aMatch.' '.s:bundleDir.'/'.aMatch.
                \ '~ >/dev/null'
        else
          let l:cmd='rm -rf '.s:bundleDir.'/'.aMatch.' >/dev/null'
        endif
      endif
      let error=system(l:cmd)
      call s:BanishMagic(aMatch)
      if v:shell_error!=0
        call VizardryEcho(a:type.'ed '.aMatch,'')
      else
        let error = strpart(error, 0, strlen(error)-1)
        call VizardryEcho("Error renaming file: ".error,'e')
      endif
    endfor
  endif
endfunction

" Scry {{{3
function! s:Scry(input)
  if a:input == ''
    call s:DisplayInvoked()
    echo "\n"
    call s:DisplayBanished()
  else
    call s:InitLists(a:input)
    let index=0
    let length=len(s:siteList)
    redraw
    while index<length
      call VizardryEcho(index.": ".s:siteList[index],'')
      call VizardryEcho('('.s:descriptionList[index].')','')
      let index=index+1
      if index<length
        echo "\n"
      endif
    endwhile
  endif
endfunction

" Magic {{{3
function! s:MagicName(plugin)
  if a:plugin == '*'
    return s:scriptDir.'/magic/magic.vim'
  else
    return s:scriptDir.'/magic/magic_'.a:plugin.'.vim'
  endif
endfunction

function! s:BanishMagic(plugin)
  let fileName = s:MagicName(a:plugin)
  call system('mv '.fileName.' '.fileName.'~')
endfunction

function! s:UnbanishMagic(plugin)
  let fileName = s:MagicName(a:plugin)
  call system('mv '.fileName.'~ '.fileName)
endfunction

function! s:Magic(incantation)
  let incantationList = split(a:incantation, ' ')
  if len(incantationList) == 0
    call VizardryEcho("No plugin given",'w')
    return
  endif
  let plugin = incantationList[0]
  let incantation = join(incantationList[1:],' ')

  try
    exec incantation
    call system('mkdir '.s:scriptDir.'/magic')
    call system('cat >> '.s:MagicName(plugin), incantation."\n")
  endtry
endfunction

function! s:MagicEdit(incantation)
  exec "edit" s:MagicName(a:incantation)."*"
endfunction

function! s:MagicSplit(incantation)
  exec "split" s:MagicName(a:incantation)."*"
endfunction

function! s:MagicVSplit(incantation)
  exec "vsplit ".s:MagicName(a:incantation)."*"
endfunction

let &cpo = g:save_cpo
unlet g:save_cpo
" vim:set et sw=2:
