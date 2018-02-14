script "revSEMenubarBehavior"
# Description
#   Sent by the parent when the menubar group may need to resize itself
command resize
   lock screen
   local tTopLeft
   put the topLeft of button "File" of me into tTopLeft
   repeat for each item tButton in "File,Edit,Debug,Handler,Window,Help"
      set the width of button tButton of me to the formattedWidth of button tButton of me
      set the topLeft of button tButton of me to tTopLeft
      put the topRight of button tButton of me into tTopLeft
   end repeat
   unlock screen
end resize

# Description
#  Sent by the parent when the menubar group may need to update itself
command update
   # The menubar is affected by keyboard shortcuts. If the preferences change,
   # this message should be sent as the menubar needs to update its keyboard shortcut
   # handling.
   try
      buildMenus
   catch tError
      --log tError
   end try
end update

local sKeyboardShortcut

 # OK-2009-01-17 : Bug 7597 - Ensure that mouseDown gets passed if it was a keyboard shortcut
on mouseDown pButtonNumber
   if pButtonNumber is empty then
      put true into sKeyboardShortcut
      pass mouseDown
   else
      put false into sKeyboardShortcut
      update
   end if
end mouseDown

# Returns
#   An array that contains the context that the menubar should be built with,
#   this contains information about the state of everything that might affect
#   the menubar, e.g. what text is selected, what the current keyboard shortcuts
#   are etc.
private function buildMenusGetContext
  local tContext
  
  # Is there any text selected?
  local tTextSelected
  put false into tTextSelected
  get the selectedChunk
  
  # OK-2009-01-17 : Bug 7597 - Text is considered selected if there is any selectedChunk, it doesn't depend on which control may contain it.
  if (word 2 of it < word 4 of it) then
    put true into tTextSelected
  end if
  put tTextSelected into tContext["textSelected"]
  
  # Is there any pastable data on the clipboard?
  local tClipboardText
  put false into tClipboardText
  if the clipboardData["text"] is not empty or the clipboardData["htmltext"] is not empty then
    put true into tClipboardText
  end if
  put tClipboardText into tContext["clipboardText"]
   
  # What mode is the script editor in?
  local tMode
  revSEGetMode
  put the result into tMode
  put tMode into tContext["mode"]
   
  return tContext
end buildMenusGetContext

private command buildMenus
   local tContext
   put buildMenusGetContext() into tContext
   
   lock menus
   buildFileMenu tContext
   buildEditMenu tContext
   buildDebugMenu tContext
   buildWindowMenu tContext
   buildHelpMenu tContext
   buildHandlerMenu tContext
   unlock menus
end buildMenus

private command buildFileMenu pContext
   local tFile
   put "Apply/^Return|Compile" & return & \
   "-" & return & \
   "Save/S" & return & \
   "Close/W" & return & \
   "Print/P"  & return & \
   "-"  & return & \
   "Quit" & return into tFile
   
   set the text of button "File" of me to modifyMenu("File", tFile)
end buildFileMenu

private command buildEditMenu pContext
   local tEdit
   if seUndoAvailable() then
      put "Undo/Z" & return into tEdit
   else
      put "(Undo/Z" & return into tEdit
   end if
   
   if seRedoAvailable() then
      put "Redo/^@Z" & return after tEdit
   else
      put "(Redo/^@Z" & return after tEdit
   end if
   
   if pContext["textSelected"] then
      put "Cut/X" & return & \
             "Copy/C" & return after tEdit
   else
      put "(Cut/X" & return & \
             "(Copy/C" & return after tEdit
   end if
   
   put "Paste/V" & return & \
         "Select All/A" & return & \
         "Revert" & return & \
         "-" & return & \
         "Comment/-" & return & \
         "Uncomment/_" & return & \
         "-" & return & \
         "Quick Find/F" & return & \
         "Find and Replace.../^@F" & return & \
         "Find Selection/^#F" & return & \
         "Go.../L" & return after tEdit
   
   if revEnvironmentEditionProperty("autocomplete_pro") then
      put "Autocomplete Snippets..." & return after tEdit
   end if
   
   put "Options" & return after tEdit
   put toggleMenuItem(tab & "Variable Checking", sePrefGet("explicitVariables")) & return after tEdit
   put toggleMenuItem(tab & "Live Errors", sePrefGet("editor,liveerrors")) & return after tEdit
   put toggleMenuItem(tab & "Bracket Completion", sePrefGet("editor,bracketcompletion")) & return after tEdit
   put toggleMenuItem(tab & "Bracket Highlighting", sePrefGet("editor,brackethighlighting")) & return after tEdit
   put toggleMenuItem(tab & "Control Structure Completion", sePrefGet("editor,autocomplete")) & return after tEdit
   
   if revEnvironmentEditionProperty("autocomplete") then
      put toggleMenuItem(tab & "Autocomplete", sePrefGet("editor,providercompletion")) & return after tEdit
   end if
   put toggleMenuItem(tab & "Autoformat", sePrefGet("editor,autoformat")) & return after tEdit
   
   put "-" & return & \
          "Preferences" after tEdit
   
   set the text of button "Edit" of me to modifyMenu("Edit", tEdit)
end buildEditMenu

private command buildDebugMenu pContext
   # Some of the debugger shortcuts are currently platform specific, for now
   # we just deal with that here.
   local tStepIntoShortcut, tStepOverShortcut, tStepOutShortcut, tStopShortcut, tRunShortcut, tBreakpointShortcut
   if seGetPlatform() is "Macos" then
      put "/I" into tStepIntoShortcut
      put "/O" into tStepOverShortcut
      put "/T" into tStepOutShortcut
      put "/Y" into tStopShortcut
      put "/^@>" into tRunShortcut
      put "/\" into tBreakpointShortcut
   else
      put "/F11" into tStepIntoShortcut
      put "/F10" into tStepOverShortcut
      put "/@F11" into tStepOutShortcut
      put "/@F5" into tStopShortcut
      put "/F5" into tRunShortcut
      put "/F9" into tBreakpointShortcut
   end if
   
   local tDebug
   if pContext["mode"] is "debug" then
      put "Show next" & return & \
             "-"  & return & \
             "Step Into" & tStepIntoShortcut & return & \
             "Step Over" & tStepOverShortcut & return & \
             "Step Out" & tStepOutShortcut & return & \
             "Stop" & tStopShortcut & return & \
             "Run" & tRunShortcut & return & \
             "-" & return & \
             "Toggle Breakpoint" & tBreakpointShortcut & return & \
             "Clear all breakpoints" & return & \
             "-" & return & \
             "Variables" & return & \
             "Breakpoints" & return & \
             "Entry Point..." & return & \
             "-" & return into tDebug
   else
      put "(Show next" & return & \
             "-"  & return & \
             "(Step into" & tStepIntoShortcut & return & \
             "(Step over" & tStepOverShortcut & return & \
             "(Step out" & tStepOutShortcut & return & \
             "(Stop" & tStopShortcut & return & \
             "(Run" & tRunShortcut & return & \
             "-" & return & \
             "Toggle Breakpoint" & tBreakpointShortcut & return & \
             "Clear all Breakpoints" & return & \
             "Add Variable Watch" & return & \
             "-" & return & \
             "Variables" & return & \
             "Breakpoints" & return & \
             "Entry Point..." & return & \
             "-" & return into tDebug
   end if
   
   if revDebuggerEnabled() then
      put "!cScript Debug Mode" after tDebug
   else
      put "!nScript Debug Mode" after tDebug
   end if
   
   set the text of button "Debug" of me to modifyMenu("Debug", tDebug)
end buildDebugMenu

# OK-2010-02-19: Bug 8157 - Escape special characters from stack names in menus, more may 
# need to be added here.
private function revMenubarEscapeStackNameForMenu pName
   replace "!" with "\!" in pName
   if the platform is "MacOS" then 
      replace "/" with "\/" in pName
      replace "(" with "\(" in pName
   else
      replace "/" with "//" in pName
   end if
   return pName
end revMenubarEscapeStackNameForMenu

private command buildWindowMenu pContext
   #   Set sWindowMenuText to a list of open Windows in suitable format for putting into a menu button.
   #   This will be any script editors or the dictionary or resource center if they are open, and any user stacks.
   revIDEUpdateWindowList
   
   local tWindows
   put revIDEWindowList() into tWindows
   
   // PM-2016-05-14: [[ Bug 18166 ]] Show users stacks by name
   local tMenu, tMenuLine, tStackName
   repeat for each line tStack in tWindows
      put the short name of tStack into tStackName
      // in case we have an instance of of the script editor, the Dictionary or the Resource Center, show their title
      if revIDEStackNameIsIDEStack(tStackName) then
         put the title of tStack into tStackName
      end if
      
      put "!n" & revMenubarEscapeStackNameForMenu(tStackName) & "/|" & tStack into tMenuLine
      if tMenu is empty then
         put tMenuLine into tMenu
      else
         put return & tMenuLine after tMenu
      end if
   end repeat
   
   if tMenu is empty then
      put "(No Windows Open" into tMenu
   else
      # Put a checkmark against the 'topmost' stack
      put "!c" into char 1 to 2 of line 1 of tMenu
      put return & "-" & return & "Send Window to Back/`" after tMenu
   end if
   
   set the text of button "Window" of me to modifyMenu("Window", tMenu)
end buildWindowMenu

private command buildHelpMenu pContext
   local tText
   put "Documentation Pane" & return & \
          "-" & return & \
          "Dictionary"  & return & \
          "Resource Center" & return & \
          "-" & return & \
          "Start Center" & return & \
          "User Guide" & return & \
          "About LiveCode" into tText
   
   set the text of button "Help" of me to modifyMenu("Help", tText)
end buildHelpMenu

private command buildHandlerMenu pContext
   local tHandlers
   revSEGetHandlerList
   put the result into tHandlers
   
   local tFormattedHandlers
   repeat for each line tHandler in tHandlers
      put tab & word 2 of tHandler & return after tFormattedHandlers
   end repeat
   delete the last char of tFormattedHandlers
   
   local tDefaultHandlers
   put revSEDefaultHandlers() into tDefaultHandlers
   
   local tFormattedDefaultHandlers
   repeat for each line tHandler in tDefaultHandlers
      put tab & tHandler & return after tFormattedDefaultHandlers
   end repeat
   delete the last char of tFormattedDefaultHandlers
   
   local tShowDefaultHandlers
   dispatch function "sePrefGet" to me with "editor,showDefaultHandlers"
   put the result into tShowDefaultHandlers
   
   local tMenu
   if tHandlers is not empty then
      put enableMenuItem("Go to handler...", true) into tMenu
      put return & tFormattedHandlers after tMenu
   else
      put enableMenuItem("Go to handler...", false) into tMenu
   end if
   if tDefaultHandlers is not empty then
      put return & enableMenuItem("Add default handler...", true) after tMenu
      put return & tFormattedDefaultHandlers after tMenu
   else
      put return & enableMenuItem("Add default handler...", false) after tMenu
   end if
   put return & toggleMenuItem("Show default handlers", tShowDefaultHandlers) after tMenu
   
   set the cHandlers of me to tHandlers
   
   set the text of button "Handler" of me to modifyMenu("Handler", tMenu)
end buildHandlerMenu

on menuPick pItemName
   if sKeyboardShortcut then
      pass menuPick
   end if
   
   switch the short name of the target
      case "File"
         handleFileMenuPick pItemName
      break
      case "Edit"
         handleEditMenuPick pItemName
      break
      case "Debug"
         handleDebugMenuPick pItemName
      break
      case "Window"
         handleWindowMenuPick pItemName
      break
      case "Help"
         handleHelpMenuPick pItemName
      break
      case "Handler"
         handleHandlerMenuPick pItemName
      break
   end switch
end menuPick

private command handleHandlerMenuPick pItemName
   if dispatchMenuPick("Handler", pItemName) then
      exit handleHandlerMenuPick
   end if
   
   set the itemdelimiter to "|"
   switch item 1 of pItemName
      case "Go to handler..."
         local tPick, tHandlerInfo
         put item 2 of pItemName into tPick
         if not matchText(the cHandlers of me, "(.* " & tPick & " .*)", \
               tHandlerInfo) then
            exit handleHandlerMenuPick
         end if

         dispatch "handlerPicked" to group "Left Handler List" \
               with tHandlerInfo
         break
      case "Add default handler..."
         dispatch "handlerPicked" to group "Left Handler List" \
               with item 2 of pItemName
         break
      case "Show default handlers"
         local tShowDefaultHandlers
         dispatch function "sePrefGet" to me with "editor,showDefaultHandlers"
         put the result into tShowDefaultHandlers
         dispatch "sePrefSet" to me with "editor,showDefaultHandlers", not tShowDefaultHandlers
         break
   end switch
   
   seUpdateLeftBar
   seUpdateToolbar
end handleHandlerMenuPick

private command handleFileMenuPick pItemName
   if dispatchMenuPick("File", pItemName) then
      exit handleFileMenuPick
   end if
   
   switch pItemName
      case "Compile"
         actionCompile
      break
      case "Save"
         actionSave
      break
      case "Print"
         actionPrint
      break
      case "Close"
         actionClose
      break
      case "Quit"
         actionQuit
      break
   end switch
end handleFileMenuPick

private command handleEditMenuPick pItemName
   if dispatchMenuPick("Edit", pItemName) then
      exit handleEditMenuPick
   end if
   
   switch pItemName
      case "Undo"
         actionUndo
         break
      case "Redo"
         actionRedo
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
      case "Select all"
         actionSelectAll
         break
      case "Comment"
         actionComment
         break
      case "Uncomment"
         actionUncomment
         break
      case "Quick Find"
         actionInteractiveFind
         break
      case "Find and replace..."
         actionFindDialog
         break
      case "Find Selection"
         actionFindSelection
         break
      case "Go..."
         actionGoDialog
         break
      case "Revert"
         actionRevert
         break
      case "Options|Variable Checking"
         sePrefSet "explicitVariables", (not sePrefGet("explicitVariables"))
         break
      case "Options|Live Errors"
         sePrefSet "editor,liveerrors", (not sePrefGet("editor,liveerrors"))
         break
      case "Options|Bracket Completion"
         sePrefSet "editor,bracketcompletion", (not sePrefGet("editor,bracketcompletion"))
         break
      case "Options|Bracket Highlighting"
         sePrefSet "editor,brackethighlighting", (not sePrefGet("editor,brackethighlighting"))
         break
      case "Options|Control Structure Completion"
         sePrefSet "editor,autocomplete", (not sePrefGet("editor,autocomplete"))
         break
      case "Options|Autocomplete"
         sePrefSet "editor,providercompletion", (not sePrefGet("editor,providercompletion"))
         break
      case "Options|Autoformat"
         sePrefSet "editor,autoformat", (not sePrefGet("editor,autoformat"))
         break
      case "Preferences"
         actionShowPreferences
         break
      case "Autocomplete Snippets..."
         actionAutocompleteSnippetManager
         break
   end switch
end handleEditMenuPick

private command handleDebugMenuPick pItemName
   if dispatchMenuPick("Debug", pItemName) then
      exit handleDebugMenuPick
   end if
   
   switch pItemName
      case "Show next"
         actionDebugShowNext
         break
      case "Step into"
         actionDebugStepInto
         break
      case "Step over"
         actionDebugStepOver
         break
      case "Step out"
         actionDebugStepOut
         break
      case "Stop"
         actionDebugStop
         break
      case "Run"
         actionDebugRun
         break
      case "Clear all Breakpoints"
         answer warning "Really clear all breakpoints from all open stacks?  This operation cannot be undone." with "Don't Clear" or "Clear"
         if it is "Clear" then 
            revDebuggerClearAllBreakpoints
            revSEUpdate false
         end if
         break
      case "Variables"
         sePaneShow "Variables"
         break
      case "Breakpoints"
         sePaneShow "Breakpoints"
         break
      case "Entry Point..."
         actionEditDebugEntry
         break
      case "Script Debug Mode"
         if revDebuggerEnabled() then
            revDebuggerDisable
         else
            revDebuggerEnable
         end if
         break
      case "Toggle Breakpoint"
         actionToggleBreakpoint
         break
      case "Add Variable Watch"
         seNewBreakpointDialog "watch"
         revSEUpdate
         break
   end switch
end handleDebugMenuPick

private command handleWindowMenuPick pItemName
   if dispatchMenuPick("Window", pItemName) then
      exit handleWindowMenuPick
   end if
   
   if pItemName is "Send Window to back" then
      actionSendWindowToBack
      exit handleWindowMenuPick
   end if
   
   if exists(pItemName) then
      lock screen
      go pItemName
      show pItemName
      unlock screen
   end if
end handleWindowMenuPick
     
private command handleHelpMenuPick pItemName
   if dispatchMenuPick("Help", pItemName) then
      exit handleHelpMenuPick
   end if
   
   switch pItemName
      case "Documentation Pane"
         sePaneShow "Documentation"
         break
      case "Dictionary"
      case "Resource Center"
      case "Start Center"
         revIDEOpenPalette pItemName
         break
      case "User Guide"
         revIDELaunchResource pItemName
         break
      case "About LiveCode"
         revIDEOpenPalette "About"
         break
   end switch
end handleHelpMenuPick

#########

private function toggleMenuItem pItem, pHilited
   if pHilited then
      return "!c" & pItem
   end if
   return "!n" & pItem
end toggleMenuItem

private function enableMenuItem pItem, pEnabled
   if pEnabled then
      return pItem
   end if
   return "(" & pItem
end enableMenuItem

private function modifyMenu pMenuName, pMenu
   if the last char of pMenu is not return then
      put return after pMenu
   end if
   
   local tModifiedMenu
   dispatch "revHookBuildScriptEditorMenu" to me with pMenuName, pMenu, tModifiedMenu
   if it is not "handled" then
      put pMenu into tModifiedMenu
   end if
   return tModifiedMenu
end modifyMenu

private function dispatchMenuPick pMenuName, pWhich
   dispatch "revHookScriptEditorMenuPick" to me with pMenuName, pWhich
   return it is "handled"
end dispatchMenuPick
