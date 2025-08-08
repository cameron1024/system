; extends

(
  (identifier) @ident
  (node_field (value (string) @injection.content))
  (#eq? @ident "docs")
  (#offset! @injection.content 0 3 0 -2)
  (#set! injection.language "markdown")
) 

(
  (identifier) @ident
  (node_field (value (string) @injection.content))
  (#eq? @ident "extra-dart")
  (#offset! @injection.content 0 3 0 -2)
  (#set! injection.language "dart")
) 
