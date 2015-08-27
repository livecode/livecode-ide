script "revSELeftBarBehavior"
command resize
   set the rect of group "Left Handler List" of me to the rect of me
   send "resize" to group "Left Handler List" of me
end resize

command update pDontUpdateSelectedHandler
   lock screen
   
   local tObject
   put the long id of group "Left Handler List" of me into tObject
   
   set the cCallback of tObject to "handlerSelected"
   set the cCallbackTarget of tObject to the long id of me
   
   local tHandler
   revSEGetSelectedHandler pDontUpdateSelectedHandler
   put the result into tHandler
   if tHandler is not empty then
      set the cSelectedHandler of tObject to tHandler
   end if
   
   local tCurrentObject
   revSEGetCurrentObject
   put the result into tCurrentObject
   
   set the cObject of tObject to tCurrentObject
   set the cCaller of tObject to the long id of stack (revTargetStack(the long id of me))
   
   set the cMaxWidth of tObject to the width of me
   set the cMinWidth of tObject to the width of me
   set the cMaxHeight of tObject to the height of me
   set the cMinHeight of tObject to the height of me
   
   call "initializeWithoutGrabbingFocus" to tObject
   unlock screen
end update

command updateSelectedHandler
   local tObject
   put the long id of group "Left Handler List" of me into tObject
   
   local tHandler
   revSEGetSelectedHandler true
   put the result into tHandler
   if tHandler is not empty then
      set the cSelectedHandler of tObject to tHandler
   end if
   
   send "updateSelectedHandler" to tObject
end updateSelectedHandler

# Description
#   Callback for the handler list object. This is called when the stack is closed
#   which either means the user has choosen a handler, or dismissed the stack.
on handlerSelected
   local tObject
   put the long id of group "Left Handler List" of me into tObject
   
   local tHandler, tLine, tType
   put item 1 of the cChoice of tObject into tLine
   put item 2 of the cChoice of tObject into tHandler
   put item 3 of the cChoice of tObject into tType
   if tLine is empty then
      exit handlerSelected
   end if
   
   # OK-2009-03-04 : Bug 7450 - If the script is invalid (i.e. doesn't compile) then the line number returned by the handler
   # list may be wrong because its the last known location of the handler when the script was compiled. To try and locate
   # the handler correctly we call this function which will check if tLine is wrong, and attempt to adjust it.
   put seLocateHandler(tHandler, tLine, tType) into tLine
   
   send "goLine tLine, true" to group "Editor"
   seUpdateToolbar
end handlerSelected
