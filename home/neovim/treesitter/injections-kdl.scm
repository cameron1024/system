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

(
  (identifier) @ident
  (node_field (value (string) @injection.content))
  (#eq? @ident "builder-extra-dart")
  (#offset! @injection.content 0 3 0 -2)
  (#set! injection.language "dart")
) 

(
  (identifier) @ident
  (node_field (value (string (string_fragment) @injection.content)))
  (#eq? @ident "to-json")
  (#set! injection.language "dart")
) 

(
  (identifier) @ident
  (node_field (value (string (string_fragment) @injection.content)))
  (#eq? @ident "from-json")
  (#set! injection.language "dart")
) 

(
  (identifier) @ident
  (node_field (value (string) @injection.content))
  (#eq? @ident "postamble")
  (#offset! @injection.content 0 3 0 -2)
  (#set! injection.language "dart")
) 

(
  (identifier) @ident
  (node_field (value (string) @injection.content))
  (#eq? @ident "preamble")
  (#offset! @injection.content 0 3 0 -2)
  (#set! injection.language "dart")
) 
