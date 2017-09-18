script "revSELeftBarBehavior"

-- Resize the group, placing the filter field below the list of
-- handlers.
command resize
   local tList, tFilter, tRect, tLeft, tWidth, tHeight, tTop, tBottom
   put the long id of group "Left Handler List" of me into tList
   put the long id of field "Filter" of me into tFilter

   -- Capture the target dimensions exactly once.  Otherwise,
   -- rubberbanding can occur
   put the rect of me into tRect
   put item 1 of tRect into tLeft
   put item 3 of tRect - tLeft into tWidth
   put item 2 of tRect into tTop
   put item 4 of tRect into tBottom
   put tBottom - tTop into tHeight

   -- Aim to put the filter field below the list of handlers.
   -- FIXME What happens when the space is to short to show the filter field?
   lock screen
   set the width of tFilter to tWidth
   set the bottom of tFilter to tBottom
   set the left of tFilter to tLeft

   set the top of tList to tTop
   set the left of tList to tLeft
   set the width of tList to tWidth
   set the cMaxWidth of tList to tWidth
   set the cMinWidth of tList to tWidth
   set the height of tList to (tHeight - the height of tFilter)
   set the cMaxHeight of tList to (tHeight - the height of tFilter)
   set the cMinHeight of tList to (tHeight - the height of tFilter)

   send "resize" to group "Left Handler List" of me
   unlock screen
end resize

command update pDontUpdateSelectedHandler, pClearFilter
   lock screen
   
   local tObject, tFilter
   put the long id of group "Left Handler List" of me into tObject
   put the long id of field "Filter" of me into tFilter
   
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
   set the cMaxHeight of tObject to (the height of me - the height of tFilter)
   set the cMinHeight of tObject to (the height of me - the height of tFilter)
   
   call "initializeWithoutGrabbingFocus" to tObject
   
   -- Hook up the filter field to the list of handlers, and initialise it.
   set the cCallback of tFilter to "filterChanged"
   set the cCallbackTarget of tFilter to tObject
   set the cPlaceholderText of tFilter to "Filter..."
   
   if pClearFilter then
      dispatch "clearFilter" to tFilter
   else
      send "update" to tFilter
   end if
   
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
#   which either means the user has chosen a handler, or dismissed the stack.
on handlerSelected pNewlyAdded
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
   
   -- If we just added this handler, select at the (empty) line after the handler decl.
   if pNewlyAdded then
      add 1 to tLine
      send "goLine tLine, after" to group "Editor"
   else
      send "goLine tLine, true" to group "Editor"
   end if
   
   seUpdateToolbar
end handlerSelected
