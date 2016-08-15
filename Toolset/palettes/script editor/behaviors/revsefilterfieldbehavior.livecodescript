script "revSEFilterFieldBehavior"

/*
The aim here is to display the text stored in the custom property
cPlaceholderText in italics when the field is not focused and there
is no current filter text, and to display the filter text in normal
font otherwise.

When the content is modified, a message is sent immediately.
The following custom properties are used to configure how the
message is sent:

    cCallback       -- the message to send
    cCallbackTarget -- the long ID of the object that the message
                       should be sent to
*/

----------------------------------------------------------------
-- Helper functions for providing the placeholder text
----------------------------------------------------------------

local lPlaceholderText

setProp cPlaceholderText pPlaceholderText
   put pPlaceholderText into lPlaceholderText
   if not the cFiltering of me then
      set the text of me to lPlaceholderText
      set the textstyle of me to "italic"
   end if
end cPlaceholderText

getProp cPlaceholderText
   return lPlaceholderText
end cPlaceholderText

private command startFiltering
   if not the cFiltering of me then
      put empty into me
      set the cFiltering of me to true
      send "update" to me
   end if
   selectAll
end startFiltering

private command stopFiltering
   if me is empty then
      set the cFiltering of me to false
      send "update" to me
   end if
end stopFiltering

private command selectAll
   select char 1 to -1 of me
end selectAll

-- This does the main work of fixing up the formatting.  It also
-- sends the registered callback message if necessary.
on update
   if the cFiltering of me then
      set the textstyle of me to empty
      set the cFilterText of me to the text of me
   else
      if lPlaceholderText is not empty then
         set the text of me to lPlaceholderText
      else
         set the text of me to empty
      end if
      set the textstyle of me to "italic"
      set the cFilterText of me to empty
   end if

   -- Send a filtering change notification only if necessary
   if the cOldFilterText of me is not the cFilterText of me and \
         the cCallback of me is not empty and \
         the cCallbackTarget of me is not empty then

      dispatch the cCallback of me to the cCallbackTarget of me \
            with the cFilterText of me
      set the cOldFilterText of me to the cFilterText of me

   end if
end update

--
-- Field event handlers
--
on textChanged
   send "update" to me
end textChanged

on openField
   startFiltering
end openField

on closeField
   stopFiltering
end closeField

on exitField
   stopFiltering
end exitField

on returnInField
   selectAll
end returnInField

on enterInField
   selectAll
end enterInField

command clearFilter
   put empty into me
   stopFiltering
end clearFilter
