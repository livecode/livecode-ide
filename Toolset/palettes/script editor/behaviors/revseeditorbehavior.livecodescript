script "revSEEditorBehavior"
# Stores the following mapping
#  <handler name>,type   => string representing the handler type eg PF for private function
# <handler name>,start  => line offset to start of handler
#  <handler name>,end    => line offset to end of handler
# The map is updated whenever scriptCompile is called.
local sHandlerMap

# The following variables store information used for the undo / redo system.
local sTextOperationOffsets
local sTextOperationNewTexts
local sTextOperationOldTexts
local sTextOperationIndex

local sTextOperationTop

local sTextGroupLabels
local sTextGroupLengths
local sTextGroupIndex
local sTextGroupTop

local sTextGutterNumbers
local sTextGutterOverlay
local sTextGutterLastNumber

local sTextFormatKeywordMap

local sTextMark

# These two variables store which object the current search was started on, and which#
# object the most recent result was found in respectively.
local sFirstFindObject
local sLastFindObject

# OK-2009-01-17 : Bug 7169 - Store whether scripts are "dirty" or not, i.e whether the user has actually
# modified them, as opposed to they were modified by the script editor. (This can happen in the case of template scripts)
local sDirty

################################################################################
#
# Editor object interface, please do not call any commands / functions outside the
# following section.
#
################################################################################

# OK-2009-01-17 : Bug 7169
command setDirty pObject, pValue
   put pValue into sDirty[pObject]
end setDirty

command getDirty pObject
   return sDirty[pObject]
end getDirty

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

local sObjectId
local sUniqueId

# Description
#   Sent by the parent when editor group is about to be used for the first time
#   Initializes the group. Note that this is also called when there are no more
#   objects to edit, this may happen when the user has removed the last object
#   from the script editor. This is the reason why this command saves the previous
#   context before putting empty into sObjectId.
command initialize
   if sObjectId is not empty then
      contextSave
   end if
   
   lock screen
   textInitialize
   call "initialize" to group "Gutter" of me
   
   set the backgroundColor of field "Script" of me to sePrefGet("editor,backgroundcolor")
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
   
   put empty into sObjectId
   put 0 into sUniqueId
   
   unlock screen
end initialize

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
   set the hScrollbar of field "Script" of me to (sePrefGet("editor,hscrollbar") is "true")
   
   updateGutterRequest empty, empty, empty, empty, false, false, true
   resize
   unlock screen
end reapplyPreferences

# Stores an array of cached object scripts for switching back to objects with unsaved changes
local sScriptCache

local sLastSelections

# Description
#   Saves the script editor context of the current object as metadata on that object.
#   The context includes such information as vscroll and selected chunk. For selections,
#   we save the last char of the selection as metadata on the object, and the full selection
#   in memory as a script local. Thus full selections are remembered when switching tabs, but only
#   the location of the selection is remembered when opening a new tab or after restarting rev.
private command contextSave
   revMetadataSet sObjectId, "general", "scripteditorvscroll", the vScroll of field "Script" of me
   
   if the long id of the focusedObject is the long id of field "Script" of me then
      get the selectedChunk
      put word 2 of it & comma & word 4 of it into sLastSelections[sObjectId]
      revMetadataSet sObjectId, "general", "scripteditorselection", word 4 of it
   end if
end contextSave

local sLastSelectedChunk

# Description
#   Loads the previously saved context for for current object if one was saved.
private command contextLoad
   local tSelection
   
   if sLastSelections[sObjectId] is not empty then
      # If there is a last selection stored in memory, this means the user has previously opened this object
      # and is just changing tabs. In this case we remember the entire selection.
      put sLastSelections[sObjectId] into tSelection
   else
      # If there is no last selection in memory, this means either the user didnt select anything, or they
      # have not opened the object yet. In this case we only remember the location of the selection, not what was selected.
      # This information is stored as object metadata. In previous versions of the script editor, both the selection start and end
      # were stored, but this was changed to store only the selection end. This change is what warrants the extra check.
      put revMetadataGet(sObjectId, "general", "scripteditorselection") into tSelection
      
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
         put tSelection into sLastSelectedChunk
      end try
   end if
   
   local tScroll
   put revMetadataGet(sObjectId, "general", "scripteditorvscroll") into tScroll
   
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
   put sScriptCache[sObjectId] into tCachedScript
   lock screen
   if tCachedScript is not empty then
      # If there is a cached script, this means that the user is coming back to this object from another tab.
      textSetScriptRaw tCachedScript
   else
      # If the object has no script, get the default script for it, otherwise the current script is used
      if the script of sObjectId is not empty then
         local tScript
         put the script of sObjectId into tScript
         
         textSetScriptRaw tScript
         
         # OK-2008-07-07 : Bug 6746
         seUpdateCheckSum sObjectId, tScript
      else
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

# Parameters
#   pObjectId : reference to the object to set the script to. Must be one of the target objects of the script editor.
# Description
#   Sets the current target object of the editor group.
command setObject pObjectId, pDontSendCallbacks
   local tRuggedObjectId
   put seGetRuggedId(pObjectId) into tRuggedObjectId

   if sObjectId is not empty and tRuggedObjectId is sObjectId then
      if not pDontSendCallbacks then
         seSendCallbacks sObjectId, the name of stack (revTargetStack(the long id of me))
      end if
      exit setObject
   end if
   
   # If we are closing a previous object and the script has not been applied,
   # cache the script of the previous object internally, and save the context
   if sObjectId is not empty then
      put textGetScript() into sScriptCache[sObjectId]
      if there is a sObjectId then
         contextSave
      end if
   end if
   
   lock screen
   
   # It appears that changing the text of the field does not remove all styles,
   # so it is necessary to reset the fonts here, otherwise when changing tabs after the textSize has
   # been changed, the the textSize will appear to revert back to what it was previously.
   initializeFonts
   
   findClearResults
   
   EditorFieldCacheSwap sObjectId, tRuggedObjectId
   put tRuggedObjectId into sObjectId
   loadScript
   resize
   unlock screen
   
   if not pDontSendCallbacks then
      seSendCallbacks sObjectId, the name of stack (revTargetStack(the long id of me))
   end if
end setObject

# Description
#   Reverts the script of the current object to the last applied version
command revertObject
   loadScript
   seSetObjectState sObjectId, "applied"
end revertObject

# Parameters
#   pObjectId : reference to the object to set the script to. Must be the same object as is currently set.
# Description
#   Sets the object being edited to the specified object *without* changing the script. This should be called
#   when the object being edited has changed ids, been moved to a new stack etc, anything that might change
#   its rugged id. It should not be called outside this situation as stuff will break.
command setObjectRaw pObjectId
   local tOldObjectId
   put sObjectId into tOldObjectId
   
   put seGetRuggedId(pObjectId) into sObjectId
   
   if tOldObjectId is empty then
      exit setObjectRaw
   end if
   
   # If there was a previous object and we are changing its id, then we have to update all the script locals
   # that may contain references to the old object. This is rather ugly, but it allows things like undo to work
   # even when objects are moved.
   local tStateData
   
   # Script cache, stores unapplied scripts when tabs are changed
   updateArrayKey sScriptCache, tOldObjectId, sObjectId
   
   # Undo stuff
   updateMultiItemArrayKey sTextOperationOffsets, tOldObjectId, sObjectId, 44, 1
   updateMultiItemArrayKey sTextOperationOldTexts, tOldObjectId, sObjectId, 44, 1
   updateMultiItemArrayKey sTextOperationNewTexts, tOldObjectId, sObjectId, 44, 1
   updateArrayKey sTextOperationTop, tOldObjectId, sObjectId
   updateArrayKey sTextOperationIndex, tOldObjectId, sObjectId
   
   updateMultiItemArrayKey sTextGroupLabels, tOldObjectId, sObjectId, 44, 1
   updateMultiItemArrayKey sTextGroupLengths, tOldObjectId, sObjectId, 44, 1
   updateArrayKey sTextGroupIndex, tOldObjectId, sObjectId
   updateArrayKey sTextGroupTop, tOldObjectId, sObjectId
   updateArrayKey sTextMark, tOldObjectId, sObjectId
   
   # Find results
   if sLastFindObject is tOldObjectId then
      put sObjectId into sLastFindObject
   end if
   
   if sFirstFindObject is tOldObjectId then
      put sObjectId into sFirstFindObject
   end if
end setObjectRaw


# Parameters
#   pArray : reference to an array. This gets modified
#   pOldKey : one of the array keys
#   pNewKey : the new key to replace pOldKey with
# Description
#   Removes the element pOldKey from the array, and creates
#   a new element pNewKey with the same data. Essentially renaming the key.
#   If the element is empty, does nothing.
private command updateArrayKey @pArray, pOldKey, pNewKey
   local tData
   if pArray[pOldKey] is not empty then
      put pArray[pOldKey] into tData
      delete variable pArray[pOldKey]
      put tData into pArray[pNewKey]
   end if
end updateArrayKey

# Parameters
#   pArray : reference to an array. This gets modified
#   pOldKey : one of the array keys
#   pNewKey : the new key to replace pOldKey with
#   pDelimiter : an ascii char code that delimits dimensions in the array's key. If empty, comma is assumed.
#   pItemNumer : which item number of the key needs to match pOldKey
# Description
#   Removes all keys with the specified dimension matching pOldKey from the array
#   and replaces them with equivalent keys matching pNewKey.
private command updateMultiItemArrayKey @pArray, pOldKey, pNewKey, pDelimiter, pItemNumber
   local tData
   
   if pDelimiter is not empty then
      set the itemDelimiter to numToChar(pDelimiter)
   end if
   
   # Create a list of keys that need to be modified
   local tKeys
   repeat for each line tKey in the keys of pArray
      if item pItemNumber of tKey is pOldKey then
         put tKey & return after tKeys
      end if
   end repeat
   delete the last char of tKeys
   
   if tKeys is empty then
      exit updateMultiItemArrayKey
   end if
   
   # Apply the modification to the keys
   repeat for each line tKey in tKeys
      local tNewKey
      put tKey into tNewKey
      put pNewKey into item pItemNumber of tNewKey
      put pArray[tKey] into pArray[tNewKey]
      delete variable pArray[tKey]
   end repeat
end updateMultiItemArrayKey

# Description
#   Returns a reference to the current object being edited.
command getObject
   return sObjectId
end getObject

# Description
#   Returns the number of the selected line in the current script
command getSelectedLine
   return word 2 of the selectedLine
end getSelectedLine

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
   # The script is compiled before updating the handler list. We temporarily turn off
   # variable checking before this.
   local tOldVarChecking
   put sePrefGet("explicitVariables") into tOldVarChecking
   sePrefSet "explicitVariables", "false"
   scriptCompile sObjectId
   sePrefSet "explicitVariables", tOldVarChecking
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
   delete variable sScriptCache[tObject]
   delete variable sLastSelections[tObject]
end clearCache

--command revertCache pObject
--   local tObject
--   put seGetRuggedId(pObject) into tObject
--   delete variable sLastSelections[tObject]
--   put the script of tObject into sScriptCache[tObject]
--end revertCache

# Description
#  Returns the last known token that the caret was placed into. This is not done properly
#  at the moment as it depends on the syntax, for now we just return something sensible.
command getCaretToken pUseClick
   local tScript
   put the text of getScriptField() into tScript
   
   # Don't return tokens in comments. For now we determine if the user is typing
   # in a comment by simple means, using proper tokenization is not yet possible.
   # This means that multi-line comments will break this.
   local tLine
   if pUseClick then
      put word 2 of the clickLine into tLine
   else
      put word 2 of the selectedLine of getScriptField() into tLine
   end if
   if token 1 of line tLine of tScript is empty then
      return empty
   end if
   
   local tSelectedText
   if pUseClick then
      put the clickText into tSelectedText
   else
      put the selectedText of getScriptField() into tSelectedText
      # OK-2008-06-22 : Bug 8054 - pUseClick is only set if we are building a context menu, so in this case
      # do the expansion anyway to try and get a whole token.
      if tSelectedText is not empty then
         return tSelectedText
      end if
   end if
   
   # This is expanded to include tokens that the caret was placed immediately before or after,
   # the reason for this is that it allows us to begin searching for tokens while the user is typing.
   local tFrom, tTo
   if pUseClick then
      get the clickChunk
   else
      get the selectedChunk
   end if
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   # We can't perfectly match tokens at the moment, so we just make a reasonable guess with a regular expression
   # to match any char that delimits a token.
   ## AL-2014-01-15: [[ Bug 11094 ]] Added # to the list of script editor token delimiters
   local tExpression 
   put "\s|[\%\^\&\*\(\)\-\+\=\]\]\;\,\\@\\\/\<\>\#]" into tExpression
   
   # Try looking backwards first
   local tText, tChar
   repeat with x = (tFrom - 1) down to 1
      put char x of tScript into tChar
      if matchText(tChar, tExpression) then
         exit repeat
      end if
      put tChar before tText
   end repeat
   
   # Try looking forwards
   repeat with x = tFrom to the number of chars of tScript
      put char x of tScript into tChar
      if matchText(tChar, tExpression) then
         exit repeat
      end if
      put tChar after tText
   end repeat
   
   return tText
end getCaretToken

local slastNonEmptySelection

command getLastSelection
   return slastNonEmptySelection
end getLastSelection

command getLastSelectedWord
   local tFrom, tTo
   put item 1 of sLastSelectedChunk into tFrom
   put item 2 of sLastSelectedChunk into tTo
   
   # If there is a non empty selection, just return that.
   if tTo > tFrom then
      return char tFrom to tTo of the text of getScriptField()
   end if
   
   # If the selection is in the middle of a word, then return that.
   # First loop back from the selected character to find the first part of the word. Keep going until we find a character
   # that is either whitespace, or a bracket.
   local tWordDivider
   put merge("^[\[[quote]]|\[|\]\(|\)|\s]$") into tWordDivider
   
   local tBefore
   repeat with x = tTo down to 1
      get char x of the text of getScriptField()
      if matchText(it, tWordDivider) then
         exit repeat
      end if
      put it before tBefore
   end repeat
   
   local tAfter
   repeat with x = tTo + 1 to the number of chars of the text of getScriptField()
      get char x of the text of getScriptField()
      if matchText(it, tWordDivider) then
         exit repeat
      end if
      put it after tAfter
   end repeat
   
   local tWord
   put tBefore & tAfter into tWord
   return tWord
end getLastSelectedWord

# Description
#   Locks the script to prevent the uesr from editing it. Used by the debugger.
command scriptLock
   set the lockText of field "Script" of me to true
   set the backgroundColor of field "Script" of me to sePrefGet("editor,debugBackgroundcolor")
end scriptLock

# Returns
#   Whether or not the script is locked
private function scriptLocked
   return the lockText of field "Script" of me
end scriptLocked

# Description
#   Unlocks the script, allowing the user to edit it.
command scriptUnlock
   set the lockText of field "Script" of me to false
   set the backgroundColor of field "Script" of me to sePrefGet("editor,backgroundColor")
end scriptUnlock

# Returns
#   Whether or not the current object script is password protected.
private function scriptProtected
   # Prevent errors when editing the script editor.
   if sObjectId is empty then
      return false
   end if
   
   local tStack
   put revTargetStack(sObjectId)  into tStack
   
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
   if seGetRuggedId(pObject) is sObjectId then
      updateGutterRequest empty, empty, empty, empty, false, true
   end if
end setCompilationErrors

# Parameters
#   rStartLine : receives the line number that the current selection begins on
#   rEndLine : receices the line number that the current selection ends on
#   rStartChar : receives the char that the curent selection starts on
#   rText : receives the block of text that will be commented or uncommented.
# Description
#   This command obtains the details required to comment / uncomment a block of code
#   it is used by the scriptComment and scriptUncomment commands.
private command commentGetDetails @rStartLine, @rEndLine, @rStartChar, @rText
   # Calculate the chunk of text that the commenting will be applied to
   local tStartLine, tEndLine
   get the selectedLine
   put word 2 of it into tStartLine
   if word 3 of it is "to" then
      put word 4 of it into tEndLine
   end if
   
   # Adjust the chunk so that we have only complete lines by searching from the beginning
   # backwards to the next return char. Don't bother doing this for the end as this doesn't matter.
   get the selectedChunk
   local tCurrentStart
   put word 2 of it into tCurrentStart
   
   local tStartChar
   
   if tStartLine = 1 then
      put 1 into tStartChar
   else
      local tPreviousChars
      put char 1 to (tCurrentStart - 1) of field "Script" of me into tPreviousChars
      
      local tOffset
      put 0 into tOffset
      repeat with x = the number of chars of tPreviousChars down to 1
         if char x of tPreviousChars is return then
            exit repeat
         end if
         add 1 to tOffset
      end repeat
      #subtract 1 from tOffset
      
      put tCurrentStart - tOffset into tStartChar
   end if
   
   # Get the text and add in the comments
   local tText
   if tEndLine is empty then
      put line tStartLine of field "Script" of me into tText
   else
      put line tStartLine to tEndLine of field "Script" of me into tText
   end if
   
   put tStartChar into rStartChar
   put tStartLine into rStartLine
   put tEndLine into rEndLine
   put tText into rText
end commentGetDetails

# Description
#   Comments out the selected text
command scriptComment
   local tStartLine, tEndLine, tStartChar, tText
   commentGetDetails tStartLine, tEndLine, tStartChar, tText
   if tStartLine is empty then
      exit scriptComment
   end if
   
   lock screen
   
   local tCommentChar
   put sePrefGet("editor,commentchar") & space into tCommentChar
   
   local tCommentedText
   repeat for each line tLine in tText
      # Don't comment out empty lines as it looks messy
      if not matchText(tLine, "^\s*$") then
         put tCommentChar before tLine
      end if
      put tLine & return after tCommentedText
   end repeat
   delete the last char of tCommentedText
   
   # Apply the mutation to the field
   textMark "Insert"
   textReplace tStartChar, tText, tCommentedText
   
   # Restore the selection
   select char tStartChar to tStartChar + length(tCommentedText)  of field "Script"
   
   # OK-2009-03-03 : Bug 7537 - Reformat the handler after commenting, this may be flawed,
   # but the proper solution is rather time-consuming.
   if sePrefGet("editor,autoformat") then
      scriptFormat "handler"
   end if
   
   unlock screen
end scriptComment

# Desription
#   Uncomments the selected text
command scriptUncomment
   local tStartLine, tEndLine, tStartChar, tText
   commentGetDetails tStartLine, tEndLine, tStartChar, tText
   if tStartLine is empty then
      exit scriptUncomment
   end if
   
   lock screen
   local tCommentChar
   put sePrefGet("editor,commentchar") into tCommentChar
   local tUncommentedText
   
   local tCommentCharLength
   put the length of tCommentChar  into tCommentCharLength
   
   repeat for each line tLine in tText
      # Remove the first comment char that appears on the line
      local tOffset
      put offset(tCommentChar, tLine) into tOffset
      if tOffset is 0 then
         put tLine & return after tUncommentedText
         next repeat
      end if
      
      # Only remove the comment char if there is nothing significant before it
      # MM-2012-09-28: [[ Bug 10162 ]] Make sure we include lines with chars before the comment in the uncommented text.
      local tPreviousChars
      put char 1 to (tOffset - 1) of tLine into tPreviousChars
      if matchText(tPreviousChars, "^\s*$") then
         if char tOffset + tCommentCharLength of tLine is space then
            delete char tOffset + tCommentCharLength of tLine
         end if
         put char 1 to (tOffset - 1) of tLine & char (tOffset + tCommentCharLength) to -1 of tLine & return after tUncommentedText
      else
         put tLine & return after tUncommentedText
      end if
   end repeat
   delete the last char of tUncommentedText
   
   # Apply the mutation to the field
   textMark "Insert"
   textReplace tStartChar, tText, tUncommentedText
   
   # Restore the selection
   select char tStartChar to tStartChar + length(tUncommentedText)  of field "Script"
   
   # OK-2009-03-03 : Bug 7537 - Reformat the handler after commenting, this may be flawed,
   # but the proper solution is rather time-consuming.
   if sePrefGet("editor,autoformat") then
      scriptFormat "handler"
   end if
   
   unlock screen
end scriptUncomment

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
#   pOption : one of three possible strings, see below for details.
#   pValue : depends on pOption, details below.
# Description
#   Colorizes the current script. pOption is one of the following options.
#     "script" - colorize the whole script (default). pValue is ignored.
#     "line" - colorize a particular line, pValue is the line number
#     "handler" - colorize a particular handler, pValue is the handler name. Currently not implemented.
command scriptColorize pOption, pValue
   if pOption is "script" then
      _internal script colorize char 1 to (the number of chars of field "Script" of me) of field "Script" of me
   else if pOption is "line" then
      _internal script colorize line pValue to pValue of field "Script" of me
   end if
end scriptColorize

# Formats the specified script snippet.
command scriptFormatSnippet pScript
   textFormatInitialize
   local tNewScript
   put textFormatSelection(pScript) into tNewScript
   return tNewScript
end scriptFormatSnippet


# Parameters
#   pScope : either "script" or "handler"
# Description
#   Formats the current script according to the pScope parameter. If pScope is "script", then
#   entire script is formatted. If pScope is handler, then the current handler is formatted.
#   Note, formatting the whole script could be quite slow.
command scriptFormat pScope
   lock screen
   local tScroll
   put the vScroll of field "Script" of me into tScroll
   
   local tStart, tEnd
   get the selectedChunk
   put word 2 of it into tStart
   put word 4 of it into tEnd
   
   if pScope is "script" then
      local tStartChar
      put 1 into tStartChar
      
      local tOldText
      put the text of field "Script" of me into tOldText
      
      local tNewText
      put textFormatSelection(tOldText) into tNewText
      textReplace tStartChar, tOldText, tNewText
      
      if tStart is not empty then
         select char tStart to tEnd of field "Script" of me
      end if
      
   else # handler only
      local tLine
      put word 2 of the selectedLine into tLine
      
      local tScript
      put the text of the selectedField into tScript
      
      local tSelectionLineCount
      put the number of lines of char tStart to tEnd of tScript into tSelectionLineCount
      
      # Before doing the formatting, save the indent of the first and last line of the selection.
      # Once the formatting is done, we can compare this with the new indents in order to adjust the selection.
      local tOldFirstIndent
      put textFormatGetLineIndent(line tLine of tScript) into tOldFirstIndent
      
      local tOldLastIndent
      if tStart > tEnd then
         put tOldFirstIndent into tOldLastIndent
      else
         put textFormatGetLineIndent(line (tLine + tSelectionLineCount) of tScript) into tOldLastIndent
      end if
      
      local tCode
      put textFormat(tLine, tSelectionLineCount, tScript) into tCode
      textReplace tCode["startchar"], tCode["oldtext"], tCode["newtext"]
      
      local tNewScript
      put the text of field "Script" of me into tNewScript
      
      # We know that formatting cannot change the number of lines of the field, so we can assume that
      # tLine will still be corrrect. (tStart and tEnd now no longer point to meaningful chars in the new script.)
      local tNewFirstIndent
      put textFormatGetLineIndent(line tLine of tNewScript) into tNewFirstIndent
      
      local tNewLastIndent
      if tStart > tEnd then
         put tNewFirstIndent into tNewLastIndent
      else
         # Note that we use the line count from the original selection, as we know this is correct, rather than calculating
         # it again for the new selection.
         put textFormatGetLineIndent(line (tLine + tSelectionLineCount) of tNewScript) into tNewLastIndent
      end if
      
      # The selection offsets are composed of two parts, the difference in the indent of the line that the selection started / ended on
      # and the difference in the number of chars before that line.
      local tFirstSelectionOffset
      put (the number of chars of tNewFirstIndent - the number of chars of tOldFirstIndent) + (the number of chars of line 1 to (tLine - 1) of tNewScript - the number of chars of line 1 to (tLine - 1) of tScript) into tFirstSelectionOffset
      
      local tLastSelectionOffset
      if tStart > tEnd then
         put tFirstSelectionOffset into tLastSelectionOffset
      else
         put (the number of chars of tNewLastIndent - the number of chars of tOldLastIndent) + (the number of chars of line 1 to (tLine + tSelectionLineCount) of tNewScript - the number of chars of line 1 to (tLine + tSelectionLineCount) of tScript) into tLastSelectionOffset
      end if
      
      if tStart is not empty then
         select char (tStart + tFirstSelectionOffset) to (tEnd + tLastSelectionOffset) of field "Script" of me
      end if
   end if
   
   set the vScroll of field "Script" of me to tScroll
   unlock screen
end scriptFormat

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
   set the script of button "revCompileObject" of me to tScript
   put the result into tResult
   
   if tResult is empty then
      put the revAvailableHandlers of button "revCompileObject" of me into sHandlerList
   end if
   
   set the preserveVariables to tOldPreserveVariables
   set the explicitVariables to tOldExplicitVariables
   
   # The script should be unset because it could cause issues with idle handlers
   set the script of button "revCompileObject" of me to empty
   
   unlock messages
   unlock screen
   
   return tResult
end scriptCompile

# Parameters
#   pObject : the object to get the script of. Must be one of the current target objects
# Description
#   If pObject is not specified then returns the current script in the editor group,
#   otherwise returns the script of the specified object in the state it was last left in
#   by the user. I.e. if the script is not applied, the edited one is returned.
command scriptGet pObject
   if pObject is empty or seGetRuggedId(pObject) is seGetRuggedId(sObjectId) then
      return textGetScript()
   end if
   
   # If not the current script, we need to retrieve the script from a cache, as it
   # is no longer in the field.
   local tCachedScript
   put sScriptCache[seGetRuggedId(pObject)] into tCachedScript
   if tCachedScript is empty then
      return the script of pObject
   else
      return tCachedScript
   end if
end scriptGet

# Description
#   Returns the number of lines of the current script
command scriptGetLineCount
   return the number of lines of field "Script" of me
end scriptGetLineCount

# Description
#   This command returns the current script as *real* html. The result of this command
#   is suitable for displaying in a browser, not in Revolution fields as htmlText. This command
#   requires the colorization scheme "Revolution Classic" to be used as it contains hard-coded 
#   replacements. For html suitable for printing or displaying in a Revolution field see scriptGetHtmlText.
command scriptGetAsHtml
   local tOldScript
   put the text of field "Script" of me into tOldScript
   
   # First wrap the script to the required width, this is a total hack as doing it properly would take quite a while.
   local tScript
   put tOldScript into tScript
   
   local tMaxCharCount
   put "65" into tMaxCharCount
   
   local tWrappedScript
   repeat for each line tLine in tScript
      # Ignore lines that don't need to be wrapped
      if the number of chars of tLine <= tMaxCharCount then
         put tLine & return after tWrappedScript
         next repeat
      end if
      
      # Find the word offset to wrap from. Only whole words can be wrapped
      local tWordOffset
      put (the number of words of char 1 to tMaxCharCount of tLine)  -1 into tWordOffset
      
      # The line could be a comment, in which case we need to find which comment char its using
      # wrap the line, and put the comment char in front of the wrapped part. This won't work with
      # multi-line comments etc.
      local tCommentChar
      if token 1 of tLine is empty then
         local tOffset
         put offset("#", tLine) into tOffset
         if tOffset = 0 then
            put offset("--", tLine) into tOffset
            put "--" into tCommentChar
         else
            put "#" into tCommentChar
         end if
         
         if tCommentChar is empty then
            put word 1 to tWordOffset of tLine & return & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         else
            put word 1 to tWordOffset of tLine & return & tCommentChar & space & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         end if
         next repeat
      end if
      
      # The line was not a comment. In this case we just wrap it with a continuation char
      # This of course may have issues if the line already has a continuation char, is inside a nested comment etc.
      if token 1 of tLine is not empty then
         put word 1 to tWordOffset of tLine & " \" & return & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         next repeat
      end if
   end repeat
   delete the last char of tWrappedScript
   
   textReplace 1, tOldScript, tWrappedScript
   scriptFormat "script"
   
   local tHtml
   put the htmlText of field "Script" of me into tHtml
   
   local tNewHtml
   put "<div class=" & quote & "code" & quote & ">" & return into tNewHtml
   put "<pre>" & return after tNewHtml
   
   local tBody
   put tHtml into tBody
   replace "<p>" with empty in tBody
   replace "</p>" with empty in tBody
   
   replace "<font color=" & quote & "#000000" & quote & ">" with "<span class=" & quote & "normal" & quote & ">" in tBody
   replace "<font color=" & quote & "#0000FF" & quote & ">" with "<span class=" & quote & "command" & quote & ">" in tBody
   replace "<font color=" & quote & "#FF0000" & quote & ">" with "<span class=" & quote & "property" & quote & ">" in tBody
   replace "<font color=" & quote & "#68228B" & quote & ">" with "<span class=" & quote & "comment" & quote & ">" in tBody
   replace "<font color=" & quote & "#F88017" & quote & ">" with "<span class=" & quote & "function" & quote & ">" in tBody
   replace "<font color=" & quote & "#980517" & quote & ">" with "<span class=" & quote & "keyword" & quote & ">" in tBody
   replace "</font>" with "</span>" in tBody
   put tBody & return after tNewHtml
   
   put "</pre>" & return after tNewHtml
   put "</div>" after tNewHtml
   
   
   # Restore the original script
   textReplace 1, the text of field "Script" of me, tOldScript
   
   return tNewHtml
end scriptGetAsHtml

# Description
#   Returns the htmlText of the script field. This is suitable for printing, or displaying
#   in another Revolution field, not for putting on the net. For real html, see scriptGetAsHtml.
command scriptGetHtmlText
   return the htmlText of field "Script" of me
end scriptGetHtmlText

# Description
#   Returns the long id of the script field. This is required by the Revolution printing library,
#   the field ID is used to determine the properties require to make the printout look correct.
#   Please *do not* use this command to directly access the script field, doing so will break the 
#   script editor completely.
command scriptGetField
   return the long id of field "Script" of me
end scriptGetField

# Description
#   Returns the name of the current handler. This is the handler that the caret
#   is inside in edit mode, or that the current statement to execute is in in
#   debug mode.
command scriptGetCurrentHandler
   # Waiting for engine support for this function...
end scriptGetCurrentHandler

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

# Description
#   Returns whether or not undo is available in the current object. I.e. the script has been edited since it was opened in this
#   instance of the script editor.
command undoAvailable
   if sTextGroupIndex[sObjectId] is 0 then
      return false
   else
      return true
   end if
end undoAvailable

# Description
#   Returns whether or not redo is available in the current object. I.e. something has been undone since it was opened in
#   this instance of the script editor.
command redoAvailable
   if sTextGroupIndex[sObjectId] is sTextGroupTop[sObjectId] then
      return false
   else
      return true
   end if
end redoAvailable

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
   put empty into field "Script" of me
   put empty into sTextOperationOffsets
   put empty into sTextOperationNewTexts
   put empty into sTextOperationOldTexts
   put 0 into sTextOperationIndex
   put 0 into sTextOperationTop
   
   put empty into sTextGroupLabels
   put empty into sTextGroupLengths
   put 0 into sTextGroupIndex
   put 0 into sTextGroupTop
   
   put empty into sTextMark
   put empty into sScriptCache
   
   initializeFonts
   textFormatInitialize
   seColorizationInit
   
   colorizationUpdate
   
   textMark "Insert"

   EditorFieldCacheFlushAll
end textInitialize

on textMark pLabel
   put pLabel into sTextMark[sObjectId]
end textMark

on textBeginGroup pLabel, pObject
   local tObject
   if pObject is empty then
      put sObjectId into tObject
   else
      put pObject into tObject
   end if
   
   add 1 to sTextGroupIndex[tObject]
   
   put pLabel into sTextGroupLabels[tObject,sTextGroupIndex[tObject]]
   put 0 into sTextGroupLengths[tObject,sTextGroupIndex[tObject]]
   
   repeat with tIndex = sTextGroupIndex[tObject] + 1 to sTextGroupTop[tObject]
      delete variable sTextGroupLabels[tObject,tIndex]
      delete variable sTextGroupLengths[tObject,tIndex]
   end repeat
   
   repeat with tIndex = sTextOperationIndex[tObject] + 1 to sTextOperationTop[tObject]
      delete variable sTextOperationOffsets[tObject,tIndex]
      delete variable sTextOperationNewTexts[tObject,tIndex]
      delete variable sTextOperationOldTexts[tObject,tIndex]
   end repeat
   
   put sTextOperationIndex[sObjectId] into sTextOperationTop[tObject]
   put sTextGroupIndex[sObjectId] into sTextGroupTop[tObject]
   
   put empty into sTextMark[tObject]
end textBeginGroup

on textEndGroup
   if sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] = 0 then
      throw "empty_text_group_inserted"
   end if
   textMark "Insert"
end textEndGroup

-- Text Formatting Code
private command textFormatInitialize
   local tTabDepth
   put sePrefGet("editor,tabdepth") into tTabDepth
   
   put "0," & tTabDepth into sTextFormatKeywordMap["try"]
   put "0," & tTabDepth into sTextFormatKeywordMap["switch"]
   put "0," & tTabDepth into sTextFormatKeywordMap["if"]
   put -tTabDepth & ",0" into sTextFormatKeywordMap["endif"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["elseif"]
   put "0," & tTabDepth into sTextFormatKeywordMap["repeat"]
   
   put "0," & tTabDepth into sTextFormatKeywordMap["on"]
   put "0," & tTabDepth into sTextFormatKeywordMap["function"]
   put "0," & tTabDepth into sTextFormatKeywordMap["setprop"]
   put "0," & tTabDepth into sTextFormatKeywordMap["getprop"]
   put "0," & tTabDepth into sTextFormatKeywordMap["command"]
   put "0," & tTabDepth into sTextFormatKeywordMap["private"]
   put "0," & tTabDepth into sTextFormatKeywordMap["before"]
   put "0," & tTabDepth into sTextFormatKeywordMap["after"]
   
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["else"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["case"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["default"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["catch"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["finally"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["catch"]
   --put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["break"]
   put 0 & comma & 0 into sTextFormatKeywordMap["break"]
   
   put -tTabDepth & ",0" into sTextFormatKeywordMap["end"]
end textFormatInitialize

private function textFormatIndentLineAdds pLine
   local tToken
   put token 1 of pLine into tToken
   if tToken is "if" then
      if "else" is among the words of pLine then
         return 0
      else if token -1 of pLine is not "then" then
         return 0
      else
         return item 2 of sTextFormatKeywordMap["if"]
      end if
      
   else if tToken is "else" then
      if token 2 of pLine is "if" then
         if "else" is among the words of word 3 to -1 of pLine then
            return 0
         else if token -1 of pLine is not "then" then
            return 0
         else
            return item 2 of sTextFormatKeywordMap["elseif"]
         end if
      else if token 2 of pLine is not empty then
         return 0
      else
         return item 2 of sTextFormatKeywordMap["else"]
      end if
      
   else if token 1 of pLine is empty then
      return 0
      ## Bug 10467 - else in a comment was causing incorrect indentation
      ## Check for "else" in line without comments
      --else if token 1 of pLine is not "else" and "else" is among the words of pLine then
   else if token 1 of pLine is not "else" and "else" is among the words of lineStripComments(pLine) then
      return -sePrefGet("editor,tabdepth")
   else if token -1 of pLine is "then" then
      # Either a weirdly formatted if structure, or the condition of the if contained a line continuation character.
      # In this case, behave as though pLine is a normal if.
      return item 2 of sTextFormatKeywordMap["if"]
   else
      return item 2 of sTextFormatKeywordMap[tToken]
   end if
   return 0
end textFormatIndentLineAdds


private function textFormatIndentLineRemoves pPreviousLine, pLine
   local tToken
   put token 1 of pLine into tToken
   if tToken is "else" then
      if token 2 of pLine is "if" then
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" then
            return 0
         else
            return item 1 of sTextFormatKeywordMap["elseif"]
         end if
         
      else
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" then
            return 0
         else
            return item 1 of sTextFormatKeywordMap["else"]
         end if
      end if
   else if tToken is empty then
      # Comments and empty lines do not remove any formatting
      return 0
   else if tToken is "end" and token 2 of pLine is "switch" and token 1 of pPreviousLine is not "switch" then
      # Special case for end switch if there is a preceeding "break", "default" or other statement, we need to remove
      # double the normal indent.
      return (2 * item 1 of sTextFormatKeywordMap["end"])
   else if tToken is "case" then
      # A case statement removes indent from the previous line in all cases except if the
      # previous line was the beginning of the parent switch structure.
      if token 1 of pPreviousLine is "switch"  then
         return 0
      else
         return item 1 of sTextFormatKeywordMap["case"]
      end if
      # OK-2009-04-28 : Bug 8016 - Special case required for "default" to make switches format correctly.
   else if tToken is "default" then
      if token 1 of pPreviousLine is "switch" then
         return 0
      else
         return item 1 of sTextFormatKeywordMap["default"]
      end if
   else if tToken is "end" and token 2 of pLine is not among the words of "if switch repeat try" and not lineIsContinued(pLine) then
      # Handler ends always remove all indentation as they can't be nested
      # OK-2009-02-16 : Bug 7707 - We can't assume the previous line was correctly formatted or script may be deleted.
      # Instead we simplify this by simply chopping off whatever indentation it did have.
      --return min(-(the number of chars of textFormatGetLineIndent(pPreviousLine)), item 1 of sTextFormatKeywordMap[tToken])
      return item 1 of sTextFormatKeywordMap["end"]
   else
      # We can't assume that the previous line was correctly indented
      # because the script might have been edited from outside this script editor. Therefore
      # we have to ensure that a line doesnt try to remove more formating than the previous
      # line actually had. Otherwise non-whitespace chars may be deleted.
      if the number of chars of textFormatGetLineIndent(pPreviousLine) + the number of chars of textFormatGetLineIndent(pLine) + textFormatIndentLineAdds(pPreviousLine) < abs(item 1 of sTextFormatKeywordMap[tToken]) then
         return -(the number of chars of textFormatGetLineIndent(pPreviousLine))
      else
         return item 1 of sTextFormatKeywordMap[tToken]
      end if
   end if
end textFormatIndentLineRemoves

private function textFormatGetLineIndent pLine
   local tResult
   repeat for each char tChar in pLine
      if tChar is space then
         put space after tResult
      else
         return tResult
      end if
   end repeat
   return tResult
end textFormatGetLineIndent

private function lineIsContinued pLine
   if word -1 of pLine is "\" then
      return true
   else
      return false
   end if
end lineIsContinued

private function textFormatGetContinuationIndent pLastLineNumber
   # In order to calculate the indentation we need to loop back until we find the start of the continuation,
   # constructing a string which is the equivalent of the continued line in a single line. We then use this to calculate
   # the indent of the last line 
end textFormatGetContinuationIndent

private function combineContinuedLine pLastLineNumber, @pTextLines
   local tContinuation
   put pTextLines[pLastLineNumber] into tContinuation
   
   local tIndex
   repeat with tIndex = (pLastLineNumber - 1) down to 1
      if not lineIsContinued( pTextLines[tIndex]) then
         exit repeat
      end if
      
      put pTextLines[tIndex] before tContinuation
   end repeat
   replace "\" with empty in tContinuation
   return tContinuation
end combineContinuedLine

constant kContinuationIndent = 6

private function textFormatLine pLine, pTextLines, @xPreviousLine
   local tResult
   
   # OK-2009-01-30 : Bug 7051 - Deal better with continuation characters.
   local tCurrentLineIsContinued
   local tPreviousLineWasContinued
   local tPreviousPreviousLineWasContinued
   
   # Continuations can only happen with consecutive lines, there can't be comments or empty lines in between,
   # so we simply use the two previous lines to work out if they are continued or not. If these lines are empty
   # or are comments, then the result will be that they are not continuations anyway which is correct.
   put lineIsContinued(pTextLines[pLine - 1]) into tPreviousLineWasContinued
   put lineIsContinued(pTextLines[pLine - 2]) into tPreviousPreviousLineWasContinued
   
   put lineIsContinued(pTextLines[pLine]) into tCurrentLineIsContinued
   
   # Get the previous non-empty line
   if xPreviousLine is 0 and pLine > 1 then
      put pLine into xPreviousLine
      repeat while xPreviousLine > 1
         subtract 1 from xPreviousLine
         if token 1 of pTextLines[xPreviousLine] is not empty then
            exit repeat
         end if 
      end repeat
   end if
   
   local tPreviousLine
   if xPreviousLine > 0 then
      # This is the case where we have reached the end of a continued line. Here, we treat the continued line
      # as a single entity in order to calculate its indentation properties correctly for the line after it.
      if lineIsContinued(pTextLines[xPreviousLine - 1]) then
         put combineContinuedLine(xPreviousLine, pTextLines) into tPreviousLine
      else
         put pTextLines[xPreviousLine] into tPreviousLine
      end if
      
      # Get the current indent of the previous line
      local tPreviousLineIndent
      put textFormatGetLineIndent(tPreviousLine) into tPreviousLineIndent
   end if
   
   # Get the current indent of the line
   local tCurrentLineIndent
   put textFormatGetLineIndent(pTextLines[pLine]) into tCurrentLineIndent
   
   # Work out how much indentation the current line should remove from the previous line
   local tIndentCurrentLineRemoves
   if tPreviousLineWasContinued then
      put 0 into tIndentCurrentLineRemoves
   else
      put textFormatIndentLineRemoves(tPreviousLine, pTextLines[pLine]) into tIndentCurrentLineRemoves
   end if
   
   # Work out how much indentation the previous line should add to the current line.
   local tIndentPreviousLineAdds
   if xPreviousLine is 0 then
      put 0 into tIndentPreviousLineAdds
   else if tPreviousLineWasContinued then
      # we always add the continuation indent because we combined the continued lines
      put kContinuationIndent into tIndentPreviousLineAdds
   else
      put textFormatIndentLineAdds(pTextLines[xPreviousLine]) into tIndentPreviousLineAdds
   end if
   
   local tCurrentIndent
   repeat (the number of chars of tPreviousLineIndent + tIndentCurrentLineRemoves + tIndentPreviousLineAdds)
      put space after tCurrentIndent
   end repeat
   
   put ((the number of chars of tPreviousLineIndent + tIndentCurrentLineRemoves + tIndentPreviousLineAdds) - the number of chars of tCurrentLineIndent) & comma into tResult
   
   -- Finally, calculate the expected next indent.
   local tNewIndent
   put tCurrentIndent into tNewIndent
   
   local tIndentCurrentLineAdds
   if tCurrentLineIsContinued and tPreviousLineWasContinued then
      put 0 into tIndentCurrentLineAdds
   else if tCurrentLineIsContinued and (not tPreviousLineWasContinued) then
      put kContinuationIndent into tIndentCurrentLineAdds
   else if (not tCurrentLineIsContinued) and tPreviousLineWasContinued then
      put -kContinuationIndent into tIndentCurrentLineAdds
   else
      put textFormatIndentLineAdds(pTextLines[pLine]) into tIndentCurrentLineAdds
   end if
   
   if tIndentCurrentLineAdds < 0 then
      repeat -tIndentCurrentLineAdds times
         delete char 1 of tNewIndent
      end repeat
   else
      repeat tIndentCurrentLineAdds times
         put space after tNewIndent
      end repeat
   end if
   
   put tNewIndent after tResult
   
   if token 1 of pTextLines[pLine] is not empty then
      put pLine into xPreviousLine
   end if
   return tResult
end textFormatLine

# Returns
#   The chunk of pLine from the beginning of the first word to the end.
private function firstWordToEnd pLine
   local tOffset
   put offset(word 1 of pLine, pLine) into tOffset
   return char tOffset to -1 of pLine
end firstWordToEnd

# Parameters
#   pText : the text to format
private function textFormatSelection pText
   local tResult
   local tPreviousLine = 0
   local tTextLines
   put pText into tTextLines
   split tTextLines by return
   
   get textFormatLine(1, tTextLines, tPreviousLine)
   put firstWordToEnd(tTextLines[1]) into tTextLines[1]
   put tTextLines[1] into tResult
   local tIndex
   repeat with tIndex = 2 to the number of elements of tTextLines
      put item 2 of it & firstWordToEnd(tTextLines[tIndex]) into tTextLines[tIndex]
      get textFormatLine(tIndex, tTextLines, tPreviousLine)
      
      if item 1 of it < 0 then
         repeat -(item 1 of it) times
            if char 1 of line -1 of tTextLines[tIndex] is space then
               delete char 1 of tTextLines[tIndex]
            end if
         end repeat
      else if item 1 of it > 0 then
         repeat item 1 of it times
            put space before tTextLines[tIndex]
         end repeat
      end if
      
      put return & tTextLines[tIndex] after tResult
   end repeat
   
   return tResult
end textFormatSelection

private function handlerTypes
   return "command,on,function,setprop,getprop,before,after"
end handlerTypes

private function textFormat pLineNumber, pLineCount, pText
   -- Find the range to format.
   -- 1. Search down until we find a handler (a) or the end of one (b).
   -- 2. Based on 1, in case a, search up until we find the end of any other handler, or the beginning of the script.
   --    In case b we need to search for the start of that handler.
   local tEnd
   
   local tText
   put pText into tText
   split tText by return
   put pLineNumber into tEnd
   
   # Search down to find what the handler name is and whether pLineNumber is the first line of the handler.
   local tHandler
   local tFirstLine
   put true into tFirstLine
   
   local tContinuation, tCurrentLineContinues
   put lineIsContinued(tText[pLineNumber-1]) into tContinuation
   
   local tLineIndex
   repeat with tLineIndex = pLineNumber to the number of elements of tText
      put lineIsContinued(tText[tLineIndex]) into tCurrentLineContinues
      if token 1 of tText[tLineIndex] is "end" and token 2 of tText[tLineIndex] is not among the items of "if,repeat,switch,try" and not tContinuation and not tCurrentLineContinues then
         put true into tHandler[token 2 of tText[tLineIndex]]
         if pLineCount < 0 then
            exit repeat
         end if
      else if token 1 of tText[tLineIndex] is among the items of handlerTypes() and not tFirstLine then
         if pLineCount < 0 then
            exit repeat
         end if
         exit repeat
      else if token 1 of tText[tLineIndex] is "private" and token 2 of tText[tLineIndex] is among the items of handlerTypes() and not tFirstLine then
         if pLineCount < 0 then
            exit repeat
         end if
         exit repeat
      else
         put tCurrentLineContinues into tContinuation
      end if
      if tFirstLine then put false into tFirstLine
      subtract 1 from pLineCount
      add 1 to tEnd
   end repeat
   
   # Search up to find the beginning of the handler, or the beginning of the script if not found.
   local tStart
   repeat with tLineIndex = pLineNumber down to 1
      put tLineIndex into tStart
      if tHandler is an array then
         if token 1 of tText[tLineIndex] is among the items of  handlerTypes() and tHandler[token 2 of tText[tLineIndex]] then
            exit repeat
         else if token 1 of tText[tLineIndex] is "private" and token 2 of tText[tLineIndex] is among the items of handlerTypes() and tHandler[token 3 of tText[tLineIndex]] then
            exit repeat
         end if
      else if token 1 of tText[tLineIndex] is "end" and token 2 of tText[tLineIndex] is not among the items of "if,repeat,switch,catch" then
         exit repeat
      end if
   end repeat
   
   if tHandler is not an array and tStart is not 1 then
      add 1 to tStart
   end if
   if tEnd > the number of elements of tText then
      put the number of elements of tText into tEnd
   end if
   
   -- Now format lines tStart to tEnd of pText, and return the result.
   local tStartChar
   if tStart is 1 then
      put 1 into tStartChar
   else
      put the number of chars of line 1 to (tStart - 1) of pText into tStartChar
      add 2 to tStartChar
   end if
   
   local tOldText
   put line tStart to tEnd of pText into tOldText
   
   local tResult
   put tStartChar into tResult["startchar"]
   put tOldText into tResult["oldtext"]
   put textFormatSelection(tOldText) into tResult["newtext"]
   
   return tResult
end textFormat

function textGetScript
   return the text of field "Script" of me
end textGetScript

function getScriptField
   return the long id of field "Script" of me
end getScriptField

on textSetSelection pAfterChar
   select after char pAfterChar of field "Script" of me
end textSetSelection

# Parameters
#   pOldText : the text replaced in an operation
#   pNewText : the replacing text in an operation
# Returns
#   Whether or not a new undo group is needed for the specified
#   operation.
private function textReplaceNewGroupNeeded pOldText, pNewText
   # If the invoker of the replacement operation has specified that an undo group
   # is needed, always create one
   if sTextMark[sObjectId] is not empty then
      return true
   end if
   
   # If the number of chars of either the string replaced or replacing string is above one
   # this means it must be a deletion of a selection or a cut or paste. This should always
   # require a new group
   if the number of chars of pOldText > 1 or the number of chars of pNewText > 1 then
      return true
   end if
   
   # If either the text being replaced or the replacing text contain return chars, new group
   if pOldText contains return or pNewText contains return then
      return true
   end if
   
   return false
end textReplaceNewGroupNeeded

# Parameters
#   pOffset : the char number of where the replacement should start
#   pOldText : the text that is being replaced
#   pNewText : the text that is being inserted
#   pObject : the long id of the object to replace in. If not given, the current object is assumed.
# Description
#   This is the point through which all standard editing operations on scripts are sent through.
#   Any change made via this function will be added to the undo system. This is called when the
#   user types keys, formats text, cuts, pastes etc.
private command textReplace pOffset, pOldText, pNewText, pObject
   local tObject
   if pObject is empty then
      put sObjectId into tObject
   else
      put pObject into tObject
   end if
   
   if textReplaceNewGroupNeeded(pOldText, pNewText) then
      textBeginGroup sTextMark[tObject], tObject
   end if
   
   add 1 to sTextOperationIndex[tObject]
   add 1 to sTextGroupLengths[tObject,sTextGroupIndex[tObject]]
   
   put pOffset into sTextOperationOffsets[tObject,sTextOperationIndex[tObject]]
   put pOldText into sTextOperationOldTexts[tObject,sTextOperationIndex[tObject]]
   put pNewText into sTextOperationNewTexts[tObject,sTextOperationIndex[tObject]]
   
   # When the script has been edited, the breakpoints should be suspended until it is applied again.
   # Because this command is called as the user types, we could a send in time for this, as its not that urgent.
   revDebuggerSuspendBreakpoints tObject
   
   # If the specified object to replace in is the current object being edited, we perform the replace
   # directly on the script editing field using textReplaceRaw. Otherwise we perform it on the
   # script cache stored for the object.
   if tObject is empty or seGetRuggedId(tObject) is sObjectId then
      textReplaceRaw pOffset, pOldText, pNewText
   else
      local tCache
      put sScriptCache[seGetRuggedId(tObject)] into tCache
      if tCache is empty then
         put the script of tObject into tCache
      end if
      textReplaceRawInVariable tCache, pOffset, pOldText, pNewText
      put tCache into sScriptCache[seGetRuggedId(tObject)]
   end if
   
   set the caseSensitive to true
   if pOldText is not pNewText then
      seSetObjectState tObject, "edited"
      
      # OK-2009-01-17 : Bug 7169 - Flag the object as dirty when it is modifed by this method only.
      # The textReplaceRaw etc functions should not do this as they do not represent a user modifying
      # the script.
      setDirty tObject, true
   end if
end textReplace

# Parameters
#   pOffset : the char number to begin the replacement at
#   @rScript : the text to perform the replacement in, gets mutated
#   @pOldText : the text that is to be replaced. This is not mutated, its a reference for efficiency reasons
#   @pNewText : the text to be inserted. This is not mutated, its a reference for efficiency reasons
# Description
#   Performs a raw replace exactly as textReplaceRaw, except in a variable instead of directly in the editing field.
#   This is used by replace-all, because it may need to replace text in the script of objects which are not open.
private command textReplaceRawInVariable @rScript, pOffset, @pOldText, @pNewText
   local tOldLength
   put the length of pOldText into tOldLength
   put pNewText into char pOffset to pOffset + tOldLength - 1 of rScript
end textReplaceRawInVariable

# Parameters
#   pOffset : the char number to begin the replacement at
#   @pOldText : the text that is to be replaced. This is not mutated, its a reference for efficiency reasons
#   @pNewText : the text to be inserted. This is not mutated, its a reference for efficiency reasons
#   pDontUpdateBreakpoints : optional, defaults to false. If this is true, breakpoints in the gutter are not moved.
# Description
#   This is the raw replacement operation that performs a mutation on the script field without
#   saving any undo information. This should be called only from inside textReplace, when doing an undo or a redo
#   and when setting the script when a new object is loaded.
private command textReplaceRaw pOffset, @pOldText, @pNewText, pDontUpdateBreakpoints
   lock screen
   lock messages
   
   local tSelectedLine
   put word 2 of the selectedLine into tSelectedLine
   
   local tEndOffset
   put max(0, pOffset + the length of pOldText - 1) into tEndOffset

   _internal script replace char pOffset to tEndOffset of field "Script" of me with pNewText
   
   --Do some work to update the gutter.
   local tOldLines, tNewLines
   put the number of lines of pOldText into tOldLines
   if pOldText is not return and (char -1 of pOldText is return or pOldText is empty) then
      add 1 to tOldLines
   end if
   if pNewText is empty and pOldText is return then
      put 0 into tNewLines
   else
      put the number of lines of pNewText into tNewLines
      if char -1 of pNewText is return or pNewText is return or pNewText is empty then
         add 1 to tNewLines
      end if
   end if
   
   if pDontUpdateBreakpoints then
      updateGutterRequest empty, empty, tOldLines, tNewLines, false, false
   else
      updateGutterRequest pOffset, tSelectedLine, tOldLines, tNewLines, true, false
   end if
   
   unlock messages
   
   # OK-2008-09-10 : Bug 7132 - Update the panes  and handler list everytime the text of the field is changed.
   # OK-2009-01-19 : Don't do this here as it slows down the script editor on OS X. Instead do it in the individual
   # cases where it may be needed, cut, paste, return, delete, backspace, undo and redo
   --selectionUpdateRequest
   
   unlock screen
end textReplaceRaw

-- Sets the contents of the fields to pScript WITHOUT touching the undo queue. This should be done before any editing.
on textSetScriptRaw pScript
   --put empty into field "Script" of me
   local tOldText
   put the text of field "Script" of me into tOldText
   if tOldText is not pScript then
      textReplaceRaw 1, tOldText, pScript, true
   end if
end textSetScriptRaw

-- Sets the script within the undo queue.
on textSetScript pScript
   textReplace 1, the text of field "Script" of me, pScript
end textSetScript

# Description
#   Performs an undo operation on the current script
on textUndo
   undoAvailable
   if not the result then
      exit textUndo
   end if
   
   local tOperations
   put sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] into tOperations
   lock screen
   repeat with tIndex = sTextOperationIndex[sObjectId] down to sTextOperationIndex[sObjectId] - tOperations + 1
      local tNewText, tOldText
      put sTextOperationNewTexts[sObjectId,tIndex] into tNewText
      put sTextOperationOldTexts[sObjectId,tIndex] into tOldText
      textReplaceRaw sTextOperationOffsets[sObjectId,tIndex], tNewText, tOldText
   end repeat
   unlock screen
   
   subtract tOperations from sTextOperationIndex[sObjectId]
   subtract 1 from sTextGroupIndex[sObjectId]
   
   revDebuggerSuspendBreakpoints sObjectId
   seSetObjectState sObjectId, "edited"
   textMark "Insert"
end textUndo

# Description
#   Performs a redo operation on the current script
on textRedo
   redoAvailable
   if not the result then
      exit textRedo
   end if
   
   add 1 to sTextGroupIndex[sObjectId]
   
   local tOperations
   put sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] into tOperations
   lock screen
   repeat with tIndex = sTextOperationIndex[sObjectId] + 1 to sTextOperationIndex[sObjectId] + tOperations
      local tNewText, tOldText
      put sTextOperationOldTexts[sObjectId,tIndex] into tOldText
      put sTextOperationNewTexts[sObjectId,tIndex] into tNewText
      textReplaceRaw sTextOperationOffsets[sObjectId,tIndex], tOldText, tNewText
   end repeat
   unlock screen
   
   add tOperations to sTextOperationIndex[sObjectId]
   revDebuggerSuspendBreakpoints sObjectId
   seSetObjectState sObjectId, "edited"
   textMark "Insert"
end textRedo

# Description
#   This is a debugging command used to print the status of the undo queue when investigating
#   problems. It should not be called anywhere in the code.
on textPrint
   lock screen
   
   local tOperation
   put 1 into tOperation
   repeat with x = 1 to sTextGroupTop[sObjectId]
      
      put "Group(" & x & "):" && sTextGroupLabels[sObjectId,x] & return after message
      repeat sTextGroupLengths[sObjectId,x] times
         
         local tOldText, tNewText
         put sTextOperationOldTexts[sObjectId,tOperation] into tOldText
         put sTextOperationNewTexts[sObjectId,tOperation] into tNewText
         replace return with "\n" in tOldText
         replace return with "\n" in tNewText
         
         put tab & "[" & tOperation & "]:" && sTextOperationOffsets[tOperation], tOldText, tNewText & return after message
         
         if tOperation is sTextOperationIndex[sObjectId] then
            put tab & "--------" & return after message
         end if
         
         add 1 to tOperation
      end repeat
      
      if x is sTextGroupIndex[sObjectId] then
         put "--------" & return after message
      end if
   end repeat
   
   unlock screen
end textPrint

# Stores the id of the last request to update the gutter, if there is one pending.
local sGutterUpdateRequest

# We also need to store whether the last update request involved text changing and 
# whether it required the compilation errors to be updated. This is because it may be
# cancelled by a subsequent request that didn't require these things, resulting in the update
# being lost.
local sGutterUpdateRequestDetails

private command updateGutterMergeRequestDetails pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   # The offset and selected line are just overwritten providing they are not empty
   if pOffset is not empty then
      put pOffset into sGutterUpdateRequestDetails["offset"]
   end if
   
   if pSelectedLine is not empty then
      put pSelectedLine into sGutterUpdateRequestDetails["selectedLine"]
   end if
   
   # The old number of lines is not changed, however if its empty, we put the new value in
   if sGutterUpdateRequestDetails["oldLines"] is empty then
      put pOldLines into sGutterUpdateRequestDetails["oldLines"]
   end if
   
   # The new number of lines overwrites the previous setting, again providing that its not empty
   if pNewLines is not empty then
      put pNewLines into sGutterUpdateRequestDetails["newLines"]
   end if
   
   # The new text changed value is the logical OR of the new and old values
   # The same is done for the update compilation errors and the force breakpoint redraw 
   put (pTextChanged or sGutterUpdateRequestDetails["textChanged"]) into sGutterUpdateRequestDetails["textChanged"]
   put (pUpdateCompilationErrors or sGutterUpdateRequestDetails["updateCompilationErrors"]) into sGutterUpdateRequestDetails["updateCompilationErrors"]
   put (pForceBreakpointRedraw or sGutterUpdateRequestDetails["forceBreakpointRedraw"]) into sGutterUpdateRequestDetails["forceBreakpointRedraw"]
end updateGutterMergeRequestDetails

# Parameters
#   pOffset : the offset of the last text change
#   pSelectedLine : the selected line at the point of the last text change
#   pOldLines : the old number of lines in the script field at the point of the last text change
#   pNewLines : the new number of liens in the script field after the last text change
#   pTextChanged : whether text was changed or not since the last gutter update. If this is false, all the previous parameters are ignored.
#   pUpdateCompilationErrors : whether to update the gutter's compilation errors
# Description
#   Sends a request to update the gutter. This is called whenever the current script is edited, or the field
#   is scrolled etc. A request is sent using a short delay and any previous requests are cancelled.
#  The gutter's scroll is updated immediately however. Also a message is sent to the gutter to hide its
#  mutable objects (the breakpoint / compilation error images). These are show again when the update is
#  actually carried out.
command updateGutterRequest pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   updateGutterMergeRequestDetails pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   if sGutterUpdateRequest is not empty then
      cancel sGutterUpdateRequest
   end if
   
   # We always update the gutter's scroll immediately, as otherwise it looks bad. Other stuff is delayed though.
   send "updateScroll" to group "Gutter" of me
   send "updateGutterDo" to me in 5 milliseconds
   put the result into sGutterUpdateRequest
end updateGutterRequest


# Description
#   Updates the gutter according to the specified parameters.
command updateGutterDo
   local tOffset, tSelectedLine, tOldLines, tNewLines, tTextChanged
   put sGutterUpdateRequestDetails["offset"] into tOffset
   put sGutterUpdateRequestDetails["selectedLine"] into tSelectedLine
   put sGutterUpdateRequestDetails["oldLines"] into tOldLines
   put sGutterUpdateRequestDetails["newLines"] into tNewLines
   put sGutterUpdateRequestDetails["textChanged"] into tTextChanged
   
   local tUpdateCompilationErrors
   put sGutterUpdateRequestDetails["updateCompilationErrors"] into tUpdateCompilationErrors
   
   local tForceBreakpointRedraw
   put sGutterUpdateRequestDetails["forceBreakpointRedraw"] into tForceBreakpointRedraw
   
   send "update tOffset, tSelectedLine, tOldLines, tNewLines, tTextChanged, tUpdateCompilationErrors, tForceBreakpointRedraw" to group "Gutter" of me
   
   # Once an update has been carried out, we reset the sGutterUpdateRequestDetails array
   delete variable sGutterUpdateRequestDetails
end updateGutterDo

################################################################################

command actionCopy
   copy
end actionCopy

command actionCut
   if scriptLocked() then
      exit actionCut
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   if tFrom <= tTo then -- something is selected
      textBeginGroup "Cut"
      copy -- set the clipboard (dont cut as we do not allow field modification here)
      textReplace tFrom, char tFrom to tTo of field "Script" of me, empty
      textEndGroup
      
      # OK-2009-01-19 : Update the handler list
      selectionUpdateRequest
   end if
end actionCut

command actionPaste
   if scriptLocked() then
      exit actionPaste
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   textBeginGroup "Paste"
   textReplace tFrom, char tFrom to tTo of field "Script" of me, the clipboardData["text"]
   textEndGroup
   
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end actionPaste

command actionUndo
   if scriptLocked() then
      exit actionUndo
   end if
   textUndo
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end actionUndo

command actionRedo
   if scriptLocked() then
      exit actionRedo
   end if
   textRedo
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end actionRedo

command actionDeselectAll
   lock messages
   select empty
   unlock messages
end actionDeselectAll

command actionSelectAll
   lock messages
   
   if word 1 of the name of the focusedObject is "field" then
      select char 1 to -1 of the focusedObject
   end if
   unlock messages
end actionSelectAll

# Description
#   Called when the script editor is about to be closed.
command finalize
   cancelPendingMessages
   
   if there is a sObjectId then
      contextSave
   end if
   _internal script flush field "Script" of me
end finalize

# Stores requests to update the script editor in reponse to a selection changed
local sSelectionUpdateRequest

# Stores requests to update the script editor panes
local sPaneUpdateRequest

command cancelPendingMessages
   if sGutterUpdateRequest is not empty then
      cancel sGutterUpdateRequest
   end if
   
   if sSelectionUpdateRequest is not empty then
      cancel sSelectionUpdateRequest
   end if
   
   if sPaneUpdateRequest is not empty then
      cancel sPaneUpdateRequest
   end if
end cancelPendingMessages

-- This is sent by the engine
on selectionChanged
   handleSelectionChanged
   -- Unmark found results when clicking on the SE
   selectionUpdateRequest
end selectionChanged

-- PM-2016-09-22: [[ Bug 15887 ]] Distinguish between "selectionChanged" sent by the engine and \
-- "selectionChangedByArrowKey pArrowKey"
on handleSelectionChanged
   if the selectedText of field "Script" of me is not empty then
      put the selectedText of field "Script" of me into sLastNonEmptySelection
   end if
   
   -- [[ Bug 18528 ]] We need this here otherwise the "it" var in the if block below is empty
   get the selectedChunk
   
   # OK-2008-10-22 : Bug 7343 - Must save the last selection point as its lost
   # when the user begins typing into the search field.
   if the long id of the focusedObject is the long id of field "Script" of me then
      put word 2 of it & comma & word 4 of it into sLastSelectedChunk
   end if
end handleSelectionChanged

on selectionChangedByArrowKey pArrowKey
   handleSelectionChanged
   
   -- [[ Bug 18595 ]] We need this here otherwise the "it" var in the if block below is empty
   get the selectedChunk
   
   local tAt
   if word 2 of it > word 4 of it then
      put word 4 of it into tAt
   else
      -- It is a multiple selection, so we need to exit this.
      exit selectionChangedByArrowKey
   end if
   
   -- Single selection in the process of making a larger selection, so exit if shift is down.
   if the shiftKey is "down" then
      exit selectionChangedByArrowKey
   end if
   
   local tLine
   put word 2 of the selectedLine into tLine
   
   local tField
   put the long id of the selectedField into tField
   
   local tScript
   put the text of tField into tScript
   
   local tLineStart
   switch pArrowKey
      case "left"
         put the number of chars of line 1 to (tLine - 1) of tScript + 1 into tLineStart
         # OK-2008-03-03 : Only add offset of return if we are not on the first line of the script
         if tLine is not 1 then
            add 1 to tLineStart
         end if
         put caretPositionLeft(tLineStart, tAt + 1, tScript) into tAt
         
         lock messages
         select after char tAt of tField
         unlock messages
         break
      case "right"
         caretUpdate tField, tScript
         break
         if char (tAt + 1) of tScript is return then
            add 1 to tLine
         end if
         put the number of chars of line 1 to (tLine - 1) of tScript + 2 into tLineStart
         get line tLine of tScript
         put caretPositionRight(tLineStart, tAt + 1, it) into tAt
         break
      case "up"
      case "down"
         caretUpdate tField, tScript
         break
      case "empty"
      default
         caretUpdate tField, tScript
         break
   end switch
   
   textMark "Insert"
   
   selectionUpdateRequest
end selectionChangedByArrowKey


private command selectionUpdateRequest
   if sSelectionUpdateRequest is not empty then
      cancel sSelectionUpdateRequest
   end if
   
   send "selectionUpdate" to me in 10 milliseconds
   put the result into sSelectionUpdateRequest
end selectionUpdateRequest

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
end selectionUpdate


# Description
#   Sends a request to the script editor to update the panes. Requests are sent
#   only after a period of inactivity to prevent bombardment.
command paneUpdateRequest
   if sPaneUpdateRequest is not empty then
      cancel sPaneUpdateRequest
   end if
   
   send "paneUpdate" to me in sePrefGet("editor,paneupdatedelay") milliseconds
   put the result into sPaneUpdateRequest
end paneUpdateRequest

# Description
#   Sets some state variables that may be needed to update the script editor panes
#   and calls the sePanesUpdate command to do the update.
command paneUpdate
   put empty into sPaneUpdateRequest
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
   get the selectedChunk
   -- MM-2012-06-20: [[ Bug 10027 ]] Make sure there was a last line selected - causes bugs deselects elsewhere within the IDE.
   if sLastSelectedGoneToChunk is not empty and word 2 of it is item 1 of sLastSelectedGoneToChunk and word 4 of it is item 2 of sLastSelectedGoneToChunk then
      lock screen
      lock messages
      local tSelobj
      put revIDESelectedObjects() into tSelobj
      select empty
      if tSelobj is not the long id of field "Script" of me then
         revIDESelectObjects tSelobj
      end if
      set the backgroundColor of char (item 1 of sLastSelectedGoneToChunk) to (item 2 of sLastSelectedGoneToChunk) of field "Script" of me to empty
      unlock messages
      unlock screen
   end if
   put empty into sLastSelectedGoneToChunk
   
   # We update the gutter here to remove the current line indicator
   updateGutterRequest empty, empty, empty, empty, false, false
end deselectLastGoneToLine


################################################################################

-- This calculates the position of the caret based on pPosition where the caret is (hypothetically).
function caretPositionRight pLineStartChar, pProposedPosition, pLine
   local tFirstPosition
   put pLineStartChar - 1 into tFirstPosition
   repeat for each char tChar in pLine
      if tChar is space then
         add 1 to tFirstPosition
      else
         exit repeat
      end if
   end repeat
   
   return max(tFirstPosition, pProposedPosition)
end caretPositionRight

-- On moving the caret/backspace left, this returns the correct char position.
function caretPositionLeft pLineStartChar, pCurrentPosition, pScript
   repeat with x = pCurrentPosition down to pLineStartChar
      if char x of pScript is not space then
         return (pCurrentPosition-1)
         break
      end if
   end repeat
   return pLineStartChar - 2
end caretPositionLeft

on caretUpdate pField, pScript
   local tLine
   put word 2 of the selectedLine into tLine
   
   local tField
   if pField is empty then
      put the long id of the selectedField into tField
   else
      put pField into tField
   end if
   
   local tScript
   if pScript is empty then
      put the text of the selectedField into tScript
   else
      put pScript into tScript
   end if
   
   # The current line is the first then its first char is char 1, otherwise it is the number of
   # chars of all previous lines + 1 char for the return char and 1 for the first char of the line.
   local tLineStart
   if tLine is 1 then
      put 1 into tLineStart
   else
      put the number of chars of line 1 to (tLine - 1) of tScript + 2 into tLineStart
   end if
   
   lock messages -- dont cause selectionChanged loop
   
   select after char caretPositionRight(tLineStart, word 4 of the selectedChunk, line tLine of tScript) of tField
   
   unlock messages
end caretUpdate


# Offset between a field's top margin and the start of the text
constant kFudge = "-4"

# Parameters
#   pLineNumber : a line number in the script of the current object
# Returns
#   The vertical location of that line in the gutter or 0 if the line is not visible
function lineNumberToVerticalLoc pLineNumber
   local tField
   put getScriptField() into tField
   
   local tHeight
   put (pLineNumber - 1) * the effective textHeight of getScriptField() into tHeight
   
   # If the breakpoint is on a line earlier than the first one in the visible area then don't render it
   if tHeight < the vScroll of getScriptField() then
      return 0
   end if
   
   # If the breakpoint is on a line after the last one in the visible area the don't render it
   if tHeight > (the vScroll of getScriptField() + the height of getScriptField()) then
      return 0
   end if
   
   # Adjust the height to take the vScroll into account
   local tLoc
   put tHeight - the vScroll of getScriptField() into tLoc
   
   # Adjust the height so its relative to the start of the gutter
   add the top of me to tLoc
   
   # Adjust the the height to take the field's margins into account. This requires a little fudge...
   if the number of items of the margins of getScriptField() = 4 then
      add item 2 of the margins of getScriptField() + kFudge to tLoc
   else
      add the margins of getScriptField() + kFudge to tLoc
   end if
   
   # Adjust to the middle of the line
   add round(0.5 * the effective textHeight of getScriptField()) to tLoc
   
   return tLoc
end lineNumberToVerticalLoc

# Parameters
#   pVerticalLoc : a vertical location within the gutter's area
# Returns
#   The line number in the current script that is associated with the specified location.
#   If the location is beyond any lines in the script, or the line cannot have a breakpoint
#   on it, then 0 is returned.
function verticalLocToLineNumber pVerticalLoc
   # Add the vScroll of the script field so that the location is relative to the start of the text
   local tHeight
   put the vScroll of getScriptField() + pVerticalLoc into tHeight
   
   # Make it relative to 0 rather than the top of the gutter
   subtract the top of me from tHeight
   
   # Adjust the the height to take the field's margins into account. This requires a little fudge...
   if the number of items of the margins of getScriptField() = 4 then
      subtract item 2 of the margins of getScriptField() + kFudge from tHeight
   else
      subtract the margins of getScriptField() + kFudge from tHeight
   end if
   
   # Divide to calculate which line number it falls nearest. Always round up.
   local tLineNumber
   put (tHeight div the effective textHeight of getScriptField()) + 1 into tLineNumber
   return tLineNumber
end verticalLocToLineNumber

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
   if not revIDEBrowserWidgetUnavailable() then
      put "Find in Docs" & return after tText
   end if
   
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

private function handleEvent pEvent, pTarget
   if the long id of pTarget is the long id of field "Script" of me then
      return true
   else
      return false
   end if
end handleEvent

# OK-2009-03-02 : Bug 7773
on optionKeyDown pKey
   if not handleEvent("optionKey", the long id of the target) then
      pass optionKeyDown
   end if
   
   # Block this message on OS X as it can cause weird characters to be entered into the field
   if the platform is not "MacOS" then
      pass optionKeyDown
   end if
   
   -- OK-2009-03-09 : But simulate the message as a normal keydown
   keyDown pKey
end optionKeyDown


on scrollBarDrag
   if the short name of the target is "Gutter" or the short name of the owner of the target is "Gutter" then
      exit scrollBarDrag
   end if
   
   updateGutterRequest empty, empty, empty, empty, false, true
end scrollBarDrag

on keyDown pChar
   if not handleEvent("keydown", the long id of the target) then
      pass keyDown
   end if
   
   if scriptLocked() then
      exit keyDown
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then -- the caret is at the end
      put 0 into tLength
      put tFrom into tAt
   else
      put tFrom into tAt
      put tTo - tFrom + 1 into tLength
   end if
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, pChar
end keyDown

on backspaceKey
   if not handleEvent("backspaceKey", the long id of the target) then
      pass backspaceKey
   end if
   
   if scriptLocked() then
      exit backspaceKey
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then
      -- Caret handling, for now, is only done for an "empty" selection.
      local tLine
      put word 2 of the selectedLine into tLine
      
      local tScript
      put the text of the selectedField into tScript
      
      local tLineStart
      put the number of chars of line 1 to (tLine - 1) of tScript + 1 into tLineStart
      -- Only add offset of return if we are not on the first line of the script
      if tLine is not 1 then
         add 1 to tLineStart
      end if
      
      # OK-2008-08-28 : Bug 6515 - Delete whole word with commandKey
      if the commandKey is "down" then
         local tWordFound
         put false into tWordFound
         repeat with x = tTo down to 1
            if not matchText(char x of tScript, "\s") then
               put true into tWordFound
            else
               if tWordFound then
                  exit repeat
               end if
            end if
         end repeat
         
         if x <> 1 then
            put x + 1 into tAt
         else
            put x into tAt
         end if
         
         put tTo - tAt + 1 into tLength
      else
         # OK-2008-08-05 : Bug 6867 - If autoformatting is turned off, simply delete the last selected character
         if sePrefGet("editor,autoformat") then
            put caretPositionLeft(tLineStart, tTo, tScript) + 1 into tAt
         else
            put tTo into tAt
         end if
         put tTo - tAt + 1 into tLength
      end if
   else
      put tTo - tFrom + 1 into tLength
      put tFrom into tAt
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, empty
   
   # If the user has deleted a selection of text rather than a single character, they will
   # expect this to be a single undoable operation. So we close the current group straight
   # after the deletion. in this case.
   if tTo > tFrom then
      textEndGroup
   end if
   
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end backspaceKey

on deleteKey
   if not handleEvent("deleteKey", the long id of the target) then
      pass deleteKey
   end if
   
   if scriptLocked() then
      exit deleteKey
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then
      put tFrom into tAt
      put 1 into tLength
   else
      put tFrom into tAt
      put tTo - tFrom + 1 into tLength
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, empty
   
   # If the user has deleted a selection of text rather than a single character, they will
   # expect this to be a single undoable operation. So we close the current group straight
   # after the deletion. in this case.
   if tTo > tFrom then
      textEndGroup
   end if
   
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end deleteKey

on tabKey
   if not handleEvent("tabKey", the long id of the target) then
      pass tabKey
   end if
   
   # To prevent interference with the command+tab shortcut to cycle between tabs
   if the commandKey is "down" then
      pass tabKey
   end if
   
   if scriptLocked() then
      exit tabKey
   end if
   
   if sePrefGet("editor,autoformat") then
      scriptFormat "handler"
   else
      get the selectedChunk
      
      local tFrom, tTo
      put word 2 of it into tFrom
      put word 4 of it into tTo
      
      local tAt, tLength
      if tFrom > tTo then
         put tFrom into tAt
         put 0 into tLength
      else
         put tFrom into tAt
         put tTo - tFrom into tLength
      end if
      
      textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, tab
   end if
end tabKey

# Key identifiers for a few important keys...
constant kKeyHome = "65360"
constant kKeyEnd = "65367"
constant kKeyLeftArrow = "65361"
constant kKeyRightArrow = "65363"
constant kKeyUpArrow = "65362"
constant kKeyDownArrow = "65364"
constant kKeyF1 = "65470"
constant kKeyF2 = "65471"
constant kKeyF3 = "65472"
constant kKeyF4 = "65473"
constant kKeyF5 = "65474"
constant kKeyF6 = "65475"
constant kKeyF7 = "65476"
constant kKeyF8 = "65477"
constant kKeyF9 = "65478"
constant kKeyF10 = "65479"
constant kKeyF11 = "65480"
constant kKeyF12 = "65481"
constant kKeyF13 = "65482"
constant kKeyNumLock = "65407"
constant kKeyPageUp = "65365"
constant kKeyPageDown = "65366"
# constant kKeyMenu = "80"

private command selectFromCurrentToLineStart
   local tAt
   put word 4 of the selectedChunk into tAt
   
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   local tLineStart
   put the number of chars of line 1 to (tLineNumber - 1) of the text of getScriptField() + 1 into tLineStart
   # Only add offset of return if we are not on the first line of the script
   if tLineNumber is not 1 then
      add 1 to tLineStart
   end if
   
   select char tLineStart to tAt of field (the short name of getScriptField()) of me
end selectFromCurrentToLineStart

private command selectFromCurrentToLineEnd
   local tAt
   put word 4 of the selectedChunk into tAt
   
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   local tLineEnd
   put the number of chars of line 1 to tLineNumber of the text of getScriptField() into tLineEnd
   
   select char (tAt + 1) to tLineEnd of field (the short name of getScriptField()) of me
end selectFromCurrentToLineEnd

-- Description
--   Implements a basic page up functionality for OS X, as this is not default field behavior.
private command pageUp
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   -- Work out the number of lines in one "page" of the script editor field.
   local tLineCount
   put the height of getScriptField() div the textHeight of getScriptField() into tLineCount
   
   -- Work out which line number we need to scroll up to
   local tNewLineNumber
   put max(tLineNumber - tLineCount, 1) into tNewLineNumber
   
   -- Calculate the char that we need to reach to do the page up
   local tStartChar
   put the number of chars of line 1 to tNewLineNumber of the text of getScriptField() into tStartChar
   
   local tAt
   put word 4 of the selectedChunk into tAt
   
   if shiftKey() is "down" then
      select char tStartChar to tAt of field (the short name of getScriptField()) of me
   else
      select after char tStartChar of field (the short name of getScriptField()) of me
   end if
end pageUp

-- Description
--   Implements a basic page down functionality for OS X, as this is not default field behavior.
private command pageDown
   local tMultiSelection, tAt
   get the selectedChunk
   if word 4 of it > word 2 of it then
      put true into tMultiSelection
      put word 4 of it into tAt
   else
      put false into tMultiSelection
      put word 2 of it into tAt
   end if
   
   local tLineNumber
   if tMultiSelection then
      put word 4 of the selectedLine into tLineNumber
   else
      put word 2 of the selectedLine into tLineNumber
   end if
   
   -- Work out the number of lines in one "page" of the script editor field.
   local tLineCount
   put the height of getScriptField() div the textHeight of getScriptField() into tLineCount
   
   -- Work out which line number we need to scroll down to
   local tNewLineNumber
   put min(tLineNumber + tLineCount, the number of lines of the text of getScriptField()) into tNewLineNumber
   
   -- Calculate the char that we need to reach to do the page down
   local tEndChar
   put the number of chars of line 1 to tNewLineNumber of the text of getScriptField() into tEndChar
   
   if shiftKey() is "down" then
      select char tAt to tEndChar of field (the short name of getScriptField()) of me
   else
      select after char tEndChar of field (the short name of getScriptField()) of me
   end if
end pageDown


# Description
#   RawKeyDown is handled mainly because of the home and end keys. These need to be manually implemented on OS X
#   and both platforms after pressing the home key we have to ensure the caret ends up in the right place.
#   Other keys may be blocked here to prevent weird chars getting inserted into the script.
on rawKeyDown pKey
   if not handleEvent("rawKeyDown", the long id of the target) then
      pass rawKeyDown
   end if
   
   # For the beginning of line/paragraph action (there is no distinction in the S/E)
   # make sure we update the caret position after the field has had its go.
   
   # For Windows: Home (Windows / Linux)
   if pKey is kKeyHome and seGetPlatform() is not "macos" then
      send "selectionChangedByArrowKey" to me in 0 milliseconds
      pass rawKeyDown
   end if
   
   # For Mac: Ctrl-Left / Cmd-Left / Ctrl-A (Mac)
   if (pKey is kKeyLeftArrow and (the controlKey is "down" or the commandKey is "down") or \
         (pKey is 65 and the controlKey is "down" and the shiftKey is "up")) and seGetPlatform() is "macos" then
      send "selectionChangedByArrowKey" to me in 0 milliseconds
      pass rawKeyDown
   end if
   
   # For actions where we need to skip back, we need to ensure the caret is at the
   # start of the line if it is in the white-space prefix.
   
   # For Mac: Alt-Down
   if (pKey is kKeyUpArrow) and (the optionKey is "down" and the shiftKey is "up") and seGetPlatform() is "macos" then
      local tScript
      put the text of the selectedField into tScript
      
      local tCaretChar
      get the selectedChunk
      put word 2 of it into tCaretChar
      try
         repeat while tCaretChar > 1 and (char (tCaretChar - 1) of tScript is space)
            subtract 1 from tCaretChar
         end repeat
      catch tError
         put tError
      end try
      if tCaretChar is not 1 and char tCaretChar - 1 of tScript is return then
         lock messages
         select before char tCaretChar of the selectedField
         unlock messages
      end if
   end if
   
   pass rawKeyDown
end rawKeyDown


# Description
#   RawKeyUp is handled to deal with the arrow keys. The script editor needs to update when these are pressed
#   because they change the selection, however in order to do this efficiently, we have to only update when the key
#   is actually released, not each repeat interval.
on rawKeyUp pKey
   if not handleEvent("rawKeyUp", the long id of the target) then
      pass rawKeyUp
   end if
   
   if pKey is not among the items of kKeyLeftArrow,kKeyRightArrow,kKeyUpArrow,kKeyDownArrow then
      pass rawKeyUp
   end if
   
   # Check to see if one of the arrow keys is still being held down. If so, don't do the selectionChanged update until they
   # are all released as it will still be moving
   local tDownKeys
   put keysDown() into tDownKeys
   if (kKeyLeftArrow is among the items of tDownKeys) or (kKeyRightArrow is among the items of tDownKeys) or (kKeyUpArrow is among the items of tDownKeys) or (kKeyDownArrow is among the items of tDownKeys) then
      pass rawKeyUp
   end if
   
   local tKeyName
   switch pKey
      case kKeyLeftArrow
         put "left" into tKeyName
         break
      case kKeyRightArrow
         put "right" into tKeyName
         break
      case kKeyUpArrow
         put "up" into tKeyName
         break
      case kKeyDownArrow
         put "down" into tKeyName
         break
   end switch
   
   if not scriptLocked() then
      textMark "Insert"
      send "selectionChangedByArrowKey tKeyName" to me in 0 milliseconds
   end if
   pass rawKeyUp
end rawKeyUp

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
   
   switch pItemName
      case "Set Breakpoint"
         if sLastClickLine is not empty then
            local tScript
            put textGetScript() into tScript
            
            local tLineNumber
            put revDebuggerNextAvailableBreakpoint(tScript, sLastClickLine - 1) into tLineNumber
            
            revDebuggerAddBreakpoint sObjectId, tLineNumber
            revDebuggerActivateBreakpoint sObjectId, tLineNumber
            updateGutterRequest empty, empty, empty, empty, false, false
         end if
         break
         
      case "Find in Docs"
         local tText, tData
         put getClickText() into tText
         put ideDocsFetchLCSData(tText) into tData
         if tData is not empty then
            revIDEGoToLCSDictionaryEntry tText, tData[1]["type"]
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

private command goMatchingDefinition pMatch
   local tObject, tLine
   put item 5 to -1 of pMatch into tObject
   
   put item 4 of pMatch into tLine
   
   revSEGoExecutionPoint tObject, tLine, true, true
end goMatchingDefinition


private function getDisambiguatorObject
   return the long id of stack "revSEDisambiguator"
end getDisambiguatorObject

--private command showDisambiguator
--   local tObject
--   put getDisambiguatorObject() into tObject
--   --set the topLeft of tObject to the selectedLoc
--   set the loc of 
--end showDisambiguator

--private command hideDisambigutator
--   set the right of getDisambiguatorObject() to the left of the long owner of getDisambiguatorObject() - 500
--end hideDisambigutator

--command disambiguatorPick pSymbol
--   hideDisambigutator
--   log "pSymbol: " & the cResult of getDisambiguatorObject()
--end disambiguatorPick

private function getSelectedText
   local tFrom, tTo
   get the selectedChunk
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tText
   if tTo < tFrom then
      getCaretToken
      put the result into tText
   else
      put char tFrom to tTo of textGetScript() into tText
   end if
   
   return tText
end getSelectedText

# OK-2009-01-22 : Bug 7278 - Use the clickText instead of the selectedText for the context menu
# Also modified getCaretToken by adding optional pUseClick parameter.
private function getClickText
   --   local tFrom, tTo
   --   get the clickChunk
   --   put word 2 of it into tFrom
   --   put word 4 of it into tTo
   
   local tText
   --   if tTo < tFrom then
   getCaretToken true
   put the result into tText
   --else
   --   put char tFrom to tTo of textGetScript() into tText
   --end if
   
   return tText
end getClickText

# Parameters
#   pLine : the line number we are inserting at (i.e word 2 of the selectedLine at the point which the return was pressed which triggered the autocomplete)
#   xString : the string to put the completion after. This is the string that is about to be appended to the script as a result of pressing return
# Description
#   Calculates the correct completion according to what is already on line pLine, including formatting, and places it after xString,
#   which can then be inserted into the script field.
private command autoComplete pLine, @xString
   local tScript
   put textGetScript() into tScript
   
   local tCurrentLine
   put line pLine of tScript into tCurrentLine
   
   # From the text in the current line, calculate what kind of structure the user is typing the start of (if any)
   local tStructureType, tStructureName
   get autoCompleteGetStructure(tCurrentLine)
   put line 1 of it into tStructureType
   put line 2 of it into tStructureName
   
   # Once we know what the structure is, lookup what the correct completion is for that structure.
   local tCompletion
   put autoCompleteGetCompletion(tStructureType, tStructureName) into tCompletion
   if tCompletion is empty then
      exit autoComplete
   end if
   
   if tCompletion is empty then
      exit autoComplete
   end if
   
   # Look down the script and work out if we actually need to complete this structure, i.e. find out if its
   # already been completed or not.
   if not autoCompleteCompletionRequired(pLine, tStructureType, tStructureName, tCompletion) then
      exit autoComplete
   end if
   
   # Format the completion, this is easy because the indentation of the complete will always match
   # that of pLine.
   local tIndent
   put textFormatGetLineIndent(tCurrentLine) before tCompletion
   put return & tCompletion after xString
end autoComplete

private function autoCompleteSearchContext @pScript, pLineNumber, pStructureType, pStructureName, pCompletion
   if pStructureName is not empty then
      return 1
   end if
   
   local tDepth
   put 0 into tDepth
   repeat with x = pLineNumber down to 1
      local tLine
      put line x of pScript into tLine
      
      if token 1 of tLine is "private" and token 2 of tLine is among the items of autoCompleteNamedStructures() then
         exit repeat
      else if token 1 of tLine is among the items of autoCompleteNamedStructures() then
         exit repeat
      end if
      
      if token 1 of tLine is pStructureType then
         add 1 to tDepth
      else if token 1 of tLine is "end" and token 2 of tLine is pStructureType then
         subtract 1 from tDepth
      end if
   end repeat
   
   return tDepth
end autoCompleteSearchContext

# Parameters
#   pLineNumber : the line that the structure to be completed starts on
#   pStructureType : the type of the structure to be completed this is either one of autoCompleteNamedStructures() or autoCompleteUnnamedStructures()
#   pStructureName : the name of the structure. (May be empty, not all structures have names, basically only handlers do)
#   pCompletion : what the completion of the structure would be (this is needed in order to see if its already there).
# Returns
#   True if a completion is required for this specification, false otherwise.
function autoCompleteCompletionRequired pLineNumber, pStructureType, pStructureName, pCompletion
   local tScript
   put textGetScript() into tScript
   
   local tInitialDepth
   put autoCompleteSearchContext(tScript, pLineNumber, pStructureType, pStructureName, pCompletion) into tInitialDepth
   put line pLineNumber + 1 to -1 of tScript into tScript
   
   # The nesting depth starts at 1 as we have just entered a structure
   local tNestingDepth
   put tInitialDepth into tNestingDepth
   repeat for each line tLine in tScript
      if token 1 of tLine is token 1 of pCompletion and token 2 of tLine is token 2 of pCompletion then
         subtract 1 from tNestingDepth
         if tNestingDepth = 0 then
            # The structure is already completed
            return false
         end if
      else if token 1 of tLine is "end" and token 2 of tLine is not among the items of autoCompleteUnnamedStructures() and token 2 of tLine is not "if" then
         # If a named structure is ending, but it doesn't match the structure we are looking for
         # then if the structure we're looking for is un-named, we return true
         if pStructureName is empty then
            return true
         end if
         
         # Else if we are looking for a named structure, then don't do the completion, because
         # its possible that the user is renaming a handler and we should be conservative here.
         if pStructureName is not empty then
            return false
         end if
      else
         get autoCompleteGetStructure(tLine)
         
         # If we have a matching structure being opened, increment the nesting depth
         if line 1 of it is pStructureType and line 2 of it is pStructureName then
            add 1 to tNestingDepth
         end if
         
         # If a new handler has started and we are completing an any structure then
         # we should return true now.
         if line 2 of it is not empty then
            return true
         end if
      end if
   end repeat
   
   return true
end autoCompleteCompletionRequired

# Returns
#   A comma separated list of the autocompleteable structures that have names. This is currently just handlers.
private function autoCompleteNamedStructures
   return handlerTypes()
end autoCompleteNamedStructures

# Returns
#   A comma separated list of the autocompleteable structures without names. Note that we don't complete IF statements
#   because there are too many possibilities, (else, else if, end if) and its better to not complete than risk forcing the user to delete stuff.
private function autoCompleteUnnamedStructures
   return "repeat,try,switch"
end autoCompleteUnnamedStructures

# Parameters
#   pLine : a line number in the current script
# Returns
#   A string describing the structure whose beginning is found on pLine. This is in the following format:
#     Line 1 : The structure's type, e.g. command, repeat, try
#     Line 2 : The structure's name if it has one, e.g. mouseUp
#   If pLine does not represent the beginning of a completable structure then the structure type will be empty.
private function autoCompleteGetStructure pLine
   local tLine
   put pLine into tLine
   
   # Disregard "private" if first token
   if token 1 of tLine is "private" then
      put token 2 to -1 of tLine into tLine
   end if
   
   local tStructureType, tStructureName
   
   # Establish what the structure type and name (if appropriate) are. We autocomplete handler declarations,
   # repeats, trys and switches, but not ifs (because they have too many different forms, might annoy the user).
   if token 1 of tLine is among the items of autoCompleteNamedStructures() then
      put token 1 of tLine into tStructureType
      put token 2 of tLine into tStructureName
   else if token 1 of tLine is among the items of autoCompleteUnnamedStructures() then
      put token 1 of tLine into tStructureType
      put empty into tStructureName
   end if
   
   return tStructuretype & return & tStructureName
end autoCompleteGetStructure

# Parameters
#   pStructureType : the type of a completeable structure
#   pStructureName : the name of a compleatable structure (may be empty)
# Returns
#   The completion of the stucture if one is known. E.g if pStructureType is "on" and pStuctureName is "mouseUp",
#   will return "end mouseUp"
private function autoCompleteGetCompletion pStructureType, pStructureName
   # Make sure we have something valid that can be completed
   if pStructureType is empty then
      return empty
   end if
   
   # Work out the completion
   local tCompletion
   if pStructureType is among the items of handlerTypes() then
      if pStructureName is not empty then
         put "end " & pStructureName into tCompletion
      end if
   else
      put "end " & pStructureType into tCompletion
   end if
   
   return tCompletion
end autoCompleteGetCompletion

# Parameters
# Description
#   Returns the specification of replace operation that represents the inserting of a
#   return character at the specified location in the current script. Includes formatting.
#   This command will also remove indentation from the previous line.
private command calculateReturnFormatting pTo, pFrom, pLine, pContinuationRequired, @rAt, @rLength, @rString
   local tReturnString
   if pContinuationRequired then
      put " \" & return into tReturnString
   else
      put return into tReturnString
   end if
   
   # If there is a non-empty selection, the inserted return char will replace this
   # and for now, no formatting is done.
   if pFrom <= pTo then
      put pFrom into rAt
      put pTo - pFrom + (the length of tReturnString) into rLength
      put tReturnString into rString
      exit calculateReturnFormatting
   end if
   
   # If the preference is not to use formatting, just return the specification of the basic 
   # insertion of a return character.
   if not sePrefGet("editor,autoformat") then
      put pFrom into rAt
      put 0 into rLength
      put tReturnString into rString
      exit calculateReturnFormatting
   end if
   
   local tScript
   put textGetScript() into tScript
   
   local tPreviousChars
   repeat with x = pFrom - 1 down to 1
      if char x of tScript is empty or char x of tScript is return then
         exit repeat
      end if
      put char x of tScript after tPreviousChars
   end repeat
   
   local tWhitespaceBefore
   put matchText(tPreviousChars, "^\s*$") into tWhitespaceBefore
   
   if tWhitespaceBefore then
      local tIndent
      put textFormatGetLineIndent(line pLine of tScript) into tIndent
      
      # If the caret has somehow been placed in the middle of the indentation string we need to allow
      # for this by subtracting from tIndent
      local tCurrentChar
      put pFrom into tCurrentChar
      repeat until (char tCurrentChar of tScript is not space) or the number of chars of tIndent = 0
         delete char 1 of tIndent
         add 1 to tCurrentChar
      end repeat
      
      local tLength
      put 0 into tLength
      
      local tAt
      put pFrom into tAt
      
      local tReturn
      put return & tIndent into tReturn
   else
      local tFormatting
      local tPreviousLine = 0
      local tTextLines
      put tScript into tTextLines
      split tTextLines by return
      
      put textFormatLine(pLine, tTextLines, tPreviousLine) into tFormatting
      
      put (the number of chars of line 1 to (pLine - 1) of tScript) + 1 into tAt 
      if pLine <> 1 then 
         add 1 to tAt 
      end if
      
      if item 1 of tFormatting > 0 then
         repeat item 1 of tFormatting times
            put space after tIndent
         end repeat
         textReplace tAt, empty, tIndent
      else if item 1 of tFormatting < 0 then
         textReplace tAt, char tAt to (tAt - item 1 of tFormatting - 1) of tScript, empty
      end if
      
      put 0 into tLength
      put pFrom into tAt
      add item 1 of tFormatting to tAt
      put tReturnString & item 2 of tFormatting into tReturn
   end if
   
   put tAt into rAt
   put tLength into rLength
   put tReturn into rString
end calculateReturnFormatting

on returnInField
   if the commandKey is "down" then
      # Pass to prevent conflict with command + return keyboard shortcut
      pass returnInField
   end if
   
   if not handleEvent("returnInField", the long id of the target) then
      pass returnInField
   end if
   
   if scriptLocked() then
      exit returnInField
   end if
   
   local tFrom, tTo
   get the selectedChunk
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tLine
   put word 2 of the selectedLine into tLine
   
   # Option+Return places a continuation char on the current line before the return.
   local tContinuationRequired
   put (optionKey() is "down") into tContinuationRequired
   
   local tAt, tLength, tReturn
   calculateReturnFormatting tTo, tFrom, tLine, tContinuationRequired, tAt, tLength, tReturn
   
   local tCaretOffset
   put tAt + the length of tReturn - 1 into tCaretOffset
   
   local tLineEnd
   put the number of chars of line 1 to tLine of textGetScript() + 1 into tLineEnd
   
   local tFollowingChars
   put char tAt to tLineEnd of textGetScript() into tFollowingChars
   
   local tWhitespaceAfter
   put matchText(tFollowingChars, "^\s*$") into tWhitespaceAfter
   
   if sePrefGet("editor,autocomplete") and tWhitespaceAfter then
      autoComplete tLine, tReturn
   end if
   
   # The return character should be grouped separately from the line that was entered before it (if there was one)
   # This copies the behavior of MS Visual Studio.
   if sTextGroupIndex[sObjectId] is not 0 then
      # OK-2008-07-29 : Bug 6825
      --textEndGroup
      textMark "Insert"
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, tReturn
   select after char tCaretOffset of field "Script" of me
   textEndGroup
   
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end returnInField

-- Drag Drop Management
local sDragMode

on dragDrop
   if not handleEvent("dragDrop", the long id of the target) then
      pass dragDrop
   end if
   
   if scriptLocked() then
      exit dragDrop
   end if
   
   lock screen
   textBeginGroup "Drag"
   
   local tDropAt
   get the dropChunk
   put word 2 of it into tDropAt
   
   local tSelectFrom, tSelectTo
   get the selectedChunk
   put word 2 of it into tSelectFrom
   put word 4 of it into tSelectTo
   
   if tDropAt >= tSelectFrom and tDropAt <= tSelectTo then
      exit dragDrop
   end if
   
   if sDragMode is "cut" then
      -- Remove the selection. This will never happen on a drag that started outside the ScriptEditorPane.
      
      -- in this case, we cannot have tFrom > tTo
      textReplace tSelectFrom, char tSelectFrom to tSelectTo of control "Script" of me, empty
      
      if tDropAt > tSelectTo then
         subtract tSelectTo - tSelectFrom + 1 from tDropAt
      end if
   end if
   
   
   local tDroppedText
   put dragData["text"] into tDroppedText
   -- There is an issue with the very last return character, for now it seams sufficient to remove this.
   #  if char -1 of tDroppedText is return then
   #    delete char -1 of tDroppedText
   #  end if
   
   textReplace tDropAt, empty, tDroppedText
   
   textEndGroup
   unlock screen
end dragDrop

on dragStart
   if not handleEvent("dragStart", the long id of the target) then
      pass dragStart
   end if
   
   # OK-2008-08-01 : Bug 6709 - On Macs, the option key should result in a copying drag.
   if seGetPlatform() is not "MacOS" then
      if the controlKey is "down" then
         put "copy" into sDragMode
      else
         put "cut" into sDragMode
      end if
   else
      if the optionKey is "down" then
         put "copy" into sDragMode
      else
         put "cut" into sDragMode
      end if
   end if
   
   pass dragStart
end dragStart

on dragEnd
end dragEnd

on exitField
   -- OK-2008-07-10 : Check that an object is loaded before attemping to save context,
   -- this is prevent annoying errors from ocurring when editing the IDE.
   if sObjectId is not empty then
      contextSave
   end if
   pass exitField
end exitField

on closeField
   -- OK-2008-07-10 : Check that an object is loaded before attemping to save context,
   -- this is prevent annoying errors from ocurring when editing the IDE.
   if sObjectId is not empty then
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
      put sObjectid into sFirstFindObject
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
   
   put sObjectId into sLastFindObject
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
         put lineOffset(seGetRuggedId(sObjectId), tObjectList) into tLineNumber
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
      put findListObjectsOnCard(sObjectId) into tObjectList
   else if pTarget is "stack" then
      # Searches the stack of the sript editor's current object. This means the stack script itself,
      # and all other objects in the stack, including all cards but not substacks.
      put findListObjectsOnStack(sObjectId) into tObjectList
   else if pTarget is "stack file" then
      # As with "stack" except also searches all stacks in the same file.
      put findListObjectsOnStackAndSubstacks(sObjectId, false, pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "all stacks" then
      # Searches all stacks and substacks in memory
      put findListObjectsOnAllStacksAndSubstacks(false, pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "stack file and stackfiles" then
      # As for "stack file" except also searches all available stacks in the stackFiles property
      put findListObjectsOnStackAndSubstacks(sObjectId, true, pCallback, pCallbackTarget, rCancelled) into tObjectList
   else if pTarget is "all available stacks" then
      # Searches all stacks and substacks in memory and all stackFiles. Note this is not recursive at the moment, i.e
      # stackFiles of stackFiles are not searched.
      put findListObjectsOnAllAvailableStacks(pCallback, pCallbackTarget, rCancelled) into tObjectList
   else
      put sObjectId into tObjectList
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
            
            local tStackFileList
            put empty into tStackFileList
            get revIDEListSearchObjectTree(the name of stack tPath, false, empty, true, true, true, tStackFileList)
            put tStackFileList after tList
         end if
         unlock messages
         
      end repeat
      delete the last char of tList
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
   # If gREVDEvelopment, then we search all IDE stacks as well, otherwise just the user stacks.
   # Searching only stacks that are actually open seems not too useful, so the script editor will
   # search all stacks in memory.
   local tMainstacks
   put the mainstacks into tMainstacks
   
   global gREVDevelopment
   
   local tList
   repeat for each line tMainstack in tMainstacks
      # Skip ide mainstacks based on their filename. It is assumed that a substack is
      # ide if and only if its mainstack is.
      if not gREVDevelopment and revIDEStack(the filename of stack tMainstack) then
         next repeat
      end if
      
      # Unfortunately not all IDE stacks have a filename, in particular the property inspector instances.
      if not gREVDevelopment and revOKTarget(the long id of stack tMainstack) then
         next repeat
      end if
      
      findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tMainstack)
      if the result is "cancel" then
         put the result into rCancelled
         return empty
      end if
      
      local tStackObjectList
      put empty into tStackObjectList
      get revIDEListSearchObjectTree(the name of stack tMainstack, false, empty, true, true, true, tStackObjectList)
      
      # Next search the stackFiles property. Note here that a stack in the stackFiles may also be in the mainstacks
      # if it happens to be open, so we skip these to avoid searching them twice.
      repeat for each line tStackFile in the stackFiles of stack tMainstack
         local tPath
         put resolveStackFilePath(item 2 to -1 of tStackFile, the name of stack tMainstack) into tPath
         
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
            
            local tStackFileList
            put empty into tStackFileList
            
            get revIDEListSearchObjectTree(the name of stack tPath, false, empty, true, true, true, tStackFileList)
            put tStackFileList after tStackObjectList
            
            --            lock messages
            --            delete stack tPath
            --            unlock messages
         end if
         unlock messages
      end repeat
      
      put tStackObjectList after tList
   end repeat
   delete the last char of tList
   return tList
end findListObjectsOnAllAvailableStacks

private function findListObjectsOnAllStacksAndSubstacks pCallback, pCallbackTarget, @rCancelled
   # If gREVDEvelopment, then we search all IDE stacks as well, otherwise just the user stacks.
   # Searching only stacks that are actually open seems not too useful, so the script editor will
   # search all stacks in memory.
   local tMainstacks
   put the mainstacks into tMainstacks
   
   global gREVDevelopment
   
   local tList
   repeat for each line tMainstack in tMainstacks
      # Skip ide mainstacks based on their filename. It is assumed that a substack is
      # ide if and only if its mainstack is.
      if not gREVDevelopment and revIDEStack(the filename of stack tMainstack) then
         next repeat
      end if
      
      findDispatchCallback pCallback, pCallbackTarget, "Listing: " & revRuggedId(the long id of stack tMainstack)
      if the result is "cancel" then
         put the result into rCancelled
         return empty
      end if
      
      local tStackObjectList
      put empty into tStackObjectList
      get revIDEListSearchObjectTree(the name of stack tMainstack, false, empty, true, true, tStackObjectList)
      put tStackObjectList after tList
   end repeat
   delete the last char of tList
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

command getLastSelectedChunk
   return sLastSelectedChunk
end getLastSelectedChunk

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
   if sLastFindObject is not empty and seGetRuggedId(sLastFindObject) is seGetRuggedId(sObjectId) then
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
      if seGetRuggedId(tObject) is not seGetRuggedId(sObjectId) then
         revSESetCurrentObject tObject, empty, true
         put 1 into tStart
      else
         if tStart is empty then
            # Must be the first iteration
            put tSearch["start"] into tStart
         else
            # Calculate a new search start
            if sLastFindObject is not empty and seGetRuggedId(sLastFindObject) is seGetRuggedId(sObjectId) and sLastFindLocation is not empty then
               if pInteractive then
                  put item 1 of sLastFindLocation into tStart
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
         
         if tResult is sFirstFindLocation and sObjectId is sFirstFindObject then
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
      
      if tResult is sFirstFindLocation and sObjectId is sFirstFindObject then
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
   put the mainstacks into tOldMainstacks
   
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
         local tObjectName
         put revRuggedId(the long id of tObject) into tObjectName
         findDispatchCallback pCallback, pCallbackTarget, "Searching: " & tObjectName
         if the result is "cancel" then
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
            local tLineNumber
            put the number of lines of char 1 to (item 1 of tResult) of tScript into tLineNumber
            put tObject & tab & tLineNumber & tab & item 1 of tResult & tab & item 2 of tResult & tab & line tLineNumber of tScript & return after tGlobalResults
         end repeat
      end if
   end repeat
   delete the last char of tGlobalResults
   
   # Format the results for display
   local tFormattedResults
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
   put tGlobalResults after tFormattedResults
   
   # Display the results in the search results pane
   # OK-2008-09-11 : Refactored to avoid direct interaction with Search Results pane.
   sePrefSet "editor,lastsearchresults", tFormattedResults
   send "setCurrentTab Search Results" to group "Pane Tabs" of seStackId()
   send "expandCurrentPane" to group "Panes" of seStackId()
   send "refreshCurrentPane" to group "Panes" of seStackId()
   
   local tNewMainstacks
   put the mainstacks into tNewMainstacks
   
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
   textReplace tAt, char tFrom to tTo of textGetScript(), pString
   
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
end mouseMove

on mouseLeave
   tooltipUpdateCancel
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
      put the revAvailableVariables of sObjectId into tVariables
   else
      put the revAvailableVariables[tHandler] of sObjectId into tVariables
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
   
   # Find out if the variable is an array
   local tKeys
   put revDebuggerGetKeys(tMouseVariable) into tKeys
   
   # Get its value in the curent debug context from the debugger. Truncate to make sure we don't try and 
   # display very large variables and format it for the tooltip.
   local tValue
   if tKeys is empty then
      put tooltipTruncateValue(revDebuggerGetValue(tMouseVariable, empty, empty, empty), empty, 500) into tValue
   else
      repeat for each line tKey in line 1 to kTooltipArrayKeyCount of tKeys
         --local tExpression
         --put tMouseVariable & "[" & quote & tKey & quote & "]" into tExpression
         local tElementList
         put tKey into tElementList[1]
         put tKey & " = " & tooltipTruncateValue(revDebuggerGetValue(tMouseVariable, ,tElementList, empty), 1, 200) & return after tValue
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

# Description
## Returns a line stripped of comments at the end of the line
private function lineStripComments pLine
   local tOffset,tCommentChar
   put offset("#", pLine) into tOffset
   if tOffset = 0 then
      put offset("--", pLine) into tOffset
      put "--" into tCommentChar
   else
      put "#" into tCommentChar
   end if
   
   if tCommentChar is empty then
      return pLine
   else
      return char 1 to tOffset of pLine
   end if
end lineStripComments

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
