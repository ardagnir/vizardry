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

if !exists("g:VizardryGitMethod")
  let g:VizardryGitMethod = "clone"
elseif (g:VizardryGitMethod =="submodule add")
  if !exists("g:VizardryCommitMsgs")
    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \}
  endif
  if !exists("g:VizardryGitBaseDir")
    echo "g:VizardryGitBaseDir must be set when VizardryGitMethod is submodule"
    echo "Vizardry not loaded"
    unlet g:loaded_vizardry
    finish
  endif
endif

if !exists("g:VizardryNbScryResults")
  let g:VizardryNbScryResults=10
endif

if !exists("g:VizardryReadmeReader")
  let g:VizardryReadmeReader='view -c "set ft=markdown" -'
endif

if !exists("g:VizardrySortScryResults")
  let g:VizardrySortScryResults="stars"
endif

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

function s:GitEvolve(path)
  let l:ret=system('cd '.a:path.' && git pull origin master')
  echo l:ret
  if l:ret=~'Already up-to-date'
    return ''
  endif
  return a:path
endfunction

function s:VimOrgEvolve(path)
  let l:ret=system(s:EvolveVimOrgPath.' '.a:path)
  echo l:ret
  if l:ret=~'upgrading .*'
    return a:path
  endif
  return ''
endfunction

function! s:Evolve(input, rec)
  if a:input==""
    let invokedList = split(s:ListInvoked('*'),'\n')
    let l:files=''
    for plug in invokedList
      let l:files.=' '.s:Evolve(plug,1)
    endfor
  else
    let inputNice = substitute(a:input, '\s\s*', '', 'g')
    let exists = s:TestForBundle(inputNice)
    if !exists
      echo "No plugin named ".inputNice." aborting upgrade"
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
    if l:files!=""
      let l:basefiles=substitute(
            \ substitute(l:files,s:bundleDir.'/','','g'),'\s\s*', ' ','g')
      if exists("g:VizardryGitBaseDir")
        execute ':!'.'cd '.g:VizardryGitBaseDir.' && git commit -m"'.
              \ g:VizardryCommitMsgs['Evolve'].' '.l:basefiles.'" '.
              \ l:files.' .gitmodules'
      else
        echo "Evolved plugins: ".l:files
      endif
    else
      echo "No plugin upgraded"
    endif
  else
    return l:files
  endif
endfunction

function! s:Invoke(input)
  if a:input == ''
    call s:ReloadScripts()
    echo "Updated vim"
    return
  endif

  let inputNumber = str2nr(a:input)
  if inputNumber!=0 && inputNumber < len(s:siteList) || a:input=="0"
    let l:index=inputNumber
    echo "Index ".inputNumber.' from scry search for "'.s:lastScry.'":'
    let inputNice = s:lastScry
  else
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

  while( l:index >= 0 && l:index < len(s:siteList))
    let site=s:siteList[l:index]
    let description=s:descriptionList[l:index]
  let matchingBundle = s:TestRepository(site)
    if matchingBundle != ""
      echo 'Found '.site
      echo '('.description.')'
      if(matchingBundle[len(matchingBundle)-1] == '~')
        let matchingBundle = strpart(matchingBundle,0,strlen(matchingBundle)-1)
        echohl WarningMsg
        echo 'This is the repository for banished bundle "'.matchingBundle.'"'
        echohl None
        if( s:GetResponseFromPrompt("Unbanish it? (Yes/No)", ['y', 'n'])== 'y')
          call s:Unbanish(matchingBundle, 1)
          execute ':Helptags'
        endif
        redraw
        echo ""
      else
        echohl WarningMsg
        echo 'This has already been invoked as "'.matchingBundle.'"'
        echohl None
      endif
      return
    else
      let l:index=s:HandleInvokePrompt(site, description, inputNice,index)
      redraw
      echo ""
    endif
  endwhile
endfunction

function! s:UnbanishCommand(bundle)
  let niceBundle = substitute(a:bundle, '\s\s*', '', 'g')
  let matches = s:ListBanished(a:bundle)
  if matches!=''
    let matchList = split(matches, "\n")
    let success=0
    for aMatch in matchList
      if s:Unbanish(aMatch, 0) != ''
        echo 'Failed to unbanish "'.aMatch.'"'
      else
        echo "Unbanished ".aMatch
      endif
    endfor
    call s:ReloadScripts()
  else
    if s:ListInvoked(a:bundle)!=''
      echo 'Bundle "'.niceBundle.'" is not banished.'
    else
      echo 'Bundle "'.niceBundle.'" does not exist.'
    endif
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
    let ret = ret.a:choices[i].', '
    let i+=1
  endwhile
  return ret.'or '.a:choices[length-1]
endfunction

function! s:GrabRepository(site, name)
  echo "grab repo ".a:site. " name ".a:name
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

function! s:HandleInvokePrompt(site, description, inputNice, index)
  let valid = 0
  let bundle=substitute(a:site, '.*/','','')
  let inputNice = s:FormValidBundle(bundle)
  let ret=-1
  let idx=a:index+1
  while valid == 0
    let response = s:GetResponseFromPrompt("Result ".idx."/".len(s:siteList).
          \ ": ".a:site."\n(".a:description.")\n\nClone as \"".inputNice.
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
        call s:GrabRepository(a:site, newName)
        call s:ReloadScripts()
        let valid = 1
      endif
    elseif response == 'n'
      let ret=a:index+1
      let valid = 1
    elseif response == 'd'
      echo "Looking for README url"
      let readmeurl=system('curl -silent https://api.github.com/repos/'.
            \ a:site.'/readme | grep download_url')
      let readmeurl=substitute(readmeurl,
            \ '\s*"download_url"[^"]*"\(.*\)",.*','\1','')
      echo "Retrieving README"
      if readmeurl == ""
        echohl WarningMsg
        echo "No readme found"
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
  echo ""
  return ret
endfunction

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

function! s:Banish(input, type)
  if a:input == ''
    echo 'Banish what?'
    return
  endif
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let matches = s:ListInvoked(inputNice)
  if matches == ''
    if ListBanished(inputNice) != ''
      echo '"'.inputNice.'" has already been banished'
    else
      echo 'There is no plugin named "'.inputNice.'"'
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
      if error==''
        echo a:type.'ed '.aMatch
      else
        let error = strpart(error, 0, strlen(error)-1)
        echo "Error renaming file: ".error
      endif
    endfor
  endif
endfunction

function! s:InitLists(input)
    let user=substitute(a:input, '.*-u\s\s*\(\S*\).*','\1','')
    let l:input=substitute(substitute(a:input, '-u\s\s*\S*','',''),
          \'^\s\s*','','')
    let s:lastScry = substitute(l:input, '\s\s*', '', 'g')
    let lastScryPlus = substitute(l:input, '\s\s*', '+', 'g')
    let query='vim+'.lastScryPlus
    if match(a:input, '-u') != -1
      echo "match"
      let query=substitute(query,'+$','','') "Remove useless '+' if no keyword
      let query.='+user:'.user
    endif
    echo "Searching ".query."..."
    let curlResults = system(
          \ 'curl -silent https://api.github.com/search/repositories?q='.query.
          \'\&sort='.g:VizardrySortScryResults.'\&order=desc')
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
      echo index.": ".s:siteList[index]
      echo '('.s:descriptionList[index].')'
      let index=index+1
      if index<length
        echo "\n"
      endif
    endwhile
  endif
endfunction

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
    echo "No plugins invoked"
    echohl None
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
      let origin = system('(cd '.s:bundleDir.'/'.invoked.
            \ '&& git config --get remote.origin.url) 2>/dev/null')
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
  let banishedList = split(s:ListBanished('*'),'\n')
  if len(banishedList) == ''
    echohl Define
    echo "No plugins banished"
    echohl None
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
      let origin = system('(cd '.s:bundleDir.'/'.banished.
            \ '~ && git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        echo banished
      else
        echo banished.repeat(' ',maxlen-len(banished)+3)."(".origin.")"
      endif
    endfor
  endif
endfunction

let s:scriptDir = expand('<sfile>:p:h')
let s:bundleDir = substitute(s:scriptDir, '/[^/]*/[^/]*$', '', '')
let s:EvolveVimOrgPath = s:scriptDir.'/EvolveVimOrgPlugins.sh'
if exists("g:VizardryGitBaseDir")
  let s:relativeBundleDir=substitute(s:bundleDir,g:VizardryGitBaseDir,'','')
  let s:relativeBundleDir=substitute(s:relativeBundleDir,'^/','','')
endif

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
    echo "No plugin given"
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
