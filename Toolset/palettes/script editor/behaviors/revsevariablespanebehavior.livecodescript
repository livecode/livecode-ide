script "revSEVariablesPaneBehavior"

local sTree
local sTimes

command paneOpenControl
   refresh
   resize
end paneOpenControl

command paneCloseControl
end paneCloseControl

command paneResizeControl
   update false
   resize
end paneResizeControl

local sContext

local sLastUpdateContext
local sUpdateHasRun = "false"

command update pEnvironmentChanged
   local tCurrentContext
   put seGetDebugContext() & the width of me & the height of me into tCurrentContext
   
   put tCurrentContext into sLastUpdateContext
   updateDo pEnvironmentChanged
   put true into sUpdateHasRun
end update

private command updateDo pEnvironmentChanged
   put seGetDebugContext() into sContext
   
   if pEnvironmentChanged is not "false" then
      applyPreferences
   end if
   
   if pEnvironmentChanged is not "false" then
      get buildTree()
      set the arrayData of widget "tree" of me to it
   end if
end updateDo

command refresh
   update
end refresh

command resize pDontUpdateTree
   set the rect of widget "tree" of me to the rect of me
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

local sDebugContext

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
   if sContext is not empty then
      if sePrefGet("variables,showglobals") then
         # When debugging with showGlobals, we show all globals and all locals
         # OK-2009-06-22 : Bug 8109 - Postfix all globals with "global" so that we don't have to use the globalNames
         # to determine whether each variable is global or not.
         --put revDebuggerGlobalNames() into sTopNodes
         put empty into tTopNodes
         get revDebuggerGlobalNames()
         
         repeat for each line tGlobal in it
            put tGlobal & ",global" & return after tTopNodes
         end repeat
         delete the last char of tTopNodes
         
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
         
         put tVariables into tTopNodes
      end if
   else
      # If we are not debugging, then just show the globals
      # OK-2009-06-22 : Bug 8109 - Postfix them with "global"
      --put revDebuggerGlobalNames() into sTopNodes
      put empty into tTopNodes
      get revDebuggerGlobalNames()
      repeat for each line tGlobal in it
         put tGlobal & ",global" & return after tTopNodes
      end repeat
      delete the last char of tTopNodes
   end if
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
   repeat for each item tItem in pPath
      add 1 to tCount
      if tCount is 1 then
         put tItem into rVariableName
      else
         put tItem into rDimensions[tCount - 1]
      end if
   end repeat
end pathToVariableComponents

local sVisualizationObjectCount = 0

on actionInspect pPath
   nodeCreateAndShowVisualizationObject pPath
end actionInspect

on actionDoubleClick pPath
   nodeCreateAndShowVisualizationObject pPath
end actionDoubleClick

private on nodeCreateAndShowVisualizationObject pPath
   nodeCreateVisualizationObject pPath
   nodeShowVisualizationObject the result
end nodeCreateAndShowVisualizationObject

private function visualizationObjectTemplate
   return the long id of group "Visualizer Template" of card "Templates" of revScriptEditorTemplate()
end visualizationObjectTemplate

command visualizationObjectRemove tObject
end visualizationObjectRemove

private on nodeCreateVisualizationObject pPathToNode
   add 1 to sVisualizationObjectCount
   
   local tStack
   # OK-2009-01-17 : Bug 7576 - Forgot to put the "rev" prefix in front, resulting in unwanted save dialogs and other issues.
   create invisible stack "revVariableVisualizer " & sVisualizationObjectCount
   put the long id of it into tStack
   set the cMutable of tStack to true
   set the destroyStack of tStack to true
   set the destroyWindow of tStack to true
   set the title of tStack to "Value : " & friendlyNodeReference(pPathToNode)
   set the script of tStack to the cVisualizerStackScript of me
   revMetadataSet the name of stack tStack, "general", "visualizer", true
   
   # For greater flexibility the visualization object is implemented as a group, and we create a stack
   # simply to contain it. All external interactions deal with the group.
   copy visualizationObjectTemplate() to tStack
   set the width of tStack to the width of visualizationObjectTemplate()
   set the height of tStack to the height of visualizationObjectTemplate()
   set the location of tStack to the screenLoc
   set the cManager of group 1 of tStack to the long id of me
   set the backgroundBehavior of group 1 of tStack to true
   set the location of group 1 of tStack to the location of this card of tStack
   set the cName of group 1 of tStack to friendlyNodeReference(pPathToNode)
   send "setReference pPathToNode" to group 1 of tStack
   send "initialize" to group 1 of tStack
   visualizationObjectUpdate tStack
   return tStack
end nodeCreateVisualizationObject

command visualizationObjectUpdate pObject
   local tReference
   call "getReference" to group 1 of pObject
   put the result into tReference
   
   local tVariable, tDimensions
   pathToVariableComponents tReference, tVariable, tDimensions   
   
   local tValue
   if tVariable is among the lines of revDebuggerGlobalNames() then
      put revDebuggerGetValue(tVariable, sContext, tDimensions, true) into tValue
   else
      put revDebuggerGetValue(tVariable, sContext, tDimensions) into tValue
   end if
   set the cValue of group 1 of pObject to tValue
end visualizationObjectUpdate

command visualizationObjectSetValue pObject, pNewValue
   local tReference
   call "getReference" to group 1 of pObject
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
