script "revSEStackBehavior"

on setBehaviors
   set the behavior of group "Editor" of me to the long id of stack revIDEScriptEditorBehavior("editor")
   set the behavior of group "Menubar" of me to the long id of stack revIDEScriptEditorBehavior("menubar")
   set the behavior of group "Script Tabs" me to the long id of stack revIDEScriptEditorBehavior("scripttabs")
   set the behavior of group "Toolbar" of me to the long id of stack revIDEScriptEditorBehavior("toolbar")
   set the behavior of group "Handler List" of me to the long id of stack revIDEScriptEditorBehavior("handlerlist")
   set the behavior of group "Left Bar" of me to the long id of stack revIDEScriptEditorBehavior("leftbar")
   set the behavior of field "Filter" of group "Left Bar" of me to the long id of stack revIDEScriptEditorBehavior("filterfield")
   set the behavior of group "Variables" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("variablespane")
   set the behavior of group "Documentation" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("documentationpane")
   set the behavior of group "Breakpoints" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("breakpointpane")
   set the behavior of group "Errors" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("errorspane")
   set the behavior of field "Filter" of group "Variables" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("filterfield")
   set the behavior of button "Show Globals" of group "Variables" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("variablescheckbox")
   set the behavior of button "Show Environment Vars" of group "Variables" of group "Panes" of me to the long id of stack revIDEScriptEditorBehavior("variablescheckbox")
   set the behavior of group "Gutter" of group "Editor" of me to the long id of stack revIDEScriptEditorBehavior("gutter")
   set the behavior of group "Interactive Find" of group "Editor" of me to the long id of stack revIDEScriptEditorBehavior("interactive find")
   set the behavior of stack "revSEEditBreakpoint" of me to the long id of stack revIDEScriptEditorBehavior("edit breakpoint")
   set the behavior of group "Error Template" of card "Templates" of me to the long id of stack revIDEScriptEditorBehavior("error template")
   set the behavior of stack revIDEScriptEditorBehavior("editor") to the long id of stack revIDEScriptEditorBehavior("common editor")
   set the behavior of card "main" of stack "revSEFind" to the long id of stack revIDEScriptEditorBehavior("find main card")
end setBehaviors

# Which metadata type to store the script editor data as.
constant kMetadataType = "general"


# Stores the last execution point shown by the revSEGoExecutionPoint command. This is
# used when coming out of debug mode to deselect the highilighted line if the user has
# not changed it.
local sLastShownExecutionPoint

################################################################################
#
# Script editor interface. These are the commands that the script editor makes available
# to the IDE. Please do not send any message or call any command outside this section.
# All script editor interface commands are prefixed with revSE.
#
#################################################################################

# Parameters
#   pObject : reference to an object that is being edited by this script editor
#   pStartingLine : optional line number to seek to.
# Description
#   Sets the current object to edit to pObject. If pStartingLine is given, then seeks to that line
#   otherwise seeks to the last selected line.
command revSESetCurrentObject pObject, pStartingLine, pDontSendCallbacks
   lock screen
   
   revSEGetCurrentObject
   if the result is not empty and the long id of pObject is the long id of the result then
       exit revSESetCurrentObject
   end if
   # Check that pObject is one of the target objects, if not then just do nothing
   local tTargetObjects
   revSEGetTargetObjects
   put the result into tTargetObjects
   
   local tObject
   put seGetRuggedId(pObject) into tObject
   
   if tObject is not among the lines of tTargetObjects then
      exit revSESetCurrentObject
   end if
   
   # OK-2009-03-16 : Bug 6620
   # Don't allow this to be aborted halfway through or the script editor may be broken.
   local tOldAllowInterrupts
   put the allowInterrupts into tOldAllowInterrupts
   set the allowInterrupts to false
   
   # Tell the tabs group to highlight the tab associated with pObject
   call "setCurrentTab tObject" to group "Script Tabs" of me
   call "setObject tObject, pDontSendCallbacks" to group "Editor" of me
   
   # After a new object has been set we need to update the toolbar, as the compile, undo and redo buttons need to be
   # updated.
   call "update" to group "Toolbar" of me
   dispatch "update" to group "Left Bar" of me with false, true
   
   seUpdateWindowTitle tObject
   set the allowInterrupts to tOldAllowInterrupts
   unlock screen
end revSESetCurrentObject

# Description
#   Returns the object currently being edited
command revSEGetCurrentObject
   local tObject
   call "getCurrentTab" to group "Script Tabs" of me
   put the result into tObject
   return tObject
end revSEGetCurrentObject

# Description
#   Returns a list of scripts being edited
command revSEGetTargetObjects
   local tObjects
   send "listTabs" to group "Script Tabs" of me
   put the result into tObjects
   return tObjects
end revSEGetTargetObjects

# Parameters
#   pObject : reference to any object
# Description
#   Adds the specified object to this script editor as a new tab. Does not automatically set the newly
#   added object as the current object, this must be done with a call to revSESetCurrentObject.
command revSEAddTargetObject pObject
   # If the object is already present in revSEGetTargetObjects then just don't do anything,
   # its up to the caller to decide if the object should be set as current or not.
   local tTargetObjects
   revSEGetTargetObjects
   put the result into tTargetObjects
   
   local tObject
   put seGetRuggedId(pObject) into tObject
   
   if tObject is among the lines of tTargetObjects then
      exit revSEAddTargetObject
   end if
   
   enable group "Editor" of me
   
   # Add a tab for the new object.
   call "addTab pObject" to group "Script Tabs" of me
   
   # Add the new object to the script editor history
   seHistoryAdd pObject
   
   # OK-2008-10-14 : Bug 7235 - Ensure that the object's checksum is saved as soon as its
   # added to the script editor.
   # OK-2008-11-24 : Bug 7477 - If the object is on a password protected stack, this could throw an error,
   # we catch this, and simply don't set the checksum here. Instead it will be set when the script is unlocked.
   try
      local tScript
      put the script of tObject into tScript
      seUpdateChecksum tObject, tScript
   end try
end revSEAddTargetObject

# Parameters
#   pObject : reference to the object to remove
#   pDontWarn : whether or not to warn the user of losing unapplied changes (optional, defaults to false)
#   pDontCloseIfLast : optional, defaults to false. If true, then the script editor will not be closed when the last tab is deleted.
#   pDontChangeTab : optional, defaults to false, If true, then the script editor will not attempt to change tabs after removing the object
# Description
#   Removes the specified object from this script editor. If the removed object is the current
#   editing object, then changes the current object to the last selected object.
command revSERemoveTargetObject pObject, pDontWarn, pDontCloseIfLast, pDontChangeTab
   local tState
   put seGetObjectState(pObject) into tState
   if pDontWarn is not true and (tState is "edited" or (tState is "error" and revIDEObjectIsOnIDEStack(pObject))) then
      revSEWarnBeforeClosing pObject
      if the result is "cancel" then
         exit revSERemoveTargetObject
      end if
   end if
   
   # Remove the object's tab from the script tabs group. The group will automatically select the
   # appropriate tab after attempting to remove pObject, so we simply update the editor to make
   # sure it matches the newly selected tab. Note that if pObject is not found, this will just have
   # no effect.
   local tTrueString
   put "true" into tTrueString
   send "removeTab pObject, tTrueString" to group "Script Tabs" of me
   
   # Notify the IDE
   revIDEStopEditingScriptOfObjects pObject
   
   local tCurrentTab
   send "getCurrentTab" to group "Script Tabs" of me
   put the result into tCurrentTab
   
   if tCurrentTab is not empty then
      if pDontChangeTab is not "true" then
         send "setObject tCurrentTab" to group "Editor" of me
         seUpdateWindowTitle tCurrentTab
         
         # OK-2010-02-24: Bug 8388 - Update left handler list when removing object
         seUpdateLeftBar
      end if
   else 
      if pDontCloseIfLast is "true" then
         # re-initialize the script editor. This situation can happen if the script editor is reload objects in response to a 
         # script being externally modified. The editor group must clear its state variables in order to cleanly reload the object.
         send "initialize" to group "Editor" of me
      else
         # This means the last tab has been closed. In this case, we just close the script editor.
         seFinalize
         
         send "revSEDeleteSubStack the long id of me" to stack (the mainstack of me) in 0 milliseconds
         close me
      end if
   end if
   
   # Note that the cache for the old object is removed after the object has been changed to the new one,
   # this is because changing the object in normal circumstances saves the cache of the previous object. Here however
   # we wish the cache to be cleared because we are removing the object rather than just switching tabs.
   send "clearCache pObject, tTrueString" to group "Editor" of me
   
   if there is a pObject then
      seSetObjectState pObject, "applied"
   else   
      # OK-2008-09-11 : Only cancel pending messages if the object no longer exists, otherwise 
      # gutter updates will be lost without cause.
      # Any pending messages must be cancelled as they may refer to the deleted object
      send "cancelPendingMessages" to group "Editor" of me
   end if
end revSERemoveTargetObject

local sMode

# Description
#   Returns the current mode of this script editor. The possible options are
#   "edit" and "debug".
command revSEGetMode
   # The mode will be stored in a script local variable, just return this.
   if sMode is empty then
      put "edit" into sMode
   end if
   
   return sMode
end revSEGetMode

# Parameters
#   pMode : the mode to set to, either "edit" or "debug"
# Description
#   Sets the mode of this script editor.
command revSESetMode pMode
   # Note, sMode should be set first because the various update messages
   # sent to components may check the mode, and we want them to update
   # according to the new mode, not the old one.
   put pMode into sMode
   
   if pMode is "edit" then
      send "scriptUnlock" to group "Editor" of me
      
      # This means if a line was selected by the debugger to show the user where the current
      # execution point was, it will be deselected here. If the user selected something themselves,
      # this will not be effected.
      send "deselectLastGoneToLine" to group "Editor" of me
      
      sePrefSet "debug,lastcontext", empty
   end if
   
   if pMode is "debug" then
      send "scriptLock" to group "Editor" of me
   end if
   
   # If in debug mode, we default to the variables pane for convenience
   local tLastSelectedPane
   if pMode is "Debug" then
      put "Variables" into tLastSelectedPane
   else
      put sePrefGet(pMode & ",lastSelectedPane") into tLastSelectedPane
   end if
   
   # Update the window title
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   if tObject is not empty then
      seUpdateWindowTitle tObject
   end if
   
   send "setCurrentTab tLastSelectedPane" to group "Pane Tabs" of me
   send "update" to group "Toolbar" of me
   
   actionResizeStack
end revSESetMode

# Parameters
#   pPrefsChanged : whether or not the script editor preferences have changed or not, if empty, assumes they *have* changed.
# Description
#   Updates the script editor menu, toolbar and panes etc in response to something
#   changing, eg execution context.
command revSEUpdate pPrefsChanged
   # Reinitialize the preferences in case they have been changed
   if pPrefsChanged is not "false" then
      sePrefInit
   end if
   
   # If the debug context has changed, update it
   --   if sMode is "debug" then
   --      local tCurrentContext
   --      put line 1 of seDebugContexts() into tCurrentContext
   --      sePrefSet "debug,lastcontext", tCurrentContext
   --   end if
   
   send "update" to group "Toolbar" of me
   send "refreshCurrentPane" to group "Panes" of me
   
   # Breakpoints might have been disabled or removed, so update the gutter
   local tEmptyString
   put empty into tEmptyString
   
   local tTrueString
   put "true" into tTrueString
   
   local tFalseString
   put "false" into tFalseString
   
   send "updateGutterRequest tEmptyString, tEmptyString, tEmptyString, tEmptyString, tFalseString, tFalseString, tTrueString"  to group "Editor" of me
   
   if pPrefsChanged is not "false" then
      seUpdateLeftBar
      send "reapplyPreferences" to group "Editor" of of me
      send "reapplyPreferences" to group "Variables" of me
   end if
end revSEUpdate

# Parameters
#   pObject : reference to the object executing. Must be an open object in the script editor.
#   pLine : the line number to go to
#   pHighlight : whether to highlight the line or not
#   pOpenIfNeeded : if true, the open is opened by the script editor if required.
# Description
#   Goes to the execution point specified by pObject and pLine. The line is highlighted
#   if pHighlight is true. If pObject is not one of the current target objects does nothing.
command revSEGoExecutionPoint pObject, pLine, pHighlight, pOpenIfNeeded
   local tTargetObjects
   revSEGetTargetObjects
   put the result into tTargetObjects
   
   local tObject
   put seGetRuggedId(pObject) into tObject
   if tObject is not among the lines of tTargetObjects then
      # Either open tObject or do nothing
      if pOpenIfNeeded then
         revSEAddTargetObject tObject
      else
         exit revSEGoExecutionPoint
      end if
   end if
   
   revSESetCurrentObject tObject
   send "goLine pLine, pHighlight" to group "Editor" of me
   put pLine into sLastShownExecutionPoint
end revSEGoExecutionPoint

# Description
#   Returns the last selected string in the editor group
command revSEGetLastSelection
   send "getLastSelection" to group "Editor" of me
   return the result
end revSEGetlastSelection

command revSEGetLastSelectedWord
   send "getLastSelectedWord" to group "Editor" of me
   return the result
end revSEGetLastSelectedWord

# Description
#   Initializes the script editor's find system. Should be called before beginning a search.
command revSEFindInitialize
   send "findInitialize" to group "Editor" of me
end revSEFindInitialize

# Description
#   Finalizes the script editor's find system. Should be called when a search is finished
command revSEFindFinalize
   send "findFinalize" to group "Editor" of me
end revSEFindFinalize

# Parameters
#   pQuery : the string to search for
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether or not to treat *s as wildcards
#   pIgnoreCase : whether to do a case sensitive search or not
#   pTarget : whether to search in all tabs or just the current tab
# Description
#   Searches for the next match according to the specified search criteria. Highlights the match if found.
command revSEFindNext pQuery, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget
   send "showNextFindResult pQuery, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, false, pTarget" to group "Editor" of me
end revSEFindNext

# Parameters
#   pQuery : the string to search for
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether or not to treat *s as wildcards
#   pIgnoreCase : whether to do a case sensitive search or not
#   pTarget : whether to search in all tabs or just the current tab
#   pCallback : optional. The name of a command to send with a message saying what state the search is in
# Description
#   Searches for all matches for the specified search and displays them in the "Search Results" pane.
command revSEFindAll pQuery, pIsRegExp, pUseWildCards, pWholeMatches, pIgnoreCase, pTarget, pCallback, pCallbackTarget
   send "showAllFindResults pQuery, pIsRegExp, pUseWildCards, pWholeMatches, pIgnoreCase, pTarget, pCallback, pCallbackTarget" to group "Editor" of me
end revSEFindAll

# Parameters
#   pQuery : the string to search for
#   pReplaceString : the string to replace with
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether or not to treat *s as wildcards
#   pIgnoreCase : whether to do a case sensitive search or not
#   pTarget : whether to search in all tabs or just the current tab
# Description
#   Replaces the currently highlighted search term with pReplaceString, then searches for the next match.
command revSEReplaceCurrent pQuery, pReplaceString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget
   send "replaceOnceAndFind pQuery, pReplaceString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget" to group "Editor" of me
end revSEReplaceCurrent

# Parameters
#   pQuery : the string to search for
#   pIsRegExp : whether or not pQuery is a regular expression
#   pUseWildCards : whether or not to treat *s as wildcards
#   pIgnoreCase : whether to do a case sensitive search or not
#   pTarget : whether to search in all tabs or just the current tab
# Description
# The current undo system does not support doing this on multiple tabs...
# Returns
#   The number of replacements made
command revSEReplaceAll pQuery, pString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget, pCallback, pCallbackTarget
   local tReplacementCount
   send "replaceAll pQuery, pString, pIsRegExp, pUseWildCards, pWholeMatch, pIgnoreCase, pTarget, pCallback, pCallbackTarget" to group "Editor" of me
   put the result into tReplacementCount
   
   # OK-2009-03-03 : Bug 7538 - Return the number of replacements made so that the caller can display it
   return tReplacementCount
end revSEReplaceAll

# Parameters
#   pStart : the number of the first char to mark
#   pEnd : the number of the last char to mark
# Description
#   Marks the chunk of text specified by pStart and pEnd. Unmarks any previously marked text
command revSEMarkText pStart, pEnd
   send "findClearResults" to group "Editor" of me
   send "findMarkResult pStart, pEnd, false" to group "Editor" of me
end revSEMarkText

# Description
#   Called when the name of one or more of the target objects has changed
#   Updates the script editor to display the object's new names.
command revSERefreshObjectNames
   send "refreshTabStates" to group "Script Tabs" of me
end revSERefreshObjectNames

# Parameters
#   pObject : reference to the object that had its id changed
#   pOldId : the object's old id
#   pNewId : the object's new id
# Description
#   Sent when an object being edited by this script editor has had its id changed.
#   Updates stored references to the object and any UI elements that are displaying
#   the object's id. Note that only images can have their ids changed.
command revSEObjectIdChanged pObject, pOldId, pNewId
   send "updateObjectId pObject, pOldId, pNewId" to group "Script Tabs" of me
   
   local tObject
   put seGetRuggedId(pObject) into tObject
   send "setObjectRaw tObject" to group "Editor" of me
end revSEObjectIdChanged

# OK-2008-08-19 : Bug 6947 - Store script checksums to detect whether the user has modified the script externally.
local sScriptChecksums

# Parameters
#   pObject : reference to the object that had its rugged id changed.
#   pOldRuggedId : the old rugged id of the object
# Description
#   Sent when something has caused the rugged if of an object being edited by this script editor to change.
#   There are two cases when this happens:
#      1. The user changes the id of an image that is having its script edited
#      2. The user changes the mainstack of the stack that owns (or is) one of the objects being edited.
#   Updates the script editor by changing stored references to the object and any UI elements that
#   are displaying parts of the object's rugged id.
command revSEObjectRuggedIdChanged pObject, pOldRuggedId
   local tObject
   put seGetRuggedId(pObject) into tObject
   
   local tObjectList
   revSEGetTargetObjects
   put the result into tObjectList
   repeat for each line tTargetObject in tObjectList
      if (tTargetObject is pOldRuggedId) or (seRuggedObjectContainsObject(pOldRuggedId, tTargetObject)) then
         local tNewId
         if tTargetObject is pOldRuggedId then
            put tObject into tNewId
         else
            put tTargetObject into tNewId
            replace pOldRuggedId with tObject in tNewId
         end if
         
         # Update the main tabs group
         send "updateObjectRuggedId tNewId, tTargetObject" to group "Script Tabs" of me
         
         # Update the editor group if appropriate
         local tCurrentObject
         send "getObject" to group "Editor" of me
         put the result into tCurrentObject
         
         if tCurrentObject is pOldRuggedId or (seRuggedObjectContainsObject(pOldRuggedId, tCurrentObject)) then
            send "setObjectRaw tNewId" to group "Editor" of me
         end if
      end if
   end repeat
   
   # OK-2008-10-14 : Bug 7235 - Update the stored script checksums array
   put sScriptChecksums[pOldRuggedId] into sScriptChecksums[tObject]
   delete variable sScriptChecksums[pOldRuggedId]
   
   send "refreshTabStates" to group "Script Tabs" of me
end revSEObjectRuggedIdChanged

# Description
#   Returns the handler list for the current object, in the same format as the revAvailableHandlers.
command revSEGetHandlerList
   local tHandlers
   send "getHandlerList" to group "Editor" of me
   put the result into tHandlers
   return tHandlers
end revSEGetHandlerList

# Parameters
#   pDontUpdate : if true, the selected handler is not updated and is assumed to be up to date.
# Description
#   Returns the currently selected handler for the current object, or the last selected handler if none
#   is selected or the information is unavailable.
command revSEGetSelectedHandler pDontUpdate
   local tHandler
   call "getSelectedHandler pDontUpdate" to group "Editor" of me
   put the result into tHandler
   return tHandler
end revSEGetSelectedHandler

# Description
#   Returns the number of lines of the current script being edited
command revSEGetLineCount
   local tLineCount
   send "scriptGetLineCount" to group "Editor" of me
   put the result into tLineCount
   return tLineCount
end revSEGetLineCount

# Parameters
#   pObjectList : a list of the objects that are being closed
# Description
#   Prompts the user to find out if they want to save changes in the specified list of edited
#   objects. If the user answers yes, applies the scripts of the objects without showing any
#   errors. If the user answers no, does nothing and returns empty. If the user answers cancel
#   then does nothing and returns "cancel"
command revSEWarnBeforeClosing pObjectList
   if pObjectList is empty then
      return empty
   end if
   
   set the cObjects of stack "revSEUnappliedDialog" to pObjectList
   modal stack "revSEUnappliedDialog"
   
   local tChoice
   put the cChoice of stack "revSEUnappliedDialog" into tChoice
   
   if tChoice is "cancel" then
      return "cancel"
   end if
   
   if tChoice is "no" then
      repeat for each line tObject in pObjectList
         send "clearCache tObject" to group "Editor"
      end repeat
      return empty
   end if
   
   if tChoice is "yes" then
      # Apply the current changes, ignoring compilation errors
      local tResult
      revSEApplyAll pObjectList, true
      put the result into tResult
      if tResult is not empty then
         # This means one or more scripts couldn't be compiled because of an execution error,
         # e.g. the object was executing.
         return "cancel"
      end if
   end if
   
   return empty
end revSEWarnBeforeClosing

# Parameters
#   pError : a string representing the execution error, in the standard Revolution format.
#   pObject : the object that threw the error. If empty, the current script editor object is assumed.
# Description
#   pObject should normally be one of the objects being edited. The script editor will not change the 
#   current object to pObject, this should be done by the caller.
#   Shows the errors pane with a description of the error.
command revSEDisplayExecutionError pError, pObject
   if pObject is empty then
      local tObject
      revSEGetCurrentObject
      put the result into tObject
   else
      put revRuggedId(pObject) into tObject
   end if
   
   # Because this can be called by the debugger, we must not allow an execution
   # error here or the IDE will be broken. If there is no appropriate object then 
   # we just do nothing.
   if tObject is empty then
      exit revSEDisplayExecutionError
   end if
   
   send "clearErrors" to group "Errors" of me
   send "addError execution, pError, tObject" to group "Errors" of me
   send "setCurrentTab errors" to group "Pane Tabs" of me
   send "expandCurrentPane" to group "Panes" of me
end revSEDisplayExecutionError

# Parameters
#   pObjectList : a list of object references that are being edited by this script editor
#   pIgnoreErrors : whether to ignore compilation errors or not. 
# Description
#   Attempts to compile, then applies each specified script. If pIgnoreErrors is true then
#   does not show any compile errors.
# Returns
#   Empty if application was successful, a list of scripts that failed otherwise
command revSEApplyAll pObjectList, pIgnoreErrors
   local tCompilationErrors, tResult, tFailedScripts
   repeat for each line tObject in pObjectList
      applyScript tObject, pIgnoreErrors, tCompilationErrors
      put the result into tResult
      if not tResult then
         # This means the script could not be applied due to an execution error. Not sure how to handle this,
         # but the most sensible choice seems to be to cancel the closure and allow the user to see the error.
         put tObject & return after tFailedScripts
      end if
   end repeat
   delete the last char of tFailedScripts
   return tFailedScripts
end revSEApplyAll

# Stores whether or not the script editor has been suspended by the "Suspend Development Tools" IDE function.
# This has to be stored because if the script editor is a modeless or palette window, the engine will send preOpenStack
# and related messages to it when restored, regardless of whether messages are locked. Keeping track of whether 
# the script editor is suspended allows us to disregard these messages.
local sSuspended

# Description
#   Called just before the script editor is about to be suspended (by suspend development tools menu item)
#   Prepares the script editor for this.
command revSESuspend
   set the destroyStack of me to false
   put true into sSuspended
end revSESuspend

# Description
#   Called just *after* the script editor resumes from suspension
command revSERestore
   set the destroyStack of me to true
   put false into sSuspended
end revSERestore

command revSEFormatSnippet pScript
   send "scriptFormatSnippet pScript" to group "Editor" of me
   return the result
end revSEFormatSnippet

################################################################################
#
# Script editor internal handlers. These handlers are available to any object
# inside the script editor stack. Please do not call any of these from outside
# the script editor.
#
################################################################################


# Returns
#   A list of the debug contexts available to this script editor. This is the same as the list returned
#   by the debugger library except without any contexts with this stack as their target. This means
#   that it is not possible to debug the script editor in the same instance that is being debugged,
#   but does not prevent debugging using a different instance. revLibrary should reflect this by
#   not allowing a script editor to edit its own scripts, but forcing a new instance.
function seDebugContexts
   local tContexts
   put revDebuggerContexts() into tContexts
   
   local tFilteredContexts, tArray
   repeat for each line tContext in tContexts
      # OK-2009-06-23 : Bug 7954
      put revDebuggerParseExecutionContext(tContext) into tArray
      
      local tObject
      if tArray["behavior"] is not empty then
         put tArray["behavior"] into tObject
      else
         put tArray["object"] into tObject
      end if
      
      --      if the number of items of tContext = 5 then
      --         put item 5 of tContext into tObject
      --      else
      --         put item 2 to -3 of tContext into tObject
      --      end if
      
      local tStack
      put revTargetStack(tObject) into tStack
      
      if the short name of stack tStack is the short name of me then
         next repeat
      end if
      
      if the short name of stack revTargetStack(tArray["object"]) is the short name of me then
      	next repeat
      end if
      
      if tArray["behavior"] is not empty then
         local tNewContext
         --         put item 1 to -2 of tContext into tNewContext
         --         put item 5 of tContext into item 2 of tNewContext
         put tArray["context number"] & comma & tArray["behavior"] & comma & tArray["handler"] & comma & tArray["line number"] into tNewContext
         put tNewContext & return after tFilteredContexts
      else
         put tContext & return after tFilteredContexts
      end if
   end repeat
   
   delete the last char of tFilteredContexts
   return tFilteredContexts
end seDebugContexts

local sDebugContext
function seGetSelectedDebugContext
   return sDebugContext
end seGetSelectedDebugContext

function seGetDebugContext
   local tMode
   revSEGetMode
   put the result into tMode

   if tMode is not "debug" then
      put empty into sDebugContext
      return empty
   else if sDebugContext is not empty then
      return sDebugContext
   else
      return line 1 of seDebugContexts()
   end if
end seGetDebugContext

on seSetDebugContext pContext
   lock screen
   put pContext into sDebugContext
   send "refreshCurrentPane" to group "Panes" of this card
   unlock screen
end seSetDebugContext

# OK-2009-01-17 : Bug 7169 - Semantics changed slightly. Previously this command returned a list
# of all unapplied scripts. Now it only returns unapplied scripts that were modified by the user.
# The situation where this makes a difference is when the script contains a template automatically
# filled in by the script editor. In this context, such a script is no longer viewed as modified.

# Returns
#   A list of the target objects with unapplied changes to their scripts that were made by the user.
command revSEGetModifiedObjects
   local tObjects
   send "listTabs" to group "Script Tabs" of me
   put the result into tObjects
   
   local tEditedObjects
   repeat for each line tObject in tObjects
      local tState
      put seGetObjectState(tObject) into tState
      if tState is "edited" or (tState is "error" and revIDEObjectIsOnIDEStack(tObject)) then
         # OK-2009-01-17 : Bug 7169
         local tDirty
         send "getDirty tObject" to group "Editor" of me
         put the result into tDirty
         if tDirty then
            put tObject & return after tEditedObjects
         end if
      end if
   end repeat
   delete the last char of tEditedObjects
   return tEditedObjects
end revSEGetModifiedObjects

local sObjectStates

# Parameters
#   pObject : reference to one of the target objects of the script editor.
# Returns
#   The state of the script of the specified object. This can
#   currently either be "edited" "applied" or "error"
function seGetObjectState pObject
   local tState
   put sObjectStates[seGetRuggedId(pObject)] into tState
   if tState is empty then
      put "applied" into tState
   end if
   
   return tState
end seGetObjectState

# Parameters
#   pObject : reference to one of the target objects of the script editor.
#   pState : either "edited" or "applied"
# Description
#   Stores the specified state for the object for later use. And updates any
#   script editor components that may depend on this information.
command seSetObjectState pObject, pState
   if pState is "edited" then
      local tObj
      put the long id of pObject into tObj
      if not revIDEObjectIsOnIDEStack(tObj) then
         local tParams
         put the text of field "Script" into tParams[1]
         put tObj into tParams[2]
         send "ideMessageSendWithParameters" && "ideScriptEdited, tObj, tParams" to stack "revIDELibrary" in 0 milliseconds
      end if
   end if
   
   # Small optimization, if pState is equal to the current state, don't do anything
   if pState is sObjectStates[seGetRuggedId(pObject)] then
      exit seSetObjectState
   end if
   
   put pState into sObjectStates[seGetRuggedId(pObject)]
   send "refreshTabStates" to group "Script Tabs" of me
   send "update" to group "Toolbar" of me
   if pState is not "error" then
      local tId
      put seGetRuggedId(pObject) into tId
      send "setCompilationErrors empty, tId" to group "Editor" of me
   end if
end seSetObjectState

# Returns
#  A comma delimited list of the panes that are available, in order. This may be extended to allow user panes to be added etc.
function seAvailablePanes
   return "Errors,Variables,Documentation,Breakpoints,Search Results"
end seAvailablePanes

# Returns
#   A comma delimited list of the panes that are currently visible.
function seVisiblePanes
   local tPreferedList
   put sePrefGet("panes,visiblelist") into tPreferedList
   
   if tPreferedList is empty then
      return seAvailablePanes()
   else
      return tPreferedList
   end if
end seVisiblePanes

# Description
#  Updates the panes in response to something changing that might affect them.
command sePanesUpdate
   local tPane
   send "getCurrentTab" to group "Pane Tabs" of me
   put the result into tPane
   
   # OK-2008-12-10 : Bug 7512 - Always update the documentation prefs, this fixes the problem of the docs pane
   # lagging behind.
   --if tPane is "documentation" then
   
   # For the documentation, get the last caret token from the editor group, and instruct the documentation
   # pane to search for a matching entry for this.
   local tToken
   send "getCaretToken" to group "Editor" of me
   put the result into tToken
   
   # OK-2008-09-11 : Refactored to prevent direct interaction with the Documentation pane. This needs further work
   # as it will soon be possible to have multiple panes open.
   if tToken is not empty then
      if ideDocsFetchScriptData(tToken) is not empty then
         sePrefSet "documentation,lastLoadedDoc", tToken
         sePrefSet "documentation,lastMatchingSearch", tToken
         sePrefSet "documentation,lastLoadedAlternativeDocs", tToken
      end if
   end if
   send "refreshCurrentPane" to group "Panes" of me
   --   else
   --      send "refreshCurrentPane" to group "Panes" of me
   --   end if
end sePanesUpdate

command seRefreshCurrentPaneIfItsBreakpoints
   send "refreshCurrentPaneIfItsBreakpoints" to group "Panes" of me
end seRefreshCurrentPaneIfItsBreakpoints

# Parameters
#   pPane : the name of the pane to show
# Description
#   Shows the specified pane
command sePaneShow pPane
   if pPane is not among the items of seAvailablePanes() then
      exit sePaneShow
   end if
   
   # If the pane is not currently visible, we assume that the user wishes to make it visible,
   # so update the prefs to reflect this.
   if pPane is not among the items of seVisiblePanes() then
      sePrefSet "panes,visiblelist", seVisiblePanes() & comma & pPane
      send "update" to group "Pane Tabs" of me
   end if
   
   send "setCurrentTab pPane" to group "Pane Tabs" of me
end sePaneShow

# Minimum height to attempt to keep the editor above. This is not a "hard" limit,
# if the user continues shrinking the stack eventually the editor will be smaller than this
# but the script editor will resize other objects in order to attempt to preserve this.
constant kEditorMinimumHeight = 100

function sePaneMaximumHeight
   return the bottom of this card of me - the bottom of group "Script Tabs" of me - the height of button "Resizer" of me - kEditorMinimumHeight
end sePaneMaximumHeight


# Parameters
#   pType : either "compilation", "execution" or "warning"
#   pErrorId : the error string
# Returns
#   The description of the specified error.
function seErrorDescription pType, pError
   return revIDELookupError(pType, pError)
end seErrorDescription

# Parameters
#   pObject : a valid object reference
# Description
#   Returns a friendly form of the object name suitable for displaying on tabs, etc.
function seFriendlyObject pObject
   return revDebuggerObjectName(pObject)
end seFriendlyObject

# Parameters
#   pObject : reference to the object that the breakpoint is owned by
#   pLine : the line number that the breakpoint is on
# Returns
#   A string of three lines.
#   Line 1 is whether the breakpoint should be displayed as active or not, (i.e will it actually trigger?)
#   Line 2 is whether the breakpoint is on a valid line or not
#   Line 3 is a string explaining the breakpoint's status, suitable for displaying to the user. This will be empty if the breakpoint is active.
function seBreakpointDisplayInformation pObject, pLine
   if not revDebuggerEnabled() then
      return ("inactive" & return & "false" & return & "this breakpoint will not trigger because script debug mode is currently turned off")
   end if
   
   local tObject
   put revRuggedId(pObject) into tObject
   
   local tBreakpoints
   put revDebuggerListBreakpoints(tObject) into tBreakpoints
   
   local tStates
   put revDebuggerListBreakpointStates(tObject) into tStates
   
   local tLineNumber
   set the wholeMatches to true
   put lineOffset((the long id of tObject & comma & pLine), tBreakpoints) into tLineNumber
   set the wholeMatches to false
   
   # If the object is being edited in this script editor
   local tObjects
   revSEGetTargetObjects
   put the result into tObjects
   
   local tObjectIsBeingEdited
   if tObject is among the lines of tObjects then
      put true into tObjectIsBeingEdited
   else
      put false into tObjectIsBeingEdited
   end if
   
   # Find out if the breakpoint is active or not. This is linear to the number of breakpoints
   # in the worst case, so may need to be optimized somehow.
   local tBreakpointState
   if tLineNumber = 0 then
      # If the breakpoint is not known then it must be a user added one, in this case
      # we just assume that its state is "active".
      put "active" into tBreakpointState
   else
      if tObjectIsBeingEdited and seGetObjectState(tObject) is not "applied" then
         put "inactive" into tBreakpointState
      else
         put line tLineNumber of tStates into tBreakpointState
         if tBreakpointState is "inactive" then
            return ("inactive" & return & "false" & return & "this breakpoint is currently disabled")
         end if
      end if
   end if
   
   local tScript
   if tObjectIsBeingEdited then
      send "scriptGet tObject" to group "Editor" of me
      put the result into tScript
   else
      put the script of tObject into tScript
   end if
   
   local tBreakpointInvalid
   put false into tBreakpointInvalid
   if revDebuggerNextAvailableBreakpoint(tScript, pLine - 1) <> pLine then
      put "inactive" into tBreakpointState
      put true into tBreakpointInvalid
   end if
   
   local tMessage
   if tObjectIsBeingEdited and seGetObjectState(tObject) is not "applied" then
      put "this breakpoint will not trigger because the script has not been applied or contains errors" into tMessage
   else if tBreakpointInvalid then
      put "this breakpoint will not trigger because it is currently on an empty line of code" into tMessage
   end if
   
   return (tBreakpointState & return & tBreakpointInvalid & return & tMessage)
end seBreakpointDisplayInformation


local sHistory

# Parameters
#   pObject : reference to an object whose script was edited
# Description
#   Adds the specified object to the script editor history
command seHistoryAdd pObject
   if the number of lines of sHistory >= sePrefGet("historysize") then
      # First remove any non-existing objects, if there is still no room, remove the last item on the list
      seHistoryClean
      if the number of lines of sHistory >= sePrefGet("historysize") then
         seHistoryRemove (line -1 of seHistoryGet())
      end if
   end if
   
   if sHistory is empty then
      put seGetRuggedId(pObject) into sHistory
   else
      put seGetRuggedId(pObject) & return before sHistory
   end if
end seHistoryAdd

# Parameters
#   pObject : reference to the object to remove from the history
# Description
#   Removes the specified object from the history list. Leaving the order of other items as it was
command seHistoryRemove pObject
   # Just to avoid error messages when working on the template
   if there is no pObject then
      exit seHistoryRemove
   end if
   
   local tLineNumber
   put lineOffset(seGetRuggedId(pObject), sHistory) into tLineNumber
   if tLineNumber = 0 then
      exit seHistoryRemove
   end if
   
   delete line tLineNumber of sHistory
end seHistoryRemove

# Description
#    Cleans the script editor history by removing objects that don't exist and
#    ensuring the history is trimmed to the maximum size.
command seHistoryClean
   local tCleanedHistory
   local tItemCount
   put 0 into tItemCount
   
   local tExistingObjects
   repeat for each line tObject in sHistory
      if there is a tObject  and tItemCount < sePrefGet("historysize") and tExistingObjects[tObject] is empty then
         put tObject & return after tCleanedHistory
         put true into tExistingObjects[tObject]
         add 1 to tItemCount
      end if
   end repeat
   delete the last char of tCleanedHistory
   put tCleanedHistory into sHistory
end seHistoryClean

# Description
#   Loads the history from the Revolution preferences stack into sHistory
command seHistoryLoad
   put the cScriptEditorHistory of stack "revPreferences" into sHistory
end seHistoryLoad

# Description
#   Saves sHistory in the Revolution preferences stack. Cleans it first to avoid
#   storing invalid information there.
command seHistorySave
   seHistoryClean
   set the cScriptEditorHistory of stack "revPreferences" to sHistory
end seHistorySave

# Returns
#    The current history in a valid form, i.e. with all excess / deleted objects removed
#    Note this is not private as it is called by
function seHistoryGet
   seHistoryClean
   return sHistory
end seHistoryGet

# This variable keeps track of whether or not the handler list is showing
local sHandlerListShowing = "false"

# Description
#   Shows the handler list
command seShowHandlerList
   put true into sHandlerListShowing
   send "showHandlerList" to group "Toolbar" of me
end seShowHandlerList

# Description
#   Hides the handler list
command seHideHandlerList
   put false into sHandlerListShowing
   call "hideHandlerList" to group "Toolbar" of me
end seHideHandlerList

# Returns
#   A reference to the object that represents the handler list. This is currently a group on the main card.
function seHandlerListObject
   return the long id of group "Handler List" of card "Main" of me
end seHandlerListObject

# Returns
#   Whether or not the handler list is showing.
function seHandlerListIsShowing
   return sHandlerListShowing
end seHandlerListIsShowing

function seLocateHandler pName, pProposedPosition, pType
   send "locateHandler pName, pProposedPosition, pType" to group "Editor" of me
   return the result
end seLocateHandler

function seStackId
   return the long id of me
end seStackId

# Parameters
#   pType : the type of breakpoint to show in the dialog initially. This is either "breakpoint" or "watch"
# Description
#   Shows the new breakpoint dialog
command seNewBreakpointDialog pType
   local tDialog
   put the long id of stack "revSEEditBreakpoint" into tDialog
   set the title of tDialog to "New Breakpoint"
   set the cCaller of tDialog to the long id of me
   set the cMode of tDialog to "new"
   set the cType of tDialog to pType
   set the cLine of tDialog to empty
   set the cVariable of tDialog to empty
   set the cHandler of tDialog to empty
   set the cBreakpointCondition of tDialog to empty
   set the cWatchCondition of tDialog to empty
   
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   set the cObject of tDialog to tObject
   
   set the loc of tDialog to the screenLoc
   modal tDialog
end seNewBreakpointDialog

# Parameters
#   pType : the type of breakpoint that we are editing. This is either "breakpoint" or "watch"
#   pLine : the line number (if pType is "breakpoint", otherwise ignored)
#   pVariable : the name of the variable (if pType is "watch", otherwise ignored)
#   pHandler : the name of the handler containing the variable (if pType is "watch", otherwise ignored)
#   pCondition : the condition attached to the breakpoint (both types)
#   pObject : the object that the watch or breakpoint is associated with.
# Desription
#   Shows the edit breakpoint dialog. (This is the same as the new breakpoint one, but with different properties set.)
command seEditBreakpointDialog pType, pLine, pVariable, pHandler, pCondition, pObject
   local tDialog
   put the long id of stack "revSEEditBreakpoint" into tDialog
   set the title of tDialog to "Edit Breakpoint"
   set the cCaller of tDialog to the long id of me
   set the cType of tDialog to pType
   set the cMode of tDialog to "edit"
   set the cObject of tDialog to pObject
   
   if pType is "breakpoint" then
      set the cLine of tDialog to pLine
      set the cBreakpointCondition of tDialog to pCondition
   else if pType is "watch" then
      set the cVariable of tDialog to pVariable
      set the cHandler of tDialog to pHandler
      set the cWatchCondition of tDialog to pCondition
   end if
   set the loc of tDialog to the screenLoc
   modal tDialog
   revSEUpdate false
end seEditBreakpointDialog

# Parameters
#   pAction : the name of a script editor action. E.g. "Cut", "LaunchMessageBox"
# Returns
#   A string representing the keyboard shortcut(s) associated with the specified action E.g. "command shift x"
#   Multiple shortcuts will be separated by returns.
function seLookupShortcut pAction
   # List the available shortcut actions
   local tShortcut
   put sePrefGet("shortcuts," & pAction) into tShortcut
   return tShortcut
end seLookupShortcut

# Parameters
#   pAction : the name of a script editor action. E.g. "Cut", "LaunchMessageBox"
# Returns
#   A friendly form of the shortcut suitable for displaying in tooltips etc.
function seFriendlyShortcut pAction
   local tShortcuts
   put seLookupShortcut(pAction) into tShortcuts
   
   local tCommandKeyName, tOptionKeyName
   if seGetPlatform() is "Macos" then
      put "Cmd" into tCommandKeyName
      put "Option" into tOptionKeyName
   else
      put "Ctrl" into tCommandKeyName
      put "Alt" into tOptionKeyName
   end if
   
   local tShiftKeyName
   put "Shift" into tShiftKeyName
   
   local tFriendlyStrings
   repeat for each line tShortcut in tShortcuts
      local tKeyName
      if the number of chars of word -1 of tShortcut > 1 then
         put word -1 of tShortcut into tKeyName
         put toUpper(char 1 of tKeyName) & char 2 to -1 of tKeyName into tKeyName
      else
         put word -1 of tShortcut into tKeyName
      end if
      
      local tFriendlyString
      if "command" is among the words of tShortcut then
         put tCommandKeyName & "+" into tFriendlyString
      end if
      
      if "option" is among the words of tShortcut then
         put tOptionKeyName & "+" after tFriendlyString
      end if
      
      if "shift" is among the words of tShortcut then
         put tShiftKeyName & "+" after tFriendlyString
      end if
      
      put tKeyName after tFriendlyString
      put tFriendlyString & comma & space after tFriendlyStrings
   end repeat
   delete the last char of tFriendlyStrings
   delete the last char of tFriendlyStrings
   
   return tFriendlyStrings
end seFriendlyShortcut

# Parameters
#   pText : the word to search for, note this is not necessarily a handler name
#   pObject : reference to the object containing the text
#   pHandler : the handler that the matching text was found in in the form <type>,<name> (or empty)
# Returns
#   A list, one per line, of the matching handler definitions
#   for pText. Empty if none could be found.
#   Note that for now, only handler definitions are returned.
function seMatchingDefinitions pText, pObject, pHandler
   local tObject
   
   local tUses
   put the revBehaviorUses of pObject into tUses
   if exists(tUses[1]) then
      put tUses[1] into tObject
   else
      put pObject into tObject
   end if
   
   local tDescription
   put the effective revScriptDescription of tObject into tDescription
   
   local tObjectDescription
   if pObject is not tObject then
      put the revScriptDescription of pObject into tObjectDescription
   end if
   
   local tMatches
   repeat with tIndex = 1 to the number of elements of tDescription
      if pObject is not tObject then
         if tDescription[tIndex]["object"] is the long id of tObject and \
               tDescription[tIndex]["description"]["handlers"][pText]["is_private"] then
            next repeat
         end if
         
         if tDescription[tIndex]["object"] is the long id of pObject then
            put tObjectDescription into tDescription[tIndex]["description"]
         end if
      end if
      
      if tDescription[tIndex]["description"]["handlers"][pText] is an array then
         local tType
         if tDescription[tIndex]["description"]["handlers"][pText]["is_private"] then
            put "private" && tDescription[tIndex]["description"]["handlers"][pText]["type"] into tType
         else
            put tDescription[tIndex]["description"]["handlers"][pText]["type"] into tType
         end if
         
         put "handler", \
               tType, \
               pText, \
               tDescription[tIndex]["description"]["handlers"][pText]["start_line"], \
               tDescription[tIndex]["object"] & return after tMatches
      end if
   end repeat
   
   delete the last char of tMatches
   return tMatches
end seMatchingDefinitions

function seFriendlyHandlerType pType, pIsPrivate
   local tType
   if pIsPrivate then
      put "private " into tType
   end if
   
   switch pType
      case "M"
      case "C"
         put "message" after tType
      break
      case "F"
         put "function" after tType
      break
      case "S"
         put "setprop" after tType
      break
      case "G"
         put "getprop" after tType
      break
   end switch
   
   return toUpper(char 1 of tType) & char 2 to -1 of tType
end seFriendlyHandlerType

################################################################################
#
# Script editor actions. These actions are available to any control in the script
# editor stack. Please do not call any of these from outside the script editor stack
#
################################################################################

# Description
#   Called when the script editor stack is resized. First resizes each script editor object,
#   then sends a "resize" message to each object to allow the object to resize its controls
#   appropriately to its new size.
command actionResizeStack pInitializing
   # Hide the handler list if its showing
   seHideHandlerList
   
   local tLeftSplit
   put the left of this card of me + sePrefGet("leftSplit") into tLeftSplit
   
   local tMode
   revSEGetMode
   put the result into tMode
   
   # OK-2009-02-05 : Bug 7681 - It seems that under certain circumstances the card rect is not updated
   # properly at this point. To work around this bug, we calculate the card rect ourselves from the stack.
   local tCardLeft, tCardWidth, tCardTop
   put 0 into tCardLeft
   put 0 into tCardTop
   put the width of me into tCardWidth
   
   # Menubar, Toolbar and Script Tabs group
   if sePrefGet(tMode & "showToolbars") then
      set the width of group "Menubar" of me to tCardWidth
      set the topLeft of group "Menubar" of me to (tCardLeft, tCardTop)
      set the width of group "Toolbar" of me to tCardWidth
      set the topLeft of group "Toolbar" of me to the bottomLeft of group "Menubar" of me
      set the width of group "Script Tabs" of me to tCardWidth - tLeftSplit - the width of button "Left Resizer" of me
      set the topLeft of group "Script Tabs" of me to tLeftSplit + the width of button "Left Resizer" of me, the bottom of group "Toolbar" of me
   else
      set the right of group "Menubar" of me to tCardLeft - 500
      set the right of group "Toolbar" of me to tCardLeft - 500
      set the width of group "Script Tabs" of me to tCardWidth - tLeftSplit - the width of button "Left Resizer" of me
      
      # If running on OS X, the Menubar group will be the defaultMenubar of the script editor, and Revolution will automatically
      # move all the controls down, this effectively changes the rect of the card so that it starts about 23 pixels down. We have
      # to take this into account when resizing because otherwise the script tabs will be clipped by the top of the card.
      if seGetPlatform() is "macos" then
         set the topLeft of group "Script Tabs" of me to tLeftSplit + the width of button "Left Resizer" of me, tCardTop + the height of group "Menubar" of me
      else
         set the topLeft of group "Script Tabs" of me to tLeftSplit + the width of button "Left Resizer" of me, tCardTop
      end if
   end if
   
   set the width of group "Pane Tabs" of me to the width of this card of me
   set the width of button "Resizer" of me to tCardWidth
   set the left of button "Resizer" of me to tCardLeft
   set the width of button "Left Resizer" of me to 10
   
   send "resize" to group "Menubar" of me
   send "resize" to group "Toolbar" of me
   send "resize" to group "Script Tabs" of me
   
   # OK-2010-02-12: Bug 8088 - Make the script editor position its controls correctly on startup,
   # the engine doesn't appear to allow controls to be set to the bottom of the card at this point, so
   # we have to send in time to make it work. Everything that is lined up to the bottom of the card should
   # be done in seResizeCardBottom instead of here.
   if pInitializing then
      send "seResizeCardBottom" to me in 0 milliseconds
   else
      seResizeCardBottom
   end if
end actionResizeStack

command seResizeCardBottom
   # OK-2009-02-05 : Bug 7681 - It seems that under certain circumstances the card rect is not updated
   # properly at this point. To work around this bug, we calculate the card rect ourselves from the stack.
   local tCardLeft, tCardWidth, tCardBottom
   put 0 into tCardLeft
   put the height of me into tCardBottom
   put the width of me into tCardWidth
   
   # OK-2009-03-24 : On OS X, this is required to get correct resizing, due to menubars
   if seGetPlatform() is "MacOS" and the vScroll of me is not 0 then
      add the vScroll of me to tCardBottom
   end if
   
   local tLeftSplit
   put the left of this card of me + sePrefGet("leftSplit") into tLeftSplit
   
   # Don't let the panes unnecessarily obstruct the editor
   if sePrefGet("paneHeight") > sePaneMaximumHeight() then
      sePrefSet "paneHeight", sePaneMaximumHeight()
   end if
   
   set the rect of group "Editor" of me to tLeftSplit + the width of button "Left Resizer" of me, the bottom of group "Script Tabs" of me, tCardWidth, tCardBottom - sePrefGet("paneHeight") - the height of button "Resizer" of this card of me
   set the topLeft of group "Pane Tabs" of me to tCardLeft, tCardBottom - sePrefGet("paneHeight")
   set the bottom of button "Resizer" of me to tCardBottom - sePrefGet("paneHeight")
   set the height of button "Left Resizer" of me to the the height of group "Editor" of me
   set the topRight of button "Left Resizer" of me to the topLeft of group "Editor" of me
   
   # Because a group cannot have a width of zero, if tLeftSplit is 0, we move the group offscreen
   if tLeftSplit is 0 then
      set the rect of group "Left Bar" of me to tCardLeft - 1, the top of group "Script Tabs" of me, tLeftSplit, tCardBottom - sePrefGet("paneHeight") - the height of button "Resizer" of this card of me
   else
      set the rect of group "Left Bar" of me to tCardLeft, the top of group "Script Tabs" of me, tLeftSplit, tCardBottom - sePrefGet("paneHeight") - the height of button "Resizer" of this card of me
   end if
   
   set the rect of group "Panes" of me to tCardLeft, the bottom of group "Pane Tabs" of me, tCardWidth, tCardBottom
   send "resize" to group "Panes" of me
   send "resize" to group "Editor" of me
   send "resize" to group "Pane Tabs" of me
   send "resize" to group "Left Bar" of me
end seResizeCardBottom

# Parameters
#   pObject : the object to apply the script of
#   pIgnoreErrors : causes errors in setting the script not to be displayed in the errors pane and IDE scripts to be set regardless of errors
#   @rCompilationErrors : gets the list of compilation errors placed into it. Will be set to empty if none occurred.
# Returns
#   True if the script was applied, false otherwise. Note that compilation errors may occur but the script could 
#   still be applied. Possible reasons for failure are that the script being applied is executing, on the stack's cantModify is true.
# Description
#   Attempts to set the script of the specified object to the most recent copy in this instance of the script editor. 
#   If setting the script failed due to an execution error, displays the error in the script editor errors pane (unless pIgnoreErrors is true).
private command applyScript pObject, pIgnoreErrors, @rCompilationErrors
   local tCompilationResult
   send "scriptCompile pObject" to group "Editor" of me
   put the result into tCompilationResult
   
   # Clear any old errors
   send "clearErrors" to group "Errors" of me
   
   # MW-2011-03-11: After moving S/E scripts into behaviors, we have a problem - it makes it too easy
   #   to break everything. Thus in the case the script is in an object which has 'revNewScriptEditor' in its
   #   long id we don't set the script on compilation errors.
   if tCompilationResult is empty or not revIDEObjectIsOnIDEStack(pObject) or pIgnoreErrors then
      local tScript
      send "scriptGet pObject" to group "Editor" of me
      put the result into tScript
      
      local tOldPreserveVariables, tOldExplicitVariables 
      put the preserveVariables into tOldPreserveVariables
      put the explicitVariables into tOldExplicitVariables
      set the preserveVariables to sePrefGet("preserveVariables")
      set the explicitVariables to sePrefGet("explicitVariables")
      
      # OK-2008-08-20 : All scripts end in return in the engine, we add the return here so that tScript
      # will match what the actual script gets set to. This ensures that we can store correct checksums for scripts.
      
      # OK-2008-10-16 : Bug 7199 - In fact, not all scripts end with a return, empty scripts should not have one.
      if the last char of tScript is not return and tScript is not empty then
         put return after tScript
      end if
      
      try
         set the script of pObject to tScript
      catch tExecutionError
         if not pIgnoreErrors then
            send "addError execution, tExecutionError, pObject" to group "Errors" of me
            if sePrefGet("showerrors") then
               send "expandCurrentPane" to group "Panes" of me
            end if
         end if
      end try
      
      set the preserveVariables to tOldPreserveVariables
      set the explicitVariables to tOldExplicitVariables
      
      local tStack
      put revTargetStack(pObject) into tStack
      revIDESetEdited tStack
      
      # OK-2008-08-19 : Bug 6947 - The script checksum is updated regardless of whether or not the compilation succeeded,
      # as the script is still set if it failed. If there was an execution error of course, it won't have been set. This is typically
      # because the script was running at the time.
      if tExecutionError is empty then
         seUpdateChecksum pObject, tScript
      end if
      
      # OK-2009-01-17 : Bug 7169 - When a script is compiled, it should be unflagged as dirty
      local tFalse
      put false into tFalse
      send "setDirty pObject, tFalse" to group "Editor" of me
   end if
   
   if tCompilationResult is empty and tExecutionError is empty then
      seSetObjectState pObject, "applied"
   else
      seSetObjectState pObject, "error"
      # Only show the errors pane if an error occurred, if the user is looking at another pane, it 
      # would be annoying to switch to the errors pane just to display "no errors ocurred".
      if not pIgnoreErrors then
         send "setCurrentTab Errors" to group "Pane Tabs" of me
      end if
   end if
   
   put tCompilationResult into rCompilationErrors
   return (tExecutionError is empty)
end applyScript

# OK-2008-12-20: Bug 7511 - Refactored from actionCompile to make bugfix possible
# Applies the script of the specified object, ignoring compilation errors if pIgnoreErrors is true.
private command compileScript pObject, pIgnoreErrors
   # Clear errors from previous compilation
   send "clearErrors" to group "Errors" of me
   
   local tIgnoreErrors
   if pIgnoreErrors is not "true" then
      put "false" into tIgnoreErrors
   else
      put pIgnoreErrors into tIgnoreErrors
   end if
   
   local tCompilationResult
   applyScript pObject, tIgnoreErrors, tCompilationResult
   
   # Until the parser is modified to produce multiple errors, we have to just take the topmost.
   if tCompilationResult is not empty then
      send "addError compilation, line 1 of tCompilationResult, pObject" to group "Errors" of me
      send "setCompilationErrors line 1 of tCompilationResult, pObject" to group "Editor" of me
      
      # If there were errors and the errors pane is folded down, expand it to make the errors clear.
      # Don't do this is there weren't any as the "no error occurred" message is less important.
      if sePrefGet("showerrors") then
         send "expandCurrentPane" to group "Panes" of me
      end if
   else
      send "setCompilationErrors empty, pObject" to group "Editor" of me
   end if
   
   if tCompilationResult is not empty then
      return the number of lines of tCompilationResult
   else
      # If successful, restore the object's breakpoints.
      # (They get suspended when the script is modified).
      # Also send a pane request update as the breakpoints pane will need to update itself here.
      revDebuggerRestoreBreakpoints pObject
      sePanesUpdate
      
      # Make sure we update the left hand handler list
      seUpdateLeftBar
      
      return empty
   end if
end compileScript

# Parameters
#   pIgnoreErrors : whether or not to ignore compilation errors (optional, defaults to false)
# Returns
#   the number of compilation errors encountered.
# Description
#   Attempts to compile the script of object currently being edited. If compile errors occur, adds these to the errors pane,
#   the script is applied regardless of whether errors ocurred or not. The stack is marked as edited.
command actionCompile pIgnoreErrors
   local tCurrentObject
   send "getCurrentTab" to group "Script Tabs" of this card of me
   put the result into tCurrentObject
   
   compileScript tCurrentObject, pIgnoreErrors
end actionCompile

# Description
#   Reverts the current script. This logically equivalent to closing the tab without saving changes
#   and re-opening it.
command actionRevert
   send "revertObject" to group "Editor" of me
end actionRevert

# Description
#   As actionCompile, except closes the current tab if compilation suceeded. Also closes the script editor if the closed
#  tab was the last remaining tab.
command actionApplyAndClose
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   #  If the current object is already applied, close the tab. This roughly preserves the previous
   #  script editor behavior that everyone is used to.
   local tState
   put seGetObjectState(tObject) into tState
   if tState is "applied" then
      revSERemoveTargetObject tObject
      
      # If there are now no tabs left, close the script editor
      local tObjects
      revSEGetTargetObjects
      put the result into tObjects
      if tObjects is empty then
         seFinalize
         send "revSEDeleteSubStack the long id of me" to stack (the mainstack of me) in 0 milliseconds
         close me
      end if
   else
      actionCompile
   end if
end actionApplyAndClose

# Description
#   Removes the current tab
command actionCloseTab
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   revSERemoveTargetObject tObject
end actionCloseTab

# Description
#   Undoes the last action on the current script.
command actionUndo
   # OK-2009-01-17 : Bug 7597 - Run the default undo action for controls other than the editing field
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      send "actionUndo" to group "Editor" of me
   else
      undo
   end if
end actionUndo

# Description
#   Redoes the last undone action on the current script
command actionRedo
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      send "actionRedo" to group "Editor" of me
   else
      # Cannot redo...
   end if
end actionRedo

# Description
#   Performs the "copy" action, placing the currently selected text in the script editor onto the clipboard.
command actionCopy
   copy
end actionCopy

# Description
#   Performs the "cut" action, deleting the currently selected text in the script editor and placing
#   it onto the keyboard.
command actionCut
   # OK-2009-01-17 : Bug 7597 - Run the default cut action for controls other than the editing field
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      send "actionCut" to group "Editor" of me
   else
      cut
   end if
end actionCut

# Description
#   Performs the "select all" action, selecting all text in current script
command actionSelectAll
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      send "actionSelectAll" to group "Editor" of me
   end if
end actionSelectAll

# Description
#   Performs the "save" action, saving the stack that owns the current object
command actionSave
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   local tStack
   put revTargetStack(tObject) into tStack
   
   if tStack is not empty then
      if the effective filename of stack tStack is not empty then
         revSave tStack
      else
         revSaveAs tStack
      end if
   end if
end actionSave

# Description
#   Saves the stack that the current editing script is owned by, first applying all open scripts which are contained within that stack.
command actionApplyAndSave
   # OK-2008-12-20: Bug 7511 - Previously this action only applied the current script, now it applies all scripts in the stack being saved.
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   local tStack
   put ideMainStackOfObject(tObject) into tStack
   
   local tTargetObjects
   revSEGetTargetObjects
   put the result into tTargetObjects
   
   local tIgnoreErrors = false
   repeat for each line tTargetObject in tTargetObjects
      if ideMainStackOfObject(tTargetObject) is tStack then
         # OK-2009-06-23 : Bug 8124 - When saving, still display compilation errors, just apply the script anyway.
         compileScript tTargetObject, tIgnoreErrors
         
         local tCompilationErrors
         put the result into tCompilationErrors
         
         if not tIgnoreErrors and tCompilationErrors is not empty and revIDEObjectIsOnIDEStack(tTargetObject) then
            answer error "The following script has compilation errors. Would you like to ignore errors and apply the script before saving?" & return & the long name of tTargetObject with "Ignore Errors" or "Cancel"
            
            if it is "Cancel" then
               revSESetCurrentObject tTargetObject
               exit actionApplyAndSave
            end if
            
            put true into tIgnoreErrors
            compileScript tTargetObject, tIgnoreErrors
         end if
      end if
   end repeat
   
   actionSave
end actionApplyAndSave

# Description
#   Performs the "paste" action, pasting the clipboard text into the script editor.
command actionPaste
  send "actionPaste" to group "Editor" of me
end actionPaste

# Description
#   Prints the current script
command actionPrint
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   local tHeader
   put the name of tObject & " (id " & the id of tObject & ")" & return & " of stack " & quote & revTargetStack(tObject) & quote into tHeader
   
   local tFooter
   put "<%the time%> <%the date%> <%pagenumber%>" into tFooter
   
   local tHtml
   send "scriptGetHtmlText" to group "Editor" of me
   put the result into tHtml
   
   local tEditingObject
   --send "scriptGetField" to group "Editor" of me
   --put the result into tEditingObject
   
   revSESetupPrintTemplate
   
   # This doesn't actually show the dialog, it sets two script locals in the printing library.
   # This particular call ensures that the print dialog is shown, but the page setup one is not.
   revShowPrintDialog false, true
   
   # Choose a title for the print job.
   local tTitle
   put "Script of " & seFriendlyObject(tObject) into tTitle
   set the printTitle to tTitle
   
   revPrintText tHtml, tHeader, tFooter, revSEGetPrintTemplate()
   reset the templateField
end actionPrint

# Description
#  Shows the find and replace dialog
command actionFindDialog
   set the loc of stack "revSEFind" to the loc of me
   set the cCaller of stack "revSEFind" to the long id of me
   palette stack "revSEFind"
end actionFindDialog

# Description
#   Shows the go to line dialog
command actionGoDialog
   local tLineCount
   send "scriptGetLineCount" to group "Editor" of me
   put the result into tLineCount
   set the cMaxLineNumber of stack "revSEGoDialog" to tLineCount
   
   local tChosenLine
   modal stack "revSEGoDialog"
   put the cChoice of stack "revSEGoDialog" into tChosenLine
   if tChosenLine is empty then
      exit actionGoDialog
   end if
   
   send "goLine tChosenLine, true" to group "Editor" of me
   put tChosenLine into sLastShownExecutionPoint
end actionGoDialog

# Description
#   Shows the interactive find in the editor group
command actionInteractiveFind
  send "goInteractiveFind" to group "Editor" of me
end actionInteractiveFind

# Description
#   Comments the selection in the current script
command actionComment
  send "scriptComment" to group "Editor" of me
end actionComment

# Description
#   Uncomments the selection in the current script
command actionUncomment
   send "scriptUncomment" to group "Editor" of me
end actionUncomment

# Description
#   If there was a previous search to resume, highlights the next search result for that search. 
#   Otherwise, shows the interactive find dialog to allow the user to start a search.
command actionFindNext
   local tCurrentString
   put "current" into tCurrentString
   
   local tFalseString
   put "false" into tFalseString
   send "showNextFindResult empty, empty, empty, empty, empty, tFalseString, tCurrentString" to group "Editor" of me
end actionFindNext

# Description
#   Finds the previous search result
command actionFindPrevious
   local tCurrentString
   put "current" into tCurrentString
   
   send "showPreviousFindResult empty, empty, empty, empty, empty, tCurrentString" to group "Editor" of me
end actionFindPrevious

# Description
#   Searches for the last selected string using the interactive find.
command actionFindSelection
   local tSelection
   send "getLastSelection" to group "Editor" of me
   put the result into tSelection
   
   local tCurrentString
   put "current" into tCurrentString
   
   local tFalseString
   put "false" into tFalseString
   
   local tTrueString
   put "true" into tTrueString
   
   send "showNextFindResult tSelection, tFalseString, tFalseString, tFalseString, tFalseString, tTrueString, tCurrentString" to group "Editor" of me
   actionInteractiveFind
end actionFindSelection

# Description
#   Selects the next tab. If the last tab is reached, moves back round to the first one
command actionNextScriptTab
   send "goNextTab" to group "Script Tabs" of me
end actionNextScriptTab

# Description
#   Selects the previous tab. If the first tab is reached, moves round to the last one.
command actionPreviousScriptTab
   send "goPreviousTab" to group "Script Tabs" of me
end actionPreviousScriptTab

# Description
#   Sends the current window to the back.
command actionSendWindowToBack
   revIDESendCurrentWindowToBack
end actionSendWindowToBack

# Description
#   Brings up a dialog that allows the user to specify which handler is called when the "run" button is pressed
# Returns
#   Either "saved" or "cancelled" depending on whether the user clicked the OK or Cancel button in the dialog
command actionEditDebugEntry
   set the cCaller of stack "revSEDebugEntryDialog" to the long id of me
   modal stack "revSEDebugEntryDialog"
   return the cResult of stack "revSEDebugEntryDialog"
end actionEditDebugEntry

command actionToggleBreakpoint
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   local tLine
   send "getSelectedLine" to group "Editor" of me
   put the result into tLine
   if tLine is empty or tLine is 0 then
      exit actionToggleBreakpoint
   end if
   
   # Get a list of existing breakpoints for the current object. If there is already one on the current line
   # remove it, else add one.
   local tBreakpoints
   put revDebuggerListBreakpoints(tObject) into tBreakpoints
   
   local tBreakpointExistsOnLine
   put false into tBreakpointExistsOnLine
   repeat for each line tBreakpoint in tBreakpoints
      if item -1 of tBreakpoint is tLine then
         put true into tBreakpointExistsOnLine
         exit repeat
      end if
   end repeat
   
   if tBreakpointExistsOnLine then
      revDebuggerRemoveBreakpoint tObject, tLine
   else
      revDebuggerAddBreakpoint tObject, tLine
      revDebuggerActivateBreakpoint tObject, tLine
   end if
   revSEUpdate false
end actionToggleBreakpoint


# Debugger actions. None of these have any effect if the debugger is not currently running

# Description
#   Shows the next statement to be executed in the debugger.
command actionDebugShowNext
   local tMode
   revSEGetMode
   put the result into tMode
   
   if tMode is not "debug" then
      exit actionDebugShowNext
   end if
   
   local tContexts
   put seDebugContexts() into tContexts
   
   # OK-2009-06-23 : Bug 7954
   local tArray
   put revDebuggerParseExecutionContext(line 1 of tContexts) into tArray
   
   local tLine
   --put item -1 of line 1 of tContexts into tLine
   put tArray["line number"] into tLine
   
   local tObject
   if tArray["behavior"] is not empty then
      put tArray["behavior"] into tObject
   else
      put tArray["object"] into tObject
   end if
   --put item 2 to -3 of line 1 of tContexts into tObject
   put seGetRuggedId(tObject) into tObject
   
   # Bring up the script for the object, adding it to the tabs if necessary.
   local tTargetObjects
   revSEGetTargetObjects
   put the result into tTargetObjects
   if tObject is not among the lines of tTargetObjects then
      revSEAddTargetObject tObject
   end if
   revSESetCurrentObject tObject
   
   # Go to the appropriate line
   send "goLine tLine, true" to group "Editor" of me
end actionDebugShowNext

# Description
#   This action does one of two possible things. If we are already debugging, it
#   performs the debugger "Run" function. Continues executing the script
#   that is being debugged until either execution terminates or a breakpoint is reached.
#
#   If we are not already debugging, then the script is compiled, and a message sent to the object
#   in order to begin execution. The message sent and its parameters are stored as metadata on the object
#   and the user can configure them via the actionEditDebugEntry action. If an entry point has not been
#   configured, then a dialog is shown in order to do so.
command actionDebugRun
   local tMode
   revSEGetMode
   put the result into tMode
   
   if tMode is "debug" then
      revDebuggerRun
      revSESetMode "edit"
      exit actionDebugRun
   end if
   
   if tMode is "edit" then
      # Attempt to compile the script first, if it doesn't compile then we don't run it.
      actionCompile
      if the result is not empty then
         exit actionDebugRun
      end if
      
      # Next we figure out which handler / parameters we are going to call, if we don't know
      # then show a dialog to allow the user to choose.
      local tObject
      revSEGetCurrentObject
      put the result into tObject
      
      local tHandler
      put revMetadataGet(tObject, "general", "debugEntryHandler") into tHandler
      
      local tHandlerList
      revSEGetHandlerList
      put the result into tHandlerList
      
      if tHandler is empty or (lineOffset((item 1 of tHandler & space & item 2 of tHandler), tHandlerList) = 0) then
         actionEditDebugEntry
         if the result is "cancelled" then
            exit actionDebugRun
         end if
      end if
      
      # When clicking the run button, the user will expect the "browse" tool to be selected,
      # as otherwise the debugger won't trigger even if there are breakpoints
      choose browse tool
      
      local tParameters
      put revMetadataGet(tObject, "general", "debugEntryHandler") into tHandler
      put revMetadataGet(tObject, "general", "debugParameters") into tParameters
      
      # From the handler and parameters, form a piece of Revolution code to execute
      # in order to trigger the script to run. This may not always be a "send blah to tObject"
      # style command, because we permit tHandler to be a function, getProp etc.
      local tCommand
      put buildDebugEntryMessage(tObject, tHandler, tParameters) into tCommand
      do tCommand
   end if
end actionDebugRun

# Description
#   Performs the debugger "Stop" function. Terminates the script being debugged.
command actionDebugStop
   revDebuggerStop
   revSESetMode "edit"
   seSetDebugContext empty
end actionDebugStop

# Description
#   Performs the debugger "Step Into" function. Moving into the block called by the next statement
#   if applicable. If the next statement cannot be stepped into e.g. because its an engine command
#   then the effect is the same as "Step Over"
command actionDebugStepInto
   local tCurrentObject
   revSEGetCurrentObject
   put the result into tCurrentObject
   revDebuggerStepInto tCurrentObject
   seSetDebugContext empty
end actionDebugStepInto

# Description
#   Performs the debugger "Step Over" function. Executing the next statement and continuing to the one beneath it
#   unless a breakpoint is hit or execution terminates.
command actionDebugStepOver
   local tCurrentObject
   revSEGetCurrentObject
   put the result into tCurrentObject
   revDebuggerStepOver tCurrentObject
   seSetDebugContext empty
end actionDebugStepOver

# Description
#   Performs the debugger "Step Out" function. Executes the remainder of the current block and breaks at the 
#   statement immediately following where the current block was called.
command actionDebugStepOut
  local tCurrentObject
  revSEGetCurrentObject
  put the result into tCurrentObject
  revDebuggerStepOut tCurrentObject
  seSetDebugContext empty
end actionDebugStepOut

# Description
#   Shows the handler list
command actionShowHandlerList
   seShowHandlerList
end actionShowHandlerList

# Description
#   Shows the script editor preferences. For now this is a separate stack, It will be integrated into the Revolution prefs.
command actionShowPreferences
   modeless stack "revPreferencesGUI"
   
   local tSection
   put "Script Editor" into tSection
   
   send "revPrefsGoSection tSection" to stack "revPreferencesGUI"
end actionShowPreferences

# Description
#   Closes the script editor, may prompt the user if unsaved changes exist
command actionClose
   local tModifiedObjects
   revSEGetModifiedObjects
   put the result into tModifiedObjects
   
   if tModifiedObjects is not empty then
      revSEWarnBeforeClosing tModifiedObjects
      if the result is "Cancel" then
         exit actionClose
      end if
   end if
   
   seFinalize
   
   local tStackName
   put the long id of me into tStackName
   send "revSEDeleteSubstack tStackName" to stack (the mainstack of me) in 0 milliseconds
   close me
end actionClose

# Desription
#   Quits Revolution, may prompth the user if unsaved changes exist
command actionQuit
   quit
end actionQuit

command actionAutocompleteSnippetManager
   modeless "com.livecode.palette.autocomplete-pro"
end actionAutocompleteSnippetManager

command actionLaunchMessageBox
   revIDEOpenPalette "Message Box"
end actionLaunchMessageBox

################################################################################
#
# Keyboard shortcut handling
#
################################################################################

# Parameters
#   pKey : the key that the user pressed. This should be the value of the pKey parameter to message triggered
# Returns
#   The name of the key that should be used to search for an associated action
private function shortcutResolveKey pKey
   switch pKey
   case "65360"
      return "home"
   break
   case "65367"
      return "end"
   break
   default
      return pKey
   end switch
end shortcutResolveKey
  
# Parameters
#   pKey : the key that was pressed
#   pCommandKey : the state of the command / ctrl key
#   pOptionKey : the state of the option / alt key
#   pShiftKey : the state of the shift key
#   pContext : the action context, currently this is the long id of the focusedObject
# Description
#   Searches for a shortcut that matches the specified input parameters.
#   If a shortcut is found, the associated action is returned, else empty
#   is returned.
private function shortcutFindAction pKey, pCommandKey, pOptionKey, pShiftKey, pContext
   # List the available shortcut actions
   local tActions
   put sePrefList("shortcuts,*") into tActions
   
   local tPressedKey
   put shortcutResolveKey(pKey) into tPressedKey
   
   # Loop through the available actions and attempt to find one that matches the
   # key combination pressed.
   local tFoundAction, tKeys
   repeat for each line tAction in tActions
      put sePrefGet(tAction) into tKeys
      
      # tKeys may contain multiple lines if there is more than one key combination associated
      # with this action. Loop through each and as soon as we find one that matches, choose that action.
      # It is up to the preferences to ensure that no key combination is associated with more than one
      # action. If this situation ocurrs then the first matching action will be executed.
      repeat for each line tKey in tKeys
         if word -1 of tKey is not tPressedKey then
            next repeat
         end if
         
         if pCommandKey and "command" is not among the words of tKey then
            next repeat
         end if
         
         if not pCommandKey and "command" is among the words of tKey then
            next repeat
         end if
         
         if pShiftKey and "shift" is not among the words of tKey then
            next repeat
         end if
         
         if not pShiftKey and "shift" is among the words of tKey then
            next repeat
         end if
         
         if pOptionKey and "option" is not among the words of tKey then
            next repeat
         end if
         
         if not pOptionKey and "option" is among the words of tKey then
            next repeat
         end if
         
         put item 2 of tAction into tFoundAction
         exit repeat
      end repeat
   end repeat
      
   # Once the action has been found, ensure that the action's context is compatible with 
   # pContext. This ensures for example that things like cut, copy and paste are only
   # handled if the user has focused the editing field.
   local tActionContext
   put sePrefGet("actioncontext," & tFoundAction) into tActionContext
   if tActionContext is not empty then
      if the short name of the owner of pContext is not tActionContext and the short name of pContext is not tActionContext then
         return empty
      end if
   end if
   
   if tFoundAction is not empty then
      return "action" & tFoundAction
   else
      return empty
   end if
end shortcutFindAction

# Description
#   Called when the script editor is about to be closed. Saves various things to make sure the script
#   editor's state is correctly preserved when its re-opened.
command seFinalize
   
   # Notify the IDE
   revSEGetTargetObjects
   revIDEStopEditingScriptOfObjects the result
   
   local tMode
   revSEGetMode
   put the result into tMode
   if tMode is "debug" then
      revDebuggerStop
   end if
   
   send "finalize" to group "Editor" of me
   send "paneCloseControl" to group "Variables" of me
   
   seFindHistorySave
   sePrefSave
   seHistorySave
   
   put empty into sDebugContext
end seFinalize

# Returns
#   Whether or not undo is available, i.e something has been changed in the current script
function seUndoAvailable
   # OK-2009-01-17 : Bug 7597 - We have no way of knowing if undo is available for controls
   # other than the editing field, but we assume it *is* available, in order to let it work for other controls.
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      call "undoAvailable" to group "Editor" of me
       return the result
   else
      return true
   end if
end seUndoAvailable

# Returns
#   Whether or not redo is available, i.e. something has been undone in the current script
function seRedoAvailable
   # OK-2009-01-17 : Bug 7597 - For controls other than the editing field, there is no redo
   if the long id of the owner of the focusedObject is the long id of group "Editor" of me then
      call "redoAvailable" to group "Editor" of me
      return the result
   else
      return false
   end if
end seRedoAvailable

# Description
#   Initializes the left bar of the script editor. This currently contains just a handler list,
#   so here we clone the handler list group used by the toolbar's handler list and copy it into
#   the left bar. This is done to avoid duplicating the code.
private command seInitLeftBar
   lock messages
   if there is a group "Left Handler List" of group "Left Bar" of card 1 of me then
      delete group "Left Handler List" of group "Left Bar" of card 1 of me
   end if
   unlock messages
   
   local tObject
   put seHandlerListObject() into tObject
   
   lock screen
   lock messages
   copy tObject to group "Left Bar" of me  
   unlock messages
   set the cantDelete of it to false
   set the name of it to "Left Handler List"
   unlock screen
   
   seUpdateLeftBar
end seInitLeftBar
   
# Description
#   Updates the left bar of the script editor.
command seUpdateLeftBar
    call "update" to group "Left Bar" of me
 end seUpdateLeftBar
 
 # Description
 #   Updates the toolbar of the script editor
 command seUpdateToolbar
    send "update" to group "Toolbar" of me
 end seUpdateToolbar

 # Description
 #   Called on resumeStack, checks that all the script editor's target objects are still in existence
 #   as some users may delete them with messages locked. Any objects that are found not to exist
 #   anymore are just removed from the script editor for now.
command seCheckTargetsExist
   local tObjects
   revSEGetTargetObjects
   put the result into tObjects
   
   repeat for each line tObject in tObjects
      if there is no tObject then
         revSERemoveTargetObject tObject, true, false, true
      end if
   end repeat
   
   local tCurrentTab
   send "getCurrentTab" to group "Script Tabs" of me
   put the result into tCurrentTab
      
   if tCurrentTab is not empty then
      send "setObject tCurrentTab" to group "Editor" of me
      seUpdateWindowTitle tCurrentTab
   end if
end seCheckTargetsExist

# OK-2008-08-19 : Bug 6947 - Its possible that one or more of the target scripts could have been modified outside
# the script editor while it was suspended. Use the stored checksums to detect if this is the case, and if so, prompt the
# user to either reload the script, or just carry on editing it.
command seCheckTargetChecksums
   local tObjects
   revSEGetTargetObjects
   put the result into tObjects
   
   local tModifiedScripts
   repeat for each line tObject in tObjects
      local tOldChecksum
      put seGetChecksum(tObject) into tOldChecksum
      
      local tScript
      try
         put the script of tObject into tScript
      catch tError
         # If the script is password protected, we don't know whether it has been changed or not, so we just
         # assume it was not for now.
         next repeat
      end try
      
      local tNewChecksum
      put seGenerateChecksum(tScript) into tNewChecksum
      
      if not binaryEquals(tOldChecksum, tNewChecksum) then
         put tObject & return after tModifiedScripts
      end if
   end repeat
   
   if tModifiedScripts is not empty then
      seWarnExternallyModifiedObjects tModifiedScripts
   end if
end seCheckTargetChecksums

command seWarnExternallyModifiedObjects pModifiedObjects
   set the cObjects of stack "revSEModifiedExternallyDialog" to pModifiedObjects
   modal stack "revSEModifiedExternallyDialog"
   
   local tChoice
   put the cChoice of stack "revSEModifiedExternallyDialog" into tChoice
   
   if tChoice is "Reload" then
      local tOldCurrentObject
      revSEGetCurrentObject
      put the result into tOldCurrentObject
      
      # Preserve the order of the tabs when reloading objects
      local tTabOrdering
      send "getTabOrdering" to group "Script Tabs" of me
      put the result into tTabOrdering
      
      lock screen
      repeat for each line tObject in pModifiedObjects
         revSERemoveTargetObject tObject, true, true
         revSEAddTargetObject tObject
         
         local tScript
         put the script of tObject into tScript
         seUpdateChecksum tObject, tScript
      end repeat
      
      send "setTabOrdering tTabOrdering" to group "Script Tabs" of me
      revSESetCurrentObject tOldCurrentObject
      unlock screen
   end if
   
   if tChoice is "cancel" then
      exit seWarnExternallyModifiedObjects
   end if
end seWarnExternallyModifiedObjects

private function binaryEquals p1, p2
   if (the length of p1 = the length of p2) and (p1 contains p2) then
      return true
   else
      return false
   end if
end binaryEquals


################################################################################
#
# Event handlers
#
################################################################################

# Description
#   Sent when the script editor stack is resized. First resizes each script editor object, 
#   then sends a "resize" message to each object to allow the object to resize its controls
#   appropriately to its new size.
on resizeStack
   revIDESetPaletteRectPreference the short name of me
   actionResizeStack
end resizeStack

# Description
#    Sent when the script editor is moved. Saves the new size in the preferences.
on moveStack
   revIDESetPaletteRectPreference the short name of me
end moveStack

# Description
#   Sent when the stack loses focus, restores the message box etc if appropriate
on suspendStack
   revSEShowPalettes
   
   # OK-2008-07-01 : Bug 6678 - Ensure that the script editor settings in the preferences stack are uptodate before
   # the script editor is suspended, so that any other IDE components that may refer directly to the script editor preferences
   # will be able to operate on the correct settings. This also means that if another IDE component calls revSEUpdate with the 
   # pPrefsChanged parameter set to true, the script editor will preserve any settings that had not been saved.
   sePrefSave
end suspendStack

on desktopChanged
   revIDEEnsureOnscreen the short name of this stack
end desktopChanged

# Description
#   Sent when the stack gains focus, hides the message box etc if appropriate
on resumeStack
   revSEHidePalettes
   
   # OK-2008-07-07: Bug 6582 - Some users may delete the object being edited with messages locked, giving the
   # script editor no chance to know that the objects have been deleted. Because of this we need to check every time
   # the script editor is re-focused and deal with any objects which have been removed.
   seCheckTargetsExist
   
   # OK-2008-08-19 : Bug 6947 - Its possible that one or more of the target scripts could have been modified outside
   # the script editor while it was suspended. Use the stored checksums to detect if this is the case, and if so, prompt the
   # user to either reload the script, or just carry on editing it.
   seCheckTargetChecksums
   
   # OK-2008-08-20 : Bug 6966 - Update the variable watcher in case the user has create new global variables while the script editor was suspended.
   local tCurrentPane
   send "getCurrentTab" to group "Pane Tabs" of me
   put the result into tCurrentPane
   if tCurrentPane is "Variables" then
      send "update" to group "Variables" of me
   end if
end resumeStack

# Description
#   Sent when the script editor stack is opened. Initialises the stack...
on preOpenStack pDontCheckTarget
   revSEInitialize pDontCheckTarget
end preOpenStack

# OK-2008-08-20 : Bug 6971 - This must use a non-engine message as suppress messages will block it otherwise due to the use of "call" instead of "send"
command revSEInitialize pDontCheckTarget
   if (pDontCheckTarget is not "true") and (the short name of the target is not the short name of me) and (the short name of the target is not the short name of this card of me) then
      exit revSEInitialize
   end if
   
   # If the script editor is suspended, don't do anything because this probably means its being resumed
   if sSuspended then
      exit revSEInitialize
   end if
   
   dispatch "ideSubscribe" to me with "idePreferenceChanged:cREVScriptDebugMode"
   
   # Initialize the preferences
   sePrefInit
   
   # Load the history
   seHistoryLoad
   
   # Load the find history
   seFindHistoryLoad
   
   # Initialize the editor and tabs
   call "initialize" to group "Script Tabs" of me
   call "initialize" to group "Editor" of me
   
   # OK-2009-04-24 : Update the menubar group if we're on OS X.
   if seGetPlatform() is "MacOS" then
      call "update" to group "Menubar" of me
   end if
   
   # Update the toolbar
   call "update" to group "Toolbar" of me
   
   # Make sure the handler list is not showing
   seHideHandlerList
   
   # Initialize the left bar, this currently just contains a handler list.
   seInitLeftBar
   
   # Initialize the panes and sure the correct one is selected
   lock screen
   repeat for each item tPane in seAvailablePanes()
      call "paneCloseControl" to group tPane of group "Panes" of me
      call "paneOpenControl" to group tPane of group "Panes" of me
   end repeat
   unlock screen
   
   local tMode
   revSEGetMode
   put the result into tMode
   
   local tLastSelectedPane
   put sePrefGet(tMode & ",lastSelectedPane") into tLastSelectedPane
   call "setCurrentTab tLastSelectedPane" to group "Pane Tabs" of me
   
   # On OS X, toplevel windows have a white background, which is both inconsistent with the rest of the IDE
   # and looks bad.
   if seGetPlatform() is "MacOS" then
      set the backgroundColor of me to "236,236,236"
   end if
   
   actionResizeStack true
   
   set the showInvisibles of me to false
end revSEInitialize

on idePreferenceChanged pPreference, pValue
   switch pPreference
      case "cREVScriptDebugMode"
         revSEUpdate true
         break
   end switch
end idePreferenceChanged

on closeStackRequest
   if the long id of the target is not the long id of this card of me then
      pass closeStackRequest
   end if
   
   local tModifiedObjects
   revSEGetModifiedObjects
   put the result into tModifiedObjects
   
   if tModifiedObjects is empty then
      seFinalize
      pass closeStackRequest
   end if
   
   revSEWarnBeforeClosing tModifiedObjects
   if the result is not "cancel" then
      seFinalize
      pass closeStackRequest
   end if
end closeStackRequest

# Description
#   This handles tabKey based keyboard shortcuts. The only one by default is to switch between tabs
#   Note that only command + tab shortcuts are allowed to prevent interference with other functions.
on tabKey
   # bhall2001-2017-07-18: Bug 18366 On MacOS, Use control+tab to cycle between tabs
   if (the commandKey is not "down") and (the platform is not "MacOS") then
      pass tabKey
   end if

   if (the platform is "MacOS") and (the controlKey is not "down") then
      pass tabKey
   end if
   
   local tAction
   put shortcutFindAction("tab", true, (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
   if tAction is empty then
      pass tabKey
   else
      do tAction
   end if
end tabKey


# Description
#   This handles commandKey based keyboard shortcuts.
on commandKeyDown pKey
  local tAction
  put shortcutFindAction(pKey, true, (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
  
  if tAction is empty then
    pass commandKeydown
  else
    do tAction
  end if
end commandKeyDown

# Description
#   This handles functionKey based keyboard shortcuts
on functionKey pKey
  local tAction
  put shortcutFindAction(("f" & pKey), (the commandKey is "down"), (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
  
  if tAction is empty then
    pass functionKey
  else
    do tAction
  end if
end functionKey
  
# Description
#   This handles enter based keyboard shortcuts, along with enterKey. Which one is sent depends whether a field is focused or not. 
on enterInField
   local tAction
   put shortcutFindAction("enter", (the commandKey is "down"), (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
   
   if tAction is empty then
      pass enterInField
   else
      do tAction
   end if
end enterInField

# Description
#   This handles enter based keyboard shortcuts, along with enterInField. Which one is sent depends whether a field is focused or not.
on enterKey
   local tAction
   put shortcutFindAction("enter", (the commandKey is "down"), (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
   
   if tAction is empty then
      pass enterKey
   else
      do tAction
   end if
end enterKey

# Description
#   This handles return based keyboard shortcuts, along with returnInField. Which one is sent depends on whether a field is focused or not.
#   Note that one of the default shortcuts is COMMAND + RETURN, to apply scripts. When the user presses this combination of keys, a returnKey
#   or returnInField is generated, not a commandKeyDown as one might expect.
on returnKey
   local tAction
   put shortcutFindAction("return", (the commandKey is "down"), (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
   
   if tAction is empty then
      pass returnKey
   else
      do tAction
   end if
end returnKey

# Description
#   This handles return based keyboard shortcuts, along with returnKey. Which one is sent depends on whether a field is focused or not.
#   Note that one of the default shortcuts is COMMAND + RETURN, to apply scripts. When the user presses this combination of keys, a returnKey
#   or returnInField is generated, not a commandKeyDown as one might expect.
on returnInField
   local tAction
   put shortcutFindAction("return", (the commandKey is "down"), (the optionKey is "down"), (the shiftKey is "down"), the long id of the focusedObject) into tAction
   
   if tAction is empty then
      pass returnInField
   else
      do tAction
   end if
end returnInField

# Description
#   Handles the event when the user presses the escape key. This is not part of the shortcuts system, its behavior is not configurable
on escapeKey
   # If there is a handler list open, close it and exit
   if seHandlerListIsShowing() then
      seHideHandlerList
      exit escapeKey
   end if
   
   # If there is a find and replace dialog open, close it and exit
   if the cCaller of stack "revSEFind" is the long id of me and the mode of stack "revSEFind" is not 0 then
      close stack "revSEFind"
      exit escapeKey
   end if
   
   # If interactive find is showing and the editor group has focus, then close interactive find.
   send "hideInteractiveFind" to group "Editor" of me
end escapeKey

# Description
#    Handles the event when the user presses one of the arrow keys. At the moment this is done only for the variable
#    watcher pane when debugging, to allow variables to be scrolled through without using the mouse
on arrowKey pKey
   local tMode
   revSEGetMode
   put the result into tMode
   if tMode is "edit" then
      pass arrowKey
   end if
   
   local tCurrentPane
   send "getCurrentTab" to group "Pane Tabs" of me
   put the result into tCurrentPane
   
   if tCurrentPane is not "variables" then
      pass arrowKey
   end if
   
   if pKey is "up" then
      send "hiliteMoveUp" to group "Variables" of me
   else if pKey is "down" then
      send "hiliteMoveDown" to group "Variables" of me
   end if
   
   pass arrowKey
end arrowKey

# Returns
#   The current script in a form suitable for displaying on a web page with CSS. This is designed for a specific
#   task and should not be called in any main script editor code.
function seScriptAsHtml
   send "scriptGetAsHtml" to group "Editor" of me
   return the result
end seScriptAsHtml

# Description
#   Updates the script editor's window title.
command seUpdateWindowTitle pObject
   if sMode is "debug" then
      set the title of me to seCreateWindowTitle(pObject) & " (debugging)"
   else
      set the title of me to seCreateWindowTitle(pObject) & " (editing)"
   end if
end seUpdateWindowTitle

# Parameters
#   pObject : a valid reference to an object
# Returns
#   The title that the script editor window should have if pObject is the current object
#   being edited.
function seCreateWindowTitle pObject
   return revDebuggerObjectLongName(pObject) & " - Code Editor"
end seCreateWindowTitle

command seUpdateCheckSum pObject, @pScript
   local tChecksum
   put seGenerateChecksum(pScript) into tChecksum
   put tChecksum into sScriptChecksums[pObject]
end seUpdateCheckSum

function seGenerateChecksum @pScript
   return md5digest(pScript)
end seGenerateChecksum

function seGetCheckSum pObject
   return sScriptChecksums[pObject]
end seGetCheckSum

# Parameters
#   pObject : reference to an object
#   pHandler : the specification of a public handler in the script of pObject, in the form <type>,<name>
#   pParameters : a list of parameters, one per line, in the form <name>,<value>
# Returns
#   A piece of Revolution code that can be executed in order to trigger the specified handler in the specified
#   object to run.
function buildDebugEntryMessage pObject, pHandler, pParameters
   # Process the parameters. In order to keep things clean and simple, we do this by putting each parameter into a variable
   # and forming two strings, one which declares and populates these variables, and one which contains a list of them to pass
   # to the handler we call. We also create another string which represents the parameters in the form of a revolution expression,
   # this third string is needed to get functions working properly.
   local tParameterNumber
   put 1 into tParameterNumber
   
   local tParameterDeclarations, tParameterString, tParameterExpression
   repeat for each line tParameter in pParameters
      put "local tParam" & tParameterNumber & return after tParameterDeclarations
      
      # Escape quotes from the parameters
      local tValue
      put item 2 to -1 of tParameter into tValue
      replace quote with (quote & " & quote & " & quote) in tValue
      
      put quote & " & quote & " & quote & tValue & quote & " & quote & " & quote & comma after tParameterExpression
      put "put " & quote & tValue & quote & " into tParam" & tParameterNumber & return after tParameterDeclarations
      put "tParam" & tParameterNumber & comma & space after tParameterString
      add 1 to tParameterNumber
   end repeat
   delete the last char of tParameterDeclarations
   delete char -2 to -1 of tParameterString
   delete char -1 of tParameterExpression
   
   # Now the parameters are sorted, generate the command that triggers the entry point.
   local tCommandString
   switch item 1 of pHandler
      case "M"
      case "C"
         # event handlers and commands, we can just do a simple "send" to trigger these into action
         # we do the send in 0 milliseconds to allow the script editor to fall out of the call stack before the code is executed.
         put tParameterDeclarations & return into tCommandString
         put "send " & quote & item 2 of pHandler && tParameterString & quote & " to " & pObject & " in 0 milliseconds" after tCommandString
      break
         
      case "F"
         # functions can be evaluated using the value function, but getting the parameters working is rather tricky...
         local tExpression
         put quote & item 2 of pHandler & "(" & tParameterExpression & ")" & quote into tExpression
         put "local tExpression" & return & "put " & tExpression & " into tExpression" & return into tCommandString
         put "get value(tExpression, " & pObject & ")" after tCommandString
      break
         
      case "G"
         # getprops can be evaluated using the get command. For these, we ignore the parameter string.
         put "get the " & item 2 of pHandler & " of " & pObject into tCommandString
      break
         
      case "S"
         # setprops, for now we simply create a set command to trigger these.
         put tParameterDeclarations & return into tCommandString
         put "set the " & item 2 of pHandler & " of " & pObject & " to " & item 1 of tParameterString after tCommandString
      break
   end switch
   
   return tCommandString
end buildDebugEntryMessage

////////////////////////////////////////////////////////////////////////////////

# Used by the tutorial system to interact with elements of the script editor
function absoluteRectOfObject pObject
   local tRect
   if pObject is "Apply" then
      put the rect of button "Compile" of me into tRect
   else if there is a button pObject of me then
      put the rect of button pObject of me into tRect
   else if there is a group pObject of group "Panes" of me then
      put the rect of group pObject of group "Panes" of me into tRect
   else
      local tLine, tStart, tEnd
      put lineOffset(pObject, field "Script" of me) into tLine
      put the charIndex of line tLine of field "Script" of me into tStart
      put the charIndex of char 10 of line tLine of field "Script" of me into tEnd
      put the formattedRect of char tStart to tEnd of field "Script" of me into tRect
      # Adjust rect by the current text height - seems to result in the correct rect
      put item 4 of tRect - the effective textHeight of field "Script" of me into item 4 of tRect
   end if
   put revIDERelativeRectToAbsolute(tRect, me) into tRect
   return tRect
end absoluteRectOfObject

on highlightObject pObject
   if there is a group pObject of group "Panes" of me then
      call "setCurrentTab pObject" to group "Pane Tabs" of me
   else 
      local tLine
      put lineOffset(pObject, field "Script" of me) into tLine
      if tLine not 0 then
         dispatch "goLine" to field "Script" of me with tLine, true
      end if
   end if
end highlightObject

on revSESetScript pScript
   dispatch "textSetScript" to field "Script" of me with pScript
end revSESetScript

function revSEGetScript pScript
   dispatch function "textGetScript" to field "Script" of me
   return the result
end revSEGetScript

on revSEIndentScript
   dispatch "scriptFormat" to field "Script" of me with "script"
end revSEIndentScript

on revSEApply pIgnoreErrors
   actionCompile pIgnoreErrors
end revSEApply

function revSEGetSelectedText
   return the selectedText of field "Script" of me
end revSEGetSelectedText

private command appendToList @xList, pValue
   if xList is not empty then
      put return & pValue after xList
   else
      put pValue into xList
   end if
end appendToList

local sHandlersA
private function getHandlerList pObjType
   get the keys of sHandlersA[pObjType]
   sort it 
   return it
end getHandlerList

private function revSEDefaultHandlerInfoForObjectType pObjType
   if sHandlersA[pObjType] is not empty then
      return getHandlerList (pObjType)
   end if
   
   local tMessages
   put ideDocsFetchLCSElementsOfType("message") into tMessages
   
   local tMessageList
   repeat for each element tElement in tMessages
      local tAssociations
      put tElement["Associations"] into tAssociations
      filter elements of tAssociations with pObjType
      if tAssociations is not empty then
         put tElement into tMessageList[tElement["display name"]]
      end if
   end repeat
   put tMessageList into sHandlersA[pObjType]
   return getHandlerList(pObjType)
end revSEDefaultHandlerInfoForObjectType

private function revSEDefaultHandlerInfoForWidget pWidgetKind
   if sHandlersA[pWidgetKind] is not empty then
      return getHandlerList(pWidgetKind)
   end if
   local tMessages
   put ideDocsFetchExtensionElementsOfType(pWidgetKind, "message") into tMessages
   
   local tMessageList
   repeat for each element tElement in tMessages
      put tElement into tMessageList[tElement["display name"]]
   end repeat
   put tMessageList into sHandlersA[pWidgetKind]
   return getHandlerList(pWidgetKind)
end revSEDefaultHandlerInfoForWidget

function revSEDefaultHandlers
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   if tObject is empty then
      return empty
   end if
   return revSEDefaultHandlersForObject(tObject)
end revSEDefaultHandlers

function revSEDefaultHandlersForObject pObj
   local tType
   put word 1 of the name of pObj into tType
   if tType is "widget" then
      local tKind
      put the kind of pObj into tKind
      return revSEDefaultHandlerInfoForWidget(tKind)
   end if
   
   return revSEDefaultHandlerInfoForObjectType(tType)
end revSEDefaultHandlersForObject

function revSEConstructDefaultScript pObj, pHandler
   local tType
   put word 1 of the name of pObj into tType
   if tType is "widget" then
      put the kind of pObj into tType
   end if
   
   local tInfo
   put sHandlersA[tType][pHandler] into tInfo
   
   local tScript
   -- Don't include summary for now as it has some docs specific markup
   --put "--" && tInfo["Summary"] & return into tScript
   put "on" && pHandler after tScript
   repeat with x = 1 to the number of elements in tInfo["params"]
      if x is not 1 then
         put "," after tScript
      end if
      put " " & tInfo["params"][x]["name"] after tScript
   end repeat
   local tIndent
   repeat for sePrefGet("editor,tabdepth")
      put space after tIndent
   end repeat
   put return & tIndent & return & "end" && pHandler after tScript
   return tScript
end revSEConstructDefaultScript

command revSEAddDefaultHandler pHandler
   local tDefaultScript, tObject
   revSEGetCurrentObject
   put the result into tObject
   put revIDEDefaultScript(tObject, pHandler) into tDefaultScript
   
   if tDefaultScript is empty then
      put revSEConstructDefaultScript(tObject, pHandler) into tDefaultScript
   end if
   
   local tNewScript
   put revSEGetScript() into tNewScript
   if tNewScript is not empty then
      if the last line of tNewScript is not empty then
         put return after tNewScript
      end if
      put return after tNewScript
   end if
   put tDefaultScript after tNewScript
   revSESetScript(tNewScript)
end revSEAddDefaultHandler
