vim-star
========

This plugin changes the behavior of `*` (and its friends `g*`, `#`, and `g#`) to
become a general search command.

### Normal Mode

`*`, `g*`, `#`, and `g#` have their usual behavior, except that the cursor is
left on the first character of the current match.

### Visual Mode

`*` and `g*` search for the selected text, exiting Visual mode and leaving the
cursor on the first character of the selection.

In characterwise Visual mode, with `*`, if the selected text would be matched by
a search beginning with `\<` then `\<` is added to the beginning of the search.
Likewise, if the selected text would be matched by a search ending with `\>`
then `\>` is added to the end of the search. Basically, **in characterwise
Visual mode, if you selected whole words then `*` searches for whole words**.
`g*` doesn't't put `\<` and `\>` around the search.

In linewise Visual mode (`V`), `*` surrounds the search with `^` and `$`.
Basically, **in linewise Visual mode, `*` searches for whole lines**. `g*`
doesn't put `^` and `$` around the search.

Blockwise Visual mode (`CTRL-v`) is handled by treating every line in the
selected text as a separate characterwise Visual mode selection. The searches
are the combined with `\|`.

In all cases, `#` and `g#` are exactyl like `*` and `g*`, except that the search
direction is backwards instead of forwards.

### Operator-pending Mode

`*`, `g*`, `#`, and `g#` in Operator-pending mode behave like they do in normal
mode, followed by `gn` (or `gN` in the case of `#` and `g#`). Only the `gn` part
is repeated if `.` is subsequently used.

Installation
------------

Use your favorite plugin manager. Using [vim-plug]:

```vim
Plug 'ktchen14/vim-star'
```

[vim-plug]: https://github.com/junegunn/vim-plug
