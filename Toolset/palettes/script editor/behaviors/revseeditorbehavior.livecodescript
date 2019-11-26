script "revSEEditorBehavior"
# Stores the following mapping
#  <handler name>,type   => string representing the handler type eg PF for private function
# <handler name>,start  => line offset to start of handler
#  <handler name>,end    => line offset to end of handler
# The map is updated whenever scriptCompile is called.
local sHandlerMap

# These two variables store which object the current search was started on, and which#
# object the most recent result was found in respectively.
local sFirstFindObject
local sLastFindObject

constant kMinGutterWidth = 16

# Description
#   Sent by the parent when the rect of this group may have changed. Resizes / positions all the controls in this group
#   according to the group's current rect.
command resize
   local tControls
   put the long id of group "Interactive Find" of me into tControls["find"]
   put the long id of group "Enter Password" of me into tControls["password"]
   put the long id of group "Gutter" of me into tControls["gutter"]
   put the long id of field "Script" of me into tControls["script"]

   local tMyRect, tMyWidth, tMyHeight
   put the rect of me into tMyRect
   split tMyRect by comma
   put tMyRect[3] - tMyRect[1] into tMyWidth
   put tMyRect[4] - tMyRect[2] into tMyHeight

   local tGutterWidth
   if sePrefGet("gutter,linenumbers") then
      put max(formattedWidth of field "Numbers" of tControls["gutter"], \
         kMinGutterWidth) into tGutterWidth
   else
      put kMinGutterWidth into tGutterWidth
   end if

   local tFindHeight
   if sePrefGet("editor,findvisible") then
      put the formattedheight of tControls["find"] into tFindHeight
   else
      put 0 into tFindHeight
   end if

   local tNewRect, tScriptScrollSize

   -- Position the main code editing field

   put tMyRect[1] + tGutterWidth, tMyRect[2], \
       tMyRect[3], tMyRect[4] - tFindHeight into tNewRect
   if the rect of tControls["script"] is not tNewRect then
      set the rect of tControls["script"] to tNewRect
   end if

   if the hScrollbar of tControls["script"] then
      put the scrollBarWidth of tControls["script"] into tScriptScrollSize
   else
      put 0 into tScriptScrollSize
   end if

   -- Position the "find" interface

   put tMyRect[1] + tGutterWidth, tMyRect[4] - tFindHeight, \
       tMyRect[3],  tMyRect[4] into tNewRect
   if the rect of tControls["find"] is not tNewRect then
      set the topLeft of tControls["find"] to tMyRect[1] + tGutterWidth, tMyRect[4] - tFindHeight
   end if

   -- Position the gutter

   put tMyRect[1], tMyRect[2], tMyRect[1] + tGutterWidth, \
       tMyRect[4] - tFindHeight - tScriptScrollSize into tNewRect
   if the rect of tControls["gutter"] is not tNewRect then
      set the rect of tControls["gutter"] to tNewRect
      send "resize" to tControls["gutter"]
   end if

   -- If the script is encrypted, display the password layer over the
   -- top.

   if scriptProtected() then
      set the loc of tControls["password"] to (item 1 of the loc of me), (item 2 of the loc of tControls["password"])
      set the top of tControls["password"] to the top of me + (the height of me div 3)
      send "openControl" to tControls["password"]
   else
      set the right of tControls["password"] to the left of me - 20
   end if

   -- Ensure that various bits of infrastructure that the user
   -- shouldn't see are hidden.

   set the right of button "Context Menu" of me to the left of me - 500
   set the right of button "revCompileObject" of me to the left of me - 500

end resize

local sUniqueId

# Description
#   Sent by the parent when editor group is about to be used for the first time
#   Initializes the group. Note that this is also called when there are no more
#   objects to edit, this may happen when the user has removed the last object
#   from the script editor. This is the reason why this command saves the previous
#   context before putting empty into getObjectID().
command initialize
   if getObjectID() is not empty then
      contextSave
   end if
   
   lock screen
   textInitialize
   call "initialize" to group "Gutter" of me
   
   set the backgroundColor of field "Script" of me to sePrefGet("editor,backgroundcolor")
   setHandlersFieldBackColor
   set the hScrollbar of field "Script" of me to (sePrefGet("editor,hscrollbar") is "true")
   
   -- See bug 16773. Mac likes an odd scrollbarwidth,
   -- Windows requires a scrollbarwidth > 16
   set the scrollbarWidth of field "Script" of me to 17
   
   # OK-2009-03-11 : Bug 7499 - The hilite color was previously not being reset to empty on OS X.
   # At the same time as fixing this issue, I've made the hilite color a preference in case we decide
   # to allow users to configure it in the future.
   set the hiliteColor of field "Script" of me to sePrefGet("editor,hilitecolor")
   
   # OK-2008-07-07 : Bug 6748 - Interactive find not remembering last search
   if sePrefGet("editor,findvisible") then
      call "openControl" to group "Interactive Find" of me
   end if
   
   setObjectID empty
   put 0 into sUniqueId
   
   unlock screen
end initialize

private command setHandlersFieldBackColor
   if there is a field "Handlers" of group "Left Handler List" of group "Left Bar" \
         of card "Main" of this stack then
      set the backgroundColor of  field "Handlers" of group "Left Handler List" of group "Left Bar" \
            of card "Main" of this stack to sePrefGet("editor,backgroundcolor")
   end if
end setHandlersFieldBackColor

private command initializeFonts
   local tFont, tFontSize
   put sePrefGet("editor,font") into tFont
   put sePrefGet("editor,fontsize") into tFontSize
   
   if the textFont of field "Script" of me is not tFont or \
         the textSize of field "Script" of me is not tFontSize then
      
      set the textFont of field "Script" of me to tFont
      set the textSize of field "Script" of me to tFontSize
      # It is not possible to set the textSize and textFont of styled text that has already
      # had its textSize / textFont set once. Therefore to allow textSize / textFont changes
      # we have to remove all styling from the script field.  Although it seems rather weird, this
      # does have to be done *after* the properties have been set to the value required..
      set the text of field "Script" of me to the text of field "Script" of me
   end if
   
   # Note that the textSize and textFont properties are set on the group overall. The gutter has a
   # numbers field and a template numbers field both of which should inherit this value. Other controls
   # must have their textFont / textSize explicitly set if they need specific values.
   if the textSize of group "Gutter" of me is not tFontSize or \
         the textHeight of group "Gutter" of me is not the effective textHeight of field "Script" of me then
      
      set the textSize of group "Gutter" of me to tFontSize
      set the textHeight of group "Gutter" of me to the effective textHeight of field "Script" of me
   end if
   
end initializeFonts

# Description
#   Sent by the parent when the script editor preferences have been changed.
#   Causes the script editor to reread preferences such as font, text size
#   and colorization scheme, and update itself according to these.
command reapplyPreferences
   lock screen
   initializeFonts
   textFormatInitialize
   colorizationUpdate
   scriptColorize "script"
   
   set the backgroundColor of field "Script" of me to sePrefGet("editor,backgroundcolor")
   setHandlersFieldBackColor
   set the hScrollbar of field "Script" of me to (sePrefGet("editor,hscrollbar") is "true")
   
   updateGutterRequest empty, empty, empty, empty, false, false, true
   resize
   unlock screen
end reapplyPreferences

local sLastSelections

# Description
#   Saves the script editor context of the current object as metadata on that object.
#   The context includes such information as vscroll and selected chunk. For selections,
#   we save the last char of the selection as metadata on the object, and the full selection
#   in memory as a script local. Thus full selections are remembered when switching tabs, but only
#   the location of the selection is remembered when opening a new tab or after restarting rev.
private command contextSave
   revMetadataSet getObjectID(), "general", "scripteditorvscroll", the vScroll of field "Script" of me
   
   if the long id of the focusedObject is the long id of field "Script" of me then
      get the selectedChunk
      put word 2 of it & comma & word 4 of it into sLastSelections[getObjectID()]
      revMetadataSet getObjectID(), "general", "scripteditorselection", word 4 of it
   end if
end contextSave

# Description
#   Loads the previously saved context for for current object if one was saved.
private command contextLoad
   local tSelection
   
   if sLastSelections[getObjectID()] is not empty then
      # If there is a last selection stored in memory, this means the user has previously opened this object
      # and is just changing tabs. In this case we remember the entire selection.
      put sLastSelections[getObjectID()] into tSelection
   else
      # If there is no last selection in memory, this means either the user didnt select anything, or they
      # have not opened the object yet. In this case we only remember the location of the selection, not what was selected.
      # This information is stored as object metadata. In previous versions of the script editor, both the selection start and end
      # were stored, but this was changed to store only the selection end. This change is what warrants the extra check.
      put revMetadataGet(getObjectID(), "general", "scripteditorselection") into tSelection
      
      # In case the object was last edited with an older version, get rid of any excess selection info.
      if the number of items of tSelection > 1 then
         put item 2 of tSelection into tSelection
      end if
      
      # Form the full selection from what is stored
      put (tSelection + 1) & comma & tSelection into tSelection   
   end if
   
   if tSelection is not empty then
      # Try is used here to allow the IDE to add objects to a script editor before opening it
      try 
         select char (item 1 of tSelection) to (item 2 of tSelection) of field "Script" of me
         
         # OK-2009-01-17 : Bug 7601 - Update sLastSelectedChunk here as it will be incorrect until the first selectionChanged message is triggered
         setLastSelectedChunk tSelection
      end try
   end if
   
   local tScroll
   put revMetadataGet(getObjectID(), "general", "scripteditorvscroll") into tScroll
   
   if tScroll is not empty then
      set the vScroll of field "Script" of me to tScroll
   else
      set the vScroll of field "Script" of me to 0
   end if
end contextLoad

local sHandlerList
local sLastSelectedHandler

command loadScript
   # When changing object, the gutter should update its compilation errors. The gutter is updated
   # in the call to textSetScriptRaw, however this does not update these errors for efficiency reasons
   # so an extra call is made here to make sure the errors are updated.
   send "updateCompilationErrors" to group "Gutter" of me
   
   # OK-2008-07-07 : Bug 6746 - When loading a new script, we clear the handler list, this means that if the newly
   # loaded script cannot be compiled, a empty handler list will be shown instead of the one from the previous object.
   put empty into sHandlerList
   put empty into sLastSelectedHandler
   
   # If the current object is password protected, show dialog and disable script field.
   if scriptProtected() then
      textSetScriptRaw empty
      scriptLock
      exit loadScript
   end if
   
   # If the mode is edit then make sure the script is unlocked.
   local tMode
   revSEGetMode
   put the result into tMode
   if tMode is "edit" then
      scriptUnlock
   end if
   
   local tCachedScript
   scriptGetCache getObjectID()
   put the result into tCachedScript
   
   lock screen
   if tCachedScript is not empty then
      # If there is a cached script, this means that the user is coming back to this object from another tab.
      textSetScriptRaw tCachedScript
   else
      local tScript
      put the script of getObjectID() into tScript
      
      textSetScriptRaw tScript
      
      # OK-2008-07-07 : Bug 6746
      seUpdateCheckSum getObjectID(), tScript
      if tScript is empty then
         select before field "Script" of me
      end if
   end if
   
   # The lock messages is required, because otherwise an exitField is received before the contextLoad
   # can execute, causing the context to be overwritten just before we load it. Not currently sure why 
   # this happens...
   lock messages
   contextLoad
   unlock messages
   
   # As we have changed the selection, update the rest of the script editor to reflect this
   --selectionUpdateRequest
   
   # OK-2008-08-14 : In this case, do the selection update immediately, not in time.
   selectionUpdate
end loadScript

command selectionUpdate
   lock screen
   findClearResults
   if the lockText of field "Script" of me is false then
      deSelectLastGoneToLine
   end if
    
   # Tell the script editor to update its panes. This is called here in particular
   # for the documentation pane to update itself when the user selects a new term.
   paneUpdateRequest
    
   # Update the variables that store the last selected line and handler list
   updateHandlerList
    
   updateSelectedHandler
   
   contextSave
    
   # Update the toolbar so that the handlers list can reflect the new selection. For efficiency we pass
   # a parameter to the update command which tells it that the selected handler can be assumed to be
   # up to date, so it doesn't need to evaluate it again (as we just updated it).
   local tTrueString
   put "true" into tTrueString
     
   # OK-2009-10-05: Optimized this a little. The previous call to update was doing quite a bit of stuff
   # that is not required here. I factored out the stuff that we actually need into a new method, which
   # is now called instead.
   -- send "update tTrueString" to group "Toolbar" of stack (revTargetStack(the long id of me))
   send "updateSelectedHandler tTrueString" to group "Toolbar" of stack (revTargetStack(the long id of me))
   # Update the left bar in the same way as the toolbar is updated
   # OK-2009-10-05: Some more optimization here, the update method was doing a lot of stuff that is not
   # needed, so I added a more specific method to handle this situation.
   send "updateSelectedHandler" to group "Left Bar" of stack (revTargetStack(the long id of me))
   unlock screen
   pass selectionUpdate
end selectionUpdate

# Parameters
#   pObjectId : reference to the object to set the script to. Must be one of the target objects of the script editor.
# Description
#   Sets the current target object of the editor group.
command setObject pObjectId, pDontSendCallbacks
   local tRuggedObjectId
   put seGetRuggedId(pObjectId) into tRuggedObjectId

   if getObjectID() is not empty and tRuggedObjectId is getObjectID() then
      if not pDontSendCallbacks then
         seSendCallbacks getObjectID(), the name of stack (revTargetStack(the long id of me))
      end if
      exit setObject
   end if
   
   # If we are closing a previous object and the script has not been applied,
   # cache the script of the previous object internally, and save the context
   if getObjectID() is not empty then
      cacheScript getObjectID(), textGetScript()
      if there is a getObjectID() then
         contextSave
      end if
   end if
   
   lock screen
   
   # It appears that changing the text of the field does not remove all styles,
   # so it is necessary to reset the fonts here, otherwise when changing tabs after the textSize has
   # been changed, the the textSize will appear to revert back to what it was previously.
   initializeFonts
   
   findClearResults
   
   EditorFieldCacheSwap getObjectID(), tRuggedObjectId
   setObjectID tRuggedObjectId
   loadScript
   resize
   unlock screen
   
   if not pDontSendCallbacks then
      seSendCallbacks getObjectID(), the name of stack (revTargetStack(the long id of me))
   end if
end setObject

# Description
#   Reverts the script of the current object to the last applied version
command revertObject
   loadScript
   seSetObjectState getObjectID(), "applied"
end revertObject

# Parameters
#   pObjectId : reference to the object to set the script to. Must be the same object as is currently set.
# Description
#   Sets the object being edited to the specified object *without* changing the script. This should be called
#   when the object being edited has changed ids, been moved to a new stack etc, anything that might change
#   its rugged id. It should not be called outside this situation as stuff will break.
command setObjectRaw pObjectId
   local tOldObjectId
   put getObjectID() into tOldObjectId
   
   setObjectID pObjectId
   
   if tOldObjectId is empty then
      exit setObjectRaw
   end if
   
   updateObjectID tOldObjectID, getObjectID()
   
   # Find results
   if sLastFindObject is tOldObjectId then
      put getObjectID() into sLastFindObject
   end if
   
   if sFirstFindObject is tOldObjectId then
      put getObjectID() into sFirstFindObject
   end if
end setObjectRaw

# Description
#   Returns a reference to the current object being edited.
command getObject
   return getObjectID()
end getObject

# Parameters
#   pDontUpdate : if true, the selected handler is assumed to be up to date and the stored one is just returned.
# Description
#   Returns the last selected handler of the current object
command getSelectedHandler pDontUpdate
   if pDontUpdate is not "true" then
      updateSelectedHandler
   end if
   return sLastSelectedHandler
end getSelectedHandler

# Parameters
#   pLineNumber : a line number in the current script
# Returns
#   Either the name and type of the handler if pLineNumber falls inside a handler
#   or empty. Uses revAvailableHandlers so only works with compiled scripts. Note that this function
#   assumes that the handler list has been updated before its called. This is for efficiency purposes.
private function handlerContainingLine pLineNumber
   # If we have no available handlers empty must be the correct result.
   if sHandlerList is empty then
      return empty
   end if
   
   local tHandlers
   put sHandlerList into tHandlers
   
   # Otherwise, calculate the selected handler, and return it.
   local tMatchingHandlerName, tMatchingHandlerType
   repeat for each line tHandler in tHandlers
      if word 3 of tHandler > pLineNumber then
         next repeat
      end if
      if word 4 of tHandler < pLineNumber then
         next repeat
      end if
      
      put word 2 of tHandler into tMatchingHandlerName
      put word 1 of tHandler into tMatchingHandlerType
      exit repeat
   end repeat
   
   if tMatchingHandlerName is empty then
      return empty
   end if
   
   if char 1 of tMatchingHandlerType is "P" then
      delete char 1 of tMatchingHandlerType
   end if
   
   return (tMatchingHandlerType & comma & tMatchingHandlerName)
end handlerContainingLine

# Description
#   Updates the sLastSelectedHandler variable to contain the details of the handler that was last
#   selected by the user. NOTE: this command assumes that the handler list is up to date at the time of calling.
#   If the handler list may not be up to date, use updateHandlerList to ensure it is first. The reason this is the case
#   is so that this command and updateHandlerList can both be called without needing to update the handler list twice.
private command updateSelectedHandler
   # If we have no selected line in the script field, then don't update the variable, leave the last value intact
   local tLine
   put word 2 of the selectedLine into tLine
   if tLine is empty or the long id of the focusedObject() is not the long id of getScriptField() then
      exit updateSelectedHandler
   end if
   
   local tMatchingHandler
   put item 2 of handlerContainingLine(tLine) into tMatchingHandler
   
   # For now, if the selection is outside any handler, we don't update the variable.
   if tMatchingHandler is empty then
      exit updateSelectedHandler
   end if
   
   put tMatchingHandler into sLastSelectedHandler
end updateSelectedHandler

# Description
#   Returns the handler list of the current object
command getHandlerList
   updateHandlerList
   return sHandlerList
end getHandlerList

private command updateHandlerList
   scriptCompile getObjectID()
end updateHandlerList

# Parameters
#   pObjectId : reference to the object to set the script to. Must be one of the target objects of the script editor.
# Description
#   Clears the script cache for the specified object. This should be called when the object is being closed. The cache also
#   includes selection information.
command clearCache pObject, pDontCheckId
   local tObject
   if pDontCheckId then
      put pObject into tObject
   else
      put seGetRuggedId(pObject) into tObject
   end if
   delete variable sLastSelections[tObject]
   
   pass clearCache
end clearCache

# Description
#   Locks the script to prevent the uesr from editing it. Used by the debugger.
command scriptLock
   set the lockText of field "Script" of me to true
   set the backgroundColor of field "Script" of me to sePrefGet("editor,debugBackgroundcolor")
   set the backgroundColor of  field "Handlers" of group "Left Handler List" of group "Left Bar" \
         of card "Main" of this stack to sePrefGet("editor,debugBackgroundcolor")
end scriptLock

# Description
#   Unlocks the script, allowing the user to edit it.
command scriptUnlock
   set the lockText of field "Script" of me to false
   set the backgroundColor of field "Script" of me to sePrefGet("editor,backgroundColor")
   setHandlersFieldBackColor
end scriptUnlock

# Returns
#   Whether or not the current object script is password protected.
private function scriptProtected
   # Prevent errors when editing the script editor.
   if getObjectID() is empty then
      return false
   end if
   
   local tStack
   put revTargetStack(getObjectID())  into tStack
   
   # think this may be wrong...
   --   if the passKey of stack tStack is not the password of stack tStack then
   --      return true
   --   else
   --      return false
   --   end if
   
   try
      get the script of stack tStack
      return false
   catch tError
      return true
   end try
end scriptProtected

# Description
#   Shows error indicators for the specified compilation errors
command setCompilationErrors pErrors, pObject
   send "setCompilationErrors pErrors, pObject" to group "Gutter" of me
   if seGetRuggedId(pObject) is getObjectID() then
      updateGutterRequest empty, empty, empty, empty, false, true
   end if
end setCompilationErrors

# OK-2009-03-03 : Bug 7450
# Parameters
#   pName : the name of a handler
#   pProposedPosition : the suggested start line of the handler (i.e was returned by the revAvailableHandlers)
#   pType : the handler type code (e.g "F", "PM" etc)
# Returns
#   The line number that the handler was located at, or empty if it could not be found.
command locateHandler pName, pProposedPosition, pType
   local tScript
   put the text of field "Script" of me into tScript
   
   local tStartLine
   put line pProposedPosition of tScript into tStartLine
   
   local tSyntaxOptions
   put convertTypeCodeToSyntax(pType, pName) into tSyntaxOptions
   
   # Unknown handler type, this is a bug in whatever called this command.
   if tSyntaxOptions is empty then
      return empty
   end if
   
   repeat for each line tSyntax in tSyntaxOptions
      if word 1 to (the number of words of tSyntax) of tStartLine is tSyntax and word (the number of words of tSyntax + 1) of tStartLine is pName then
         return pProposedPosition
      end if
   end repeat
   
   # If we got here, it means the handler was no longer at the location proposed. This is probably because the handler
   # was moved and at the same time the script was made invalid. We search for the handler manually instead.
   # As this case will not happen too often, it is not optimized for now.
   local tLineNumber
   put 1 into tLineNumber
   repeat for each line tLine in tScript
      repeat for each line tSyntax in tSyntaxOptions
         if word 1 to (the number of words of tSyntax) of tLine is tSyntax and word (the number of words of tSyntax + 1) of tLine is pName then
            return tLineNumber
         end if
      end repeat
      add 1 to tLineNumber
   end repeat
   
   # Could not be found, in this case the script editor will get the wrong line...
   return pProposedPosition
end locateHandler

private function convertTypeCodeToSyntax pTypeCode
   local tSyntax
   switch pTypeCode
      case "F"
         return "function"
         break
      case "PF"
         return "private function"
         break
      case "M"
         return "on" & return & "command"
         break
      case "PM"
         return "private on" & return & "private command"
         break
      case "G"
         return "getprop"
         break
      case "S"
         return "setprop"
         break
      case "B"
         return "before"
         break
      case "A"
         return "after"
         break
      default
         return empty
   end switch
end convertTypeCodeToSyntax

# Parameters
#   pObject : reference to the object to compile the script of. Must be one of the target objects.
# Description
#   Attempts to compile the specified script. Does not apply it to the target object, instead
#   creates a temporary object and attemps to set the script of that. If compilation is successful
#   stores a map of handler names to line numbers for later use.
# Returns
#   Empty if compilation suceeded, otherwise a list of errors.
command scriptCompile pObject
   lock screen
   lock messages
   
   local tOldPreserveVariables, tOldExplicitVariables
   put the preserveVariables into tOldPreserveVariables
   put the explicitVariables into tOldExplicitVariables
   set the preserveVariables to sePrefGet("preserveVariables")
   set the explicitVariables to sePrefGet("explicitVariables")
   
   local tScript
   scriptGet pObject
   put the result into tScript
   
   local tResult
   local tDoUpdateDescription
   set the script of button "revCompileObject" of me to tScript
   put the result into tResult
   -- if setting the script failed with explicit vars try without
   if tResult is not empty and the explicitVariables then
      set the explicitVariables to false
      set the script of button "revCompileObject" of me to tScript
      put the result is empty into tDoUpdateDescription
   else
      put tResult is empty into tDoUpdateDescription
   end if
   
   if tDoUpdateDescription then
      --! TODO remove use of revAvailableHandlers here (quite invasive)
      put the revAvailableHandlers of button "revCompileObject" of me into sHandlerList
      get getObjectID()
      if exists(it) and revEnvironmentEditionProperty("autocomplete") then
         ideAutocompleteUpdateScriptDescription it, the revScriptDescription of button "revCompileObject" of me
      end if
   end if
   
   local tLiveErrors
   put sePrefGet("editor,liveerrors") into tLiveErrors
   put tLiveErrors and not the lockText of field "script" of me into tLiveErrors
   
   local tState
   getDirty pObject
   if the result then
      put "edited" into tState
   else
      put "applied" into tState
   end if
   
   if tLiveErrors then
      send "clearErrors" to group "Errors" of the owner of me
      if tResult is empty then
         setCompilationErrors empty, pObject
      else
         send "addError compilation, line 1 of tResult, pObject" to group "Errors" of the owner of me
         setCompilationErrors line 1 of tResult, pObject
         put "error" into tState
      end if
   end if
   
   seSetObjectState pObject, tState
   
   set the preserveVariables to tOldPreserveVariables
   set the explicitVariables to tOldExplicitVariables
   
   # The script should be unset because it could cause issues with idle handlers
   set the script of button "revCompileObject" of me to empty
   
   unlock messages
   unlock screen
   
   return tResult
end scriptCompile


# Description
#   Shows the interactive find dialog and focuses the appropriate control for the user to enter text.
#   The dialog remains visible until the user closes it.
command goInteractiveFind
   sePrefSet "editor,findvisible", "true"
   resize
   send "openControl" to group "Interactive Find" of me
end goInteractiveFind

command hideInteractiveFind
   sePrefSet "editor,findvisible", "false"
   resize
   send "closeControl" to group "Interactive Find" of me
end hideInteractiveFind

################################################################################
#
# End of editor object interface. Code below here is part of the object's internal
# workings and should not be accessed from outside.
#
################################################################################

--local sMetricGutterSize
--local sMetricGutterNumbersMargin
--local sMetricGutterOverlayMargin

# Parameters
#   pLineNumber : the number of a line in the current script
# Returns
#   The number of line with next available for a breakpoint from pLineNumber
# Description
#   If line pLineNumber can have a breakpoint, then pLineNumber is returned.
#   Otherwise the function iterates down until it finds a line that is not in
#   a comment or a variable declaration. This does not take multi-line comments
#   into account at the moment. Returns empty if no line can be found.
function nextAvailableBreakpoint pLineNumber
   local tMatchingLineNumber
   
   local tCurrentLineNumber
   put pLineNumber - 1 into tCurrentLineNumber
   
   local tText
   put line pLineNumber to -1 of textGetScript() into tText
   
   repeat for each line tCurrentLine in tText
      add 1 to tCurrentLineNumber
      
      # Detect if the line is a comment or the line is whitespace
      if token 1 of tCurrentLine is empty then
         next repeat
      end if
      
      # Detect if the line is a variable declaration
      if token 1 of tCurrentLine is among the words of "local global" then
         next repeat
      end if
      
      put tCurrentLineNumber into tMatchingLineNumber
      exit repeat
      
      
   end repeat
   return tMatchingLineNumber
end nextAvailableBreakpoint

private function getUniqueId
   add 1 to sUniqueId
   return sUniqueId
end getUniqueId

private command gutterResize pRect
   set the rect of group "Gutter" of me to pRect
   send "resize" to group "Gutter" of me
end gutterResize

private command colorizationUpdate
   local tClasses, tKeywords
   put seColorizationConfigClasses() into tClasses
   put seColorizationConfigKeywords() into tKeywords
   
   _internal script configure classes tClasses
   _internal script configure keywords tKeywords
end colorizationupdate

# For debugging only, remove at some point
private function arrayShow pArray
   local tKeys
   put the keys of pArray into tKeys
   sort tKeys
   
   local tText
   repeat for each line tKey in tKeys
      put tKey & tab & pArray[tKey] & return after tText
   end repeat
   delete the last char of tText
   
   return tText
end arrayShow

command textInitialize
   initializeFonts
   seColorizationInit
   
   colorizationUpdate
   
   EditorFieldCacheFlushAll
   
   pass textInitialize
end textInitialize

# Description
#   Updates the gutter according to the specified parameters.
command updateGutterDo
   local tOffset, tSelectedLine, tOldLines, tNewLines, tTextChanged
   
   local tDetails
   put getUpdateGutterRequestDetails() into tDetails
   put tDetails["offset"] into tOffset
   put tDetails["selectedLine"] into tSelectedLine
   put tDetails["oldLines"] into tOldLines
   put tDetails["newLines"] into tNewLines
   put tDetails["textChanged"] into tTextChanged
   
   local tUpdateCompilationErrors
   put tDetails["updateCompilationErrors"] into tUpdateCompilationErrors
   
   local tForceBreakpointRedraw
   put tDetails["forceBreakpointRedraw"] into tForceBreakpointRedraw
   
   send "update tOffset, tSelectedLine, tOldLines, tNewLines, tTextChanged, tUpdateCompilationErrors, tForceBreakpointRedraw" to group "Gutter" of me
   
   # Once an update has been carried out, we reset the sGutterUpdateRequestDetails array
   deleteUpdateGutterRequestDetails
end updateGutterDo

################################################################################

# Description
#   Called when the script editor is about to be closed.
command finalize
   cancelPendingMessages
   
   if there is a getObjectID() then
      contextSave
   end if
   _internal script flush field "Script" of me
end finalize

# Description
#   Sets some state variables that may be needed to update the script editor panes
#   and calls the sePanesUpdate command to do the update.
command paneUpdate
   sePanesUpdate
end paneUpdate

local sLastSelectedGoneToChunk
local sLastGoneToLine

# Parameters
#   pLine : a line number to go to, from 1 up to the number of lines in the current script.
#   pHighlightMode :  How to highlight the specified line. If this is false or not specified, the line is not highlighted.
# Description
#   Goes to the specified line and highlights if required. The highlight mode is either false / empty for no highlight
#   or "select" to select the line or "color" to set the line's background color. A value of "true" is treated the same
#   as "select".
command goLine pLine, pHighlightMode, pPosition
   local tScroll
   put the vScroll of field "Script" of me into tScroll
   
   # OK-2008-08-25 : Bug 7013 - Preserve horizontal scroll
   local tHScroll
   put the hScroll of field "Script" of me into tHScroll
   
   # Select the line according to the value of pHighlight
   lock messages
   if pHighlightMode is "true" or pHighlightMode is "select" then
      select line pLine of field "Script" of me
      get the selectedChunk
      put word 2 of it & comma & word 4 of it into sLastSelectedGoneToChunk
   else if pHighlightMode is "color" then
      set the backgroundColor of line pLine of field "Script" of me to sePrefGet("editor,selectbackgroundcolor")
      local tStart
      put the number of chars of line 1 to (pLine - 1) of field "Script" of me + 1 into tStart
      put tStart & comma & tStart + the number of chars of line pLine of field "Script" of me into sLastSelectedGoneToChunk
   else if pHighlightMode is "position" then
      # OK-2009-03-03 : Bug 7550 - Allow for particular chars to be highlighted for better error display
      local tEnd
      put item 1 of pPosition into tStart
      put item 2 of pPosition into tEnd
      
      # As typically Revolution errors only have a start char, and every after that gets ignored,
      # if no end is specified, we highlight from the start char to the end of the line.
      if tEnd is empty then
         put the number of chars of line pLine of field "Script" of me into tEnd
      end if
      
      select char tStart to tEnd of line pLine of field "Script" of me
      get the selectedChunk
      put word 2 of it & comma & word 4 of it into sLastSelectedGoneToChunk
   else if pHighlightMode is "after" then
      put empty into sLastSelectedGoneToChunk
      select after line pLine of field "Script" of me
   else
      put empty into sLastSelectedGoneToChunk
      select before line pLine of field "Script" of me
   end if
   unlock messages
   
   # Scroll until the line is centred (assumes fixed line height)
   if the vScroll of field "Script" of me > tScroll then
      # The field has scrolled down in order to show the selection, therefore
      # we need to make it scroll down again to centre it.
      set the vScroll of field "Script" of me to the vScroll of field "Script" of me + round(the height of field "Script" of me / 2)
   else if the vScroll of field "Script" of me < tScroll then
      # The field has scrolled up in order to show the selection, therefore
      # we need to make it scroll up again to centre it.
      set the vScroll of field "Script" of me to the vScroll of field "Script" of me - round(the height of field "Script" of me / 2)
   end if
   
   set the hScroll of field "Script" of me to tHScroll
   
   put pLine into sLastGoneToLine
   
   updateGutterRequest empty, empty, empty, empty, false, false
end goLine

function getLastGoneToLine
   return sLastGoneToLine
end getLastGoneToLine

# Description
#   Deselects the last line that was selected by the goLine command if there was one
#   and it is still selected.
command deselectLastGoneToLine
   lock screen
   get the selectedChunk
   -- MM-2012-06-20: [[ Bug 10027 ]] Make sure there was a last line selected - causes bugs deselects elsewhere within the IDE.
   if sLastSelectedGoneToChunk is not empty and word 2 of it is item 1 of sLastSelectedGoneToChunk and word 4 of it is item 2 of sLastSelectedGoneToChunk then
      
      lock messages
      local tSelobj
      put revIDESelectedObjects() into tSelobj
      select empty
      if tSelobj is not the long id of field "Script" of me then
         revIDESelectObjects tSelobj
      end if
      set the backgroundColor of char (item 1 of sLastSelectedGoneToChunk) to (item 2 of sLastSelectedGoneToChunk) of field "Script" of me to empty
      unlock messages
      
   end if
   put empty into sLastSelectedGoneToChunk
   
   # We update the gutter here to remove the current line indicator
   updateGutterRequest empty, empty, empty, empty, false, false
   unlock screen
end deselectLastGoneToLine


################################################################################

local sDefinitionMatches

private command prepareContextMenu
   local tSelectedText
   put getClickText() into tSelectedText
   
   local tLine, tSelectedHandler
   put word 2 of the selectedLine into tLine
   if tLine is not empty then
      put handlerContainingLine(tLine) into tSelectedHandler
   end if
   
   local tObject
   getObject
   put the result into tObject
   
   local tMatches
   put seMatchingDefinitions(tSelectedText, tObject, tSelectedHandler) into tMatches
   
   put tMatches into sDefinitionMatches
   
   local tGoToDefinition
   put "Go to definition" into tGoToDefinition
   if tMatches is empty then
      put "(" before tGoToDefinition
   end if
   
   local tText
   put tGoToDefinition & return into tText
   put "Find in" & return after tText
   
   if not revIDEBrowserWidgetUnavailable() then
      put tab & "Docs" & return after tText
   end if
   
   repeat for each item tItem in \
         "Current Tab,All Tabs,Card,Stack,Stack File,Stack File and its stackFiles,All Stack Files,All available stacks"
      put tab & tItem & return after tText
   end repeat
   put "-" & return after tText
   
   put "Set Breakpoint" & return after tText
   put "-" & return after tText
   
   if scriptLocked() then
      put "(Cut" & return & \
             "Copy" & return & \
             "(Paste" after tText
   else
      put"Cut" & return & \
             "Copy" & return & \
             "Paste" after tText
   end if
   
   if the last char of tText is not return then
      put return after tText
   end if
   
   -- Dispatch a hook into the message path to customize the context menu
   local tModifiedText
   dispatch "revHookBuildScriptEditorContextMenu" to me with (the long id of tObject), tSelectedText, tText, tModifiedText
   if it is not "handled" then
      put tText into tModifiedText
   end if
   
   set the text of button "Context Menu" of me to tModifiedText
end prepareContextMenu

################################################################################

local sLastClickLine

on mouseDown pButtonNumber
   put word 2 of the clickLine into sLastClickLine
   if pButtonNumber <> 3 or the long id of the target is not the long id of field "Script" of me then
      pass mouseDown
   end if
   
   prepareContextMenu
   showContextMenu
   pass mouseDown
end mouseDown

private command showContextMenu
   popup button "Context Menu" of me
end showContextMenu

on menuPick pItemName   
   if the long id of the target is not the long id of button "Context Menu" of me then
      pass menuPick
   end if
   
   -- Dispatch a hook into the message path to give first action to any customizations
   dispatch "revHookScriptEditorContextMenuPick" to me with pItemName
   if it is "handled" then
      exit menuPick
   end if
   
   set the itemDelimiter to "|"
   
   switch item 1 of pItemName
      case "Set Breakpoint"
         if sLastClickLine is not empty then
            local tScript
            put textGetScript() into tScript
            
            local tLineNumber
            put revDebuggerNextAvailableBreakpoint(tScript, sLastClickLine - 1) into tLineNumber
            
            revDebuggerAddBreakpoint getObjectID(), tLineNumber
            revDebuggerActivateBreakpoint getObjectID(), tLineNumber
            updateGutterRequest empty, empty, empty, empty, false, false, true
         end if
         break
         
      case "Find in"
         
         local tCallback
         put "__FindAllCallback" into tCallback
         
         local tCallbackTarget
         put the long id of me into tCallbackTarget
         
         local tText
         put getClickText() into tText
         
         local tTarget
         switch item 2 of pItemName
            case "Docs"
               local tData
               put ideDocsFetchLCSData(tText) into tData
               if tData is not empty then
                  revIDEGoToLCSDictionaryEntry tText, tData[1]["type"]
               end if
               break
            case "All tabs"
               put "all" into tTarget
               break
            case "Current Tab"
               put "current" into tTarget
               break
            case "Card"
               put "card" into tTarget
               break
            case "Stack"
               put "stack" into tTarget
               break
            case "Stack File"
               put "stack file" into tTarget
               break
            case "All Stack Files"
               put "all stacks" into tTarget
               break
            case "Stack File and its stackFiles"
               put "stack file and stackfiles" into tTarget
               break
            case "All available stacks"
               put "all available stacks" into tTarget
               break
         end switch
         if item 2 of pItemName is not "Docs" then
            send "revSEFindAll tText, false, false, false, true, tTarget, tCallback, tCallbackTarget" to this stack
         end if
         break
      case "Cut"
         actionCut
         break
         
      case "Copy"
         actionCopy
         break
         
      case "Paste"
         actionPaste
         break
         
      case "Go to definition"
         local tMatches
         put sDefinitionMatches into tMatches
         if tMatches is empty then
            exit menuPick
         end if
         
         if the number of lines of tMatches > 1 then
            set the cSymbols of getDisambiguatorObject() to tMatches
            send "update" to getDisambiguatorObject()
            modal getDisambiguatorObject()
            
            local tResult
            put the cResult of getDisambiguatorObject() into tResult
            if tResult is empty then
               exit menuPick
            end if
            
            goMatchingDefinition tResult
         else
            goMatchingDefinition tMatches
         end if
         
         break
   end switch
end menuPick

on __FindAllCallback pMessage
   wait 0 with messages
   set the cursor to busy
end __FindAllCallback

private command goMatchingDefinition pMatch
   local tObject, tLine
   put item 5 to -1 of pMatch into tObject
   
   put item 4 of pMatch into tLine
   
   revSEGoExecutionPoint tObject, tLine, true, true
end goMatchingDefinition


private function getDisambiguatorObject
   return the long id of stack "revSEDisambiguator"
end getDisambiguatorObject

on exitField
   -- OK-2008-07-10 : Check that an object is loaded before attemping to save context,
   -- this is prevent annoying errors from ocurring when editing the IDE.
   if getObjectID() is not empty then
      contextSave
   end if
   pass exitField
end exitField

on closeField
   -- OK-2008-07-10 : Check that an object is loaded before attemping to save context,
   -- this is prevent annoying errors from ocurring when editing the IDE.
   if getObjectID() is not empty then
      contextSave
   end if
   pass closeField
end closeField


################################################################################
#
# Find and replace code
#
################################################################################

-- Marcus note:
-- I have implemented the search a little different now.
-- in branch 4a, the search is done once, and an index into the result maintained.
-- The problem with this seems twofold:
-- * the user edits the field directly, bypassing replace (this should be possible)
-- * the next/previous finds do not start from the current caret, but rather the index into the
--   current search results. This could be fixed by calculating the correct position, based on the caret
--   using the results.

-- A solution to point 1 could be to distinguish between a find/replace edit, and any other edit.
-- This way, we could know when a search was to be refreshed.

-- Ultimately, the only reason for implementing this as such is speed. It should be more efficient as the
-- search would not need to be repeated. It appears, however, that using matchChunk is indeed fast enough
-- so I have rewritten the code in THIS branch, to do a new search when next or previous is hit.
-- Next search: find from the current caret position: we only need ONE result, as this would be done each time
--              this is then selected, and the replaceonce function simply changes the selection
-- Previous search: the inverse of next search: this time we also require ONE index, but then as close to the caret
--                  as possible.
-- General search: a find is really just a showNext: find the first occurence, so this will be linked as such.

-- Replace all: find the entire list of occurences, and replace them, one by one.
-- One issue: what about "nested" results, such as "ginging", which one to replace, etc. We will work around this
-- by making a choice: either the first or last one. Xcode chooses the last one, so so will we. This question
-- is especially important when we consider regular expressions. The replaceRaw handler will replace character
-- selections starting at the end of the text, going up. It will only do a replacement, if the range is not found
-- to intersect any of the ranges coming after it (looking at the text).

local sFindResults
local sFindResultIndex
local sFindUpdateRequired
local sFindQuery
local sFindRestart
local sLastFindLocation
local sFirstFindLocation

private function escapeString pString, pUseWildCard
   replace "\" with "\\" in pString
   replace "^" with "\^" in pString
   replace "$" with "\$" in pString
   replace "[" with "\[" in pString
   replace "]" with "\]" in pString
   replace "{" with "\{" in pString
   replace "}" with "\}" in pString
   replace ")" with "\)" in pString
   replace "(" with "\(" in pString
   replace "|" with "\|" in pString
   replace "-" with "\-" in pString
   
   # OK-2009-01-17 : Bug 7611 - Periods must be replaced as they match any char otherwise
   replace "." with "\." in pString
   
   if pUseWildCard then
      replace "*" with ".*" in pString
   else
      replace "*" with "\*" in pString
   end if
   replace "+" with "\+" in pString
   replace "?" with "\?" in pString
   return pString
end escapeString

command findInitialize
   put empty into sFindQuery
   put empty into sFindResults
   findClearResults
end findInitialize


-- the following is a seperate attempt at a find function
-- addition: pGlobal, flag which if true causes all results to be returned in a return delimited list.
-- if false, only the first available result between (and inclusive) pStartFrom and pEndAt is returned.
private command findText pText, pGlobal, pStartFrom, pEndAt, pSearch
   local tResult, tRegExp
   
   put empty into sFindUpdateRequired
   
   # Clear previous search results
   findClearResults
   
   if pSearch["query"] is empty then
      return empty
   end if
   
   -- findText works via a regular expression. Thus, anything that comes in is transformed into one.
   if pSearch["regexp"] then
      put "(" & pSearch["query"] & ")" into tRegExp
   else
      put "(" into tRegExp
      put escapeString(pSearch["query"], pSearch["wildcard"]) into pSearch["query"]
      if pSearch["ignorecase"] then
         put "(?i)" after tRegExp
      end if
      if pSearch["wholematches"] then
         put "\b" before pSearch["query"]
         put "\b" after pSearch["query"]
      end if
      put pSearch["query"] & ")" after tRegExp
   end if
   
   local tStart, tEnd, tFrom, tTo, tText
   
   put pText into tText
   
   if pStartFrom is empty or pStartFrom <= 1 then
      put 1 into tFrom
   else
      put pStartFrom into tFrom
   end if
   if pEndAt is empty then
      put the number of chars of tText into tTo
   else
      put pEndAt into tTo
   end if
   repeat forever
      try
         if matchChunk(char tFrom to tTo of tText, tRegExp, tStart, tEnd) then
            put tStart + tFrom - 1,tEnd + tFrom - 1 & return after tResult
            if not pGlobal then -- we have one result, we're happy
               exit repeat
            end if
            add tEnd to tFrom
            if tFrom > tTo then
               exit repeat
            end if
         else
            -- no match, exit
            exit repeat
         end if
      catch tError
         put "invalid regular expression." into tResult
         exit repeat
      end try
   end repeat
   delete the last char of tResult
   return tResult
end findText

command findFinalize pResult
   findClearResults
   put false into sFindRestart -- we just did a search..
   put pResult into sFindResults
end findFinalize

# Parameters
#   pStart : the first char of the found chunk to mark
#   pEnd : the last char of the found chunk to mark
#   pInteractive : whether the search was in interactive mode or not.
# Description
#   Marks the specified chunk of text as found. This must be done using other means than selecting
#   the chunk because of interactive search which finds text as the user types.
command findMarkResult pStart, pEnd, pInteractive
   set the backgroundColor of char pStart to pEnd of field "Script" of me to sePrefGet("editor,findcolor")
   
   # If using interactive search, we can't select the find text, because doing so will take the 
   # selection away from the search field while the user is probably still typing in it, otherwise this is ok.
   if not pInteractive then
      lock messages
      select char pStart to pEnd of field "Script" of me
      unlock messages
   end if
   
   # As the search results are shown with a backgroundcolor instead of a selection,
   # the field must be automatically scrolled to show the currently hilited result.
   # The field is scrolled by the minimum amount required to bring the current search
   # result fully into view.
   local tHeight
   put the formattedHeight of char 1 to pEnd of field "Script" of me into tHeight
   
   # If tHeight is before the beginning of the visible area then scroll back until its the first line
   local tScroll
   if the vScroll of field "Script" of me > tHeight then
      put tHeight - (the effective textHeight of field "Script" of me + the topMargin of field "Script" of me) into tScroll
   end if
   
   # If tHeight is after the end of the visible area then scroll forward until its the last line
   if the vScroll of field "Script" of me + the height of field "Script" of me < (tHeight + the textHeight of field "Script" of me) then
      local tBottomMargin
      if the hScrollbar of field "Script" of me then
         put the scrollbarWidth of field "Script" of me + the bottomMargin of field "Script" of me into tBottomMargin
      else
         put the bottomMargin of field "Script" of me into tBottomMargin
      end if
      
      put tHeight - the height of field "Script" of me + (the effective textHeight of field "Script" of me + tBottomMargin) into tScroll
   end if
   
   if tScroll is not empty then
      set the vScroll of field "Script" of me to tScroll
   end if
   
   if sFirstFindObject is empty then
      put getObjectID() into sFirstFindObject
   end if
   
   if sFirstFindLocation is empty or pInteractive then
      put pStart & comma & pEnd into sFirstFindLocation
   end if
   
   # OK-2008-07-28 : Bug 6846 - Showing find results can cause the script editor field to scroll,
   # which can put the line numbers out of sync with the script, in order to fix this we send a gutter
   # update request here.
   updateGutterRequest empty, empty, empty, empty, false, true
   
   # OK-2009-02-20: Bug 7732 - The left bar needs updating as showing a find result can change the current handler.
   local tFalseString
   put false into tFalseString
   send "update tFalseString" to group "Left Bar" of stack (revTargetStack(the long id of me))
   
   put getObjectID() into sLastFindObject
   put pStart & comma & pEnd into sLastFindLocation
end findMarkResult


# Parameters
#   pInteractive : whether the search was in interactive mode or not.
command findClearResults pInteractive
   put empty into sLastFindObject
   if sLastFindLocation is not empty then
      put empty into sLastFindLocation
      set the backgroundColor of char 1 to -1 of field "Script" of me to empty
   end if
end findClearResults

# Parameters
#   pTarget : either "all" or "current"- which tabs to search
#   pDirection : either "forward" or "backward" (Currently ignored as backward is not yet needed)
# Returns
#   The list of objects that a search with the specified target and direction should loop through,
#   in order. Item 1 of the returned list should always be the current object.
private function findObjectList pTarget, pDirection, pCallback, pCallbackTarget, @rCancelled
   local tObjectList
   if pTarget is "all" then
      revSEGetTargetObjects
      put the result into tObjectList
      
      if the number of lines of tObjectList <> 1 then
         # Sort the object list so that tabs are cycled through in order, starting with current object
         local tLineNumber
         set the wholeMatches to true
         put lineOffset(seGetRuggedId(getObjectID()), tObjectList) into tLineNumber
         set the wholeMatches to false
         
         local tReorderedObjectList
         repeat for each line tObject in line tLineNumber to -1 of tObjectList
            put tObject & return after tReorderedObjectList
         end repeat
         
         repeat for each line tObject in line 1 to (tLineNumber - 1) of tObjectList
            put tObject & return after tReorderedObjectList
         end repeat
         delete the last char of tReorderedObjectList
         put tReorderedObjectList into tObjectList
      end if
      
   else if pTarget is "card" then
      # This will search the card of the script editor's current object. This means the card itself
      # and all objects on it.
      put findListObjectsOnCard(getObjectID()) into tObjectList
   else if pTarget is "stack" then
      # Searches the stack of the sript editor's current object. This means the stack script itself,
      # and all other objects in the stack, including all cards but not substacks.
      put findListObjectsOnStack(getObjectID()) into tObjectList
   else if pTarget is "stack file" then
      # As with "stack" except also searches all stacks in the same file.
      put findListObjectsOnStackAndSubstacks(getObjectID(), false, pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "all stacks" then
      # Searches all stacks and substacks in memory
      put findListObjectsOnAllStacksAndSubstacks(pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "stack file and stackfiles" then
      # As for "stack file" except also searches all available stacks in the stackFiles property
      put findListObjectsOnStackAndSubstacks(getObjectID(), true, pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "all available stacks" then
      # Searches all stacks and substacks in memory and all stackFiles. Note this is not recursive at the moment, i.e
      # stackFiles of stackFiles are not searched.
      put findListObjectsOnAllAvailableStacks(pCallback, pCallbackTarget, rCancelled) into tObjectList
   else
      put getObjectID() into tObjectList
   end if
   
   if tObjectList is an array then
      combine tObjectList with return as set
   end if
   
   return tObjectList
end findObjectList

private function findGetObjectOwner pObject, pType
   # Start with the object itself
   local tObject
   put revRuggedId(pObject) into tObject
   
   repeat
      # First check if the current object is of the type we want, if so, return it
      if pType is "card" and word 1 of the name of tObject is "card" then
         return the long id of tObject
      end if
      if pType is "stack" and word 1 of the name of tObject is "stack" then
         return the long id of tObject
      end if
      
      # If the object has no owner we can't continue, this can only happen if the caller requests the card that owns a stack,
      # so is a bug.
      if the owner of tObject is empty then
         exit repeat
      end if
      
      # This means the object was not of the type we wanted, but it does have an owner, so we check its owner.
      put revRuggedId(the long owner of tObject) into tObject
   end repeat
   
   # Should never get here...
end findGetObjectOwner

private function findListObjectsOnCard pObject
   # Get the card associated with the current object. This is either the current card if pObject is a stack,
   # pObject if pObject is a card, and the card owning pObject otherwise.
   local tCard
   if word 1 of the name of pObject is "stack" then
      put revRuggedId(the long id of this card of pObject) into tCard
   else
      put findGetObjectOwner(pObject, "card") into tCard
   end if
   
   # List the controls owned by the card
   local tList
   get revIDEListSearchObjectTree(tCard, false, empty, false, true, true, tList)
   return tList
end findListObjectsOnCard

private function findListObjectsOnStack pObject
   # Get the stack associated with the current object. This is either pObject if pObject is a stack,
   # or the stack owning pObject otherwise.
   local tStack
   if word 1 of the name of pObject is "stack" then
      put pObject into tStack
   else
      put findGetObjectOwner(pObject, "stack") into tStack
   end if
   
   # List the controls owned by the stack
   local tList
   get revIDEListSearchObjectTree(tStack, false, empty, false, true, true, tList)
   return tList
end findListObjectsOnStack

private function findListObjectsOnStackAndSubstacks pObject, pIncludeStackfiles, pCallback, pCallbackTarget, @rCancelled
   # Get the mainstack associated with the curernt object. This is either pObject if pObject is already a mainstack,
   # or the owning mainstack of pObject otherwise.
   local tMainstack
   if the owner of pObject is empty then
      put pObject into tMainstack
   else
      local tParentStack
      put findGetObjectOwner(pObject, "stack") into tParentStack
      
      if the mainstack of tParentStack is the short name of tParentStack then
         put tParentStack into tMainstack
      else
         put revRuggedId(the long id of stack (the mainstack of tParentStack)) into tMainstack
      end if
   end if
   
   findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tMainstack)
   if the result is "cancel" then
      put the result into rCancelled
      return empty
   end if
   
   # List the controls owned by the stack and its substacks
   local tList
   get revIDEListSearchObjectTree(tMainstack, false, empty, true, true, true, tList)
   
   # If pIncludeStackFiles is true, list all the stackfiles as well.
   if pIncludeStackFiles then
      repeat for each line tStackFile in the stackFiles of tMainstack
         local tPath
         put resolveStackFilePath(item 2 to -1 of tStackFile, tMainstack) into tPath
         
         lock messages
         if there is a stack tPath then
            findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tPath)
            if the result is "cancel" then
               put the result into rCancelled
               return empty
            end if
            
            get revIDEListSearchObjectTree(the name of stack tPath, false, empty, true, true, true, tList)
         end if
         unlock messages
         
      end repeat
   end if
   
   return tList
end findListObjectsOnStackAndSubstacks

private function resolveStackFilePath pFilename, pMainstack
   local tFilename
   if pathIsRelative(pFilename) then
      set the itemDelimiter to slash
      put item 1 to -2 of the filename of pMainstack & slash & pFilename into tFilename
   else
      put pFilename into tFilename
   end if
   return tFilename
end resolveStackFilePath

private function stackFileIsInMemory pFilename
   repeat for each line tMainstack in the mainstacks
      if the filename of stack tMainstack is pFilename then
         return true
      end if
   end repeat
   return false
end stackFileIsInMemory

private function pathIsRelative pPath
   # On Windows, an absolute path begins with a drive letter and a colon, anything else
   # is relative.
   if seGetPlatform() is "win32" then
      if char 1 of pPath is among the chars of "ABCDEFGHIJKLMNOPQRSTUVWXYZ" and char 2 of pPath is ":" then
         return false
      else
         return true
      end if
   else
      # On OS X and Linux, an absolute path begins with a slash, anything else is relative
      if char 1 of pPath is "/" then
         return false
      else
         return true
      end if
   end if
end pathIsRelative

private function findListObjectsOnAllAvailableStacks pCallback, pCallbackTarget, @rCancelled
   # Searching only stacks that are actually open seems not too useful, so the script editor will
   # search all stacks in memory.
   local tMainstacks
   put ideMainStacks() into tMainstacks
   
   local tStackFiles
   
   local tList
   repeat for each line tMainstack in tMainstacks
      
      findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tMainstack)
      if the result is "cancel" then
         put the result into rCancelled
         return empty
      end if
      
      get revIDEListSearchObjectTree(the name of stack tMainstack, false, empty, true, true, true, tList)
      
      # Next search the stackFiles property. Note here that a stack in the stackFiles may also be in the mainstacks
      # if it happens to be open, so we skip these to avoid searching them twice.
      repeat for each line tStackFile in the stackFiles of stack tMainstack
         local tPath
         put resolveStackFilePath(item 2 to -1 of tStackFile, the name of stack tMainstack) into tPath
         
         if tStackFiles[tPath] then
            next repeat
         end if
         
         local tIsInMemory
         put stackFileIsInMemory(tPath, the name of stack tMainstack) into tIsInMemory
         if tIsInMemory then
            next repeat
         end if
         
         lock messages
         if there is a stack tPath then
            findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tPath)
            if the result is "cancel" then
               put the result into rCancelled
               return empty
            end if
            
            get revIDEListSearchObjectTree(the name of stack tPath, false, empty, true, true, true, tList)
            
         end if
         
         put true into tStackFiles[tPath]
         
         unlock messages
      end repeat
   end repeat
   
   return tList
end findListObjectsOnAllAvailableStacks

private function findListObjectsOnAllStacksAndSubstacks pCallback, pCallbackTarget, @rCancelled
   # Searching only stacks that are actually open seems not too useful, so the script editor will
   # search all stacks in memory.
   local tMainstacks
   put ideMainStacks() into tMainstacks
   
   local tList
   repeat for each line tMainstack in tMainstacks
      findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tMainstack)
      if the result is "cancel" then
         put the result into rCancelled
         return empty
      end if
      
      get revIDEListSearchObjectTree(the name of stack tMainstack, false, empty, true, true, true, tList)
   end repeat
   
   return tList
end findListObjectsOnAllStacksAndSubstacks

private function findDefaultSearch
   local tQuery
   put line 1 of seFindHistoryGet("find") into tQuery
   if tQuery is empty then
      return empty
   end if
   
   local tSearch
   put tQuery into tSearch["query"]
   put not sePrefGet("find,casesensitive") into tSearch["ignorecase"]
   put sePrefGet("find,wholematches") into tSearch["wholematches"]
   put sePrefGet("find,regularexpressions") into tSearch["regexp"]
   put true into tSearch["wildcard"]
   
   return tSearch
end findDefaultSearch

# Parameters
#   (same as showNextFindResult and showPreviousFindResult) +:
#   pDirection : forward or backward
#   pScript : the script to search in, this is not changed, its a reference for efficiency.
# Returns
#   An array describing the search specified by the parameters. If pQuery is empty, attempts to retrieve the
#   last built search and return this. If no last built search is available then returns empty. The array is saved
#   in the script local sFindQuery.
private function findBuildSearch pQuery, pIsRegExp, pUseWildcard, pWholeMatch, pIgnoreCase, pInteractive, pTarget, pDirection, @pScript
   if pQuery is empty then
      
      # OK-2008-08-12 : Bug 6893 - If no search string was specified then check to see if one of the two search fields are active.
      local tFocusedObject
      put the long id of the focusedObject into tFocusedObject
      
      local tStack
      put revTargetStack(tFocusedObject) into tStack
      
      if tStack is "revSEFind" then
         send "getSearchString" to stack "revSEFind"
         put the result into sFindQuery["query"]
      else if sePrefGet("editor,findvisible") then
         send "getSearchString" to group "Interactive Find" of me
         put the result into sFindQuery["query"]
      else if sFindQuery["query"] is empty then
         put findDefaultSearch() into sFindQuery
         return sFindQuery
      end if
      
      # OK-2009-06-19 : Bug 8111 - Changing the case does not have to reset the search completely,
      # instead we just check here to make sure we are searching using the current preference setting.
      put not sePrefGet("find,casesensitive") into sFindQuery["ignorecase"]
      
   else
      put pQuery into sFindQuery["query"]
      put pIsRegExp into sFindQuery["regexp"]
      put pUseWildCard into sFindQuery["wildcard"]
      put pWholeMatch into sFindQuery["wholematches"]
      put pIgnoreCase into sFindQuery["ignorecase"]
   end if
   
   # Calculate the initial start and end for the search.
   local tLastFindLocation
   if sLastFindObject is not empty and seGetRuggedId(sLastFindObject) is seGetRuggedId(getObjectID()) then
      put sLastFindLocation into tLastFindLocation
   end if
   
   # OK-2008-10-22 : Bug 7343 - Use getLastSelectedChunk instead of the actual selectedChunk,
   # because by the time we reach this point, the user is probably typing in the search field, so
   # the selectedChunk will not relate to the correct field anymore.
   local tLastSelectedChunk
   getLastSelectedChunk
   put the result into tLastSelectedChunk
   
   if pDirection is "forward" then
      # Starts the search from the selection point if there was no previous search
      # to continue.
      local tSearchStart
      if tLastFindLocation is empty then
         get tLastSelectedChunk
         if item 1 of it > item 2 of it then
            put item 1 of it into tSearchStart
         else if it is empty then
            put 1 into tSearchStart
         else
            put item 1 of it + 1 into tSearchStart
         end if
      else
         # In interactive search, we begin search at the *same* location as the previous search
         # in non-interactive search, we begin just after it.
         if pInteractive then
            put item 1 of tLastFindLocation into tSearchStart
         else
            put item 1 of tLastFindLocation + 1 into tSearchStart
         end if
      end if
      
      local tEnd
      put the number of chars of pScript into tEnd
   end if
   
   if pDirection is "backward" then
      -- Problem: regular expression matching goes from left to right :(.
      -- So, at least for the time being (or if time is a problem) we implement this
      -- by doing a global search from the start, taking the last result.
      if sLastFindLocation is empty then
         get tLastSelectedChunk
         if item 1 of it > item 2 of it then
            put item 1 of it into tEnd
         else if it is empty then
            put the number of chars of pScript into tEnd
         else
            put item 1 of it + 1 into tEnd
         end if
      else
         # OK-2009-10-12 : Bug 8331 - Searching backwards was broken for words less than 3 letters due to the error below.
         --put item 1 of sLastFindLocation + 1 into tEnd
         put item 1 of sLastFindLocation - 1 into tEnd
         
      end if
      
      put 1 into tSearchStart
   end if
   
   put tEnd into sFindQuery["end"]
   put tSearchStart into sFindquery["start"]
   
   # Store the initial start of the search separately so we can check if the search
   # loops back on itself.
   if (not pInteractive and pQuery is not empty) or (pInteractive and sFindQuery["initialstart"] is empty) then
      put tSearchStart into sFindQuery["initialstart"]
   end if
   
   return sFindQuery
end findBuildSearch


# Parameters
#   pQuery : the search pattern
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether to use wildcards or not
#   pWholeMatch : whether to match whole words only
#   pIgnoreCase : whether to perform a case insensitive search or not
#   pInterative : whether the search is in interative mode or not
#   pTarget : either "all" or "current"- which tabs to search in.
# Description
#   Performs a search operation on the script field and marks the result to show it to the user.
#   Interactive mode is designed for updating the search as the user types, in this case it is
#   expected that pQuery will change each time, and each search will begin at the same location
#   as the previous one began. In normal mode, it is expected that pQuery will remain the same
#   between successive searches, and each search will begin just after the previous one.
#   If pQuery is empty, it is assumed that the user wants to search for the next result with all the
#   same parameters as the previous search carried it.
command showNextFindResult pQuery, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pInteractive, pTarget
   local tObjectList, tCancelled
   put findObjectList(pTarget, "forward", empty, empty, tCancelled) into tObjectList
   
   local tScript
   put textGetScript() into tScript
   
   local tSearch
   put findBuildSearch(pQuery, pIsRegExp, pUseWildcards, pWholeMatch, pIgnoreCase, pInteractive, pTarget, "forward", tScript) into tSearch
   if tSearch["query"] is empty then
      goInteractiveFind
      exit showNextFindResult
   end if
   
   seFindHistoryAdd "find", tSearch["query"]
   
   lock screen
   local tStart
   repeat for each line tObject in tObjectList
      if seGetRuggedId(tObject) is not seGetRuggedId(getObjectID()) then
         revSESetCurrentObject tObject, empty, true
         put 1 into tStart
      else
         if sLastFindLocation is empty then
            # Must be the first iteration
            put tSearch["start"] into tStart
         else
            # Calculate a new search start
            if sLastFindObject is not empty and seGetRuggedId(sLastFindObject) is seGetRuggedId(getObjectID()) and sLastFindLocation is not empty then
               if pInteractive then
                  put item 2 of sLastFindLocation into tStart
               else
                  put item 1 of sLastFindLocation + 1 into tStart
               end if
            else
               put 1 into tStart
            end if
         end if
      end if
      
      local tResult
      findText tScript, false, tStart, tSearch["end"], tSearch
      if the result is not empty then
         put the result into tResult
         unlock screen
         
         if tResult is sFirstFindLocation and getObjectID() is sFirstFindObject then
            --beep
         end if
         
         findMarkResult item 1 of tResult, item 2 of tResult, pInteractive
         exit repeat
      end if
   end repeat
   
   if tResult is empty then
      revSESetCurrentObject (line 1 of tObjectList), empty, true
   end if
   
   if tResult is empty and tSearch["start"] > 1 then
      # If we found no results, but the search did not start at the beginning of the text, then
      # we do another search from the beginning up to where we started the previous one.
      findText textGetScript(), false, 1, tSearch["start"], tSearch
      put the result into tResult
      
      if tResult is sFirstFindLocation and getObjectID() is sFirstFindObject then
         --beep
      end if
      
      if tResult is not empty then
         findMarkResult item 1 of tResult, item 2 of tResult, pInteractive
      else
         beep
      end if
   end if
   unlock screen
end showNextFindResult

# Parameters
#   pQuery : the search pattern
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether to use wildcards or not
#   pWholeMatch : whether to match whole words only
#   pIgnoreCase : whether to perform a case insensitive search or not
#   pTarget : either "all" or "current"- which tabs to search in. (Currently this is ignored)
command showPreviousFindResult pQuery, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget
   local tScript
   put textGetScript() into tScript
   
   local tSearch
   put findBuildSearch(pQuery, pIsRegExp, pUseWildcards, pWholeMatch, pIgnoreCase, false, pTarget, "backward", tScript) into tSearch
   if tSearch["query"] is empty then
      exit showPreviousFindResult
   end if
   
   seFindHistoryAdd "find", tSearch["query"]
   
   local tResult
   findText tScript, true, tSearch["start"], tSearch["end"], tSearch
   if the result is not empty then
      put line -1 of the result into tResult
      findMarkResult item 1 of tResult, item 2 of tResult
   else if tSearch["end"] < the number of chars of tScript then
      # If we found no results, but the search did not run to the end of the text, then
      # we do another search from where we finished, to the end
      findText tScript, true, tSearch["end"], the number of chars of tScript, tSearch
      put line -1 of the result into tResult
      if tResult is not empty then
         findMarkResult item 1 of tResult, item 2 of tResult
      else
         beep
      end if
   end if
end showPreviousFindResult

private command findDispatchCallback pCallback, pCallbackTarget, pMessage
   if pCallback is empty then
      return empty
   end if
   
   local tResult
   try
      send pCallback && "pMessage" to pCallbackTarget
      put the result into tResult
   end try
   
   return tResult
end findDispatchCallback

command showAllFindResults pQuery, pIsRegExp, pUseWildCards, pWholeMatches, pIgnoreCase, pTarget, pCallback, pCallbackTarget
   findDispatchCallback pCallback, pCallbackTarget, "Calculating list of objects to search"
   if the result is "cancel" then
      exit showAllFindResults
   end if
   
   local tOldMainstacks
   put ideMainStacks() into tOldMainstacks
   
   # Calculate the list of objects to search in
   local tObjectList, tCancelled
   put findObjectList(pTarget, "forward", pCallback, pCallbackTarget, tCancelled) into tObjectList
   if tCancelled then
      exit showAllFindResults
   end if
   
   # Note that with a global search we don't build a search using findBuildSearch. This is because global
   # searches cannot be continued, so we don't want to save the search or allow a previous one to be started.
   local tSearch
   put pQuery into tSearch["query"]
   put pIsRegExp into tSearch["regexp"]
   put pUseWildcards into tSearch["wildcard"]
   put pWholeMatches into tSearch["wholematches"]
   put pIgnoreCase into tSearch["ignorecase"]
   
   if tSearch["query"] is empty then
      exit showAllFindResults
   end if
   
   seFindHistoryAdd "find", tSearch["query"]
   
   local tFormattedResults
   
   # Format the results for display
   put pQuery & return into tFormattedResults
   
   local tDescription
   switch pTarget
      case "all"
         put "all tabs" into tDescription
         break
      case "current"
         put "current tab" into tDescription
         break
      case "card"
         put "current card" into tDescription
         break
      case "stack"
         put "current stack" into tDescription
         break
      case "stack file"
         put "current stack file" into tDescription
         break
      case "all stacks"
         put "all stack files" into tDescription
         break
      case "stack file and stackfiles"
         put "stack file and its stack files" into tDescription
         break
      case "all available stacks"
         put "all available stacks" into tDescription
         break
      default
         put "current" into tDescription
   end switch
   
   put tDescription & return after tFormattedResults
   
   local tObjectCount = 0
   local tFoundCount = 0
   
   local tTotalObjects
   put the number of lines of tObjectList into tTotalObjects
   # Execute the search
   local tGlobalResults, tResults
   repeat for each line tObject in tObjectList
      # OK-2009-04-21 : It seems to be possible for objects to be deleted between listing them and searching them,
      # in this case, we have little option but to skip the object.
      if there is no tObject then
         next repeat
      end if
      
      if pCallback is not empty then
         # Pass the rugged id to the callback, as this form is quite compact, despite not being the most readable.
         add 1 to tObjectCount
         findDispatchCallback pCallback, pCallbackTarget, "Search results found:" && tFoundCount && "with" && round(tObjectCount / tTotalObjects * 100) & "% complete"
         if the result is "cancel" then
            sePrefSet "editor,lastsearchresults", tFormattedResults & tGlobalResults
            send "setCurrentTab Search Results" to group "Pane Tabs" of seStackId() in 0
            exit showAllFindResults
         end if
      end if
      
      local tScript
      scriptGet tObject
      put the result into tScript
      
      findText tScript, true, 1, the number of chars of tScript, tSearch
      put the result into tResults
      if tResults is not empty then
         repeat for each line tResult in tResults
            add 1 to tFoundCount
            local tLineNumber
            put the number of lines of char 1 to (item 1 of tResult) of tScript into tLineNumber
            put tObject & tab & tLineNumber & tab & item 1 of tResult & tab & item 2 of tResult & tab & line tLineNumber of tScript & return after tGlobalResults
         end repeat
      end if
   end repeat
   
   send "expandCurrentPane" to group "Panes" of seStackId()
   send "refreshCurrentPane" to group "Panes" of seStackId()
   
   local tNewMainstacks
   put ideMainStacks() into tNewMainstacks
   
   if pCallback is not empty then
      findDispatchCallback pCallback, pCallbackTarget, "Total results found:" && tFoundCount 
   end if
   
   sePrefSet "editor,lastsearchresults", tFormattedResults & tGlobalResults
   send "setCurrentTab Search Results" to group "Pane Tabs" of seStackId() in 0
   
   repeat for each line tStack in tNewMainstacks
      if tStack is not among the lines of tOldMainstacks then
         lock messages
         delete stack tStack
         unlock messages
      end if
   end repeat
end showAllFindResults

command replaceOnce pString
   local tFrom, tTo
   put item 1 of sLastFindLocation into tFrom
   put item 2 of sLastFindLocation into tTo
   
   if tFrom is empty or tTo is empty then
      exit replaceOnce
   end if
   
   seFindHistoryAdd "replace", pString
   
   local tAt, tLength
   put tFrom into tAt
   
   textBeginGroup "Replace"
   textReplace tAt, char tFrom to tTo of textGetScript(), pString, , , true
   
   # OK-2009-02-16 : Bug 7712 - Return information about the replaced text so that in a the context of replaceOnceAndFind, we can ensure
   # that the replaced text does not get searched.
   return (tFrom + the length of pString)
end replaceOnce

command replaceOnceAndFind pQuery, pString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget
   # OK-2009-02-16 : Bug 7712 - replaceOnce modified to return the last char of the replaced string. We should ensure
   # that the next find result doesn't happen until after this.
   local tLastReplacedChar
   replaceOnce pString
   put the result into tLastReplacedChar
   
   # We should be able to move the start of the search by changing the sLastFindLocation script local,
   # this is clearly a bit of a hack, but hopefully doing is this way will minimize the risk.
   put tLastReplacedChar + 1 & comma & tLastReplacedChar into sLastFindLocation
   
   showNextFindResult pQuery, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, false, pTarget
end replaceOnceAndFind

command replaceAll pQuery, pString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget, pCallback, pCallbackTarget
   # Calculate the list of objects to search in. The order is not important so we loop forwards
   # through the objects.
   local tObjectList, tCancelled
   put findObjectList(pTarget, "forward", pCallback, pCallbackTarget, tCancelled) into tObjectList
   if tCancelled then
      # Search cancelled before any replacements carried out
      return 0
   end if
   
   local tSearch
   put pQuery into tSearch["query"]
   put pIsRegExp into tSearch["regexp"]
   put pUseWildcards into tSearch["wildcard"]
   put pWholeMatch into tSearch["wholematches"]
   put pIgnoreCase into tSearch["ignorecase"]
   
   if tSearch["query"] is empty then
      exit replaceAll
   end if
   
   seFindHistoryAdd "replace", pString
   
   local tReplacementCount
   put 0 into tReplacementCount
   
   repeat for each line tObject in tObjectList
      if pCallback is not empty then
         findDispatchCallback pCallback, pCallbackTarget, "Replacing: " & revRuggedId(the long id of tObject)
         if the result is "cancel" then
            return tReplacementCount
         end if
      end if
      
      local tScript
      scriptGet tObject
      put the result into tScript
      
      local tResults
      findText tScript, true, 1, "", tSearch
      put the result into tResults
      
      # Move to next object if no search results found
      if tResults is empty then
         next repeat
      end if
      
      # Build the replacements into a single operation so it can be undone
      local tAt, tNewText, tOldText
      replaceBuildSingleOperation tScript, tResults, pString, tAt, tNewText, tOldText
      
      # Perform the replacement operation on the object. There are three options here:
      # 1. tObject is the current script being edited. In this case we replace using the standard undo system and flag the script as modified
      # 2. tObject is open in the script editor, but non-current. Here we do a raw replacmenet on the object's cached script and synthesize the undo information
      #     meaning that the operation can still be undone when the replaced object's tab is opened.
      # 3. tObject is not open in the script editor. In this situation, we replace directly on the object's script and apply it, ignoring any errors. This cannot be undone.
      local tTargetObjects
      revSEGetTargetObjects
      put the result into tTargetObjects
      if seGetRuggedId(tObject) is among the lines of tTargetObjects then
         textReplace tAt, tOldText, tNewText, seGetRuggedId(tObject)
         add the number of lines of tResults to tReplacementCount
      else
         # We assume that the script can be opened here, as otherwise it would have not been searchable so we shouldn't have got here.
         local tReplaceScript
         put the script of tObject into tReplaceScript
         textReplaceRawInVariable tReplaceScript, tAt, tOldText, tNewText
         
         # Setting the script may fail if the object is executing code or has some property set that doesn't allow this.
         # If it fails, we simply skip past this one without incrementing the replacement count.
         try
            set the script of tObject to tReplaceScript
            add the number of lines of tResults to tReplacementCount
         end try
      end if
   end repeat
   
   # OK-2009-03-03 : Bug 7538 - Return the number of replacements made so that the calling dialog can display it
   return tReplacementCount
end replaceAll

# Parameters
#   pScript : the script that the replacements are to be done in
#   pResults : a list of the chunks to be replaced
#   pString : the string to replace each chunk with
#   rAt : set to the start of the resulting operation
#   rNewText : set to the new text of the resulting operation
#   rOldText : set to the old text of the resulting operation
# Description
#   Given a list of replacements and the script to replace in, returns the specification of a
#   single replacement operation that performs the equivalent of all the individual replacements.
private command replaceBuildSingleOperation pScript, pResults, pString, @rAt, @rNewText, @rOldText
   local tResults
   put pResults into tResults
   sort tResults numeric descending by item 1 of each
   
   # The resulting operation starts at the beginning of the first result
   put item 1 of line -1 of tResults into rAt
   
   # The old text is from rAt to the end of the last match
   put char rAt to (item 2 of line 1 of tResults) of pScript into rOldText
   
   local tNewText
   put rOldText into tNewText
   repeat for each line tResult in tResults
      put pString into char (item 1 of tResult - rAt + 1) to (item 2 of tResult -rAt + 1) of tNewText
   end repeat
   
   put tNewText into rNewText
end replaceBuildSingleOperation

# Stores requests to update the tooltip so that pending requests can be cancelled if new ones come about
local sTooltipUpdateRequest

# How often to update the tooltip. The reason for this delay is that the tooltip update is triggered by mouseMove
# so we can't update it every time or it would be too slow.
constant kTooltipUpdateDelay = 10

# The number of array keys to display in tooltips
constant kTooltipArrayKeyCount = 17

on mouseMove
   tooltipUpdateCancel
   tooltipReset
   send "tooltipUpdate" to me in kTooltipUpdateDelay milliseconds
   put the result into sTooltipUpdateRequest
   pass mouseMove
end mouseMove

on mouseLeave
   tooltipUpdateCancel
   pass mouseLeave
end mouseLeave

# Description
#   Updates the tooltip of the script field to match the token that the mouse is over.
#   If we are in edit mode, this command has no effect, if we're in debug mode, the tooltip is set
#   to contain the value of the variable the mouse is over (if its over one).
command tooltipUpdate
   # For now, tooltips are limited to debug mode- where we know the script has been compiled.
   local tMode
   revSEGetMode
   put the result into tMode
   if tMode is not "debug" then
      exit tooltipUpdate
   end if
   
   local tLine
   put word 2 of the mouseLine into tLine
   
   local tHandler
   put handlerContainingLine(tLine) into tHandler
   
   # Get the list of variables available for either the handler the mouse is in, or the script.
   local tVariables
   if tHandler is empty then
      put the revAvailableVariables of getObjectID() into tVariables
   else
      put the revAvailableVariables[tHandler] of getObjectID() into tVariables
   end if
   
   # "Flatten" the list of variables- we don't care if they are locals, parameters, globals etc.
   replace return with comma in tVariables
   put replaceText(tVariables, ",+", ",") into tVariables
   
   # From the mouseChunk, work out the possible name of the variable the mouse is over
   local tMouseVariable
   put getSelectedVariable(word 2 of the mouseChunk, word 4 of the mouseChunk) into tMouseVariable
   
   # Check that tMouseVariable is one of the available variable names
   if tMouseVariable is empty or tMouseVariable is not among the items of tVariables then
      exit tooltipUpdate
   end if
   
   # There is a special case here if gREVDevelopment is true.  In this case the debugger only filters out debug contexts
   # that are in the debugger, or called by the debugger. However the current context, i.e. this handler is are neither of these things, 
   # and so is not filtered out. However because it calls debugger functions,  we have to manually adjust the context here 
   # to make sure its correct.
   global gREVDevelopment
   if gREVDevelopment then
      local tContexts
      put revDebuggerContexts() into tContexts
      
      # Note that the calls here to revDebuggerGetcontext() and revDebuggerContexts() in the IF condition
      # have to be on the same line otherwise they won't match properly (because the line number will have changed).
      if revDebuggerGetContext() is line 1 of revDebuggerContexts() then
         revDebuggerSetContext line 2 of revDebuggerContexts()
      end if
   end if
   
   local tContext
   put seGetDebugContext() into tContext
   
   # Find out if the variable is an array
   local tKeys
   put revDebuggerGetKeys(tMouseVariable, tContext) into tKeys
   
   # Get its value in the curent debug context from the debugger. Truncate to make sure we don't try and 
   # display very large variables and format it for the tooltip.
   local tValue
   if tKeys is empty then
      put tooltipTruncateValue(revDebuggerGetValue(tMouseVariable, tContext, empty, empty), empty, 500) into tValue
   else
      repeat for each line tKey in line 1 to kTooltipArrayKeyCount of tKeys
         --local tExpression
         --put tMouseVariable & "[" & quote & tKey & quote & "]" into tExpression
         local tElementList
         put tKey into tElementList[1]
         put tKey & " = " & tooltipTruncateValue(revDebuggerGetValue(tMouseVariable, tContext, tElementList, empty), 1, 200) & return after tValue
      end repeat
      delete the last char of tValue
   end if
   
   local tTooltip
   put tMouseVariable & ": " into tTooltip
   if the number of lines of tValue > 1 then
      put return after tTooltip
   end if
   put tValue after tTooltip
   
   # Display the tooltip
   tooltipDisplay tTooltip
end tooltipUpdate

# Parameters
#   pValue : the string to truncate
#   pLines : the number of lines to truncate it to
#   pChars : the number of chars to truncate it to
# Returns
#   A substring of pValue truncated first to pLines, and then the remainder truncated to pChars.
#   If the value was truncated, then "..." will be appended to it.
private function tooltipTruncateValue pValue, pLines, pChars
   local tTruncationNeeded
   if pLines is not empty and the number of lines of pValue > pLines then
      put true into tTruncationNeeded
   end if
   
   if pChars is not empty and the number of chars of line 1 to pLines of pValue > (pChars - 3) then
      put true into tTruncationNeeded
   end if
   
   local tValue
   if pLines is not empty then
      put line 1 to pLines of pValue into tValue
   else
      put pValue into tValue
   end if
   
   if pChars is not empty then
      put char 1 to (pChars - 3) of tValue into tValue
   end if
   
   if tTruncationNeeded then
      put "..." after tValue
   end if
   
   return tValue
end tooltipTruncateValue

# Parameters
#   pText : the text to display as a tooltip
# Description
#   Sets the tooltip of the script field to pText
private command tooltipDisplay pText
   local tText
   put char 1 to 500 of pText into tText
   set the tooltip of field "Script" of me to tText
end tooltipDisplay

# Parameters
#   pStart : the first char of the mouseText
#   pEnd : the last char of the mouseText
# Returns
#   What the value of the mouseText would be if it included the chars in kVariablePunctuators in words.
#   Basically this means if the user is mousing over a variable name, the full name of that variable should be returned.
private function getSelectedVariable pStart, pEnd
   if pStart is empty then
      return empty
   end if
   
   # Expand the start of the chunk backwards until a non-valid char is found
   local tStart
   put pStart into tStart
   repeat with x = (pStart - 1) down to 1
      if charAllowedInVariableName(char x of field "Script" of me) then
         subtract 1 from tStart
      else
         exit repeat
      end if
   end repeat
   
   # Expand the end forwards until a non-valid char is found
   local tEnd
   put pEnd into tEnd
   repeat with x = (pEnd + 1) to the number of chars of field "Script" of me
      if charAllowedInVariableName(char x of field "Script" of me) then
         add 1 to tEnd
      else
         exit repeat
      end if
   end repeat
   
   return char tStart to tEnd of field "Script" of me
end getSelectedVariable

# These are the non alpha-numeric characters that Revolution allows in variable names.
constant kVariablePunctuators = "£$_`@'?."

# Parameters
#   pChar : a single character
# Returns
#   Whether or not pChar is allowed in a Revolution variable name
private function charAllowedInVariableName pChar
   # Numbers are allowed
   if pChar is a number then
      return true
   end if
   
   local tAsciiValue
   put charToNum(pChar) into tAsciiValue
   
   # Upper case letters
   if tAsciiValue >= 65 and tAsciiValue <= 90 then
      return true
   end if
   
   # Lower case letters
   if tAsciiValue >= 97 and tAsciiValue <= 122 then
      return true
   end if
   
   # And finally the punctuators
   if pChar is among the chars of kVariablePunctuators then
      return true
   end if
   
   return false
end charAllowedInVariableName

# Description
#   Resets the tooltip of the script field. Called when the user has moved the mouse away from any variable names.
private command tooltipReset
   set the tooltip of field "Script" of me to empty
end tooltipReset

# Description
#   Cancels a request to update the tooltip. This is called when the user moves the mouse away from any variable name.
private command tooltipUpdateCancel
   if sTooltipUpdateRequest is not empty then
      cancel sTooltipUpdateRequest
   end if
   put empty into sTooltipUpdateRequest
end tooltipUpdateCancel

----------------------------------------------------------------
-- Editor field cache
----------------------------------------------------------------

-- Setting up an editor field is very expensive, especially for
-- particularly large scripts (1000s of lines).  In order to speed up
-- switching between tabs, for example, the editor field itself is
-- cached.

constant kScriptEditorMaxCached = 10

local sScriptEditorFieldCache

/*
Remove the editor field for pRuggedObjectId from the cache
*/
private command __EditorFieldCacheFlush pRuggedObjectId
   local tField
   put sScriptEditorFieldCache[pRuggedObjectId] into tField
   if tField is empty then
      exit __EditorFieldCacheFlush
   end if
   if the name of field tField of me is "Script" then
      exit __EditorFieldCacheFlush
   end if

   lock messages
   delete field tField of me
   unlock messages

   delete variable sScriptEditorFieldCache[pRuggedObjectId]
end __EditorFieldCacheFlush

/*
Delete all cached editing fields
*/
private command EditorFieldCacheFlushAll
   local tRuggedObjectId
   -- Mutating a collection while iterating over it...!
   repeat for each key tRuggedObjectId in sScriptEditorFieldCache
      __EditorFieldCacheFlush tRuggedObjectId
   end repeat
end EditorFieldCacheFlushAll

/*
If there are too many editor fields cached, randomly purge one of
them.  Note that because the current editor field isn't in the cache, there
is no danger of incorrectly deleting it.
*/
private command __EditorFieldCacheFlushExcess
   local tCacheSize
   put the number of elements in sScriptEditorFieldCache into tCacheSize
   if tCacheSize < kScriptEditorMaxCached then
      exit __EditorFieldCacheFlushExcess
   end if

   -- Flush a random field from the cache
   put the random of tCacheSize into tCacheSize

   local tRuggedObjectId
   repeat for each key tRuggedObjectId in sScriptEditorFieldCache
      if tCacheSize is 1 then
         __EditorFieldCacheFlush tRuggedObjectId
         exit __EditorFieldCacheFlushExcess
      end if
      subtract 1 from tCacheSize
   end repeat
end __EditorFieldCacheFlushExcess

/*
Check whether pRuggedObjectId has a cached editing field.
*/
private function __EditorFieldIsCached pRuggedObjectId
   return pRuggedObjectId is among the keys of sScriptEditorFieldCache
end __EditorFieldIsCached

/*
Switch from editing pOldRuggedObjectId to editing pNewRuggedObjectId,
swapping or caching editor fields as required.
*/
private command EditorFieldCacheSwap pOldRuggedObjectId, pNewRuggedObjectId
   if pOldRuggedObjectId is empty or \
      pNewRuggedObjectId is empty or \
      pOldRuggedObjectId is pNewRuggedObjectId then
      exit EditorFieldCacheSwap
   end if

   local tCachedName
   put "Script for" && pOldRuggedObjectId into tCachedName

   if __EditorFieldIsCached(pNewRuggedObjectId) then

      -- If the script that the script editor is switching to already
      -- has a script editing field cached, add the current field to
      -- the cache and replace it with the new object's field.

      lock messages
      set the name of field "Script" of me to tCachedName
      set the visible of field tCachedName of me to false
      unlock messages

      put tCachedName into sScriptEditorFieldCache[pOldRuggedObjectId]

      put sScriptEditorFieldCache[pNewRuggedObjectId] into tCachedName

      lock messages
      set the visible of field tCachedName of me to true
      set the name of field tCachedName of me to "Script"
      unlock messages

      delete variable sScriptEditorFieldCache[pNewRuggedObjectId]

   else

      -- Otherwise, just copy the current field into the cache for the
      -- old object

      lock messages
      clone invisible field "Script" of me
      relayer it before field "Script" of me
      set the name of it to tCachedName
      unlock messages

      put tCachedName into sScriptEditorFieldCache[pOldRuggedObjectId]
   end if

   -- Make sure the number of cached fields stays reasonable.  This
   -- helps cope with objects being deleted or their script editor
   -- tabs being closed, without leaking memory into expensive unused
   -- controls.
   __EditorFieldCacheFlushExcess
end EditorFieldCacheSwap

# Parameters
#   pRootObject : the object to list the tree for, this is a reference to any LiveCode object
#   pIncludeSubstacks : if pRootObject is a mainstack, this determines whether or not its substacks are searched. Otherwise its ignored.
# Returns
#   Empty if all possible objects were returned, otherwise a warning string explaining why some / all were ommited.
# Description
#   rList will be set to the list of objects underneath the root object. This is inclusive, i.e. it includes pRootObject.
#   If pRootObject is a mainstack, the stack will be searched, followed by all mainstacks if pIncludeSubstacks is true.
#   If pRootObject is a stack, the object list is the stack, all its cards, and all objects on each card
#   If pRootObject is a card the list is the card and all objects on it
#   If pRootObject is any other control, the list is pRootObject.
function revIDEListSearchObjectTree pRootObject, pObeyDontSearch, pMarked, pIncludeSubstacks, pIgnorePasswordProtected, pScriptsOnly, @xList
   --delete variable sAddedObjects
   
   # Put the root object into the list first. If this is not possible because to dontSearch or card marking then
   # return an error and put empty into the list. What might also happen is that one of the child objects
   # as its dontSearch set to true. In this case, we'll return a partial list.
   if pObeyDontSearch and word 1 of the name of pRootObject is among the words of "field group card" and the dontSearch of pRootObject then
      return "dontSearch of root object set"
   end if
   
   # Set the HCAddressing property of the owning stack of pRootObject to false, as this will mess
   # up everything otherwise.
   local tOldHCAddressing
   put the hcAddressing of stack revTargetStack(pRootObject) into tOldHCAddressing
   set the hcAddressing of stack revTargetStack(pRootObject) to false
   
   # If the root object is a mainstack, we add the stack itself, then all its substacks if applicable
   local tResult
   switch word 1 of pRootObject
      case "stack"
         if the mainstack of pRootObject is the short name of pRootObject and pIncludeSubstacks then
            addStack pRootObject, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
            put the result into tResult
            
            repeat for each line tSubstack in the substacks of pRootObject
               local tSubstackResult
               addStack the name of stack tSubstack, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
               put the result into tSubstackResult
               if tResult is empty then
                  put tSubstackResult into tResult
               end if
            end repeat
         else
            # If its not a mainstack, or we're not adding substacks, just add the stack
            addStack pRootObject, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
            put the result into tResult
         end if 
         break
      case "card"
         # If its a card then add the card and all its controls
         addCard pRootObject, pObeyDontSearch, pMarked, xList, pScriptsOnly
         put the result into tResult
         break
      case "group"
         # If its a group then add the group and all its control
         addGroup pRootObject, pObeyDontSearch, xList, pScriptsOnly
         put the result into tResult
         break
      default
         # All other objects, i.e non-containers, just add the single object to the list.
         addObject pRootObject, pObeyDontSearch, xList, pScriptsOnly
         put the result into tResult
         break
   end switch
   
   set the hcAddressing of stack revTargetStack(pRootObject) to tOldHCAddressing
   
   return tResult
end revIDEListSearchObjectTree

private command addObject pObject, pObeyDontSearch, @xList, pScriptsOnly
   if pObeyDontSearch and word 1 of the name of pObject is among the words of "card group field" and the dontSearch of pObject then
      return "dontSearch set on object"
   end if
   
   if not pScriptsOnly or the script of pObject is not empty then
      put true into xList[the long id of pObject]
   end if
   
   local tBehavior
   put the behavior of pObject into tBehavior
   repeat while exists(tBehavior)
      put true into xList[the long id of tBehavior]
      put the behavior of tBehavior into tBehavior
   end repeat
   
   return empty
end addObject

private command addCard pCard, pObeyDontSearch, pMarked, @xList, pScriptsOnly
   if pMarked is not empty and pMarked is not the mark of pCard then
      return "marked mismatch"
   end if
   
   # Add the card itself
   local tResult
   addObject pCard, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   # Add the non-grouped controls
   local tObjectResult
   local tControlID
   repeat for each line tControlID in the childControlIDs of pCard
      # Don't add groups
      if word 1 of the name of control id tControlID of pCard is among the words of "group bkgnd" then
         next repeat
      end if
      
      # Don't add grouped controls
      if the owner of control id tControlID of pCard is not empty and word 1 of the name of the owner of control id tControlID of pCard is among the words of "group bkgnd" then
         next repeat
      end if
      
      addObject the long id of control id tControlID of pCard, pObeyDontSearch, xList, pScriptsOnly
      put the result into tObjectResult
      
      if tResult is empty then
         put tObjectResult into tResult
      end if
   end repeat
   
   # Add any groups.
   local tGroup, tGroupResult
   local tID
   repeat for each line tId in the groupIds of pCard
      put the long id of group id tId of pCard into tGroup
      if the sharedBehavior of tGroup then
         next repeat
      end if
      
      # Note that if a group on the card does not have its backgroundBehavior set, but is placed on multiple cards,
      # it will be duplicated in the list. I'm not sure if this is correct or not...
      addGroup tGroup, pObeyDontSearch, xList, pScriptsOnly
      put the result into tGroupResult
      
      if tResult is empty then
         put tGroupResult into tResult
      end if
   end repeat
   
   return tResult
end addCard

private command addGroup pGroup, pObeyDontSearch, @xList, pScriptsOnly
   if pObeyDontSearch and the dontSearch of pGroup then
      return "dontSearch set on group"
   end if
   
   local tResult
   addObject pGroup, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   local tObjectResult
   local tControlID
   repeat for each line tControlID in the controlIDs of pGroup
      addObject the long id of control id tControlID of pGroup, pObeyDontSearch, xList, pScriptsOnly
      put the result into tObjectResult
      
      if tResult is empty then
         put tObjectResult into tResult
      end if
   end repeat
   
   return tResult
end addGroup

private command addStack pStack, pObeyDontSearch, pMarked, pIgnorePasswordProtected, @xList, pScriptsOnly
   local tResult
   
   if pIgnorePasswordProtected then
      try
         get the script of pStack
      catch tError
         return "Stack password protected"
      end try
   end if
   
   # The stack itself
   addObject pStack, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   # All shared groups groups on the stack
   local tSharedGroupResult
   local tGroupID
   repeat for each line tGroupID in the sharedGroupIDs of pStack
      addGroup the long id of control id tGroupID of pStack, pObeyDontSearch, xList, pScriptsOnly
      put the result into tSharedGroupResult
      
      if tResult is empty then
         put tSharedGroupResult into tResult
      end if
   end repeat
   
   # All the cards on the stack
   local tCardResult
   local tCardID
   repeat for each line tCardID in the cardIDs of pStack
      addCard the long id of card id tCardID of pStack, pObeyDontSearch, pMarked, xList, pScriptsOnly
      put the result into tCardResult
      
      if tResult is empty then
         put tCardResult into tResult
      end if
   end repeat
   
   return tResult
end addStack
