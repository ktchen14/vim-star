" We can't just escape \ in `text` and use \V (very nomagic) as that'd record
" an item in the search history (and echo a message) different from what
" would've been recorded by * and #. Thus we have to handle &magic and escape
" each special character here.
function! s:escape_string(string)
  return escape(a:string, &magic ? '*^$.~[]\' : '^$\')
endfunction

" Here `text` should be a list of strings as returned by getreg() or expand()
" with list = 1. Escape each string and join them with \n (the literal string)
" so that NULs in the text aren't clobbered.
function! s:escape(text)
  return join(map(a:text, 's:escape_string(v:val)'), '\n')
endfunction

" Return the search term that should be used in Visual mode. If g is true then
" this will be done as if g* or g# were used.
function! star#visual(g)
  " Save the content of the Visual mode area into `text`. This will reselect
  " the last area and yank it into @v. We have to take care to save both the
  " text and type of @v before this operation and restore it afterward. To
  " read the yanked text from @v, getreg(..., list = 1) must be used so that
  " NULs aren't clobbered.
  let save_text = getreg('v', 1, 1)
  let save_type = getregtype('v')
  silent! normal! gv"vy
  let text = getreg('v', 1, 1)
  call setreg('v', save_text, save_type)

  " In blockwise Visual mode, each line in the selection is interpreted as a
  " separate branch to be joined with \| in the actual search. The non-g
  " variant is intended to behave like a disjunctive variant of characterwise
  " Visual mode. That is, if a line begins with the beginning of a word, then
  " it's prefixed with \<, and if it ends at the end of a word, then it's
  " suffixed with \>.
  if visualmode() ==# ''
    " In Visual blockwise mode the beginning of the Visual mode area isn't
    " always '<, and the end of the Visual mode area isn't always '>.
    let [lnum_1, vcol_1] = [line("'<"), virtcol("'<")]
    let [lnum_2, vcol_2] = [line("'>"), virtcol("'>")]

    " Set `vcol_s` to the leftmost virtual column number in the selection,
    " `vcol_e` to the rightmost virtual column number in the selection, and
    " `lnum_s` to the first line number in the selection.
    let vcol_s = min([vcol_1, vcol_2])
    let vcol_e = max([vcol_1, vcol_2])
    let lnum_s = min([line("'<"), line("'>")])

    let result = []
    for [lnum, string] in map(text, "[lnum_s + v:key, v:val]")
      " Skip this branch if the leftmost virtual column in the Visual area is
      " past the last virtual column on this line. We can't just test if the
      " line is empty() because Vim will assign text to this line even in this
      " case.
      let vcol_l = virtcol([lnum, '$']) - 1
      if vcol_s > vcol_l | continue | endif

      if !a:g
        " Don't read a line if we don't need to (if the branch is skipped or
        " this is the g variant)
        let line = getline(lnum)

        " Prefix the line with \< if it's matchable with it
        let prefix = match(line, '\<\%' . vcol_s . 'v.') > -1 ? '\<' : ''

        " Suffix the line with \> if it's matchable with it. Use the last
        " virtual column if the rightmost virtual column in the Visual area is
        " past it on this line.
        let vcol_l = min([vcol_e, vcol_l])
        let suffix = match(line, '\%' . vcol_l . 'v.\>') > -1 ? '\>' : ''
      else
        let [prefix, suffix] = ['', '']
      end

      call add(result, prefix . s:escape_string(string) . suffix)
    endfor

    return join(result, '\|')
  endif

  " In the g variant just return the escaped search itself
  if a:g | return s:escape(text) | endif

  " In linewise Visual mode, search only for entire lines that match the
  " selection
  if visualmode() ==# 'V'
    return '^' . s:escape(text) . '$'
  endif

  " In characterwise Visual mode, if the selection begins with the beginning
  " of a word then prefix the search with \<, and if the selection ends at the
  " end of a word then suffix the search with \>.
  if visualmode() ==# 'v'
    " Prefix the search with \< if it's matchable with that prefix
    let [_, lnum, col, _] = getpos("'<")
    let line = getline(lnum)
    let prefix = match(line, '\<\%' . col . 'c.') > -1 ? '\<' : ''

    " Suffix the search with \> if it's matchable with that suffix
    let [_, lnum, col, _] = getpos("'>")
    let line = getline(lnum)
    let suffix = match(line, '\%' . col . 'c.\>') > -1 ? '\>' : ''

    return prefix . s:escape(text) . suffix
  endif

  return search " Just in case (Neo)Vim gets a new kind of Visual mode
endfunction

" Return the search term that should be used in Normal mode. If g is true then
" this will be done as if g* or g# were used.
function! star#normal(g)
  " We have to call expand(..., list = 1) here so that NULs in the word aren't
  " clobbered.
  let text = expand('<cword>', 1, 1)

  " The normal * command will echo this error message if no word is under the
  " cursor. We'll have to simulate it with echohl ErrorMsg | echom ... |
  " echohl None. We can't use :throw or :echoerr here as both of them output a
  " multiline error message (e.g. "Error detected while processing function
  " star#normal") if called from within a function.
  if empty(text)
    echohl ErrorMsg | echom 'E348: No string under cursor' | echohl None
    return 1
  endif

  " Decorate the search with \< ... \> if g wasn't used
  let search = (a:g ? '' : '\<') . s:escape(text) . (a:g ? '' : '\>')

  " Ensure that the the cursor is at the beginning of <cword>. Note that
  " len(text) must be 1 as text is expanded from <cword> and <cword> doesn't
  " look past the current line.
  let [_, lnum, cursor, _] = getpos('.')
  let [_, i] = searchpos('\C' . search, 'bcn', lnum, 20)
  if i == cursor
  elseif i && cursor < i + strlen(text[0])
    call cursor(0, i)
  else
    call search('\C' . search, 'z', lnum, 20)
  end

  return search
endfunction

" Take the search `type` and `search` term and execute a no cursor movement
" search. This will return a list of length 2, with the values of
" v:searchforward and v:hlsearch to set, as that must be done outside of a
" function to be effective. If the `search` isn't a string then do nothing; in
" this case v:searchforward and v:hlsearch remain safe to set.
function! star#search(type, search)
  if type(a:search) != type('')
    return [v:searchforward, v:hlsearch]
  endif

  let @/ = a:search
  call histadd('/', a:search)
  echom a:type . a:search
  return [a:type == '/', 1]
endfunction

" Return the {rhs} to be used in a Visual mode mapping. If <count> is given,
" then emit <count>n to handle hlsearch.
function! star#xnoremap_expr(g, type)
  let search = 'star#visual(' . string(a:g) . ')'
  let search = 'star#search(' . string(a:type) . ', ' . search . ")\<CR>"
  if !v:count
    return ":\<C-u>let [v:searchforward, v:hlsearch] = " . search
  end
  return ":\<C-u>let [v:searchforward, _] = " . search . v:count . 'n'
endfunction

" Return the {rhs} to be used in a Normal mode mapping. If <count> is given,
" then just emit <count>[g]* or <count>[g]# and skip star#search().
function! star#nnoremap_expr(g, type)
  if v:count
    return (a:g ? 'g' : '') . (a:type == '/' ? '*' : '#')
  endif
  let search = 'star#normal(' . string(a:g) . ')'
  let search = 'star#search(' . string(a:type) . ', ' . search . ")\<CR>"
  return ":\<C-u>let [v:searchforward, v:hlsearch] = " . search
endfunction

" Return the {rhs} to be used in a Operator-pending mode mapping. We have to
" be careful here as it's very easy to mess up the expected behavior when the
" change is repeated with (.). The approach that we'll take is:
"   1. <Esc> to exit Operating-pending mode
"   2. Do the search
"   3. Handle v:searchforward and v:hlsearch
"   4. Move the cursor
"   5. Reform the command
" Note that the repeat command will repeat the last actual command (part 5 as
" described) *only*, but in it's *entirety*.
function! star#onoremap_expr(g, type)
  let search = 'star#normal(' . string(a:g) . ')'
  let search = 'star#search(' . string(a:type) . ', ' . search . ")\<CR>"
  let expr = "\<Esc>:let [v:searchforward, v:hlsearch] = " . search
  let motion = a:type == '/' ? 'gn' : 'gN'
  if !v:count
    return expr . '"' . v:register . v:operator . motion
  end
  return expr . 'n' . '"' . v:register . v:count1 . v:operator . motion
endfunction!
