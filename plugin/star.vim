" Maintainer: Kaiting Chen <ktchen14@gmail.com>
" Version: 1.0

if exists("g:loaded_star") || v:version < 800
  finish
endif
let g:loaded_star = 1

xnoremap <silent> <expr>  * star#xnoremap_expr(0, '/')
xnoremap <silent> <expr> g* star#xnoremap_expr(1, '/')
xnoremap <silent> <expr>  # star#xnoremap_expr(0, '?')
xnoremap <silent> <expr> g# star#xnoremap_expr(1, '?')

nnoremap <silent> <expr>  * star#nnoremap_expr(0, '/')
nnoremap <silent> <expr> g* star#nnoremap_expr(1, '/')
nnoremap <silent> <expr>  # star#nnoremap_expr(0, '?')
nnoremap <silent> <expr> g# star#nnoremap_expr(1, '?')

onoremap <silent> <expr>  * star#onoremap_expr(0, '/')
onoremap <silent> <expr> g* star#onoremap_expr(1, '/')
onoremap <silent> <expr>  # star#onoremap_expr(0, '?')
onoremap <silent> <expr> g# star#onoremap_expr(1, '?')
