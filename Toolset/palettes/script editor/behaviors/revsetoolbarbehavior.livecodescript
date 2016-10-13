script "revSEToolbarBehavior"
constant kObjectSpacing = 1
constant kDividerSpacing = 3
constant kLeftSpacing = 9
constant kRightSpacing = 5

# NOTE: To remove a object from the toolbar, remove the object's entry from the toolbarObjects() function
# and its alignment from the toolbarAlignments() function then delete the control. To add an object just 
# do the reverse.

# Returns
#   A comma delimited list of the objects that should be managed by the toolbar
#   Any objects in the group but not in this list will not be updated or resized in any way.
#   The list is ordered with the first object being the left-most in the toolbar and the last
#   being the right-most. Note: each toolbar object MUST have a unique name, regardless of its type.
private function toolbarObjects
  return "Compile,Undo,Redo,Run,Stop,Show Next,Step Into,Step Over,Step Out,Debug Context,Handlers"
end toolbarObjects

# Returns
#   A comma delimited list of aligments for the toolbar objects. Each alignment can be either "left" or "right"
# Description
#   "left" means the object is placed to the right of the previously left aligned object.
#   "right" means the object is placed to the left of the previously right aligned object.
private function toolbarObjectAlignments
  return "left,left,left,left,left,left,left,left,left,left,left"
end toolbarObjectAlignments

private function toolbarObjectVisibility
   local tMode
   revSEGetMode
   put the result into tMode
   if tMode is "edit" then
      # In edit mode, the compile, undo and redo buttons and the handler list are shown. Also the run button is shown
      # as this can be used to start up debugging as well as continue it.
      return "true,true,true,true,false,false,false,false,false,false,true"
   else
      # In debug mode, the editing controls are disabled as there is no way they can be used, even if the user opens another script.
      # The handler list is still enabled, as are all the debug controls.
      return "false,false,false,true,true,true,true,true,true,true,true"
   end if
end toolbarObjectVisibility

# These are the limiting dimensions for the handler list drop-down menu button
constant kHandlerListMaxWidth = 320
constant kHandlerListMinWidth = 25

# This holds the minimum width for the actual handler list object. (Its allowed to be smaller than
# the button which drops it down).
constant kHandlerListObjectMinWidth = 150

# Description
#   Sent by the parent when the size of the toolbar changes. Resizes / moves all toolbar controls
#   to reflect the new size of the toolbar.
command resize
   lock screen
   # On Windows Vista, the script editor's menubar will be themed, and this theme will include a divider at the bottom,
   # so to prevent ugliness, we hide the divider graphic in this case.
   if seGetPlatform() is "Win32" and char 1 of word 2 of seGetSystemVersion() is "6" then
      set the right of graphic "Divider" of me to the left of me - 500
   else
      set the width of graphic "Divider" of me to the width of me
      set the topLeft of graphic "Divider" of me to the topLeft of me
   end if
   
   local tLeft, tTop, tRight
   put the left of me + kLeftSpacing into tLeft
   put the top of me + kDividerSpacing into tTop
   put the right of me + kRightSpacing into tRight
   
   local tObjectNumber
   put 1 into tObjectNumber
   repeat for each item tObjectName in toolbarObjects()
      if not item tObjectNumber of toolbarObjectVisibility() then
         set the right of control tObjectName of me to the left of me - 500
      else if item tObjectNumber of toolbarObjectAlignments() is "left" then
         set the topLeft of control tObjectName of me to tLeft, tTop
         add the width of control tObjectName of me + kObjectSpacing to tLeft
      else if item tObjectNumber of toolbarObjectAlignments() is "right" then
         set the topRight of control tObjectName of me to tRight, tTop
         subtract the width of control tObjectName of me from tRight
      else
         error "invalid object aligment for item: " & tObjectName & "(" & item tObjectNumber of toolbarObjectAligments() & ")"
      end if
      
      add 1 to tObjectNumber
   end repeat
   
   
   # Allow the handler list to grow and shrink according to the window size within certain limits.
   # If the button is overlapping the right edge and its width is bigger than the minimum then shrink it down
   # until either it fits, or the minimum width is reached.
   local tHandlerListLeft
   put the left of button "Handlers" of me into tHandlerListLeft
   
   local tRequiredWidth
   put the right of me - the left of button "Handlers" of me into tRequiredWidth
   
   if the right of button "Handlers" of me > the right of me and the width of button "Handlers" of me > kHandlerListMinWidth then
      set the width of button "Handlers" of me to max(kHandlerListMinWidth, tRequiredWidth)
      set the width of button "Fake Handler Menu" of me to max(kHandlerListMinWidth, tRequiredWidth)
   end if
   
   if the right of button "Handlers" of me < the right of me and the width of button "Handlers" of me < kHandlerListMaxWidth then
      set the width of button "Handlers" of me to min(kHandlerListMaxWidth, tRequiredWidth)
      set the width of button "Fake Handler Menu" of me to min(kHandlerListMaxWidth, tRequiredWidth)
   end if
   
   set the top of button "Fake Handler Menu" of me to the top of button "Handlers" of me
   set the left of button "Handlers" of me to tHandlerListLeft
   set the left of button "Fake Handler Menu" of me to tHandlerListLeft
   unlock screen
end resize

# Parameters
#   pDontRecalculateSelectedHandler : if true then the selected handler is assumed to be up to date
# Description
#   Sent by the parent whenever something might have changed which could use the toolbar to need updating.
command update pDontRecalculateSelectedHandler
   local tMode
   revSEGetMode
   put the result into tMode
   
   if tMode is "debug" then
      debugControlsEnable
   else
      debugControlsDisable
   end if
   
   debugControlsUpdate tMode
   
   # Update the compile button
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   if tObject is empty then
      disable button "Compile" of me
   else
      local tObjectState
      put seGetObjectState(tObject) into tObjectState
      if tObjectState is "edited" then
         enable button "Compile" of me
      else if tObjectState is "applied" then
         disable button "Compile" of me
      else if tObjectState is "error" then
         enable button "Compile" of me
      end if
   end if
   
   # Update the undo and redo buttons
   if tObject is empty then
      disable button "Undo" of me
      disable button "Redo" of me
   else
      if seUndoAvailable() then
         enable button "Undo" of me
      else
         disable button "Undo" of me
      end if
      
      if seRedoAvailable() then
         enable button "Redo" of me
      else
         disable button "Redo" of me
      end if
   end if
   
   # Update the handler list
  updateSelectedHandler pDontRecalculateSelectedHandler
   
   resize
   updateTooltips
end update

command updateSelectedHandler pDontRecalculate
   lock screen
   local tHandler
   revSEGetSelectedHandler pDontRecalculate
   put the result into tHandler
   if tHandler is not empty then
      set the label of button "Fake Handler Menu" of me to "TempLabel"
      set the label of button "Fake Handler Menu" of me to tHandler
      set the toolTip of button "Handlers" of me to tHandler
   else
      set the toolTip of button "Handlers" of me to "Handler List"
      set the label of button "Fake Handler Menu" of me to "Handler list"
   end if
   unlock screen
end updateSelectedHandler

private function shortcutDescription pAction
   local tShortcut
   put seFriendlyShortcut(pAction) into tShortcut
   if tShortcut is empty then
      return empty
   else
      return " (" & seFriendlyShortcut(pAction) & ")"
   end if
end shortcutDescription

# Description
#   Sets the tooltips on all menubar controls. This needs to be done dynamically because the tooltips are platform specific
private command updateTooltips
   set the toolTip of button "Compile" of me to "Compile and apply the current script" & shortcutDescription("ApplyAndClose")
   set the toolTip of button "Undo" of me to "Undo last change" & shortcutDescription("Undo")
   set the toolTip of button "Redo" of me to "Redo last undone change" & shortcutDescription("Redo")
   set the toolTip of button "Run" of me to "Continue" & shortcutDescription("DebugRun")
   set the toolTip of button "Show Next" of me to "Show next statement" & shortcutDescription("DebugShowNext")
   set the toolTip of button "Step Into" of me to "Step into next statement"  & shortcutDescription("DebugStepInto")
   set the toolTip of button "Step Over" of me to "Step over next statement" & shortcutDescription("DebugStepOver")
   set the toolTip of button "Step Out" of me to "Step out of current handler" & shortcutDescription("DebugStepOut")
   set the toolTip of button "Stop" of me to "Stop debugging" & shortcutDescription("DebugStop")
end updateTooltips

# Description
#   Disables the debug controls
private command debugControlsDisable
  repeat for each item tObjectName in toolbarObjects()
    if the cDebugControl of control tObjectName of me then
      disable control tObjectName of me
    end if
  end repeat
end debugControlsDisable

# Description
#   Enables the debug controls
private command debugControlsEnable
  repeat for each item tObjectName in toolbarObjects()
    if the cDebugControl of control tObjectName of me then
      enable control tObjectName of me
    end if
  end repeat
end debugControlsEnable

# Parameters
#   pMode : the current script editor mode (either "edit" or "debug")
# Description
#   Updates the debug controls. In particular populates the execution contexts menu
private command debugControlsUpdate pMode
   lock screen
   local tFilteredContexts
   put seDebugContexts() into tFilteredContexts
   
   local tShortContexts
   repeat for each line tContextLine in tFilteredContexts
      put debugContextShort(tContextLine) & return after tShortContexts
   end repeat
   delete the last char of tShortContexts
   
   local tLastContext
   put seGetDebugContext() into tLastContext
   
   set the text of button "Debug Context" of me to tShortContexts
   
   if pMode is "debug" then
      if tLastContext is empty or tLastContext is not among the lines of tFilteredContexts then
         set the label of button "Debug Context" of me to "TempLabel"
         set the label of button "Debug Context" of me to line 1 of tShortContexts
      else
         set the label of button "Debug Context" of me to "TempLabel"
         set the label of button "Debug Context" of me to debugContextShort(tLastContext)
      end if
   end if
   
   set the cContexts of button "Debug Context" of me to tFilteredContexts
   unlock screen
end debugControlsUpdate

# Parameters
#   pContext : an execution context
# Returns
#   A shorter form of the specified context suitable for display in an option menu.
private function debugContextShort pContext
   # OK-2009-06-23 : Bug 7954 - Modified to use properly parsed execution context.
   local tArray
   put revDebuggerParseExecutionContext(pContext) into tArray
   
   local tName, tResult
   put seFriendlyObject(tArray["object"]) into tName
   
   put tName & comma & " line " & tArray["line number"] into tResult
   
   return tResult
end debugContextShort

on menuPick pItemName
   lock screen
   if the short name of the target is "Debug Context" then
      local tNumber, tContexts
      put the menuHistory of button "Debug Context" of me into tNumber
      put the cContexts of button "Debug Context" of me into tContexts
      
      local tSelectedContext
      put line tNumber of tContexts into tSelectedContext
      revDebuggerSetContext tSelectedContext
      seSetDebugContext tSelectedContext
      
      # OK-2009-06-23 : Bug 7954 - Properly parse execution context and deal with the behavior situation.
      local tArray
      put revDebuggerParseExecutionContext(tSelectedContext) into tArray
      
      local tObject
      if tArray["behavior"] is not empty then
         put tArray["behavior"] into tObject
      else
         put tArray["object"] into tObject
      end if
      
      revSEGoExecutionPoint tObject, tArray["line number"], true, true
   end if
   unlock screen
end menuPick

constant kFudge = 2

command showHandlerList
   lock screen
   # OK-2008-08-18 : Bug 6916 - The handler list object should always be at the top layer
   set the layer of seHandlerListObject() to top
   
   set the topRight of seHandlerListObject() to (the right of button "Handlers" of me), (the bottom of button "Handlers" of me)
   set the cCallback of seHandlerListObject() to "handlerSelected"
   set the cCallbackTarget of seHandlerListObject() to the long id of me
   
   local tHandler
   revSEGetSelectedHandler
   put the result into tHandler
   if tHandler is not empty then
      set the cSelectedHandler of seHandlerListObject() to tHandler
   end if
   
   local tObject
   revSEGetCurrentObject
   put the result into tObject
   
   set the cObject of seHandlerListObject() to tObject
   set the cCaller of seHandlerListObject() to the long id of this stack
   
   set the cMaxWidth of seHandlerListObject() to max(the width of button "Handlers" of me, kHandlerListObjectMinWidth)
   set the cMinWidth of seHandlerListObject() to max(the width of button "Handlers" of me, kHandlerListObjectMinWidth)
   
   local tMaxHeight
   put min((the height of this card - the bottom of me), 450) into tMaxHeight
   set the cMaxHeight of seHandlerListObject() to tMaxHeight
   
   send "initialize" to seHandlerListObject()
   unlock screen
end showHandlerList
  

command hideHandlerList
   set the right of seHandlerListObject() to the left of this card - 20
end hideHandlerList

# Description
#   Callback for the handler list object. This is called when the stack is closed
#   which either means the user has choosen a handler, or dismissed the stack.
on handlerSelected
   lock screen
   local tHandler, tLine, tType
   put item 1 of the cChoice of seHandlerListObject() into tLine
   put item 2 of the cChoice of seHandlerListObject() into tHandler
   put item 3 of the cChoice of seHandlerListObject() into tType
   if tLine is empty then
      exit handlerSelected
   end if
   
   # OK-2009-03-04 : Bug 7450 - If the script is invalid (i.e. doesn't compile) then the line number returned by the handler
   # list may be wrong because its the last known location of the handler when the script was compiled. To try and locate
   # the handler correctly we call this function which will check if tLine is wrong, and attempt to adjust it.
   put seLocateHandler(tHandler, tLine, tType) into tLine
   
   set the label of button "Fake Handler Menu" of me to "TempLabel"
   set the label of button "Fake Handler Menu" of me to tHandler
   set the toolTip of button "Handlers" of me to tHandler
   
   send "goLine tLine, true" to group "Editor"
   seUpdateLeftBar
   unlock screen
end handlerSelected
