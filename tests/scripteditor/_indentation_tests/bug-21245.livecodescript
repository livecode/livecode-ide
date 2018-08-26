command inlineCommentTest \
      pBasePath,     /* base path for export folders     */ \
      @xRelativePath /* relative path for folder         */
   -- code
end inlineCommentTest

command quoteAfterCommentTest
   put "test" -- "extra" \
   put "test"
end quoteAfterCommentTest