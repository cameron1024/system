; extends

(
  (block_comment) @injection.language (#offset! @injection.language 0 3 0 -3)
  [
    (string_literal (string_content) @injection.content)
    (raw_string_literal (string_content) @injection.content)
  ]
)
