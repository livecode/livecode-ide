script "revSEEditBreakpointStackBehavior"
# This group of variables holds the specification of the original breakpoint / watch if we are editing one.
local sOriginalHandler
local sOriginalVariable
local sOriginalLine
local sOriginalWatchCondition
local sOriginalBreakpointCondition
local sOriginalType
local sOriginalObject

on preOpenCard
   ideSubscribe "idePreferenceChanged:cScriptEditor,editor,backgroundcolor"
   ideSubscribe "idePreferenceChanged:cScriptEditor,editor,font"
   ideSubscribe "idePreferenceChanged:cScriptEditor,editor,fontSize"
   
   --   set the loc of me to the screenLoc
   
   update
   
   if the cType of me is "watch" then
      set the hilite of button "Watch" of me to true
      set the hilite of button "Breakpoint" of me to false
      focus on button "Handler" of group "Watch" of me
   else
      set the hilite of button "Breakpoint" of me to true
      set the hilite of button "Watch" of me to false
      focus on field "Line" of group "Breakpoint" of me
      select char 1 to -1 of field "Line" of group "Breakpoint" of me
   end if
   
   put the cObject of me into sOriginalObject
   
   # If we are in editing an existing breakpoint / watch rather than creating a new one,
   # we save the original details so that the existing one can be removed if the user accepts the changes.
   if the cMode of me is "edit" then
      put the cType of me into sOriginalType
      if the cType of me is "watch" then
         put the cHandler of me into sOriginalHandler
         put the cVariable of me into sOriginalVariable
         put the cWatchCondition of me into sOriginalWatchCondition
      else
         put the cLine of me into sOriginalLine
         put the cBreakpointCondition of me into sOriginalBreakpointCondition
      end if
   end if
   
   __UpdateConditionColors
   __UpdateConditionFont
end preOpenCard

on mouseUp
   if the short name of the target is "Breakpoint" then
      set the cType of me to "breakpoint"
      update
   end if
   
   if the short name of the target is "Watch" then
      set the cType of me to "watch"
      update
   end if
   
   pass mouseUp
end mouseUp

on enterKey
   closeAccept
end enterKey

on returnKey
   closeAccept
end returnKey

on enterInField
   closeAccept
end enterInField

on returnInField
   closeAccept
end returnInField

on escapeKey
   closeReject
end escapeKey

on commandKeyDown pKey
   if pKey is not "v" then
      pass commandKeyDown
   end if
   
   local tTextToPaste
   put line 1 of the clipboardData["text"] into tTextToPaste
   set the clipboardData["text"] to empty
   set the clipboardData["html"] to empty
   
   if the short name of the target is "Line" then
      if tTextToPaste is not a number then
         exit commandKeyDown
      else
         set the clipboardData["text"] to tTextToPaste
      end if
   end if
   
   if the short name of the target is "Condition" then
      set the clipboardData["text"] to tTextToPaste
   end if
   
   pass commandKeyDown
end commandKeyDown

command closeReject
   close this stack
end closeReject

command closeAccept
   updateProperties
   
   # If we are in edit mode, delete the existing breakpoint / watch before creating a new one to replace it
   if the cMode of me is "edit" then
      if sOriginalType is "watch" then
         revDebuggerRemoveWatch sOriginalObject, sOriginalHandler, sOriginalVariable
      else
         revDebuggerRemoveBreakpoint sOriginalObject, sOriginalLine
      end if
   end if
   
   local tCondition
   if the cType of me is "watch" then
      put the cWatchCondition of me into tCondition
   else
      put the cBreakpointCondition of me into tCondition
   end if
   
   if tCondition is not empty then
      ideCompileCheck "return" && tCondition
      if the result is not empty then
         answer error revIDELocalise("The entered condition does not compile")
         exit closeAccept
      end if
   end if
   
   # Create a new breakpoint / watch according to the current properties   
   if the cType of me is "watch" then
      local tObject
      if the cVariableScope of me is "Global" then
         put empty into tObject
      else
         if the cMode of me is "edit" then
            put sOriginalObject into tObject
         else
            put the cObject of me into tObject
         end if
      end if
      
      local tResult
      revDebuggerAddWatch tObject, the cHandler of me, the cVariable of me, the cWatchCondition of me
      put the result into tResult
      
      revDebuggerActivateWatch tObject, the cHandler of me, the cVariable of me
      put the result into tResult
   else
      revDebuggerAddBreakpoint sOriginalObject, the cLine of me
      if the cBreakpointCondition of me is not empty then
         revDebuggerSetBreakpointCondition sOriginalObject, the cLine of me, the cBreakpointCondition of me
      end if
      revDebuggerActivateBreakpoint sOriginalObject, the cLine of me
   end if
   
   close this stack
end closeAccept

private command updateProperties
   if the cType of me is "watch" then
      if the label of button "Handler" of group "Watch" of me is "Global Scope" then
         set the cHandler of me to empty
      else
         set the cHandler of me to the label of button "Handler" of group "Watch" of me
      end if
      
      local tVariable
      put line (the menuHistory of button "Variable" of group "Watch" of me) of the cVariables of button "Variable" of group "Watch" of me into tVariable
      
      local tVariableName, tVariableScope
      put item 1 of tVariable into tVariableScope
      put item 2 of tVariable into tVariableName
      
      set the cVariableScope of me to tVariableScope
      
      set the cVariable of me to tVariableName
      set the cWatchCondition of me to the text of field "Condition" of group "Watch" of me
   else
      set the cVariableScope of me to empty
      set the cLine of me to the text of field "Line" of group "Breakpoint" of me
      set the cBreakpointCondition of me to the text of field "Condition" of group "Breakpoint" of me
   end if
end updateProperties

command update
   lock screen
   
   if the cType of me is "watch" then
      set the topLeft of group "Watch" of me to 10, 32
      set the right of group "Breakpoint" of me to -500
      updateWatch
   else
      set the topLeft of group "Breakpoint" of me to 10, 32
      set the right of group "Watch" of me to -500
      updateBreakpoint
   end if
   
   unlock screen
end update

command updateWatch
   # First sort out the handler menu. We query the script editor to get the list of handlers
   # and the currently selected handler.
   # OK-2010-01-18: The handler list should depend on the object
   --   local tHandlers
   --   send "revSEGetHandlerList" to the cCaller of me
   --   put the result into tHandlers
   
   # Sort out the variables list. To do this we query the script editor to get the current object
   # and use what we already know about the current handler to get the list of available variables.
   local tObject
   if the cObject of me is empty then
      send "revSEGetCurrentObject" to the cCaller of me
      put the result into tObject
   else
      put the cObject of me into tObject
   end if
   
   local tHandlers
   put the revAvailableHandlers of tObject into tHandlers
      
   local tDisplayHandlers
   put "Global Scope" & return into tDisplayHandlers
   repeat for each line tHandler in tHandlers
      put word 2 of tHandler & return after tDisplayHandlers
   end repeat
   delete the last char of tDisplayHandlers
   
   local tCurrentHandler
   if the cHandler of me is empty then
      send "revSEGetSelectedHandler" to the cCaller of me
      put the result into tCurrentHandler
      if tCurrentHandler is empty then
         put line 1 of tDisplayHandlers into tCurrentHandler
      end if
   else
      put the cHandler of me into tCurrentHandler
   end if
   
   set the text of button "Handler" of group "Watch" of me to tDisplayHandlers
   set the cHandlers of button "Handler" of group "Watch" of me to empty & return & tHandlers
   set the label of button "Handler" of group "Watch" of me to "TempLabel"
   set the label of button "Handler" of group "Watch" of me to tCurrentHandler
   
   local tCurrentHandlerDetails,tHandlerType
   if tCurrentHandler is "Global Scope" then
      put empty into tCurrentHandlerDetails
      put empty into tHandlerType
   else
      set the wholeMatches to true
      put line lineOffset(tCurrentHandler, tDisplayHandlers) of tHandlers into tCurrentHandlerDetails
      set the wholeMatches to false
      
      get word 1 of tCurrentHandlerDetails
      if char 1 of it is "P" then
         delete char 1 of it
      end if
      put it into tHandlerType
   end if
   
   local tVariables
   if tHandlers is empty then
      put empty into tVariables
   else
      if tCurrentHandler is "Global Scope" then
         put the revAvailableVariables of tObject into tVariables
      else
         put the revAvailableVariables[tHandlerType & comma & tCurrentHandler] of tObject into tVariables
      end if
   end if
   
   # OK-2010-01-15: Store another list which keeps track of the scope of the variables we listed.
   # This way when the user clicks ok, we know what kind of variable they have chosen. This is particularly
   # useful for global watches, as otherwise we have no way of telling if the watch is a script local or a global.
   local tFormattedVariables, tListCopy, tVariablesWithScope, tLineNumber
   put 1 into tLineNumber
   repeat for each line tList in tVariables
      if tList is empty then
         add 1 to tLineNumber
         next repeat
      end if
      
      put tList into tListCopy
      replace comma with return in tListCopy
      
      repeat for each line tVariable in tListCopy
         put getVariableScopeFromContextAndLineNumber((tCurrentHandler is "Global Scope"), tLineNumber) & comma & tVariable & return after tVariablesWithScope
      end repeat
      
      put tListCopy & return after tFormattedVariables
      add 1 to tLineNumber
   end repeat
   delete the last char of tFormattedVariables
   delete the last char of tVariablesWithScope
   
   set the text of button "Variable" of group "Watch" of me to tFormattedVariables
   set the cVariables of button "Variable" of group "Watch" of me to tVariablesWithScope
   set the label of button "Variable" of group "Watch" of me to "TempLabel"
   if the cVariable of me is empty then
      set the label of button "Variable" of group "Watch" of me to line 1 of tVariables
   else
      set the label of button "Variable" of group "Watch" of me to the cVariable of me
   end if
   
   set the text of field "Condition" of group "Watch" of me to the cWatchCondition of me
end updateWatch

private function getVariableScopeFromContextAndLineNumber pGlobal, pLineNumber
   if pGlobal then
      if pLineNumber = 1 then
         return "Script Local"
      else
         return "Global"
      end if
   else
      if pLineNumber = 1 then
         return "Parameter"
      else if pLineNumber = 2 then
         return "Local"
      else if pLineNumber = 3 then
         return "Script Local"
      else
         return "Global"
      end if
   end if
end getVariableScopeFromContextAndLineNumber

private command updateBreakpoint
   local tLineCount
   send "revSEGetLineCount" to the cCaller of me
   put the result into tLineCount
   
   set the text of field "Line Label" of group "Breakpoint" of me to "Line (1 - " & tLineCount & "):"
   set the text of field "Line" of group "Breakpoint" of me to the cLine of me
   set the text of field "Condition" of group "Breakpoint" of me to the cBreakpointCondition of me
   dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of field "Condition" of me
end updateBreakpoint

on textChanged
   if the short name of the target is "Condition" then
      dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of field "Condition" of me
   end if
end textChanged
  
on idePreferenceChanged pPreference, pValue
   lock screen
   switch pPreference
      case "cScriptEditor,editor,backgroundcolor"
         __UpdateConditionColors
         break
      case "cScriptEditor,editor,font"
      case "cScriptEditor,editor,fontSize"
         __UpdateConditionFont
         break
   end switch
   unlock screen
end idePreferenceChanged

private command __UpdateConditionFont
   local tFont, tSize
   put revIDEGetPreference("cScriptEditor,editor,font") into tFont
   put revIDEGetPreference("cScriptEditor,editor,fontSize") into tSize
   
   set the textFont of field "condition" of me to tFont
   set the textSize of field "condition" of me to tSize
end __UpdateConditionFont

private command __UpdateConditionColors
   local tColor
   put revIDEGetPreference("cScriptEditor,editor,backgroundcolor") into tColor
   set the backgroundColor of field "condition" of me to tColor
end __UpdateConditionColors
