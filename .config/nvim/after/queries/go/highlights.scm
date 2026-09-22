; extends

; Bundled go highlights.scm lumps these in with the generic `@keyword` group
; (blue), while `for`/`if`/`return` etc. use the more specific control-flow
; groups (`@keyword.repeat`/`@keyword.conditional`/`@keyword.return`) that
; the colorscheme colors purple. Match that.
[
  "break"
  "continue"
  "range"
] @keyword.repeat

"default" @keyword.conditional
