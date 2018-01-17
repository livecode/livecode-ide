script "revSEInteractiveFindBehavior"
local sPreviousRequest

# Description
#   Sent by the parent when the interactive find group has just been shown.
command openControl
   # OK-2009-03-10 : Bug 7070 - The match case check box should take the current preference value.
   set the hilite of button "Case" of me to (sePrefGet("find,casesensitive") is true)
   
   local tSearch
   put revSEGetSelectedText() into tSearch
   if tSearch is empty then
      put line 1 of seFindHistoryGet("find") into tSearch
   end if
   
   if tSearch is not empty then
      put tSearch into field "Find" of me
   else
      put empty into field "Find" of me
   end if
   
   focus on field "Find" of me
   select char 1 to -1 of field "Find" of me
end openControl

# Description
#   Sent by the parent when the interative find group has just been hidden.
command closeControl
end closeControl

command iFindNext, pInteractive
   local tQuery, tIgnoreCase
   put the text of field "Find" of me into tQuery
   put not the hilited of button "Case" of me into tIgnoreCase
   
   # We do a case sensitive comparison between the searches only if the case button was
   # checked in the previous search and is still checked now.
   if not the cLastIgnoreCase of me and not tIgnoreCase then
      set the caseSensitive to true
   else
      set the caseSensitive to false
   end if
   
   if not pInteractive and line 1 of seFindHistoryGet("find") is tQuery and tIgnoreCase is the cLastIgnoreCase of me then
      showNextFindResult empty, false, false, false, empty, pInteractive
   else
      showNextFindResult tQuery, false, false, false, tIgnoreCase, pInteractive
   end if
   set the caseSensitive to false
   
   --sePrefSet "find,lastsearch", tQuery
   --seFindHistoryAdd "find", tQuery
   set the cLastIgnoreCase of me to tIgnoreCase
end iFindNext

command iFindPrevious pInteractive
   local tQuery, tIgnoreCase
   put the text of field "Find" of me into tQuery
   put not the hilited of button "Case" of me into tIgnoreCase
   
   # We do a case sensitive comparison between the searches only if the case button was
   # checked in the previous search and is still checked now.
   if not the cLastIgnoreCase of me and not tIgnoreCase then
      set the caseSensitive to true
   else
      set the caseSensitive to false
   end if
   
   if not pInteractive and line 1 of seFindHistoryGet("find") is tQuery and tIgnoreCase is the cLastIgnoreCase of me then
      showPreviousFindResult empty, false, false, empty, pInteractive
   else
      showPreviousFindResult tQuery, false, false, false, tIgnoreCase, pInteractive
   end if
   set the caseSensitive to false
   
   --sePrefSet "find,lastsearch", tQuery
   --seFindHistoryAdd "find", tQuery
      set the cLastIgnoreCase of me to tIgnoreCase
end iFindPrevious

private command iFindNextRequest
   if sPreviousRequest is not empty then
      cancel sPreviousRequest
   end if
   
   if sePrefGet("editor,useInteractiveFind") then
      send "iFindNext true" to me in 10 milliseconds
      put the result into sPreviousRequest
   end if
end iFindNextRequest

on keyDown pKey
  if the short name of the target is not the short name of field "Find" of me then
    pass keyDown
  end if
  
  iFindNextRequest
  pass keyDown
end keyDown

# Description
#   Intercepts the paste keyboard shortcut and processes the clipboard data to make
#   sure something sensible gets put into the field. 
on commandKeyDown pKey
   --   if pKey is not "v" or the short name of the target is not the short name of field "Find" of me then
   --      pass commandKeyDown
   --   end if
   
   if the short name of the target is not "Find" then
      pass commandKeyDown
   end if
   
   if pKey is "v" then
      local tTextToPaste
      put line 1 of the clipboardData["text"] into tTextToPaste
      --set the text of field "Find" of me to tTextToPaste
      put tTextToPaste into the selection
      
      # If the user deletes all the text then we start a new search.
      if the text of field "Find" of me is empty then
         findInitialize
      end if
      
      # OK-2010-03-18: Bug 8291 - Intercept this here to implement select all, because the editor group is the parent
      # of this group, and it will have custom keyboard shortcut handling that only triggers for the script field.
   else if pKey is "a" then
      select char 1 to -1 of field "Find" of me
   else
      pass commandKeyDown
   end if
end commandKeyDown

on deleteKey
  if the short name of the target is not the short name of field "Find" of me then
    pass deleteKey
  end if
  
  # Allow the delete key to take its effect then check if the search status
  # needs updating as a result of it.
  send "textDeleted" to me in 0 milliseconds
  pass deleteKey
end deleteKey


on backspaceKey
  if the short name of the target is not the short name of field "Find" of me then
    pass backspaceKey
  end if
  
  # Allow the backspace key to take its effect then check if the search status
  # needs updating as a result of it.
  send "textDeleted" to me in 0 milliseconds
  pass backspaceKey
end backspaceKey

on returnInField
  if the short name of the target is not the short name of field "Find" of me then
    pass returnInField
  end if
  iFindNext true
end returnInField

on enterInField
  if the short name of the target is not the short name of field "Find" of me then
    pass enterInField
  end if
  iFindPrevious
end enterInField

on mouseUp
   if the short name of the target is "More" then
      actionFindDialog
      hideInteractiveFind
   else
      pass mouseUp
   end if
end mouseUp

# Description
#   Sent when text has been deleted either by pressing the delete or backspace key
on textDeleted
   if the text of field "Find" of me is empty then
      findInitialize
   else
      if sePrefGet("editor,useInteractiveFind") then
         local tQuery, tIgnoreCase
         put the text of field "Find" of me into tQuery
         put not the hilited of button "Case" of me into tIgnoreCase
         showNextFindResult tQuery, false, false, false, tIgnoreCase, true 
      end if
   end if
end textDeleted

command getSearchString
   return the text of field "Find" of me
end getSearchString














