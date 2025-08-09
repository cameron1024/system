; extends

(source_file
  (header
    (tripleDash) 
    (headerContent 
      (headerSource (restOfLine)) 
      (headerExpression (restOfLine) @injection.language)
    )
    (tripleDash)
  )
  (body) @injection.content
)
