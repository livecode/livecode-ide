script "revSEBreakpointPaneBehavior"
local sSelectedItem

on paneOpenControl
end paneOpenControl

on paneCloseControl
end paneCloseControl

on paneResizeControl
   local tBarHeight
   put 0 into tBarHeight
   
   ensureListObject
   set the height of listObject() to the height of me - tBarHeight
   set the width of listObject() to the width of me - the width of scrollbar "Scrollbar" of me
   set the topLeft of listObject() to the topLeft of me
   send "update" to listObject()
   
   set the height of scrollbar "Scrollbar" of me to the height of listObject()
   set the topLeft of scrollbar "Scrollbar" of me to the topRight of listObject()
   set the rect of field "Message Blocker" of me to the rect of me
   updateScrollbar
end paneResizeControl

local sData

on update
   ensureListObject
   
   local tPrefs
   put "marginLeft=5" & return & \
   "marginRight=5" & return & \
   "marginTop=10" & return & \
   "spacing=5" & return & \
   "justification=left" into tPrefs
   
   set the cPrefs of listObject() to tPrefs
   set the cData of listObject() to getData()
   call "update" to listObject()
   put empty into sSelectedItem
   
   updateScrollbar
end update

# Returns
#   A list of breakpoints to display ordered correctly etc. Each breakpoint is in the following format (urlEncoded):
#   <type> - Possible types are "breakpoint" or "watch"
#   <active> - True or false, whether the breakpoint is enabled
#   <object> - The object that the breakpoint is associated with
#   <lineOrVariable> - Either the line number (breakpoints) or variable name (watches)
#   <handler> - either empty (breakpoints) or the handler name (watches)
#   <condition> - The condition to be evaluated when the breakpoint is hit. Empty for unconditional.
#   <message> - additional information on the breakpoint that should be displayed. May be empty.
#   <actualState> - whether the breakpoint will trigger or not. This may be different to the state, i.e an active breakpoint on a commented line.
#   
#   The breakpoints are listed in the following order:
#    1. Breakpoints on current object, active first, sorted by line number
#    2. Other active breakpoints, sorted by object then line number
#    3. Watched variables, current object first, then sorted by object / line number
private function getData
   local tObject
   revSEGetCurrentObject
   put the result into tObject
 
   local tObjectBreakpoints
   put getObjectBreakpoints(tObject) into tObjectBreakpoints
   
   local tActiveBreakpoints
   put getActiveBreakpoints(tObject) into tActiveBreakpoints
   
   local tWatches
   put getWatches(tObject) into tWatches
   
   local tData
   if tObjectBreakpoints is not empty then
      put tObjectBreakpoints  & return into tData
   end if
   
   if tActiveBreakpoints is not empty then
      put tActiveBreakpoints & return after tData
   end if
   
   if tWatches is not empty then
      put tWatches & return after tData
   end if
   
   delete the last char of tData
   return tData
end getData

# Returns
#   A list of breakpoints for the specified object, sorted by line number, in the format described
#   in the comment above getData.
private function getObjectBreakpoints pObject
   local tObject
   put pObject into tObject
   
   # In case the breakpoints pane is updated before any object is added to the script editor,
   # we simply ignore the case where there is no current object.
   if tObject is empty then
      return empty
   end if
   
   local tBreakpoints
   put revDebuggerListBreakpoints(tObject) into tBreakpoints
   
   local tStates
   put revDebuggerListBreakpointStates(tObject) into tStates
   
   local tConditions
   put revDebuggerListBreakpointConditions(tObject) into tConditions
   
   --sort tBreakpoints numeric by item -1 of each
   
   local tList
   
   local tLineNumber
   put 1 into tLineNumber
   repeat for each line tBreakpoint in tBreakpoints
      local tDisplayState, tInvalid, tMessage
      get seBreakpointDisplayInformation(item 1 to -2 of tBreakpoint, item -1 of tBreakpoint)
      put line 1 of it into tDisplayState
      put line 2 of it into tInvalid
      put line 3 of it into tMessage
      
      local tFormattedBreakpoint
      put urlEncode("breakpoint" & return & line tLineNumber of tStates & return & revRuggedId(item 1 to -2 of tBreakpoint) & return & item -1 of tBreakpoint & return & empty & return & line tLineNumber of tConditions  & return & tMessage & return & tDisplayState) into tFormattedBreakpoint
      put tFormattedBreakpoint & return after tList
      add 1 to tLineNumber
   end repeat
   delete the last char of tList
   
   return tList
end getObjectBreakpoints

# Returns
#   A list of active breakpoints for all objects. Sorted by object then line number.
private function getActiveBreakpoints pObject
   # Unfortunately because of the way the debugger library works, this one is a little clunky. 
   # We get a list of all the active breakpoints, then loop through them, and get the list of breakpoints
   # for each object in the list.
   local tActiveBreakpoints
   put revDebuggerListActiveBreakpoints() into tActiveBreakpoints
   sort tActiveBreakpoints
   
   # These breakpoints are all active unless the debugger is disabled.
   local tState, tMessage
   if revDebuggerEnabled() then
      put "active" into tState
      put empty into tMessage
   else
      put "this breakpoint will not trigger because script debug mode is currently turned off" into tMessage
      put "inactive" into tState
   end if
   
   
   local tFilteredBreakpoints
   repeat for each line tBreakpoint in tActiveBreakpoints
      if pObject is not empty and revRuggedId(item 1 to -2 of tBreakpoint) is revRuggedId(pObject) then
         next repeat
      end if
      
      # We know the breakpoint is active, however we don't know if it has a condition or not, use the debugger
      # library to work out if it does.
      local tBreakpoints, tConditions
      put revDebuggerListBreakpoints(item 1 to -2 of tBreakpoint) into tBreakpoints
      
      local tLineNumber
      set the wholeMatches to true
      put lineOffset(tBreakpoint, tBreakpoints) into tLineNumber
      
      local tCondition
      if tLineNumber <> 0 then
         # This means the breakpoint is one we know about, rather than one that the user
         # has manually set. In this case we can check to see if it has a condition attached.
         put revDebuggerListBreakpointConditions(item 1 to -2 of tBreakpoint) into tConditions
         
         put line tLineNumber of tConditions into tCondition
      end if
      
      put urlEncode("breakpoint" & return & "active" & return & revRuggedId(item 1 to -2 of tBreakpoint) & return & item -1 of tBreakpoint & return & empty & return & tCondition & return & tMessage & return & tState) & return after tFilteredBreakpoints
   end repeat
   delete the last char of tFilteredBreakpoints
   
   return tFilteredBreakpoints
end getActiveBreakpoints

# Returns
#   A list of watches, with watches set on the current object coming first, followed by a list of all other active watches.
private function getWatches pObject
   local tObjectWatches
   local tObjectWatchStates
   
   if pObject is not empty then
      # If there is an object specified put the watches specific to that object first.
      put revDebuggerListWatches(pObject) into tObjectWatches
      put revDebuggerListWatchStates(pObject) into tObjectWatchStates
   end if
   if tObjectWatches is not empty then
      put return after tObjectWatches
   end if
   
   if tObjectWatchStates is not empty then
      put return after tObjectWatchStates
   end if
   
   # Add the global watches to the list, otherwise they'll disappear if inactive
   put revDebuggerListWatches(empty) after tObjectWatches
   put revDebuggerListWatchStates(empty) after tObjectWatchStates
   
   local tActiveWatches
   put revDebuggerListActiveWatches() into tActiveWatches
   
   local tObjectId
   if pObject is not empty then
      put the long id of pObject into tObjectId
   else
      put empty into tObjectId
   end if
   
   # We only want to display the active watches which the debugger doesn't know about, i.e those
   # manually set by the user by setting the watchedVariables, so we filter out any duplicates here.
   # These watches will not be stored unless the user changes them in the debugger, in which case
   # the debugger will adopt them into its system and manage them.
   local tFilteredActiveWatches
   repeat for each line tActiveWatch in tActiveWatches
      local tArray
      put revDebuggerParseWatch(tActiveWatch) into tArray
      
      local tWatchAlreadyKnown
      put false into tWatchAlreadyKnown
      repeat for each line tObjectWatch in tObjectWatches
         local tObjectWatchArray
         put revDebuggerParseWatch(tObjectWatch) into tObjectWatchArray
         
         # Do we want to allow multiple watches on the same variable but with different conditions??
         # Currently we don't do this...
         if (tArray["object"] is tObjectWatchArray["object"]) and (tArray["handler"] is tObjectWatchArray["handler"]) and (tArray["variable"] is tObjectWatchArray["variable"]) then
            put true into tWatchAlreadyKnown
            exit repeat
         end if
      end repeat
      
      if not tWatchAlreadyKnown then
         put tActiveWatch & return after tFilteredActiveWatches
      end if
   end repeat
   delete the last char of tFilteredActiveWatches
   
   local tLineNumber
   put 1 into tLineNumber
   
   local tFormattedObjectWatches
   repeat for each line tWatch in tObjectWatches
      put revDebuggerParseWatch(tWatch) into tArray
      if tArray["object"] is empty then
         put urlEncode("watch" & return & line tLineNumber of tObjectWatchStates & return & "" & return & tArray["variable"] & return & tArray["handler"] & return & tArray["condition"] & return & empty & return & line tLineNumber of tObjectWatchStates) & return after tFormattedObjectWatches
      else
         put urlEncode("watch" & return & line tLineNumber of tObjectWatchStates & return & revRuggedId(tArray["object"]) & return & tArray["variable"] & return & tArray["handler"] & return & tArray["condition"] & return & empty & return & line tLineNumber of tObjectWatchStates) & return after tFormattedObjectWatches
      end if
      
      add 1 to tLineNumber
   end repeat
   delete the last char of tFormattedObjectWatches
   
   local tFormattedActiveWatches
   repeat for each line tWatch in tFilteredActiveWatches
      put revDebuggerParseWatch(tWatch) into tArray
      if tArray["object"] is empty then
         put urlEncode("watch" & return & "active" & return & "" & return & tArray["variable"] & return & tArray["handler"] & return & tArray["condition"] & return & empty & return & "active") & return after tFormattedActiveWatches
      else
         put urlEncode("watch" & return & "active" & return & revRuggedId(tArray["object"]) & return & tArray["variable"] & return & tArray["handler"] & return & tArray["condition"] & return & empty & return & "active") & return after tFormattedActiveWatches
      end if
   end repeat
   delete the last char of tFormattedActiveWatches
   
   local tWatches
   if tFormattedObjectWatches is not empty then
      put tFormattedObjectWatches & return into tWatches
   end if
   
   if tFormattedActiveWatches is not empty then
      put tFormattedActiveWatches  & return after tWatches
   end if
   delete the last char of tWatches
   
   sort tWatches by watchSortKey(each)
   
   return tWatches
end getWatches

private function watchSortKey pWatch
   # This is rather insane and should be tidied up when there is time, probably to use an array instead.
   # We need to make sure that whether or not a watch is active doesn't appear in the sort key, otherwise
   # activating / deactivating watches has the unwanted effect of changing the order of the list.
   get urlDecode(pWatch)
   return line 3 of it & line 4 of it
end watchSortKey

private command updateScrollbar
   lock screen
   set the height of scrollbar "Scrollbar" of me to the height of listObject()
   set the topLeft of scrollbar "Scrollbar" of me to the topRight of listObject()
   set the startValue of scrollbar "Scrollbar" of me to 0
   set the endValue of scrollbar "Scrollbar" of me to the formattedHeight of listObject() + 1
   set the lineInc of scrollbar "Scrollbar" of me to round(the formattedHeight of listObject() / 200)
   set the pageInc of scrollbar "Scrollbar" of me to round(the height of listObject())
   set the thumbSize of scrollbar "Scrollbar" of me to the height of listObject()
   set the thumbPosition of scrollbar "Scrollbar" of me to the vScroll of listObject()
   set the visible of scrollbar "Scrollbar" of me to (the formattedHeight of listObject() > the height of listObject())
   unlock screen
end updateScrollbar

on mouseDoubleUp
   local tItem
   put resolveItem(the long id of the target) into tItem
   if tItem is not empty and the short name of the target is not "Enabled" then
      if the cType of tItem is "breakpoint" then
         local tObjects
         revSEGetTargetObjects
         put the result into tObjects
         
         if the cObject of tItem is not among the lines of tObjects then
            revSEAddTargetObject the cObject of tItem
            revSESetCurrentObject the cObject of tItem
         end if
         
         revSEGoExecutionPoint the cObject of tItem, the cLine of tItem, true
      end if
   end if
end mouseDoubleUp
  

on mouseUp
   local tItem
   put resolveItem(the long id of the target) into tItem
   
   local tObject
   if tItem is not empty then
      put the cObject of tItem into tObject
   end if
   
   # Enabled checkbox. Activate / deactivate breakpoint so it matches the hilite of the checkbox
   if tItem is not empty and the short name of the target is "Enabled" then
      if the cType of tItem is "breakpoint" then
         if the hilite of button "Enabled" of tItem then
            revDebuggerActivateBreakpoint tObject, the cLine of tItem
         else
            revDebuggerDeactivateBreakpoint tObject, the cLine of tItem
         end if
      else if the cType of tItem is "watch" then
         if the hilite of button "Enabled" of tItem then
            revDebuggerActivateWatch tObject, the cHandler of tItem, the cVariable of tItem
         else
            revDebuggerDeactivateWatch tObject, the cHandler of tItem, the cVariable of tItem
         end if
      end if
      revSEUpdate false
      exit mouseUp
   end if
   
   if tItem is not empty and the short name of the target is "Edit" then
      seEditBreakpointDialog the cType of tItem, the cLine of tItem, the cVariable of tItem, the cHandler of tItem, the cCondition of tItem, the cObject of tItem
      exit mouseUp
   end if
end mouseUp
  

private function listObject
   if there is a group "List" of me then
      return the long id of group "List" of me
   else
      return empty
   end if
end listObject

private command ensureListObject
   if listObject() is empty then
      lock messages
      local tObject
      copy group "List Template" of card "Templates" to me
      put the long id of it into tObject
      unlock messages
      
      set the cItemTemplate of tObject to itemTemplate()
      set the name of tObject to "List"
      set the cantDelete of tObject to false
      set the lockLocation of tObject to true
      set the cMutable of tObject to true
   end if
end ensureListObject

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

private function itemTemplate
   --return revRuggedId(long id of group "Breakpoint Template" of card "Templates")
   return the long id of group "Breakpoint Template" of card "Templates" of this stack
end itemTemplate

on scrollbarDrag
   set the vScroll of group "List" of me to the thumbPosition of scrollbar "Scrollbar" of me
end scrollbarDrag

on mouseDown pButtonNumber
   local tItem
   put resolveItem(the long id of the target) into tItem
   if tItem is not empty and the short name of the target is not "Enabled" and the short name of the target is not "Edit" then
      lock screen
      repeat with x = 1 to the number of controls of me
         if the cListItem of control x of me then
            send "itemUnhilite" to control x of me
         end if
      end repeat
      
      send "itemHilite" to tItem
      put the long id of tItem into sSelectedItem
      unlock screen
   end if
   
   if pButtonNumber = 3 then
      updateContextMenu tItem
      popup button "Breakpoint Context Menu" of me
   end if
   
   pass mouseDown
end mouseDown

on menuPick pItemName
   if the short name of the target is not "Breakpoint Context Menu" then
      pass menuPick
   end if
   
   switch pItemName
      case "New Breakpoint"
         seNewBreakpointDialog "breakpoint"
      break
      case "New Watch"
         seNewBreakpointDialog "watch"
      break
      case "Edit"
         if sSelectedItem is not empty then
            seEditBreakpointDialog the cType of sSelectedItem, the cLine of sSelectedItem, the cVariable of sSelectedItem, the cHandler of sSelectedItem, the cCondition of sSelectedItem, the cObject of sSelectedItem
         end if
      break
      case "Delete"
         if sSelectedItem is not empty then
            if the cType of sSelectedItem is "breakpoint" then
               revDebuggerRemoveBreakpoint the cObject of sSelectedItem, the cLine of sSelectedItem
            else
               revDebuggerRemoveWatch the cObject of sSelectedItem, the cHandler of sSelectedItem, the cVariable of sSelectedItem
            end if
         end if
      break
   end switch
   
   revSEUpdate
end menuPick

private command updateContextMenu pTarget
   local tText
   put "New Breakpoint" & return & "New Watch" & return into tText
   put "-" & return after tText
   
   if pTarget is not empty then
      put "Edit" & return & "Delete" after tText
   else
      put "(Edit" & return & "(Delete" after tText
   end if
   
   set the text of button "Breakpoint Context Menu" of me to tText
end updateContextMenu
