vim-star
========

This plugin changes the behavior of `*`, `g*`, `#`, and `g#`.

### Normal Mode

`*`, `g*`, `#`, and `g#` have their usual behavior, except that the cursor is
left on the first character of the current match.

### Visual Mode

`*`, `g*`, `#`, and `g#` search for the selected text, exiting Visual mode and
leaving the cursor on the first character of the selection. As usual, `*` and
`g*` search forward while `#` and `g#` search backward. In general, `*` and `#`
bracket the search while `g*` and `g#` don't.

In characterwise Visual mode, with `*` and `#`, if the selected text would be
matched by a search beginning with `\<`, then `\<` is added to the beginning of
the search. Likewise, if the selected text would be matched by a search ending
with `\>`, then `\>` is added to the end of the search. Basically, **in
characterwise Visual mode, if you selected whole words then `*` and `#` search
for whole words**. `g*` and `g#` don't put `\<` and `\>` around the search.

In linewise Visual mode (`V`), `*` and `#` surround the search with `^` and `$`.
Basically, **in linewise Visual mode, `*` and `#` search for whole lines**. `g*`
and `g#` don't put `^` and `$` around the search.

Blockwise Visual mode (`CTRL-v`) is handled by treating every line in the
selected text as a separate characterwise Visual mode selection. The searches
are the combined with `\|`.

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
