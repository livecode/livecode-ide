script "revseutilities"
################################################################################
#
# WARNING Making changes to this script using the (new) script editor may
# result in the script editor breaking as instances of the editor call functions
# and commands in here. Viewing the script should be ok and it might be possible
# to edit it with care, but its safer to copy the script to another stack first
# in a similar way to if you are editing revBackscript.
#
################################################################################

on preOpenStack
   set the behavior of stack "revSETemplate" of me to the long id of stack revIDEScriptEditorBehavior("stack")
   send "setBehaviors" to stack "revSETemplate" of me
end preOpenStack

# Because all script editors are substacks of this stack, we should delete them here
# as the engine will not remove them from memory otherwise.
on closeStackRequest
   if the cMutable of the owner of the target then
      send "revSEDeleteSubStack the long id of the owner of the target" to me in 0 milliseconds
   end if
   
   pass closeStackRequest
end closeStackRequest

# Parameters
#   pStack : a reference to one of the substacks of the script editor.
# Description
#   Deletes the specified stack, providing its a valid deletable substack.
command revSEDeleteSubstack pStack
   # The DestroyStack property of script editors is set to true, however it seems that they sometimes get deleted
   # and sometimes don't when the window is closed. For now this is worked around by checking that the stack still exists before
   # attempting to delete. This may be the result of a bug in revFrontScript somewhere.
   if pStack is empty or there is no pStack then
      exit revSEDeleteSubStack
   end if
   
   # BB-2014-07-25 : Bug 9598 - Catch an error being thrown when LiveCode IDE is shutting down
   # Fix courtesy of Mark Wieder
   try
      if the cMutable of pStack and the long id of the owner of pStack is the long id of me then
         delete stack (the short name of pStack)
      end if
   catch e
   end try
   
   # OK-2008-12-16 : Bug 7542 - If there are no script editors left open, ensure that the find and replace palette 
   # is not left showing on its own.
   if the number of lines of revListScriptEditors() = 0 then
      close stack "revSEFind"
   end if
end revSEDeleteSubstack

on saveStackRequest
   # Clear substacks, this is just to ensure that the script editor is always
   # saved in a clean state after being edited.
   if the long id of the target is the long id of this card of me then
      revSEPurgeMutableStacks
   end if
   pass saveStackRequest
end saveStackRequest

command revSEPurgeMutableStacks
   repeat for each line tSubStack in the substacks of me
      if the cMutable of stack tSubstack then
         delete stack tSubStack
      end if
   end repeat
end revSEPurgeMutableStacks

# Parameters
#   pPreference : the name of the preference setting to return
# Description
#   Returns the default value of the specified preference setting.
command revSEGetDefaultPreference pPreference
   local tPrefs
   sePrefGetDefaults
   put the result into tPrefs
   
   if pPreference is not among the keys of tPrefs then
      --throw "invalid_preference"
      return empty
   end if
   
   return tPrefs[pPreference]
end revSEGetDefaultPreference

# Parameters
#   pPreference : the name of the preference setting to return
# Description
#   Returns the value of the specified script editor preference currently being used.
command revSEGetPreference pPreference
   local tPropname
   put "cScriptEditor," & pPreference into tPropname
   
   local tValue
   put revIDEGetPreference(tPropname) into tValue
   if tValue is not empty then
      return tValue
   end if
   
   local tDefaultValue
   revSEGetDefaultPreference pPreference
   put the result into tDefaultValue
   
   return tDefaultValue
end revSEGetPreference

# Description
#   Called when Revolution is about to be quit. Makes a list of all scripts with unsaved changes and 
#   pops up a dialog asking the user if they should be applied or not. Returns empty if the result
#   of this is that Revolution should quit, and returns "cancel" otherwise.
command revSEQuitCheck
   local tEditors
   put revListScriptEditors() into tEditors
   
   # Get a list of all objects with unsaved scripts currently open
   local tModifiedObjects
   repeat for each line tEditor in tEditors
      local tObjects
      send "revSEGetModifiedObjects" to tEditor
      put the result into tObjects
      if tObjects is not empty then
         put tObjects & return after tModifiedObjects
      end if
   end repeat
   delete the last char of tModifiedObjects
   
   # Bring up a dialog listing all these objects and find out if the user wants to quit or not
   local tResult
   revSEWarnBeforeClosing tModifiedObjects
   put the result into tResult
   return tResult
end revSEQuitCheck

# Parameters
#   pTarget : reference to the object that had its named changed
#   pOldName : the object's old name
#   pNewName : the objects' new name
# Description
#   Updates all script editors to reflect the renaming of this object.
command revSEObjectNameChanged pTarget, pOldName, pNewName
   # If a stack has had its name changed, its rugged id will have changed
   local tEditors
   if word 1 of the name of pTarget is "stack" then
      local tStackId
      put revRuggedId(pTarget) into tStackId
      put quote & pOldName & quote into word 2 of tStackId
      
      put listAffectedEditors(tStackId) into tEditors
      
      repeat for each line tEditor in tEditors
         send "revSEObjectRuggedIdChanged pTarget, tStackId" to tEditor
      end repeat
   else
      put listAffectedEditors(pTarget) into tEditors
      
      repeat for each line tEditor in tEditors
         send "revSERefreshObjectnames" to tEditor
      end repeat
   end if
end revSEObjectNameChanged

# Parameters
#   pObject : reference to the object about to be deleted
# Description
#   Sent just before pObject is deleted. Removes pObject from any script editor
#   that may be editing it, gives no warning if the script is not saved etc. Note
#   this is different to the old script editor behavior, where the "Copy and close" dialog
#   was shown. The idea here is that the IDE should ask the user before deleting an object 
#   with script rather than copy the script to the clipboard afterwards. 
command revSEObjectDeleted pObject
   local tObject
   put revRuggedId(pObject) into tObject
   
   local tEditors
   put listAffectedEditors(tObject) into tEditors
   
   local tTargetObjects
   repeat for each line tEditor in tEditors
      send "revSEGetTargetObjects" to tEditor
      put the result into tTargetObjects
      
      repeat for each line tTargetObject in tTargetObjects
         if tTargetObject is tObject or seRuggedObjectContainsObject(tObject, tTargetObject) then
            send "revSERemoveTargetObject tTargetObject, true" to tEditor
         end if
      end repeat
   end repeat
end revSEObjectDeleted
  
# Parameters
#   pObject : a valid object rugged id. Does not have to be a valid object reference, i.e it may be an id of a deleted / renamed object.
# Returns
#   A list of the script editors affected by changes to the specified object. This is all
#   editors that have the object's script open, or any of the objects that pObject may contain.
private function listAffectedEditors pObject
   local tEditors
   put revListScriptEditors() into tEditors
   
   local tAffectingObject
   put pObject into tAffectingObject
   
   local tAffectedEditors
   repeat for each line tEditor in tEditors
      local tObjects
      send "revSEGetTargetObjects" to tEditor
      put the result into tObjects
      
      repeat for each line tObject in tObjects
         if tObject is tAffectingObject or seRuggedObjectContainsObject(tAffectingObject, tObject) then
            put tEditor & return after tAffectedEditors
            exit repeat
         end if
      end repeat
   end repeat
   delete the last char of tAffectedEditors
   
   return tAffectedEditors
end listAffectedEditors

# Parameters
#   pObject : reference to the object that just had its id changed
#   pOldId : the object's old id
#   pNewId : the object's new id
# Description
#   Called when an object's id is changed, updates script editor's as appropriate. 
#   Note that only images can have their ids changed.
command revSEObjectIdChanged pObject, pOldId, pNewId
   # Work out what the old object id was, do this by getting its current
   # rugged id, and replacing the id with the old one. This is ok since we
   # know that pObject is not a stack (in fact it has to be an image).
   local tOldObject
   put seGetRuggedId(pObject) into tOldObject
   put pOldId into word 3 of tOldObject
   
   # We can't use the normal method for looking up a script editor revScriptEditor() 
   # because it requires the object to exist, so we have to look up the editor manually.
   local tEditors
   put revListScriptEditors() into tEditors
   
   local tFoundEditor
   repeat for each line tEditor in tEditors
      local tObjects
      send "revSEGetTargetObjects" to tEditor
      put the result into tObjects
      
      if tOldObject is among the lines of tObjects then
         put tEditor into tFoundEditor
         exit repeat
      end if
   end repeat
   
   # Now we send a message to the editor to let it know the id has changed.
   #send "revSEObjectIdChanged pObject, pOldId, pNewId" to tEditor
   if tFoundEditor is not empty then
      send "revSEObjectRuggedIdChanged pObject, tOldObject" to tFoundEditor
   end if
end revSEObjectIdChanged

# Parameters
#   pStack : reference to the stack that has just had its mainstack changed
#  Description
#   Sent when a stack has its mainstack changed. Updates script editors as appropriate.
command revSEMainstackChanged pStack, pOldStackName, pNewStackName
   # Go through the script editors and get a list of all affected objects
   local tEditors
   put revListScriptEditors() into tEditors
   repeat for each line tEditor in tEditors
      local tObjects
      send "revSEGetTargetObjects" to tEditor
      put the result into tObjects
      repeat for each line tObject in tObjects
         # Work out the name of the stack that owns the object and check that it matches the name of pStack
         local tOwningStack
         set the wholeMatches to true
         put char 2 to -2 of word (wordOffset("stack", tObject) + 1) of tObject into tOwningStack
         set the wholeMatches to false
         
         if tOwningStack is not the short name of pStack then
            next repeat
         end if
         
         # Work out what the new rugged id of the object will be
         local tNewObject
         put tObject into tNewObject
         
         # If the stack was previously a mainstack and is now a substack, we need to add its new mainstack
         if pOldStackName is the short name of pStack and pNewStackName is not pOldStackName then
            put " of stack " & quote & pNewStackName & quote after tNewObject
         end if
         
         # If the stack was previously a substack and is now a mainstack we need to remove the old mainstack
         if pOldStackName is not the short name of pStack and pNewStackname is the short name of pStack then
            delete word -3 to -1 of tNewObject
         end if
         
         # If the stack was previously a substack and is still a substack, but of a different stack, we just replace
         if pOldStackName is not the short name of pStack and pNewStackName is not the short name of pStack and pOldStackName <> pNewStackName then
            put " of stack " & quote & pNewStackName & quote into word -3 to -1 of tNewObject
         end if
         
         # We should now have a working reference to the object
         if there is a tNewObject then
            send "revSEObjectRuggedIdChanged tNewObject, tObject" to tEditor
         else
            log "new object does not exist!"
            log "Object: " & tObject
            log "tNewObject: " & tNewObject
         end if
      end repeat
   end repeat
end revSEMainstackChanged

# Description
#   Called when the IDE is suspending the development tools, prepares all script editors for suspension
command revSESuspendEditors
   local tEditors
   put revListScriptEditors() into tEditors
   
   repeat for each line tEditor in tEditors
      send "revSESuspend" to tEditor
   end repeat
end revSESuspendEditors

# Description
#   Called *just after* the IDE has restored the development tools, restores all script editors.
command revSERestoreEditors
   local tEditors
   put revListScriptEditors() into tEditors
   
   repeat for each line tEditor in tEditors
      send "revSERestore" to tEditor
   end repeat
end revSERestoreEditors

# Description
#   Sends an update message to each active script editor. This causes the breakpoints and variables panes to update
#   and will reload the script editor preferences in pPrefsChanged is true.
command revSEUpdateEditors pPrefsChanged
   local tEditors
   put revListScriptEditors() into tEditors
   
   repeat for each line tEditor in tEditors
      send " revSEUpdate pPrefsChanged" to tEditor
   end repeat
end revSEUpdateEditors

local sPrefs

# Description
#   Deletes any stored script editor preferences, and reloads from the Revolution preferences stack.
#   This is called when the Revolution preferences are reset.
command revSEReloadPreferences
   delete variable sPrefs
   sePrefInit
end revSEReloadPreferences

local sObjectCallbacks

# Parameters
#   pCallback : the name of a non-private command that can be sent to pCallbackTarget
#   pCallbackTarget : a valid reference to an object to recieve the callback
#   pObject : the object that the callback applies to.
# Description
#   When a callback is registered, it is sent to the callback target when pObject is loaded into
#   the script editor. The callback is only sent once, it needs to be registered again if futher callbacks are
#   required.
command revSERegisterObjectCallback pCallback, pCallbackTarget, pObject
   local tObject
   put revRuggedId(pObject) into tObject
   if sObjectCallbacks[tObject] is empty then
      put pCallback & comma & pCallbackTarget into sObjectCallbacks[tObject]
   else
      put pCallback & comma & pCallbackTarget into sObjectCallbacks[tObject]
   end if
end revSERegisterObjectCallback

command seSendCallbacks pObject, pScriptEditor
   local tCallbacks
   put sObjectCallbacks[pObject] into tCallbacks
   
   local tCallback, tCallbackTarget
   repeat for each line tLine in tCallbacks
      put item 1 of tLine into tCallback
      put item 2 to -1 of tLine into tCallbackTarget
      
      try
         send tCallback && "pObject,pScriptEditor" to tCallbackTarget
      end try
   end repeat
   
   delete variable sObjectCallbacks[pObject]
end seSendCallbacks


# Parameters
#   pTag : the name of the preference setting to get
# Returns
#   The value of the preference setting, or empty if not found.
function sePrefGet pTag
   if pTag is "editor,font" and \
         sPrefs[pTag] is empty and \
         "Source Code Pro" is among the lines of the fontNames then
      return "Source Code Pro"
   end if
   return sPrefs[pTag]
end sePrefGet

# Parameters
#   pTag : the name of the preference setting to set
#   pValue : the value to set it to
# Description
#   Sets a script editor preference
command sePrefSet pTag, pValue
   put pValue into sPrefs[pTag]
end sePrefSet

# Parameters
#   pFilter : a pattern to filter the preferences with, wildcards etc.
# Returns
#   The existing preference settings that match the filter pFilter
function sePrefList pFilter
  local tKeys
  put the keys of sPrefs into tKeys
  filter tKeys with pFilter
  return tKeys
end sePrefList


# Description
#   Initialises the script editor preferences system.
command sePrefInit
   # Get the default preferences, which are returned in an array.
   local tPrefs
   sePrefGetDefaults
   put the result into tPrefs
   
   # Loop through the default preferences array, and for each setting,
   # look in the Revolution preferences stack for a user defined value. 
   # If there is one, then replace the value in the preferences array,
   # otherwise leave the default in there.
   repeat for each key tKey in tPrefs
      local tPropname
      put "cScriptEditor," & tKey into tPropname
      
      local tValue
      put revIDEGetPreference(tPropname) into tValue
      if tValue is not empty then
         put tValue into tPrefs[tKey]
      end if
   end repeat
   
   
   ## Check the print shortcut, the default had a typo pre v8
   ## If the print shortcut has a typo replace it
   if tPrefs["shortcuts,Print"] is "command p'" then
      put "command p" into tPrefs["shortcuts,Print"]
   end if
   
   # The colorization settings need to be loaded
   seColorizationLoadScheme tPrefs["colorization,scheme"], tPrefs
   
   # Put the completed array into the script local sPrefs for use by the script editor.
   put tPrefs into sPrefs
   seColorizationInit
end sePrefInit

# Description
#   Saves the current script editor preferences in the Revolution preferences stack.
command sePrefSave
   local tDefaults
   sePrefGetDefaults
   put the result into tDefaults
   
   local tPropname
   repeat for each key tKey in sPrefs
      put "cScriptEditor," & tKey into tPropname
      
      revIDESetPreference tPropName, sPrefs[tKey]
   end repeat
end sePrefSave

command log pMessage
  put pMessage & return after msg
end log

command logFile pMessage
   put pMessage & return after url ("file:" & specialFolderPath("desktop") & "/Script Editor Log.txt")
end logFile

command printArray pArray
   log "Array: "
   log printArrayGetText(pArray, empty)
end printArray

function printArrayGetText pArray pIndent
   local tText
   repeat for each key tKey in pArray
      if (the keys of pArray[tKey]) is empty then
         put pIndent & tKey & " = " & pArray[tKey] & return after tText
      else
         put pIndent & tKey & return after tText
         put printArrayGetText(pArray[tKey], (pIndent & tab)) & return after tText
      end if
      
   end repeat
   return tText
end printArrayGetText
  
  # Parameters
#   pTag : a descriptive tag for the icon
# Returns
#   The id of the icon if found, empty otherwise.
function seGetIcon pTag
   return the uIconMap[pTag] of stack "revSETemplate"
end seGetIcon

# Returns
#   A reference to the stack that contains the script editor icons
function seIconStack
   return the name of stack "revIcons"
end seIconStack
  
function seGetPlatform
   return the platform
end seGetPlatform

function seGetSystemVersion
   return the systemVersion
end seGetSystemVersion
   
# Returns
#  An array containing the default settings for all available script editor preferences.
#  The array returned by this function is the definitive list of script editor preferences.
#  If a preference here is not set in the Revolution preferences stack, the default value is
#  used by the script editor. The Revolution preferences system may choose which ones of these
#  values to make available to the user, some of them don't make sense to allow the user to change.
command sePrefGetDefaults
   local tPrefs
   
   # General preferences
   put "false" into tPrefs["explicitVariables"]
   put "true" into tPrefs["preserveVariables"]
   put "true" into tPrefs["useTabs"]
   put "128,164,1020,755" into tPrefs["rect"]
   put 15 into tPrefs["historySize"]
   put true into tPrefs["showErrors"]
   put "130" into tPrefs["paneHeight"]
   put "true" into tPrefs["editShowToolbars"]
   put "true" into tPrefs["debugShowToolbars"]
   put 100 into tPrefs["leftSplit"]
   
   # Variable watcher preferences
   put seGetIcon("variablesBackground") into tPrefs["variables,background"]
   put "false" into tPrefs["variables,showglobals"]
   put "false" into tPrefs["variables,showenvvars"]
   
   # Documentation pane preferences
   put empty into tPrefs["documentation,lastLoadedDoc"]
   put empty into tPrefs["documentation,lastMatchingSearch"]
   put empty into tPrefs["documentation,lastLoadedAlternativeDocs"]
   
   put "Variables" into tPrefs["debug,lastSelectedPane"]
   put "Documentation" into tPrefs["edit,lastSelectedPane"]
   
   # Colorization preferences
   put "default" into tPrefs["colorization,scheme"]
   seColorizationLoadScheme "default", tPrefs
   
   # Editor preferences
   put 500 into tPrefs["editor,paneupdatedelay"]
   put "false" into tPrefs["editor,findvisible"]
   put "0,200,0" into tPrefs["editor,findcolor"]
   put empty into tPrefs["editor,font"]
   put 12 into tPrefs["editor,fontsize"]
   put true into tPrefs["editor,autoformat"]
   put "--" into tPrefs["editor,commentchar"]
   put "alphabetical" into tPrefs["editor,sortHandlerList"]
   put 3 into tPrefs["editor,tabdepth"]
   put "166,202,240" into tPrefs["editor,selectbackgroundcolor"]
   put "255,255,255" into tPrefs["editor,backgroundcolor"]
   put "255,255,255" into tPrefs["editor,debugBackgroundcolor"]
   put "true" into tPrefs["editor,hscrollbar"]
   put "false" into tPrefs["editor,useInteractiveFind"]
   
   # Gutter preferences
   put "true" into tPrefs["gutter,linenumbers"]
   
   # Panes preferences
   put empty into tPrefs["panes,visiblelist"]
   
   # Find preferences
   put false into tPrefs["find,casesensitive"]
   put false into tPrefs["find,wholematches"]
   put false into tPrefs["find,regularexpressions"]
   put empty into tPrefs["find,lastsearch"]
   put empty into tPrefs["find,findhistory"]
   put empty into tPrefs["find,replacehistory"]
   
   # Keyboard shortcuts. Each shortcut can be be associated with a single action,
   # only the name of the action should be used to identify it, not the whole command name.
   put "enter" & return & "command return" into tPrefs["shortcuts,ApplyAndClose"]
   put "command z" into tPrefs["shortcuts,Undo"]
   put "command shift z" into tPrefs["shortcuts,Redo"]
   put "command x" into tPrefs["shortcuts,Cut"]
   put "command v" into tPrefs["shortcuts,Paste"]
   put "command c" into tPrefs["shortcuts,Copy"]
   put "command a" into tPrefs["shortcuts,SelectAll"]
   put "command shift f" into tPrefs["shortcuts,FindDialog"]
   put "command f" into tPrefs["shortcuts,InteractiveFind"]
   put "command -" into tPrefs["shortcuts,Comment"]
   put "command s" into tPrefs["shortcuts,ApplyAndSave"]
   put "command tab" into tPrefs["shortcuts,NextScriptTab"]
   put "command shift tab" into tPrefs["shortcuts,PreviousScriptTab"]
   put "command m" into tPrefs["shortcuts,LaunchMessageBox"]
   put "command '" into tPrefs["shortcuts,SendWindowToBack"]
   put "command p" into tPrefs["shortcuts,Print"]
   put "command option f" into tPrefs["shortcuts,FindSelection"]
   
   # The default shortcuts need to be different on OS X due to stuff like expose etc.
   if seGetPlatform() is "macos" then
      put "command w" into tPrefs["shortcuts,CloseTab"]
      put "command shift w" into tPrefs["shortcuts,Close"]
      put "command shift _" into tPrefs["shortcuts,Uncomment"]
      put "command g" into tPrefs["shortcuts,FindNext"]
      put "command shift g" into tPrefs["shortcuts,FindPrevious"]
      put "command h" into tPrefs["shortcuts,ShowHandlerList"]
      put "command i" into tPrefs["shortcuts,DebugStepInto"]
      put "command o" into tPrefs["shortcuts,DebugStepOver"]
      put "command t" into tPrefs["shortcuts,DebugStepOut"]
      put "command shift >" into tPrefs["shortcuts,DebugRun"]
      put "command y" into tPrefs["shortcuts,DebugStop"]
      put "command l" into tPrefs["shortcuts,GoDialog"]
      put "command \" into tPrefs["shortcuts,ToggleBreakpoint"]
      put empty into tPrefs["editor,hilitecolor"]
   else
      put "command w" into tPrefs["shortcuts,Close"]
      put "command f4" into tPrefs["shortcuts,CloseTab"]
      put "command shift _" into tPrefs["shortcuts,Uncomment"]
      put "f3" & return & "command g" into tPrefs["shortcuts,FindNext"]
      put "shift f3" into tPrefs["shortcuts,FindPrevious"]
      put "f4" into tPrefs["shortcuts,ShowHandlerList"]
      put "f11" into tPrefs["shortcuts,DebugStepInto"]
      put "shift f11" into tPrefs["shortcuts,DebugStepOut"]
      put "f10" into tPrefs["shortcuts,DebugStepOver"]
      put "f5" into tPrefs["shortcuts,DebugRun"]
      put "shift f5" into tPrefs["shortcuts,DebugStop"]
      put "command l" into tPrefs["shortcuts,GoDialog"]
      put "f9" into tPrefs["shortcuts,ToggleBreakpoint"]
      put "178,180,191" into tPrefs["editor,hilitecolor"]
   end if
   
   # Action contexts. These define which actions are associated with which script editor components.
   # If there is no context associated with a given action, it is assumed to be global to the script editor.
   --put "editor" into tPrefs["actioncontext,Cut"]
   put "editor" into tPrefs["actioncontext,Paste"]
   
   # OK-2008-08-25: Bug 7024 - undo and redo should be specific to the editor group
   --put "editor" into tPrefs["actioncontext,Undo"]
   --put "editor" into tPrefs["actioncontext,Redo"]
   
   put 7 into tPrefs["print,textSize"]
   
   put true into tPrefs["editor,showDefaultHandlers"]
   
   put true into tPrefs["editor,liveerrors"]
   put true into tPrefs["editor,bracketcompletion"]
   put true into tPrefs["editor,brackethighlighting"]
   put "255,200,200" into tPrefs["editor,brackethighlightcolor"]
   -- autocomplete is legacy control structure completion
   put true into tPrefs["editor,autocomplete"]
   -- autocomplete is completions list
   put true into tPrefs["editor,providercompletion"]
   
   return tPrefs
end sePrefGetDefaults
 
command revSESetupPrintTemplate
   local tField
   put revSEGetPrintTemplate() into tField
   
   set the textFont of tField to sePrefGet("editor,font")
   set the textSize of tField to sePrefGet("print,textSize")
   set the dontWrap of tField to true
   set the fixedLineHeight of tField to true
end revSESetupPrintTemplate

function revSEGetPrintTemplate
   return the long id of field "Print Template" of revScriptEditorMain()
end revSEGetPrintTemplate
 
 
local sColorizationClasses
local sColorizationKeywords
 
# Description
#   Called when the colorization needs to be initialized. This can happen
#   when the script editor is opened, or when a colorization preference has changed.
#   Gets the current colorization settings from the preferences system, and builds
#   them into two script local arrays for use by the editor group.
command seColorizationInit
  colorizationBuildSettings sePrefGet("colorization,config"), sColorizationClasses, sColorizationKeywords
end seColorizationInit

# Parameters
#   pScheme : the name of the colorization scheme to load
#   pPreferencesArray : reference to the preferences array to set the scheme on.
# Description
#   Places the appropriate settings for the specified colorization scheme into 
#   the sPrefs array. To apply the newly loaded scheme, call seColorizationInit
#   after the scheme has been loaded.
command seColorizationLoadScheme pScheme, @pPreferencesArray
   switch pScheme
      case "default"
         put "group commands bold 127,127,0" & return & \
               "group properties none 0,127,127" & return & \
               "group functions none 127,0,127" & return & \
               "class error none 255,0,0" & return & \
               "class singlecomment bold 0,127,0" & return & \
               "class multicomment italic 0,127,0" & return & \
               "class identifier none 0,0,0" & return & \
               "class literal none 0,0,127" & return & \
               "class number none 0,0,127" & return & \
               "class keyword none 127,0,127" & return & \
               "class operator none 0,0,0" & return & \
               "class continuation none 0,0,0" & return & \
               "keyword command bold 0,0,0" & return & \
               "keyword private bold 0,0,0" & return & \
               "keyword on bold 0,0,0" & return & \
               "keyword end bold 0,0,0" & return & \
               "keyword if bold 0,0,0" & return & \
               "keyword then bold 0,0,0" & return & \
               "keyword else bold 0,0,0" & return & \
               "keyword function bold 0,0,0" & return & \
               "keyword setprop bold 0,0,0" & return & \
               "keyword getprop bold 0,0,0" & return & \
               "keyword repeat bold 0,0,0" & return & \
               "keyword switch bold 0,0,0" & return & \
               "keyword try bold 0,0,0" & return & \
               "keyword catch bold 0,0,0" & return & \
               "keyword case bold 0,0,0" & return & \
               "keyword default bold 0,0,0" & return & \
               "keyword finally bold 0,0,0" & return & \
               "keyword next bold 0,0,0" & return & \
               "keyword exit bold 0,0,0" & return into pPreferencesArray["colorization,config"]
         break
         
      case "revolution classic"
         put "group commands none 0,0,255" & return & \
               "group properties none 255,0,0" & return & \
               "group functions none 248,128,23" & return & \
               "group structures none 152,5,23" & return & \
               "class error none 0,0,0" & return & \
               "class singlecomment none 104,34,139" & return & \
               "class multicomment none 104,34,139" & return & \
               "class identifier none 0,0,0" & return & \
               "class literal none 0,0,0" & return & \
               "class number none 0,0,0" & return & \
               "class keyword none 0,0,0" & return & \
               "class operator none 0,0,0" & return & \
               "keyword on none 152,5,23" & return & \
               "keyword command none 152,5,23" & return & \
               "keyword private none 152,5,23" & return & \
               "keyword end none 152,5,23" & return & \
               "keyword if none 152,5,23" & return & \
               "keyword then none 152,5,23" & return & \
               "keyword else none 152,5,23" & return & \
               "keyword function none 0,0,255" & return & \
               "keyword setprop none 152,5,23" & return & \
               "keyword getprop none 152,5,23" & return & \
               "keyword repeat none 152,5,23" & return & \
               "keyword switch none 152,5,23" & return & \
               "keyword try none 152,5,23" & return & \
               "keyword catch none 152,5,23" & return & \
               "keyword case none 152,5,23" & return & \
               "keyword default none 152,5,23" & return & \
               "keyword finally none 152,5,23" into pPreferencesArray["colorization,config"]
         break
         
      case "no colorization"
         put "group commands none 0,0,0" & return & \
               "group properties none 0,0,0" & return & \
               "group functions none 0,0,0" & return & \
               "class error none 0,0,0" & return & \
               "class singlecomment none 0,0,0" & return & \
               "class multicomment none 0,0,0" & return & \
               "class identifier none 0,0,0" & return & \
               "class literal none 0,0,0" & return & \
               "class number none 0,0,0" & return & \
               "class keyword none 0,0,0" & return & \
               "class operator none 0,0,0" & return & \
               "keyword on none 0,0,0" & return & \
               "keyword end none 0,0,0" & return & \
               "keyword if none 0,0,0" & return & \
               "keyword then none 0,0,0" & return & \
               "keyword else none 0,0,0" & return & \
               "keyword function none 0,0,0" & return & \
               "keyword setprop none 0,0,0" & return & \
               "keyword getprop none 0,0,0" & return & \
               "keyword repeat none 0,0,0" & return & \
               "keyword switch none 0,0,0" & return & \
               "keyword try none 0,0,0" & return & \
               "keyword catch none 0,0,0" & return & \
               "keyword case none 0,0,0" & return & \
               "keyword default none 0,0,0" & return & \
               "keyword finally none 0,0,0" into pPreferencesArray["colorization,config"]
         break
   end switch
end seColorizationLoadScheme

# Parameters
#   pSettingsString : a string describing the colorization settings, format outlined below.
# Returns
#   Two arrays are placed into the rClasses and rKeywords parameters, these are in the 
#   format required by the _internal script configure classes command and the _internal script configure keywords command.
# Description
#   The settings string is a list of settings, one per line. Each setting has the following format.
#   <type> <name> <attributes> <color>
#   
#   type - either "group", "class" or "keyword"
#   name - the name of the group, class or keyword
#   attributes - a list of text styles, eg bold,italic,none etc (I think)
#   color - in RGB format, comma delimited.
private command colorizationBuildSettings pSettingsString, @rClasses, @rKeywords
  local tClasses, tKeywords
  repeat for each line tLine in pSettingsString
    if word 1 of tLine is "class" then
      put word 3 of tLine into tClasses[word 2 of tLine && "attributes"]
      put word 4 of tLine into tClasses[word 2 of tLine && "color"]
    else if word 1 of tLine is "keyword" then
      put word 3 of tLine into tKeywords[word 2 of tLine && "attributes"]
      put word 4 of tLine into tKeywords[word 2 of tLine && "color"]
    else if word 1 of tLine is "group" then
      switch word 2 of tLine
      case "commands"
        get the commandNames
        break
      case "properties"
        get the propertyNames
        break
      case "functions"
        get the functionNames
        break
      case "structures"
        get "if then else repeat for with while on command private function end switch case getprop setprop try catch the of to after before into"
        replace space with return in it
        break
      case "chunks"
        get "line char character word token item file folder card stack button field scrollbar image player audioclip videoclip group graphic number string date boolean integer color rect rectangle"
        replace space with return in it
        break
      case "operators"
        get "and or not bitNot bitOr bitXor bitAnd there is a contains among in div mod no within"
        replace space with return in it
      end switch
      repeat for each line tKeyword in it
        put word 3 of tLine into tKeywords[tKeyword && "attributes"]
        put word 4 of tLine into tKeywords[tKeyword && "color"]
      end repeat
    end if
  end repeat
  
  put tClasses into rClasses
  put tKeywords into rKeywords
end colorizationBuildSettings


# Returns
#   an array of the current colorization class settings
function seColorizationConfigClasses
  return sColorizationClasses
end seColorizationConfigClasses

# Returns
#   an array of the current colorization keyword settings
function seColorizationConfigKeywords
  return sColorizationKeywords
end seColorizationConfigKeywords

# Parameters
#   pObject : either a valid reference to an object, or a long id of an object.
# Returns
#   The "rugged id" of the object used by the script editor to refer to it. Currently the rugged id
#   is a valid object reference in a slightly different form to the long id, however it may be changed 
#   at some point to be a handle of some sort. To access an object from its rugged id, use the 
#   revAccessObject function in revBackscript.
function seGetRuggedId pObject
   return revRuggedId(pObject)
end seGetRuggedId


# Parameters
#   pObject : a valid object reference or long id
#  Returns
#   Whether or not the specified object is a container, i.e can contain other objects
#   Containers are stacks, cards and groups.
function seObjectIsContainer pObject
--   local tObject
--   put revRuggedId(pObject) into tObject
   
   switch word 1 of pObject
      case "stack"
         return true
      break
      case "card"
         return true
      break
      case "group"
         return true
      break
      default
         return false
   end switch
end seObjectIsContainer

# Parameters
#   pContainingObject : an object long id
#   pContainedObject : an object long id
# Returns
#   Whether or not pContainingObject contains pContainedObject.
function seObjectContainsObject pContainingObject, pContainedObject
   if not seObjectIsContainer(pContainingObject) then
      return false
   end if
   
   # We rely on the two parameters being valid long ids to avoid having to refer to the object
   # as this could be broken by edit group mode.
   if pContainedObject ends with pContainingObject and pContainingObject is not pContainedObject then
      return true
   else
      return false
   end if
end seObjectContainsObject

# Parameters
#   pContainingObject : an object rugged id
#   pContainedObject : an object rugged id
# Returns
#   Whether or not pContainingObject contains pContainedObject.
function seRuggedObjectContainsObject pContainingObject, pContainedObject
   if not seObjectIsContainer(pContainingObject) then
      return false
   end if
   
   # We rely on the two parameters being valid long ids to avoid having to refer to the object
   # as this could be broken by edit group mode.
   if pContainedObject ends with pContainingObject and pContainingObject is not pContainedObject then
      return true
   else
      return false
   end if
end seRuggedObjectContainsObject

local sFindHistory
local sReplaceHistory
constant kHistorySize = 20

# Parameters
#   pType : either "find" or "replace"
# Returns
#   The history of the specified action type, one per line with most recent coming first.
function seFindHistoryGet pType
   historyClean
   
   if pType is "find" then
      return sFindHistory
   else if pType is "replace" then
      return sReplaceHistory
   end if
end seFindHistoryGet

# Parameters
#   pType : either "find" or "replace"
#   pTerm: the find / replace term to add
# Description
#   Adds the specified term to the history.
command seFindHistoryAdd pType, pTerm
   if pType is "find" then
      if sFindHistory is empty then
         put pTerm into sFindHistory
      else
         put pTerm & return before sFindHistory
      end if
   else if pType is "replace" then
      if sReplaceHistory is empty then
         put pTerm into sReplaceHistory
      else
         put pTerm & return before sReplaceHistory
      end if
   end if
end seFindHistoryAdd

# Description
#   Cleans up any unwanted stuff from the history. For now this just stops the
#   history growing too big and removes duplicates.
private command historyClean
   local tCleanedHistory
   
   repeat for each line tTerm in sFindHistory
      if tTerm is not among the lines of tCleanedHistory then
         put tTerm & return after tCleanedHistory
      end if
   end repeat
   delete the last char of tCleanedHistory
   put line 1 to kHistorySize of tCleanedHistory into sFindHistory
   
   put empty into tCleanedHistory
   repeat for each line tTerm in sReplaceHistory
      if tTerm is not among the lines of tCleanedHistory then
         put tTerm & return after tCleanedHistory
      end if
   end repeat
   delete the last char of tCleanedHistory
   put line 1 to kHistorySize of tCleanedHistory into sReplaceHistory
end historyClean

# Description
#   Loads the history from the preferences
command seFindHistoryLoad
   put sePrefGet("find,findhistory") into sFindHistory
   put sePrefGet("find,replacehistory") into sReplaceHistory
end seFindHistoryLoad

# Description
#   Saves the history to the preferences
command seFindHistorySave
   historyClean
   sePrefSet "find,findhistory", sFindHistory
   sePrefSet "find,replacehistory", sReplaceHistory
end seFindHistorySave

command revSEFormat pScript
   local tFormattedScript
   send "revSEFormatSnippet pScript" to stack "revSETemplate"
   put the result into tFormattedScript
   return tFormattedScript
end revSEFormat

command revSEColorizeField pField, pStart, pEnd
   if pStart is empty then
      put 1 into pStart
   end if
   
   if pEnd is empty then
      put the number of chars in the text of pField into pEnd
   end if
   
   sePrefInit
   local tConfig
   put sePrefGet("colorization,config") into tConfig
   
   _internal script configure classes sColorizationClasses
   _internal script configure keywords sColorizationKeywords
   
   _internal script colorize char pStart to pEnd of pField
end revSEColorizeField
   
   # Colorizes pScript and returns it as revHTML
command revSEColorize pScript, pScheme
   local tOldScheme, tConfig
   if pScheme is not sePrefGet("colorization,scheme") then
      put sePrefGet("colorization,scheme") into tOldScheme
      seColorizationLoadScheme pScheme, tConfig
      put tConfig["colorization,config"] into tConfig
   else
      put sePrefGet("colorization,config") into tConfig
   end if
   
   local tClasses, tKeywords
   colorizationBuildSettings tConfig, tClasses, tKeywords
   
   _internal script configure classes tClasses
   _internal script configure keywords tKeywords
   
   local tFormattedScript
   send "revSEFormatSnippet pScript" to stack "revSETemplate"
   put the result into tFormattedScript
   
   local tField
   put the long id of field "revColourizationObject" of card 2 of stack "revSETemplate" into tField
   set the text of tField to tFormattedScript
   _internal script colorize char 1 to (the number of chars of the text of tField) of tField
   
   local tHtmlText
   put the htmlText of tField into tHtmlText
   set the text of tField to empty
   return tHtmlText
end revSEColorize

# Returns
#   A string containg the same number of spaces as (1 * the current tab depth)
#   Used by the seDefaultScript and seDefaultScriptSelection handlers as a convenience.
private function getFirstIndentLevel
  local tTabDepth
  put sePrefGet("editor,tabdepth") into tTabDepth
  
  local tIndent
  repeat tTabDepth times
    put space after tIndent
  end repeat
  
  return tIndent
end getFirstIndentLevel

# Parameters
#   pObjectType : a Revolution object type, e.g. stack, card, button etc.
#   pStyle : the object's style property
# Returns
#   The default script that the script editor should use for objects of the specified
#   type if they have no script set. Returns empty if no default script is to be used.
function seDefaultScript pObjectType, pStyle
  # AL-2015-09-21: [[ Bug 15961 ]] Add default mouseup handler to opaque button
   local tIndent
   put getFirstIndentLevel() into tIndent
   switch pObjectType
    case "button"
         if pStyle is among the items of "standard,rectangle,checkbox,radiobutton,transparent,opaque" then
            return "on mouseUp" & return & tIndent & return & "end mouseUp"
         else if pStyle is "menu" then
            return "on menuPick pItemName" & return & tIndent & "switch pItemName" & return & tIndent & tIndent & return & tIndent & "end switch" & return & "end menuPick"
         end if
         break
       case "scrollbar"
         if pStyle is among the items of "scale,scrollbar" then
            return "local sStartValue" & return & return & "on mouseDown --save the initial value" & return &\
            tIndent & "put the thumbPos of me into sStartValue" & return & "end mouseDown" & return & return &\
            "on scrollbarDrag newValue -- save the final value" & return & tIndent & return & "end scrollbarDrag" 
          end if
          break
      case "widget"
         return revIDEWidgetDefaultScript(pStyle)
         break
      default
         return empty
   end switch
end seDefaultScript

# Parameters
#   pObjectType : a Revolution object type, e.g. stack, card, button etc.
#   pStyle : the object's style property
# Returns
#   The char range (<first>,<last>) that should be selected in the default
#   script for the specified object. Returns empty if either no default script is to be
#   used or there is no default selection is required.
function seDefaultScriptSelection pObjectType, pStyle
  local tStart, tEnd
  switch pObjectType
  case "button"
    if pStyle is "menu" then
      put the number of chars of "on menuPick pItemName" + 1 + the number of chars of "switch pItemName" + 1 + (3 * the number of chars of getFirstIndentLevel()) into tStart
      put tStart - 1 into tEnd
    else if pStyle is among the words of "standard rectangle checkbox radiobutton" then
      put the number of chars of "on mouseUp" + 1 + the number of chars of getFirstIndentLevel() + 1 into tStart
      put tStart - 1 into tEnd
    end if
    break
  default
    return empty
  end switch
  
  return tStart & comma & tEnd
end seDefaultScriptSelection
