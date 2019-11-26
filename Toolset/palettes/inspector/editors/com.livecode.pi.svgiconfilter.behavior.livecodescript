script "com.livecode.pi.svgiconfilter.behavior"
on preOpenStack
   set the text of field "FilterText" to "Search"
   set the filterString of widget "iconList" of me to empty
   set the showSelectedElement of widget "iconList" of me to false
   set the iconSize of widget "iconList" of me to 45
   set the selectedIcon of widget "iconList" of me to the dialogData
   
   set the behavior of me to the long id of stack "com.livecode.pi.svgiconfilter.behavior"
   focus on nothing
end preOpenStack

on mouseUp
   if the short name of the target is "iconList" then
      if the selectedIcon of widget "iconList" of me is not empty then
         set the dialogData to the selectedIcon of widget "iconList" of me
      end if
      close this stack
   end if
end mouseUp

on openField
   if the short name of the target is "FilterText" then
      if field "FilterText" is "Search" then
         set the text of field "FilterText" to empty
      end if
   end if
end openField

on enterField
   if the short name of the target is "FilterText" then
      if field "FilterText" is "Search" then
         set the text of field "FilterText" to empty
      end if
   end if
end enterField

on closeField
   if the short name of the target is "FilterText" then
      if field "FilterText" is empty then
         set the text of field "FilterText" to "Search"
      end if
   end if
end closeField

on exitField
   if the short name of the target is "FilterText" then
      if field "FilterText" is empty then
         set the text of field "FilterText" to "Search"
      end if
   end if
end exitField

on textChanged
   local tFilterText
   
   if the short name of the target is "FilterText" then      
      put field "FilterText" into tFilterText      
      set the filterString of widget "iconList" of me to tFilterText
   end if
end textChanged

on returnInField
   // Do nothing
end returnInField

on escapeKey
   close this stack
end escapeKey
