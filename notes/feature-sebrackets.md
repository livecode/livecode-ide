# Script Editor - Brackets & Quotes

Two new features have been added to the script editor:

- The script editor will now wrap the selection when typing an opening 
square bracket `[`, parenthesis `(` or double quote `"`. If the
selection is just an insertion point the insertion point is placed
between the brackets/quotes. If a larger block of text is highlighted
it the text will be wrapped by the brackets/quotes and the insertion
point will be after the replaced text. In the case of quotes an attempt
is made to ensure that a second quote is desired by counting quotes on
the line and ensuring the number is even.
- The script editor will now highlight matching pairs of square brackets
and parentheses.
