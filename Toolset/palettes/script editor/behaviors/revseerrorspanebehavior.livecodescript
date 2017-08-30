script "revSEErrorsPaneBehavior"
# Stores the data for the nodes, an array with numeric keys that
# determine the order nodes appear in. The value of the array items
# is a string that is passed to the each item as parameters to the itemInit
# handler to allow each item to initialize itself
local sData

private function listObject
   if there is a group "List" of me then
      return the long id of group "List" of me
   else
      return empty
   end if
end listObject

command paneOpenControl
end paneOpenControl

command paneCloseControl
   clearErrors
end paneCloseControl

command paneResizeControl
   ensureListObject
   set the height of listObject() to the height of me
   set the width of listObject() to the width of me - the width of scrollbar "Scrollbar" of me
   set the topLeft of listObject() to the topLeft of me
   updateList
end paneResizeControl

# Description
#   Sent by the parent when something that might have affected the error pane has changed.
#   Causes the error pane to update itself.
command update
   updateList
end update

private command ensureListObject
   local tObject
   if listObject() is empty then
      lock messages
      copy group "List Template" of card "Templates" of stack (revTargetStack(the long id of me)) to me
      put the long id of it into tObject
      unlock messages
      
      set the name of tObject to "List"
      set the lockLocation of tObject to true
      set the cantDelete of tObject to false
      set the showBorder of tObject to false
      set the cMutable of tObject to true
   else
      put listObject() into tObject
   end if
   
   set the cItemTemplate of tObject to itemTemplate()
end ensureListObject

# Parameters
#   pType : the error type, either "compilation", "execution" or "warning"
#   pError : an error in the format returned by the result when setting a script
# Description
#   Adds pError to the errors list.
command addError pType, pError, pObject
  local tFormattedError
  put formatError(pType, pError, pObject) into tFormattedError
  if the cData of me is empty then
    set the cData of me to tFormattedError
  else
    set the cData of me to tFormattedError & return & the cData of me
  end if
  
  updateList
end addError

command clearErrors
   delete variable sData
   ensureListObject
   call "itemPurgeAll" to listObject()
   set the cData of me to empty
   set the cData of listObject() to empty
   
   updateList
end clearErrors

# Parameters
#   pType : the error type. This is either "execution", "compilation" or "warning"
#   pError : an error in the format returned by the result of setting the script.
#   pObject : reference to the object that the error is associated with
# Returns
#   A string in the following format.
#   <object> tab <type> tab <line> tab <char> tab <description> tab <token>
private function formatError pType, pError, pObject
   local tLine, tPosition, tDescription, tToken
   if pType is "compilation" then
      put seErrorDescription(pType, pError) into tDescription
      put item 2 of pError into tLine
      put item 3 of pError into tPosition
      put item 4 to -1 of pError into tToken
   else if pType is "execution" then
      put seErrorDescription(pType, pError) into tDescription
      put item 4 to -1 of line 1 of pError into tToken
      put item 2 of line 1 of pError into tLine
      if tToken is "runtime" then
         put empty into tToken
      else
         put item 3 of line 1 of pError into tPosition
      end if
   end if
   
   local tFormattedError
   put pObject & tab & pType & tab & tLine & tab & tPosition & tab & tDescription & tab & tToken into tFormattedError
   return tFormattedError
end formatError

private command updateList   
   ensureListObject
   
   local tPrefs
   put "marginLeft=5" & return & \
   "marginRight=5" & return & \
   "marginTop=10" & return & \
   "spacing=5" & return & \
   "justification=left" into tPrefs
   
   set the cPrefs of listObject() to tPrefs
   
   local tData
   put the cData of me into tData
   
   # Show a nice green tick etc if no errors occurred
   if tData is empty then
      local tObject
      revSEGetCurrentObject
      put the result into tObject
      put tObject & tab & "noerror" into tData
   end if
   
   set the cData of listObject() to tData
   
   # Update the group
   call "update" to listObject()
   
   # The scrolling is done separately to get around an engine bug (bz#4210)
   updateScrollbar
end updateList

private command updateScrollbar
  lock screen
  set the height of scrollbar "Scrollbar" of me to the height of listObject()
  set the topRight of scrollbar "Scrollbar" of me to the topRight of listObject()
  set the startValue of scrollbar "Scrollbar" of me to 0
  set the endValue of scrollbar "Scrollbar" of me to the formattedHeight of listObject() + 1
  set the lineInc of scrollbar "Scrollbar" of me to round(the formattedHeight of listObject() / 200)
  set the pageInc of scrollbar "Scrollbar" of me to round(the height of listObject())
  set the thumbSize of scrollbar "Scrollbar" of me to 1
  set the thumbPosition of scrollbar "Scrollbar" of me to the vScroll of listObject()
  set the visible of scrollbar "Scrollbar" of me to (the formattedHeight of listObject() > the height of listObject())
  unlock screen
end updateScrollbar

# Returns a reference to the item template to use, this can be any control, and will be copied into the list
# for each item and send an itemInit message to initilize itself. Basically you can use any control, but the script
# of the control must handle the itemInit message.
private function itemTemplate
   local tStackName
   put revTargetStack(the long id of me) into tStackName
   return the long id of group "Error Template" of card "Templates" of stack tStackName
end itemTemplate

# Parameters
#   pObject : reference to an object inside the errors group
# Returns
#   The long id of the item that contains pObject (or pObject if already an item).
private function resolveItem pObject
  if the cListItem of pObject is true then
    return the long id of pObject
  end if
  
  # For now the items only have one level of nested control ownership.
  if the cListItem of the owner of pObject is true then
    return the long id of the owner of pObject
  end if
end resolveItem

on mouseDoubleUp
   local tItem
   put resolveItem(the long id of the target) into tItem
   if tItem is empty then
      exit mouseDoubleUp
   end if
   
   # If the "no errors occurred" object is clicked on, don't attempt to go to the error location.
   if the cType of tItem is "noerror" then
      exit mouseDoubleUp
   end if
   
   local tObject
   put the cObject of tItem into tObject
   
   local tLine
   put the cLine of tItem into tLine
   
   local tPosition
   put the cPosition of tItem into tPosition
   
   local tHighlightType
   put "position" into tHighlightType
   
   revSESetCurrentObject tObject
   send "goLine tLine, tHighlightType, tPosition" to group "Editor"
end mouseDoubleUp

on mouseUp
   local tItem
   put resolveItem(the long id of the target) into tItem
   if tItem is empty then
      exit mouseUp
   end if
   
   lock screen
   repeat with x = 1 to the number of controls of me
      if the cListItem of control x of me then
         send "itemUnhilite" to control x of me
      end if
   end repeat
   
   send "itemHilite" to tItem
   unlock screen
end mouseUp
