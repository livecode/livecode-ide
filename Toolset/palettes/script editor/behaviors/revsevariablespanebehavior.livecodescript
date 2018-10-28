script "revSEVariablesPaneBehavior"

local sTree
local sTimes

local sVisualizationObjects
local sVisualizationObjectCount = 0

local sContext
local sLastUpdateContext
local sUpdateHasRun = "false"

command paneOpenControl
   setDefaultsAndCallbacks
   refresh
   resize
end paneOpenControl

command paneCloseControl
end paneCloseControl

on closeControl
   local tObject
   repeat for each key tObject in sVisualizationObjects
      if there is a tObject then
         close stack tObject
      end if
   end repeat
end closeControl

command paneResizeControl
   update false
   resize
end paneResizeControl

command update pEnvironmentChanged
   put seGetDebugContext() into sContext 
   put sContext & the width of me & the height of me into sLastUpdateContext
   
   lock screen
   
   if pEnvironmentChanged is not "false" then
      applyPreferences
   end if
   
   if pEnvironmentChanged is not "false" then
      get buildTree()
      set the arrayData of widget "tree" of me to it
   end if
   
   updateVisualizationObjects
   unlock screen
   
   put true into sUpdateHasRun
end update

command refresh
   update
end refresh

command resize pDontUpdateTree
   local tFilter, tWidget, tGlobals, tEnvVars, tRect, tTop, tLeft, tWidth, tHeight, tBottom
   put the long id of field "Filter" of me into tFilter
   put the long id of button "Show Globals" of me into tGlobals
   set the width of tGlobals to the formattedWidth of tGlobals
   put the long id of button "Show Environment Vars" of me into tEnvVars
   set the width of tEnvVars to the formattedWidth of tEnvVars
   put the long id of widget "tree" of me into tWidget

   put the rect of me into tRect
   put item 1 of tRect into tLeft
   put item 3 of tRect - tLeft into tWidth
   put item 2 of tRect into tTop
   put item 4 of tRect into tBottom
   put tBottom - tTop into tHeight

   lock screen

   set the width of tFilter to (tWidth - the width of tGlobals - the width of tEnvVars)
   set the top of tFilter to tTop
   set the left of tFilter to tLeft

   set the height of tEnvVars to the height of tFilter
   set the top of tEnvVars to tTop
   set the right of tEnvVars to tLeft + tWidth

   set the height of tGlobals to the height of tFilter
   set the top of tGlobals to tTop
   set the right of tGlobals to tLeft + tWidth - the width of tEnvVars

   set the width of tWidget to tWidth
   set the height of tWidget to (tHeight - the height of tFilter)
   set the bottom of tWidget to tBottom
   set the left of tWidget to tLeft

   unlock screen
end resize

command reapplyPreferences
   if there is a widget "tree" of me then
      applyPreferences
   end if
end reapplyPreferences

private command applyPreferences
   # At the moment, we ignore preferences in the variable viewer
   /*
   if the textFont of group "Tree" of me is not sePrefGet("editor,font") then
      set the textFont of group "Tree" of me to sePrefGet("editor,font")
   end if
   
   if the textSize of group "Tree" of me <> sePrefGet("editor,fontsize") then
      set the textSize of group "Tree" of me to sePrefGet("editor,fontsize")
   end if
   
   # If the user chooses a large font, we need to increase the size of the template, for now we just hack this as
   # its a little risky to fiddle too much with the template's size.
   if sePrefGet("editor,fontsize") > 15 then
      if the height of branchTemplate() <> 25 then
         set the height of branchTemplate() to 25
      end if
   else
      if the height of branchTemplate() <> 19 then
         set the height of branchTemplate() to 19
      end if
   end if
   */
end applyPreferences

private function buildTree
   local tTreeA, tTopNodes
   
   put buildTopNodes() into tTopNodes

   repeat for each line tLine in tTopNodes
      # OK-2009-06-22 : Bug 8109 - Don't always use the revDebuggerGlobalNames to determine if a variable is global,
      # as it might be a local variable with the same name as one of the globals. Instead sTopNodes will postfix all globals with
      # "global" to indicate this.
      local tVariable
      if item 2 of tLine is "global" then
         local tStatement
         put "global " & (item 1 of tLine) & return & "put " & (item 1 of  tLine) & " into tVariable" into tStatement
         do tStatement
      else
         put revDebuggerGetValue(tLine, sContext, empty) into tVariable
      end if
      
      put tVariable into tTreeA[item 1 of tLine]
   end repeat
   
   return tTreeA
end buildTree

private function buildTopNodes
   local tTopNodes
   
   put empty into tTopNodes
   
   # Environment variables are included in globals, so process the globals even if we
   # only want to display environment variables.
   if the cShowGlobals of me is true or the cShowEnvGlobals of me is true then
      # When debugging with showGlobals, we show all globals and all locals
      # OK-2009-06-22 : Bug 8109 - Postfix all globals with "global" so that we don't have to use the globalNames
      # to determine whether each variable is global or not.
      --put revDebuggerGlobalNames() into sTopNodes
      get revDebuggerGlobalNames()
         
      repeat for each line tGlobal in it
         # Filter variables based on the cShowGlobals and cShowEnvGlobals
         if (the cShowEnvGlobals of me is true and char 1 of tGlobal is "$") or \
               (the cShowGlobals of me is true and char 1 of tGlobal is not "$") then
            put tGlobal & ",global" & return after tTopNodes
         end if
      end repeat
      delete the last char of tTopNodes
   end if
  
   # Show the remaining variables only in debugging mode.
   if sContext is not empty then
      if the cShowGlobals of me is true then
         # All global variables are currently being shown, so we only need to add the local variables to the list
         get processVariableNames(revDebuggerLocalNames(sContext))
         if it is not empty then
            put return & it after tTopNodes
         end if
      else
         # If debugging without showGlobals, we show all locals and just the globals that have been declared in the current context,
         # this is given by revDebuggerVariableNames().
         
         # OK-2009-06-22 : Bug 8109 - Instead of flattening the list of variable names, we need to keep track of which
         # ones were declared in the handler as globals or not. 
         --put processVariableNames(flattenVariableList(revDebuggerVariableNames(sContext))) into sTopNodes
         local tLocals, tGlobals
         get revDebuggerVariableNames(sContext)
         
         put line 1 to 3 of it into tLocals
         put line 4 of it into tGlobals
         
         local tVariables
         put processVariableNames(flattenVariableList(tLocals)) into tVariables
         if tVariables is not empty then
            put return after tVariables
         end if
         
         repeat for each item tGlobal in tGlobals
            put tGlobal & ",global" & return after tVariables
         end repeat
         delete the last char of tVariables
         
         if tTopNodes is not empty then
            put return after tTopNodes
         end if
         
         put tVariables after tTopNodes
      end if
   end if

   filterVariableNames tTopNodes

   return tTopNodes
end buildTopNodes

private function processVariableNames pNames
   local tProcessedNames
   repeat for each line tName in pNames
      if char 1 of tName is "@" then
         put char 2 to -1 of tName & return after tProcessedNames
      else
         put tName & return after tProcessedNames
      end if
   end repeat
   delete the last char of tProcessedNames
   return tProcessedNames
end processVariableNames

private function flattenVariableList pList
   local tList
   repeat for each line tLine in plist
      if the number of words of tLine is 0 then
         next repeat
      end if
      repeat for each item tVariable in tLine
         put tVariable & return after tList
      end repeat
   end repeat
   delete the last char of tList
   return tList
end flattenVariableList

private on pathToVariableComponents pPath, @rVariableName, @rDimensions
   local tCount
   set the itemdel to the pathDelimiter of widget "tree" of me
   repeat for each item tItem in pPath
      add 1 to tCount
      if tCount is 1 then
         put tItem into rVariableName
      else
         put tItem into rDimensions[tCount - 1]
      end if
   end repeat
end pathToVariableComponents


private command addVisualizationObject pObject
   put "" into sVisualizationObjects[pObject]
end addVisualizationObject

private command removeVisualizationObject pObject
   delete variable sVisualizationObjects[pObject]
end removeVisualizationObject

private command updateVisualizationObjects
   -- Update any visualization objects
   repeat for each key tObject in sVisualizationObjects
      visualizationObjectUpdate tObject
   end repeat
end updateVisualizationObjects

on actionInspect pPath
   nodeCreateAndShowVisualizationObject pPath
end actionInspect

on actionDoubleClick pPath
   nodeCreateAndShowVisualizationObject pPath
end actionDoubleClick

private on nodeCreateAndShowVisualizationObject pPath
   local tObject
   nodeCreateVisualizationObject pPath
   put the result into tObject
   addVisualizationObject tObject
   nodeShowVisualizationObject tObject
end nodeCreateAndShowVisualizationObject

command visualizationObjectRemove tObject
   removeVisualizationObject tObject
end visualizationObjectRemove

private on nodeCreateVisualizationObject pPathToNode
   add 1 to sVisualizationObjectCount
   
   local tOldLock
   put the lockMessages into tOldLock
   lock messages
   
   local tStack
   reset the templateStack
   set the _ideoverride of the templateStack to true
   set the width of templateStack to 270
   set the height of templateStack to 250
   
   create invisible stack "revVariableVisualizer " & sVisualizationObjectCount
   put the long id of it into tStack
   set the behavior of tStack to the long id of stack revIDEScriptEditorBehavior("variable visualizer")
   set the cMutable of tStack to true
   set the destroyStack of tStack to true
   set the destroyWindow of tStack to true
   set the title of tStack to "Value : " & friendlyNodeReference(pPathToNode)
   revMetadataSet the name of stack tStack, "general", "visualizer", true
   
   -- generate variable visualizer UI
   local tOldDefaultStack
   put the defaultStack into tOldDefaultStack
   set the defaultStack to the short name of tStack
   reset the templateButton
   set the height of the templateButton to 23
   create button "Apply"
   reset the templateField
   set the vScrollbar of the templateField to true
   create field "Value"
   reset the templateField
   set the lockText of the templateField to true
   create field "Name"
   
   set the cManager of tStack to the long id of me
   set the location of tStack to the location of this stack of me
   set the cName of tStack to friendlyNodeReference(pPathToNode)
   send "setReference pPathToNode" to tStack
   send "initialize" to tStack
   visualizationObjectUpdate tStack
   
   reset the templateStack
   reset the templateButton
   reset the templateField
   set the lockMessages to tOldLock
   set the defaultStack to tOldDefaultStack
   
   return tStack
end nodeCreateVisualizationObject

command visualizationObjectUpdate pObject
   local tReference
   call "getReference" to pObject
   put the result into tReference
   
   local tVariable, tDimensions
   pathToVariableComponents tReference, tVariable, tDimensions   
   
   local tValue
   if tVariable is among the lines of revDebuggerGlobalNames() then
      put revDebuggerGetValue(tVariable, sContext, tDimensions, true) into tValue
   else
      put revDebuggerGetValue(tVariable, sContext, tDimensions) into tValue
   end if
   set the cValue of pObject to tValue
end visualizationObjectUpdate

command visualizationObjectSetValue pObject, pNewValue
   local tReference
   call "getReference" to pObject
   put the result into tReference
   
   local tVariable, tDimensions
   pathToVariableComponents tReference, tVariable, tDimensions   
   
   revDebuggerSetValue tVariable, tDimensions, pNewValue, sContext
end visualizationObjectSetValue

private function friendlyNodeReference pNodeReference
   local tString
   local tVariable, tDimensions
   pathToVariableComponents pNodeReference, tVariable, tDimensions   
   put tVariable into tString
   repeat with x = 1 to the number of elements of tDimensions
      put "[" & friendlyKey(tDimensions[x]) & "]" after tString
   end repeat
   return tString
end friendlyNodeReference

private function friendlyKey pKey
   local tWasShortened
   put false into tWasShortened
   
   # First deal with multiple lines
   local tKey
   if the number of lines of pKey > 1 then
      put line 1 of pKey into tKey
      put true into tWasShortened
   else
      put pKey into tKey
   end if
   
   # Next make sure the key is not excessively long
   local tMaxLength
   put 25 into tMaxLength
   
   if the length of tKey > tMaxLength then
      put char 1 to tMaxLength of tKey into tKey
      put true into tWasShortened
   end if
   
   if tWasShortened then
      put "..." into char -3 to -1 of tKey
   end if
   
   return tKey
end friendlyKey
  

private command nodeShowVisualizationObject pObject
   palette pObject
   show pObject
end nodeShowVisualizationObject


----------------------------------------------------------------
-- Variable filtering support
----------------------------------------------------------------

/*
The list of variables can be filtered by a string, stored in the custom
property cFilterText.  If cFilterText is non-empty, only variables that
match *all* the words of cFilterText are shown.

The filterChanged handler updates the cFilterText custom property, and
updates the display if necessary.
*/

-- This is called to update the filter text
on filterChanged pFilterText
   if pFilterText is not the cFilterText of me then
      set the cFilterText of me to pFilterText
      send "updateVariableDisplay" to me in 0 millisecs
   end if
end filterChanged

-- Process a list of handler information lines, replacing it with a list
-- containing only the handlers where the name matches the current filter.
private command filterVariableNames @xVariables
   if the cFilterText of me is empty then
      exit filterVariableNames
   end if

   local tNewVariables, tVariable, tName, tWord, tMatch

   repeat for each line tVariable in xVariables
      put true into tMatch

      set the itemDel to comma
      put item 1 of tVariable into tName

      -- The variable name needs to match *all* of the words in the
      -- filter text
      repeat for each word tWord in the cFilterText of me
         if not (tName contains tWord) then
            put false into tMatch
            exit repeat
         end if
      end repeat

      if tMatch then
         put tVariable & return after tNewVariables
      end if
   end repeat

   put tNewVariables into xVariables
end filterVariableNames

----------------------------------------------------------------
-- Global/Environment variable display support
----------------------------------------------------------------

on setGlobalDisplay pShowGlobals
   set the cShowGlobals of me to pShowGlobals
   send "updateVariableDisplay" to me in 0 millisecs
end setGlobalDisplay

on setEnvDisplay pShowEnvGlobals
   set the cShowEnvGlobals of me to pShowEnvGlobals
   sePrefSet "variables,showenvvars", pShowEnvGlobals
   send "updateVariableDisplay" to me in 0 millisecs
end setEnvDisplay

on updateVariableDisplay
   update
end updateVariableDisplay

private command setDefaultsAndCallbacks
   local tGlobals, tFilter, tEnvVars

   put the long id of button "Show Globals" of me into tGlobals
   put the long id of button "Show Environment Vars" of me into tEnvVars
   put the long id of field "Filter" of me into tFilter

   if sePrefGet("variables,showglobals") then
      set the hilite of tGlobals to true
      set the cShowGlobals of me to true
   else
      set the hilite of tGlobals to false
      set the cShowGlobals of me to false
   end if

   if sePrefGet("variables,showenvvars") then
      set the hilite of tEnvVars to true
      set the cShowEnvGlobals of me to true
   else
      set the hilite of tEnvVars to false
      set the cShowEnvGlobals of me to false
   end if

   set the cCallback of tGlobals to "setGlobalDisplay"
   set the cCallbackTarget of tGlobals to the long id of me

   set the cCallback of tEnvVars to "setEnvDisplay"
   set the cCallbackTarget of tEnvVars to the long id of me

   set the cCallback of tFilter to "filterChanged"
   set the cCallbackTarget of tFilter to the long id of me
   set the cPlaceholderText of tFilter to "Search variables..."
   
   set the pathDelimiter of widget "tree" of me to numToCodepoint(0)
   set the sortType of widget "tree" of me to "numeric"
end setDefaultsAndCallbacks
