script "revSEGutterBehavior"
# Number of lines stored initially in the numbers field. This is stored just to save
# time when updating by not needing to count the lines in the field.
constant kInitialLineStore = 3000

# This controls how many lines are added to the lines field if the script exceeds the current line count.
constant kLineAdd = 1000

# The current number of line numbers stored
local sCurrentLineStore

# Description
#   Called by the parent when the rect of this group might have changed. Resizes / positions all the
#   controls in the group to reflect the current rect of the group.
command resize
   if sePrefGet("gutter,linenumbers") then
      set the rect of field "Numbers" of me to the rect of me
   else
      set the right of field "Numbers" of me to the left of me + 500
   end if
   set the rect of field "Overlay" of me to the rect of me
   set the rect of group "Mutables" of me to the rect of me
end resize

local sLastScroll
local sLastState
local sLastObject

local sErrors

# Description
#   Called by the parent when something has changed that might have affected the gutter.
#   Causes the gutter to update itself.
command update pOffset, pSelectedLine, pOldNumber, pNewNumber, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   local tContext, tUpdateRequired
   
   lock screen
   put updateGetContext(pOffset, pSelectedLine, pOldNumber, pNewNumber, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw, tContext) into tUpdateRequired
   
   if not tUpdateRequired then
      unlock screen
      exit update
   end if
   
   if tContext["scroll"] is not empty then
      put tContext["scroll"] into sLastScroll
   end if
   
   if tContext["objectState"] is not empty then
      put tContext["objectState"] into sLastState
   end if
   
   if tContext["object"] is not empty then
      put tContext["object"] into sLastObject
   end if
   
   updateBreakpoints pOffset, pOldNumber, pNewNumber, pTextChanged, tContext
   updateLineNumbers pTextChanged, pOldNumber, pNewNumber, tContext
   updateCurrentLine tContext
   
   if pUpdateCompilationErrors then
      updateCompilationErrors, tContext
   end if
   unlock screen
end update


# Parameters
#   
# Returns
#   Whether or not an update is required. Note that if false is returned, no context information will be provided.
private function updateGetContext pOffset, pSelectedLine, pOldNumber, pNewNumber, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw, @rContext
   local tUpdateRequired
   put false into tUpdateRequired
   
   # Get the object being edited, if there isnt one, the gutter doesn't need updating, so exit straight away.
   local tObject
   getObject
   put the result into tObject
   if tObject is empty then
      return false
   end if
   
   # Work out if the breakpoints need updating. This is only the case if either the object state has changed since last update, the scroll has changed
   # since last update or lines have been added or removed from the script field. If pForceBreakpointRedraw is true, we assume the breakpoints need updating.
   if pForceBreakpointRedraw then
      put true into tUpdateRequired
   end if
   
   try
      local tScroll
      put the vScroll of getScriptField() into tScroll
   end try
   
   local tObjectState
   put seGetObjectState(tObject) into tObjectState
   
   if (tObject is not sLastObject) or (tObjectState is not sLastState) or (tScroll <> sLastScroll) or (pTextChanged and (pOldNumber <> pNewNumber)) then
      put true into tUpdateRequired
   end if
   
   # Find out if the line numbers need updating. This is only the case if more lines have been added to the script
   # than we have available in the line numbers field.
   local tNewLineCount
   if pTextChanged then
      put pNewNumber - pOldNumber + the number of lines of field "Script" of the owner of me into tNewLineCount
   else
      put the number of lines of field "Script" of the owner of me into tNewLineCount
   end if
   
   local tNumberOfAdditions
   if tNewLineCount > sCurrentLineStore and sePrefGet("gutter,linenumbers") then
      put ((pNewNumber - sCurrentLineStore) div kLineAdd) + 1 into tNumberOfAdditions
      if tNumberOfAdditions > 0 then
         put true into tUpdateRequired
      end if
   end if
   
   # Find out if the current line needs updating. It needs updating if either there is a current line image,
   # or we are in debug mode.
   # OK-2009-06-23: Bug 7954
   local tArray
   put revDebuggerParseExecutionContext(line 1 of seDebugContexts()) into tArray
   
   local tDefaultObject
   put tArray["object"] into tDefaultObject
   
   --put item 2 to -3 of line 1 of seDebugContexts() into tDefaultObject
   
   local tMode
   revSEGetMode
   put the result into tMode
   
   if (there is an image "Current Line" of me) or ((tDefaultObject is not empty and (seGetRuggedId(tObject) is seGetRuggedId(tDefaultObject) and tMode is "debug"))) then
      put true into tUpdateRequired
   end if
   
   # Finally, work out if the compilation errors need updating. They need updating if either there is a compilation error image present in the gutter
   # or there are compilation errors in the script.
   local tErrorImages
   repeat with x = the number of images of me down to 1
      if the cError of image x of me then
         put the id of image x of me & return after tErrorImages
      end if
   end repeat
   delete the last char of tErrorImages
   
   if pUpdateCompilationErrors and (the number of lines of tErrorImages > 0) or (the number of lines of sErrors[seGetRuggedId(tObject)] > 0) then
      put true into tUpdateRequired
   end if
   
   put tScroll into rContext["scroll"]
   put tObjectState into rContext["objectstate"]
   put tObject into rContext["object"]
   put tNumberOfAdditions into rContext["numberOfAdditions"]
   put tErrorImages into rContext["errorImages"]
   put tMode into rContext["mode"]
   
   return tUpdateRequired
end updateGetContext
  

# Description
#   Updates the scroll of the gutter in reponse to changes in the editor group.
command updateScroll
   set the vScroll of field "Numbers" of me to the vScroll of field "Script" of the owner of me
end updateScroll

# Description
#   Quickly hides all breakpoints, compilation errors and other mutable objects. This is used to allow the gutter
#   to have a delayed update without looking bad.
command hideMutables
   if there is an image "Current Line" of me then
      hide image "Current Line" of me
   end if
   set the visible of group "Mutables" of me to false
end hideMutables

# Description
#   Shows all breakpoints, compilation errors etc
command showMutables
   set the visible of group "Mutables" of me to true
end showMutables

# Description
#   Called by the parent when the gutter should initialize itself, e.g. because the
#   script editor has just been opened.
command initialize
   lock screen
   clearMutableObjects
   clearCompilationErrors
   initializeLineNumbers
   initializeMutables
   initializeCurrentLine
   unlock screen
end initialize

private command initializeCurrentLine
   #set the loc of image "Current Line" of me to -500, -500
   lock messages
   if there is an image "Current Line" of me then
      delete image "Current Line" of me
   end if
   unlock messages
end initializeCurrentLine

private command initializeLineNumbers
   lock messages
   if there is a field "Numbers" of me then
      delete field "Numbers" of me
   end if
   
   clone field "Numbers Template" of me as "Numbers"
   put kInitialLineStore into sCurrentLineStore
   unlock messages
end initializeLineNumbers

private command initializeMutables
   lock messages
   if there is a group "Mutables" of me then
      delete group "Mutables" of me
   end if
   unlock messages
   
   # The syntax of the create command allows a group to be specified, but the group
   # must be on the current card of the default stack. This means that the defaultStack *must*
   # be the script editor or this command will fail, preventing the script editor from initializing. 
   local tOldDefaultStack
   put the defaultStack into tOldDefaultStack
   set the defaultStack to revTargetStack(the long id of me)
   
   create group "Mutables" in me
   
   set the defaultStack to tOldDefaultStack
   
   set the lockLocation of group "Mutables" of me to true
   set the rect of group "Mutables" of me to the rect of me
end initializeMutables

private command clearCompilationErrors
   lock messages
   repeat with x = the number of images of me down to 1
      if the cError of image x of me then
         delete image x of me
      end if
   end repeat
   unlock messages
end clearCompilationErrors

command setCompilationErrors pErrors, pObject
   put pErrors into sErrors[pObject]
end setCompilationErrors

private command updateCurrentLine pContext
   if there is an image "Current Line" of me then
      delete image "Current Line" of me
   end if
   
   if pContext["mode"] is not "debug" then
      exit updateCurrentLine
   end if
   
   # The current line indicator should stay tied to the current debugger line, rather than the line that the user
   # is currently viewing in the script editor. To acheive this, we use the revDebuggerGetContext() and extract
   # the line number from it.
   --   local tLine
   --   put getLastGoneToLine() into tLine
   
   local tDebugContext
   put revDebuggerGetContext() into tDebugContext
   
   local tArray
   put revDebuggerParseExecutionContext(tDebugContext) into tArray
   
   local tDebugObject
   local tDebugLine
   if tArray["behavior"] is not empty then
      put tArray["behavior"] into tDebugObject
      put tArray["line number"] into tDebugLine
   else
      put item 2 to -3 of tDebugContext into tDebugObject
      put tArray["object"] into tDebugObject
      put tArray["line number"] into tDebugLine
   end if
   
   if (seGetRuggedId(pContext["object"]) is not seGetRuggedId(tDebugObject)) then
      exit updateCurrentLine
   end if
   
   local tId
   put seGetIcon("gutterCurrentLine") into tId
   copy control id tId of seIconStack() to me
   set the name of it to "Current Line"
   
   if tDebugLine is not empty then
      set the loc of image "Current Line" of me to (item 1 of the loc of me), lineNumberToVerticalLoc(tDebugLine)
      
      # Just for convenience, this saves having to calculate the line if the user clicks on the image.
      set the cLine of image "Current Line" of me to tDebugLine
   else
      set the loc of image "Current Line" of me to -500, -500
   end if
end updateCurrentLine
  


# Parameters
#   pTextEdited : whether or not the text in the script field has changed
#   pOldNumber : the old number of lines in the script field
#   pNewNumber : the new number of lines in the script field
# Description
#   If there are not enough line numbers to add to the field
command updateLineNumbers pTextEdited, pOldNumber, pNewNumber, pContext
   
   # only update if there's work to be done
   if pContext["numberOfAdditions"] <= 0 then exit updateLineNumbers
   
   # Add the lines in a non-locking manner, and after we've finished adding lines, the scroll
   # of the line numbers field should be updated.
   repeat pContext["numberOfAdditions"] times
      send "addLines kLineAdd" to me in 0 milliseconds
   end repeat
   send "updateScroll" to me in 0 milliseconds
end updateLineNumbers

command addLines pNumberToAdd
   local tNewLines
   repeat with x = (sCurrentLineStore + 1) to (sCurrentLineStore + pNumberToAdd)
      put x & return after tNewLines
   end repeat
   delete the last char of tNewLines
   
   put return & tNewLines after field "Numbers" of me
   put the last line of tNewLines into sCurrentLineStore
end addLines

command updateCompilationErrors pContext
   local tObject
   if pContext["object"] is not empty then
      put pContext["object"] into tObject
   else
      getObject
      put the result into tObject
   end if
   
   if there is not a tObject then
      return "object does not exist" for error
   end if
   
   # Remove previous compilation errors
   if pContext["errorImages"] is not empty then
      repeat for each line tImageId in pContext["errorImages"]
         delete image id tImageId of me
      end repeat
   else
      clearCompilationErrors  
   end if
   
   local tHorizontal
   put item 1 of the loc of me into tHorizontal
   
   local tErrorNumber
   put 1 into tErrorNumber
   
   local tVertical
   local tDescription, tLine, tToken
   repeat for each line tError in sErrors[seGetRuggedId(tObject)]
      put seErrorDescription("compilation", item 1 of tError) into tDescription
      put item 2 of tError into tLine
      put item 4 to -1 of tError into tToken
      put lineNumberToVerticalLoc(tLine) into tVertical
      if tVertical is 0 then
         # If 0 it means that the line number of the error is not within the gutter's current bounds
         next repeat
      end if
      
      local tImage
      copy getErrorImageId() to group "Mutables" of me
      put the long id of it into tImage
      set the cError of tImage to true
      set the cLine of tImage to tLine
      set the tooltip of tImage to "Error (line " & tLine & "): " & tDescription
      set the loc of tImage to tHorizontal, tVertical
      set the name of tImage to "Error " & tErrorNumber
      
      add 1 to tErrorNumber
   end repeat
end updateCompilationErrors


# Parameters
#   pObject : reference to the object to update breakpoint positions for
#   pOffset : the offset of text replacement
#   pOldNumber : the number of lines previously in the script
#   pNewNumber : the number of lines now in the script
# Description
#   Updates the the positions of breakpoints in response to the script being changed.
private command updateBreakpointPositions pObject, pOffset, pOldNumber, pNewNumber   
   local tNumber, tInsertion
   
   if pOldNumber = pNewNumber then
      exit updateBreakpointPositions
   end if
   
   local tBreakpoints
   put revDebuggerListBreakpoints(pObject) into tBreakpoints
   
   local tLineIndex
   put the lineIndex of char pOffset of getScriptField() into tLineIndex
   
   if pOldNumber < pNewNumber then
      repeat for each line tBreakpoint in tBreakpoints
         if item -1 of tBreakpoint = tLineIndex then
            local tCharIndex
            put the charIndex of line tLineIndex of getScriptField() into tCharIndex
            
            local tLine
            put the text of line tLineIndex of getScriptField() into tLine
            
            local tBefore
            put char 1 to (pOffset - tCharIndex) of tLine into tBefore
            
            # This means that the user has added a return before the beginning of the line containing the breakpoint. We move the breakpoint
            # to follow the line.
            if word 1 of tBefore is empty then
               revDebuggerMoveBreakpoint item 1 to -2 of tBreakpoint, item -1 of tBreakpoint, item 1 to -2 of tBreakpoint, item -1 of tBreakpoint + (pNewNumber - pOldNumber)
            end if
         end if
         
         # If the line that contained the breakpoint was above the added text, leave it where it is
         if item -1 of tBreakpoint < tLineIndex then
            next repeat
         end if
         
         
         # If the line that contained the breakpoint was below the added text, move the breakpoint down by the number of lines added.
         if item -1 of tBreakpoint > tLineIndex then
            revDebuggerMoveBreakpoint item 1 to -2 of tBreakpoint, item -1 of tBreakpoint, item 1 to -2 of tBreakpoint, item -1 of tBreakpoint + (pNewNumber - pOldNumber)
         end if
      end repeat
   else
      local tScript
      put textGetScript() into tScript
      repeat for each line tBreakpoint in tBreakpoints
         if (item -1 of tBreakpoint >= tLineIndex and item -1 of tBreakpoint < (tLineIndex - (pNewNumber - pOldNumber))) and revDebuggerNextAvailableBreakpoint(tScript, item -1 of tBreakpoint - 1 + (pNewNumber - pOldNumber)) <> item -1 of tBreakpoint + (pNewNumber - pOldNumber) then
            revDebuggerRemoveBreakpoint item 1 to -2 of tBreakpoint, item -1 of tBreakpoint
         else if item -1 of tBreakpoint > (tLineIndex + pNewNumber - pOldNumber) then
            # If the breakpoint was below the removed lines, move it up
            revDebuggerMoveBreakpoint item 1 to -2 of tBreakpoint, item -1 of tBreakpoint, item 1 to -2 of tBreakpoint, item -1 of tBreakpoint + (pNewNumber - pOldNumber)
         end if
      end repeat
   end if
end updateBreakpointPositions

private command updateBreakpoints pOffset, pOldNumber, pNewNumber, pTextChanged, pContext
   clearMutableObjects
   
   local tObject
   if pContext["object"] is not empty then
      put pContext["object"] into tObject
   else
      getObject
      put the result into tObject
   end if
   
   if there is not a tObject then
      return "object does not exist" for error
   end if
   
   if pTextChanged then
      updateBreakpointPositions tObject, pOffset, pOldNumber, pNewNumber
   end if
   
   # Get a list of the breakpoints set on the current object using revDebuggerListBreakpoints.
   local tBreakpoints
   put revDebuggerListBreakpoints(tObject) into tBreakpoints
   
   local tConditions
   put revDebuggerListBreakpointConditions(tObject) into tConditions

   local tHorizontal, tVertical
   put item 1 of the loc of me into tHorizontal
   
   local tLineNumber
   put 1 into tLineNumber
   repeat for each line tBreakpoint in tBreakpoints
      put lineNumberToVerticalLoc(item -1 of tBreakpoint) into tVertical
      
      # This means that tBreakpoint is on a line outside the boundaries of the gutter with the
      # current scroll, so we don't need to display it.
      if tVertical is 0 then
         next repeat
      end if
      
      # Get information about the breakpoint's state
      local tState, tInvalid, tMessage
      get seBreakpointDisplayInformation(item 1 to -2 of tBreakpoint, item -1 of tBreakpoint)
      put line 1 of it into tState
      put line 2 of it into tInvalid
      put line 3 of it into tMessage
      
      # Render the breakpoint at this location
      local tImage
      put getBreakpointImageId(tState) into tImage
      
      lock messages
      copy tImage to group "Mutables" of me
      
      # Breakpoints must be given random names. We can't use the line number or tBreakpoint as the name
      # because breakpoints can be moved, allowing a situation where two could have the same name.
      set the name of it to controlRandomName()
      put the long id of it into tImage
      unlock messages 
      
      set the cMutable of tImage to true
      set the cBreakpoint of tImage to true
      
      # Set the breakpoint's tooltip according to a few different variables.
      local tTooltip
      if tState is "inactive" then
         put "Breakpoint (line: " & item -1 of tBreakpoint & ") inactive" into tTooltip
      else
         put "Breakpoint (line: " & item -1 of tBreakpoint & ") active" into tTooltip
      end if
      
      if tMessage is not empty then
         put ", " & tMessage after tTooltip
      end if
      
      set the cInvalid of tImage to tInvalid
      set the tooltip of tImage to tTooltip
      set the cLine of tImage to item -1 of tBreakpoint
      set the cState of tImage to tState
      set the loc of tImage to tHorizontal, tVertical
      
      set the cCondition of tImage to line tLineNumber of tConditions
      
      add 1 to tLineNumber
   end repeat
end updateBreakpoints

private command clearMutableObjects
   lock messages
   repeat with x = the number of controls of me down to 1
      if the cMutable of control x of me then
         delete control x of me
      end if
   end repeat
   unlock messages
end clearMutableObjects

private function getBreakpointImageId pType
   local tId
   if pType is "active" then
      put seGetIcon("gutterActiveBreakpoint") into tId
   else
      put seGetIcon("gutterInactiveBreakpoint") into tId
   end if
   
   return the long id of control id tId of seIconStack()
end getBreakpointImageId

private function getErrorImageId
   --return the long id of image "Compilation Error" of card "Templates"
   local tId
   put seGetIcon("gutterError") into tId
   
   return the long id of control id tId of seIconStack()
end getErrorImageId

# Description
#   Sent just before the button is popped up. Builds the button text according to its context
command updateContextMenu pContext
  local tLine, tState, tValid
  put line 1 of pContext into tLine
  put line 2 of pContext into tState
  put line 3 of pContext into tValid
  
  local tText
  put "(Breakpoint (line " & tLine & ")" & return into tText
  put "-" & return after tText
  if tState is "active" then
    put "Disable" & return after tText
  else if tValid is false then
    put "(Enable" & return after tText
  else
    put "Enable" & return after tText
  end if
  put "Remove" & return after tText
  put "-" & return after tText
  put "Edit..." after tText
  
  set the text of button "Breakpoint Context Menu" of me to tText
  set the cTarget of button "Breakpoint Context Menu" of me to line 4 of pContext
end updateContextMenu

# Parameters
#   pObject : a reference to an object in the gutter
# Returns
#   Either empty if pObject is not covering a breakpoint image or the long id of the image
#   it is covering otherwise.
private function breakpointCovered pObject
   local tTarget
   put the long id of pObject into tTarget
   
   # For now, only the current line image is applicable here.
   if the short name of tTarget is "Current Line" then
      local tObject
      getObject
      put the result into tObject
      
      repeat with x = 1 to the number of controls of group "Mutables" of me
         if not the cBreakpoint of control x of group "Mutables" of me then
            next repeat
         end if
         
         if the cLine of control x of group "Mutables" of me  = the cLine of tTarget then
            return the long id of control x of group "Mutables" of me
         end if
      end repeat
   end if
   
   return empty
end breakpointCovered


on mouseDown pButtonNumber
   if not (the cBreakpoint of the target or the short name of the target is "Current Line") then
      pass mouseDown
   end if
   
   if pButtonNumber is not 3 then
      pass mouseDown
   end if
   
   # The current line image doesn't do anything itself, but it can be above a breakpoint.
   # In this case we want it to be as though the user clicked on the breakpoint. This is done
   # simply by changing the tTarget variable to contain a reference to the breakpoint image
   # instead of the original target.
   local tTarget
   put the long id of the target into tTarget
   
   local tBreakpointImage
   put breakpointCovered(tTarget) into tBreakpointImage
   if tBreakpointImage is not empty then
      put tBreakpointImage into tTarget
   end if
   
   local tContext
   put the cLine of tTarget & return & the cState of tTarget & return & (not the cInvalid of tTarget) & return & the long id of tTarget into tContext
   set the cContext of button "Breakpoint Context Menu" of me to tContext
   updateContextMenu tContext
   popup button "Breakpoint Context Menu" of me
end mouseDown

on mouseUp pButtonNumber
   if pButtonNumber is not 1 then
      exit mouseUp
   end if
   
   local tTarget, tClickLoc
   put the long id of the target into tTarget
   put the clickloc into tClickLoc
   # 2017-08-01 bhall2001
   # bugfix 20214 handle changes to gutter directly
   gutterMouseUp tTarget, tClickLoc
end mouseUp

on gutterMouseUp pTarget, pClickLoc
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   if the cBreakpoint of pTarget or the short name of pTarget is "Current Line" then
      # The current line image doesn't do anything itself, but it can be above a breakpoint.
      # In this case we want it to be as though the user clicked on the breakpoint. This is done
      # simply by changing the tTarget variable to contain a reference to the breakpoint image
      # instead of the original target.
      local tBreakpointImage
      put breakpointCovered(pTarget) into tBreakpointImage
      if tBreakpointImage is not empty then
         put tBreakpointImage into pTarget
      end if
      
      if the cState of pTarget is "active" then
         revDebuggerRemoveBreakpoint tObject, (the cLine of pTarget)
      else
         # A breakpoint is invalid if it is not currently placed on a valid line of executable code,
         # e.g. a commented line, variable declaration etc.
         if the cInvalid of pTarget or not revDebuggerEnabled() or seGetObjectState(tObject) is not "applied" then
            revDebuggerRemoveBreakpoint tObject, (the cLine of pTarget)
         else
            revDebuggerActivateBreakpoint tObject, (the cLine of pTarget)
         end if
      end if
   else
      local tLineNumber
      put verticalLocToLineNumber(item 2 of pClickLoc) into tLineNumber
      
      if tLineNumber is not empty then
         # Adjust the line number to find the next available breakpoint
         local tScript
         put textGetScript() into tScript
         put revDebuggerNextAvailableBreakpoint(tScript, tLineNumber - 1) into tLineNumber
         
         # There may be no available lines left for a breakpoint
         if tLineNumber <> 0 then
            revDebuggerAddBreakpoint tObject, tLineNumber
            revDebuggerActivateBreakpoint tObject, tLineNumber
            # OK-2008-08-12 : Bug 6887 - Scroll down if breakpoint has been created off-screen
            if lineNumberToVerticalLoc(tLineNumber) = 0 then
               goLine tLineNumber, false
            end if
         end if
      end if
   end if
   
   lock screen
   clearMutableObjects
   updateBreakpoints 1, 1, 1, false
   # OK-2010-02-26: Avoid delays when updating breakpoints by only updating the breakpoints pane
   --   sePanesUpdate
   seRefreshCurrentPaneIfItsBreakpoints
   unlock screen
end gutterMouseUp

on menuPick pItemName
   # The target appears to be wrong in this case. As there is only currently one menu
   # in the gutter group, we just ommit this check for now...
   --  if the long id of the target is not the long id of button "Breakpoint Context Menu" of me then
   --    exit menuPick
   --  end if
   
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   # The cTarget of the breakpoint menu will contain the long id of the breakpoint image the user clicked on.
   local tImage
   put the cTarget of the target into tImage
   
   switch pItemName
      case "Disable"
         revDebuggerDeactivateBreakpoint tObject, (the cLine of tImage)
         break
      case "Enable"
         revDebuggerActivateBreakpoint tObject, (the cLine of tImage)
         break
      case "Remove"
         revDebuggerRemoveBreakpoint tObject, (the cLine of tImage)
         break
      case "Edit..."
         seEditBreakpointDialog "breakpoint", the cLine of tImage,,, the cCondition of tImage, tObject
         exit menuPick
         break
   end switch
   
   lock screen
   clearMutableObjects
   updateBreakpoints 1, 1, 1, false
   
   # OK-2010-02-26: Avoid delays when updating breakpoints by only updating the breakpoints pane
   --   sePanesUpdate
   seRefreshCurrentPaneIfItsBreakpoints
   unlock screen
end menuPick

on rawKeyDown
  # Block this message as the gutter must only be scrolled in response to the main script field
end rawKeyDown

on scrollBarDrag
  # Block this message as the gutter must only be scrolled in response to the main script field
end scrollBarDrag

# Returns
#   A random name used for naming mutable controls. In particular, breakpoint images.
private function controlRandomName
   local tName
   repeat 32 times
      put any char of "abcdefghijklmnopqrstuvwxyz0123456789_-   " after tName
   end repeat
   return tName
end controlRandomName











