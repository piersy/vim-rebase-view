" Executes the provided cmdline and displays the output in a new buffer and
" new window with ft=git.
function rebaseview#OutputInGitWindow(cmdline)
	" Open new vertical window
	vert new
	setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap filetype=git

	" Name the buffer with the command we executed.
	" In order to call file with an argument we need to use execute. This is
	" becuause file doesn't accept variables as its arguments. We can infer
	" this from the doc since commands that can interpret variables (eg echo)
	" use '{expr}' to refer to their arguments whereas file doc simply lists
	" '{name}'.
	silent execute 'file Command: ' . a:cmdline

	"0read makes read insert text below the 0th line
	silent execute '0read !' . a:cmdline
	setlocal nomodifiable

	1 " go to first line
endfunction

" Returns first match in current line of 7 or more hex chars with a space at
" either end.
function rebaseview#CommitShaFromLine(line)
	return trim(matchstr(a:line,'\v \x{7,} '))
endfunction

" Returns the range of commits that are being rebased.
function rebaseview#RebaseCommitRange()
	" Searching for a line like
	"# Rebase 056af67..ef7b34d onto 056af67 (4 commands)
	let line=search('\v# Rebase \x{7,}\.\.\x{7,} onto \x{7,} \(\d+ commands\)')
	return matchstr(getline(line), '\v\x{7,}\.\.\x{7,}')
endfunction

" Displays the output of 'git show' for the commit in the current line in a new window. The
" options are passed to git show. If the current line does not contain a
" single commit sha then no action is taken.
function rebaseview#DisplayCommit(options)
	let commitsha = rebaseview#CommitShaFromLine(getline("."))
	if commitsha != ""
		call rebaseview#OutputInGitWindow('git show ' . a:options .' '. commitsha)
	endif
endfunction

" Gets the start and end commits from a visual range.
function rebaseview#getStartAndEndCommits() 
	let lnumA = line("'<")
	let lnumB = line("'>")
	if lnumA == lnumB
		return ["", ""]
	endif
	if lnumA > lnumB
		let [lnumA, lnumB] = [lnumB, lnumA]
	endif
	let commitA = rebaseview#CommitShaFromLine(getline(lnumA))
	let commitB = rebaseview#CommitShaFromLine(getline(lnumB))
	return[commitA, commitB]
endfunction

" Displays the diff of visually selected commits. The given options are passed
" to git diff. If the start and end lines of the visual selection are the same
" or either does not contains a valid commmit then no action is taken.
function rebaseview#DisplayDiff(options)
	let [commitA, commitB] = rebaseview#getStartAndEndCommits()
	if commitA != "" && commitB != ""
		call rebaseview#OutputInGitWindow('git diff ' . a:options .' '. commitA .'~ '. commitB)
	endif
endfunction

" Displays the output of 'git log --reverse' for the range of commits that are
" being rebased. The options are passed to git log. If no rebase range is
" found then no action is taken.
function rebaseview#DisplayLog(options)
	let range = rebaseview#RebaseCommitRange()
	if range != ""
		call rebaseview#OutputInGitWindow('git log --reverse ' . a:options . ' ' . range)
	endif
endfunction

" Displays the output of 'git log --reverse' for the range of commits that are
" visually selected. The options are passed to git log. If no rebase range is
" found then no action is taken.
function rebaseview#DisplayLogRange(options)
	let [commitA, commitB] = rebaseview#getStartAndEndCommits()
	if commitA != "" && commitB != ""
		call rebaseview#OutputInGitWindow('git log --reverse ' . a:options . ' ' . commitA .'~..'. commitB)
	endif
endfunction

"augroup gitrebase_maps
"	autocmd!
"	autocmd filetype git*,fugitiveblame call s:ConfigureGitRebase()
"
"augroup END
"
"function! s:ConfigureGitRebase()
"	" Map K again in buffer specific mode since it is mapped by vim by default
"	" to show the commit uner the cursor, it does this by setting keywordprg
"	" to 'git show'
"	nnoremap <buffer> K <C-U>
"	nnoremap <silent> <buffer> <leader>e :<C-u>call <SID>DisplayCommit('--stat')<CR>
"	nnoremap <silent> <buffer> <leader>d :<C-u>call <SID>DisplayCommit('')<CR>
"	nnoremap <buffer> <leader>l :<C-u>call <SID>DisplayLog('--stat')<CR>
"endfunction
