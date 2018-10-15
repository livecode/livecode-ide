script "revProjectBrowserBehavior"
local sDisplayArray, sLongIDToRow, sObjectToParent

on arrowKey pDirection
   local tHilitedRow
   put the dvHilitedRows of group "objectList" of me into tHilitedRow
   
   -- up and down are handled by the data view
   if the number of items of tHilitedRow is 1 and not (the dvIsFieldEditor of the target) then
      switch pDirection
         case "left"
            if getRowExpanded(getAbsoluteRow(tHilitedRow)) then
               toggleGroup tHilitedRow, false
            end if
            break
         case "right"
            if not getRowExpanded(getAbsoluteRow(tHilitedRow)) then
               toggleGroup tHilitedRow, true
            end if
            break
      end switch
   end if
   pass arrowKey
end arrowKey

on returnKey
   local tHilitedRow
   put the dvHilitedRows of group "objectList" of me into tHilitedRow
   
   -- up and down are handled by the data view
   if the number of items of tHilitedRow is 1 then
      local tDataA, tTemplateStyle
      DataForRow tHilitedRow, tDataA, tTemplateStyle
      
      if exists(tDataA["behavior"]) and the shiftKey is down and the optionKey is down then
         edit the script of tDataA["behavior"]
      else if exists(tDataA["long id"]) then
         if the shiftKey is down then
            edit the script of tDataA["long id"]
         else if the commandKey is down then
            revIDEInspectObjects tDataA["long id"]
         else
            goToObject tDataA["long id"]
         end if
      end if
   end if
   pass returnKey
end returnKey

on preOpenStack   
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   set the zoomBox of this stack to false
   clearFrameData
   
   revIDEUpdatePBPreferences
   
   # Navigation
   
   # Footer Actions
   addFrameItem "alignLeft","footer", "action", "Align left", "object align left", "","alignControls", the long id of me, "left"
   addFrameItem "alignTop","footer", "action", "Align top", "object align top", "","alignControls", the long id of me, "top"
   addFrameItem "alignRight","footer", "action", "Align right", "object align right", "","alignControls", the long id of me, "right"
   addFrameItem "alignBottom","footer", "action", "Align bottom", "object align bottom", "","alignControls", the long id of me, "bottom"
   
   addFrameItem "centerX","footer", "action", "Center horizontally", "object align horizontal center", "","centerControls", the long id of me, "horizontal"
   addFrameItem "centerY","footer", "action", "Center vertically", "object align vertical center", "","centerControls", the long id of me, "vertical"
   
   addFrameItem "equalizeWidth","footer", "action", "Equalize width", "object justify horizontal", "","equalizeControls", the long id of me, "width"
   addFrameItem "equalizeHeight","footer", "action", "Equalize height", "object justify vertical", "","equalizeControls", the long id of me, "height"
   addFrameItem "equalizeRect","footer", "action", "Equalize rect", "object justify both", "","equalizeControls", the long id of me, "rect"
   
   addFrameItem "distributeVertically","footer", "action", "Layout vertically", "resize vertical", "","distributeControls", the long id of me, "vertical"
   addFrameItem "distributeHorizontally","footer", "action", "Layout horizontally", "resize horizontal", "","distributeControls", the long id of me, "horizontal"
   
   addFrameItem "newControl","footer", "action", "New control", "file alt", "","newControls", the long id of me
   addFrameItem "groupControl","footer", "action", "Group controls", "folder open alt", "","groupControls", the long id of me
   addFrameItem "cloneControl","footer", "action", "Clone control", "files alt", "","cloneControls", the long id of me
   addFrameItem "deleteControl","footer", "action", "Delete control", "trash", "","deleteControls", the long id of me
   
   
   # Preferences
   addFrameItem "pb_indicator", "header", "preference", "Object type indicator", "enum","Text,Icon", "preferenceChanged", the long id of me   
   addFrameItem "pb_sections", "header", "preference", "Show Sections", "set","Front Scripts,Stacks,Back Scripts,Stacks in use", "preferenceChanged", the long id of me
   addFrameItem "pb_stackSort","header","preference","Order stacks by","enum","Name - ascending,Name - descending,Layer - ascending,Layer - descending","preferenceChanged",the long id of me
   addFrameItem "pb_cardSort","header","preference","Order cards by","enum","Name - ascending,Name - descending,Layer - ascending,Layer - descending","preferenceChanged",the long id of me
   addFrameItem "pb_controlSort","header","preference","Order controls by","enum","Name - ascending,Name - descending,Layer - ascending,Layer - descending","preferenceChanged",the long id of me
   addFrameItem "pb_textSize","header","preference","Text size","enum","default,8,10,12,14,18,24","preferenceChanged",the long id of me
   
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "ideNewControl"
   revIDESubscribe "ideNewCard"
   revIDESubscribe "ideNewStack"
   revIDESubscribe "ideOpenStack"
   revIDESubscribe "ideResumeStack"
   revIDESubscribe "ideDestroyStack"
   
   revIDESubscribe "ideControlDeleted"
   revIDESubscribe "ideCardDeleted"
   revIDESubscribe "ideStackDeleted"
   
   revIDESubscribe "ideLibraryStack"
   revIDESubscribe "ideReleaseStack"
   
   revIDESubscribe "ideNameChanged"
   revIDESubscribe "ideMainstackChanged"
   
   revIDESubscribe "idePreferenceChanged:cShowRevolutionStacks"
   
   revIDESubscribe "idePreferenceChanged:pb_indicator"
   revIDESubscribe "idePreferenceChanged:pb_sections"
   revIDESubscribe "idePreferenceChanged:pb_stackSort"
   revIDESubscribe "idePreferenceChanged:pb_cardSort"
   revIDESubscribe "idePreferenceChanged:pb_controlSort"
   revIDESubscribe "idePreferenceChanged:pb_textSize"
   
   revIDESubscribe "ideShowInProjectBrowser"
   
   local tTextSize
   put revIDEGetPreference("pb_textSize") into tTextSize
   if tTextSize is "default" then
      set the textSize of me to empty
   else
      set the textSize of me to tTextSize
   end if
   
   put empty into sDisplayArray
   loadImages
   setUpProjectView
   buildProjectView
   set the rect of group "content" of card 1 of me to the contentRect of me
   ideSelectedObjectChanged
end preOpenStack

on resizeStack
   lock screen
   set the rect of group "content" of card 1 of me to the contentRect of me
   unlock screen
end resizeStack

on closeStack
   local tExpanded
   ## Unsubscribe
   --   revIDEUnsubscribe "ideSelectedObjectChanged"
   --   revIDEUnsubscribe "ideNewControl"
   --   revIDEUnsubscribe "ideNewCard"
   --   revIDEUnsubscribe "ideNewStack"
   
   --   revIDEUnsubscribe "ideControlDeleted"
   --   revIDEUnsubscribe "ideCardDeleted"
   --   revIDEUnsubscribe "ideStackDeleted"
   
   --   revIDEUnsubscribe "ideLibraryStack"
   --   revIDEUnsubscribe "ideReleaseStack"
   
   ## Store the expanded controls
   lock screen
   repeat for each key tRow in sDisplayArray["objects"]
      if sDisplayArray["objects"][tRow]["expanded"] then put sDisplayArray["objects"][tRow]["long id"] & return before tExpanded
   end repeat
   set the cExpandedControls of me to tExpanded
   
   put empty into sDisplayArray
   refreshProjectView
   unlock screen
end closeStack

####### Subscribed IDE messages #######
###################################
on ideSelectedObjectChanged
   highlightObjects revIDESelectedObjects()
end ideSelectedObjectChanged

on ideNewControl pTarget
   if not exists(pTarget) then
      exit ideNewControl
   end if
   
   put the long id of pTarget into pTarget
   if word  1 of pTarget is "stack" or  word  1 of pTarget is "card" then
      exit ideNewControl
   end if
   
   local tSortType,tSortOrder
   revIDEGetPBSortPreferences "pb_controlSort", tSortType, tSortOrder
   if word  1 of pTarget is "group" and tSortType is "number" then
      addGroupToProjectBrowser pTarget
   else
      addControlToProjectBrowser pTarget
   end if
end ideNewControl

on ideNewCard pTarget
   if not exists(pTarget) then
      exit ideNewCard
   end if
   addCardToProjectBrowser pTarget
end ideNewCard

on ideNewStack pTarget
   if not exists(pTarget) then
      exit ideNewStack
   end if
   addStackToProjectBrowser pTarget
end ideNewStack

on ideControlDeleted pTarget
   deleteControlFromProjectBrowser pTarget
end ideControlDeleted

on ideCardDeleted pTarget
   deleteCardFromProjectBrowser pTarget
end ideCardDeleted

on ideStackDeleted pTarget
   deleteStackFromProjectBrowser pTarget
end ideStackDeleted

on ideLibraryStack pTarget
   buildProjectView true
end ideLibraryStack

on ideReleaseStack pTarget
   buildProjectView true
end ideReleaseStack

on ideOpenStack pTarget
   local tStack
   
   if not exists(pTarget) then
      exit ideOpenStack
   end if
   
   if word 1 of pTarget  is "card" then
      put ideStackOfObject(pTarget) into tStack
   else if word 1 of pTarget is "stack" then
      put pTarget into tStack
   end if
   
   addStackToProjectBrowser tStack
end ideOpenStack

on ideDestroyStack pTarget
   deleteStackFromProjectBrowser pTarget
end ideDestroyStack

on ideResumeStack pTarget
   ideSelectedObjectChanged
end ideResumeStack

on ideNameChanged pOldName, pNewName, pTarget
   # if the target is a stack, we need to deal with the name change
   # separately, as the long id is changed.
   if word 1 of pTarget is "stack" then
      local tOldTarget
      put pTarget into tOldTarget
      put quote & pOldName & quote into word 2 of tOldTarget
      deleteStackFromProjectBrowser tOldTarget
      addStackToProjectBrowser pTarget
      exit ideNameChanged
   end if
   
   updateObjectRows pTarget, "name", pNewName
   
   # If we're sorting by name, we might need to re-order
   local tSortType,tSortOrder
   if word 1 of pTarget is "card" then
      revIDEGetPBSortPreferences "pb_cardSort", tSortType, tSortOrder
   else
      revIDEGetPBSortPreferences "pb_controlSort", tSortType, tSortOrder
   end if
   if tSortType is "name" then
      buildProjectView true
   end if
end ideNameChanged

on ideMainstackChanged pOldName, pNewName, pTarget
   # The long id of the target will have changed.
   # Try and find the old stack which will have been added to the pb
   local tOldTarget
   # First check if the target was previously the substack of another stack
   local tDeleted
   put pTarget into tOldTarget
   put quote & pOldName & quote into word 5 of tOldTarget
   deleteStackFromProjectBrowser tOldTarget
   put the result into tDeleted
   
   # Otherwise the target was previously a mainstack
   if not tDeleted then
      put word 1 to 2 of pTarget into tOldTarget
      deleteStackFromProjectBrowser tOldTarget
      put the result into tDeleted
   end if
   
   addStackToProjectBrowser pTarget
end ideMainstackChanged

on preferenceChanged pPreference, pValue
   local tOldValue, tSortType, tSortOrder
   
   switch pPreference
      case "pb_sections"
         local tCurrentPreferenceValue, tPreferencePosition
         put revIDEGetPreference("pb_sections") into tCurrentPreferenceValue
         
         put itemoffset(pValue, tCurrentPreferenceValue) into tPreferencePosition
         if tPreferencePosition > 0 then
            delete item tPreferencePosition of tCurrentPreferenceValue
         else
            put "," & pValue after tCurrentPreferenceValue
         end if
         revIDESetPreference "pb_sections", tCurrentPreferenceValue
         break
      case "pb_stackSort"
      case "pb_cardSort"
      case "pb_controlSort"
      case "pb_textSize"
      case "pb_indicator"
         revIDESetPreference pPreference,pValue
         break
   end switch
end preferenceChanged

on idePreferenceChanged pPreference, pValue
   local tTextSize
   
   switch pPreference
      case "pb_indicator"
      case "pb_sections"
      case "pb_stackSort"
      case "pb_cardSort"
      case "pb_controlSort"
         buildProjectView true
         break
      case "pb_textSize"
         put revIDEGetPreference("pb_textSize") into tTextSize
         if tTextSize is "default" then
            set the textSize of me to empty
         else
            set the textSize of me to tTextSize
         end if
         setUpProjectView
         buildProjectView true
         break
      default
         buildProjectView true
   end switch
end idePreferenceChanged

on ideShowInProjectBrowser pTarget
   lock screen
   repeat for each line tObj in pTarget
      showObjects tObj
   end repeat
   scrollToObject line 1 of pTarget
   unlock screen
end ideShowInProjectBrowser

######## Project View Handlers ########
###################################

function pbSelectedObjects
   local tHilitedRows
   put the dvHilitedRows of group "objectList" of me into tHilitedRows
   
   local tObjectList, tAbsoluteRow, tObject
   repeat for each item tRow in tHilitedRows
      put getAbsoluteRow(tRow) into tAbsoluteRow
      put sDisplayArray["objects"][tAbsoluteRow]["long id"] into tObject
      
      if tObjectList is empty then
         put tObject into tObjectList
      else
         put return & tObject after tObjectList
      end if
   end repeat
   return tObjectList
end pbSelectedObjects

command setUpProjectView
   local theStylesA, tBehaviorsFolder, tStackID, tTemplatesFolder
   put revIDEPaletteResourcePath("behaviors") into tBehaviorsFolder
   put revIDEPaletteResourcePath("templates") into tTemplatesFolder
   
   set the behavior of group "objectList" of me to revIDEDataViewBehavior()
   send "ResetView" to group "objectList" of me
   
   put the long id of group "containerRow" of card 1 of stack (tTemplatesFolder & slash & "revideprojectbrowsercontainerrowtemplate.livecode") into theStylesA["container"]
   put the long id of stack (tBehaviorsFolder & slash & "revideprojectbrowsercontainerrowbehavior.livecodescript") into tStackID
   set the behavior of theStylesA["container"] to tStackID
   
   put the long id of group "controlRow" of card 1 of stack (tTemplatesFolder & slash & "revideprojectbrowsercontrolrowtemplate.livecode") into theStylesA["control"]
   put the long id of stack (tBehaviorsFolder & slash & "revideprojectbrowsercontrolrowbehavior.livecodescript") into tStackID
   set the behavior of theStylesA["control"] to tStackID
   
   put the long id of group "libraryRow" of card 1 of stack (tTemplatesFolder & slash & "revideprojectbrowserlibraryrowtemplate.livecode") into theStylesA["library"]
   put the long id of stack (tBehaviorsFolder & slash & "revideprojectbrowserlibraryrowbehavior.livecodescript") into tStackID
   set the behavior of theStylesA["library"] to tStackID
   
   put the long id of group "sectionRow" of card 1 of stack (tTemplatesFolder & slash & "revideprojectbrowsersectionrowtemplate.livecode") into theStylesA["section"]
   put the long id of stack (tBehaviorsFolder & slash & "revideprojectbrowsersectionrowbehavior.livecodescript") into tStackID
   set the behavior of theStylesA["section"] to tStackID
   
   put the long id of group "groupRow" of card 1 of stack (tTemplatesFolder & slash & "revideprojectbrowsergrouprowtemplate.livecode") into theStylesA["group"]
   put the long id of stack (tBehaviorsFolder & slash & "revideprojectbrowsergrouprowbehavior.livecodescript") into tStackID
   set the behavior of theStylesA["group"] to tStackID
   
   set the viewProp["row style templates"] of group "objectList" of me to theStylesA
   set the viewProp["hilite color"] of group "objectList" of me to revIDEColor("dataView_HiliteColor")
   
   set the viewProp["row color"] of group "objectList" of me to revIDEColor("dataView_rowColor")
   set the viewProp["alternate row color"] of group "objectList" of me to revIDEColor("dataView_rowAlternateColor")     
   
   set the viewProp["fixed row height"] of group "objectList" of me to "true"
   set the viewProp["row height"] of group "objectList" of me to the effective textSize of me + 14
   set the viewProp["cache"] of group "objectList" of me to "none"
   set the viewProp["background color"] of group "objectList" of me to empty
   set the viewProp["drop indicator template"] of group "objectList" of me to the long id of group "pbDragIndicator" of card "templates" of this stack
   set the foregroundColor of graphic "indicator" of group "pbDragIndicator" of card "templates" of this stack to revIDEColor("edition_color")
end setUpProjectView

command buildProjectView pRememberExpansion
   local tStacks, tFrontScripts, tBackScripts,tRow, tVisibleROws, tChildren
   local tLibraryStacks, tOldArray,tOldExpandedControls, tOldExpandedRows
   local tSections
   local tIndex
   
   lock screen
   
   put revIDEGetPreference("pb_sections") into tSections
   
   if pRememberExpansion then
      repeat for each key tKey in sDisplayArray["objects"]
         if sDisplayArray["objects"][tKey]["expanded"] is true then
            if sDisplayArray["objects"][tKey]["type"] is "stack" or sDisplayArray["objects"][tKey]["type"] is "substack" then
               put sDisplayArray["objects"][tKey]["long id"] & comma & 1 &  return after tOldExpandedControls
            else if  sDisplayArray["objects"][tKey]["type"] is "card" then
               put sDisplayArray["objects"][tKey]["long id"] & comma & 2 &  return after tOldExpandedControls
            else if  sDisplayArray["objects"][tKey]["type"] is "group" then
               put sDisplayArray["objects"][tKey]["long id"] & comma & 3 &  return after tOldExpandedControls
            else
               put sDisplayArray["objects"][tKey]["long id"] & comma & 4 &  return after tOldExpandedControls
            end if
         end if
      end repeat
   end if
   sort lines of tOldExpandedControls by item 2 of each
   
   repeat with x  = 1 to the number of items in tSections
      if item x of tSections is not among the items of "Front Scripts,Stacks,Back Scripts,Stacks in use" then
         delete item x of tSections
      end if
   end repeat
   
   ## If all are switched off the show stacks
   if tSections is empty then 
      put "stacks" into tSections
      revIDESetPreference "ideProjectBrowser_show",tSections
      exit buildProjectView
   end if
   
   if "Front Scripts" is among the items of tSections then
      put revIDEFrontScripts() into tFrontScripts
      
      if tFrontScripts is not empty then
         put the number of elements in tFrontScripts + 1 into tIndex
      end if
   end if
   
   if "Stacks" is among the items of tSections then
      put revIDEStacksForDataView(tIndex) into tStacks
   end if
   
   if "Back Scripts" is among the items of tSections then
      put revIDEBackScripts() into tBackScripts
   end if
   
   if "Stacks in use" is among the items of tSections then
      put revIDEStacksInUse() into tLibraryStacks
   end if
   
   put itemise(tStacks,tFrontScripts,tBackScripts,tLibraryStacks) into sDisplayArray
   put topLevelRows(sDisplayArray["objects"]) into tVisibleRows
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   ## Expanded all previously expanded controls
   local tChildRow, tVisibleRowNumber
   repeat for each line tExpandedControl in tOldExpandedControls
      delete item 2 of tExpandedControl
      put sDisplayArray["visible object keys"] into tVisibleRows
      if exists(tExpandedControl) then
         put getRow(tExpandedControl) into tChildRow
         put itemOffset(tChildRow, tVisibleRows) into tVisibleRowNumber
         if sDisplayArray["objects"][tChildRow]["childCount"] is not 0 then
            addChildren tExpandedControl, tChildRow, false
         end if
         put "false" into sDisplayArray["objects"][tChildRow]["expanded"]
         dispatch "TreeToggleRow" to group "objectList" with sDisplayArray, tVisibleRowNumber, 0, true
      end if
   end repeat
   
   refreshProjectView
   unlock screen
end buildProjectView

on refreshProjectView
   updateListeners
   
   --revPutArray sDisplayArray
   lock messages
   send "RenderView" to group "objectList" of me
   unlock messages
   ideSelectedObjectChanged
end refreshProjectView

on updateListeners
   local tOldTargets, tOldTargetsSet
   put the revObjectListeners into tOldTargets
   repeat for each line tTarget in tOldTargets
      put true into tOldTargetsSet[tTarget]
   end repeat
   
   repeat for each key tKey in sDisplayArray["objects"]
      get sDisplayArray["objects"][tKey]["long id"]
      if it is not empty then
         if tOldTargetsSet[it] then
            delete variable tOldTargetsSet[it]
         else
            if exists(it) then
               _internal listen to it
            end if
         end if
      end if
   end repeat
   
   repeat for each key tKey in tOldTargetsSet
      _internal cancel listener for tKey
   end repeat
end updateListeners

--on redrawProjectList
--   local tStacks, tFrontScripts, tBackScripts,tRow, tVisibleROws, tChildren
--   local tLibraryStacks, tOldArray,tOldExpandedControls, tOldExpandedRows
--   local tSections

--   put sDisplayArray into tOldArray
--   put tOldArray["visible object keys"] into tVisibleRows

--   repeat with x = 1 to the number of lines in the keys of tOldArray["objects"]
--      if tOldArray["objects"][x]["expanded"] is true then
--         put tOldArray["objects"][x]["long id"] & return after tOldExpandedControls
--      end if
--   end repeat      

--   repeat for each line tControl in tOldExpandedControls
--      put getRow(tControl) into tRow
--      put sDisplayArray["objects"][tRow]["children"] & comma after tVisibleRows
--      put true into sDisplayArray["objects"][tRow]["expanded"]
--   end repeat

--   delete the last char of tVisibleRows
--   sort items of tVisibleRows ascending numeric
--   put tVisibleRows into sDisplayArray["visible object keys"]

--   lock messages
--   send "RenderView" to group "objectList" of me
--   unlock messages
--end redrawProjectList

## Returns the stacks and header rows
function topLevelRows pArray
   local tTopLevelRows, tLongID
   put empty into sLongIDToRow
   put empty into sObjectToParent
   
   repeat with x = 1 to the number of elements in pArray
      ## Mainstacks
      if pArray[x]["type"] is "stack" and pArray[x]["level"] is "1" then
         put x & comma after tTopLevelRows
      end if
      
      ## Titles
      if pArray[x]["type"] is "section" then
         put x & comma after tTopLevelRows
      end if
      
      if pArray[x]["style"] is not among the items of "section,library" then
         put pArray[x]["long id"] into tLongID
         put x into sLongIDToRow[tLongID]
         try
            put the long id of the owner of tLongID into sObjectToParent[tLongID]
         catch pError
         end try
      else
      end if
   end repeat
   if the last char of tTopLevelRows is comma then delete the last char of tTopLevelRows
   return tTopLevelRows
end topLevelRows

########## Selection handlers ########## 
####################################

# Indicate that pObjects are selected
command highlightObjects pObjects, pForceScroll
   local tVisibleRows,tRow,tRows
   put sDisplayArray["visible object keys"] into tVisibleRows
   repeat for each line tObject in pObjects      
      put getRow(tObject) into tRow
      if tRow is among the items of tVisibleRows then
         put itemOffset(tRow,tVisibleRows) & comma after tRows
      end if
   end repeat
   delete the last char of tRows
   
   if pForceScroll and pObjects is not empty then
      scrollToRow(getRow(line 1 of pObjects))
   end if
   
   updateSelection tRows
end highlightObjects

## Expands stacks, cards and groups as necessary to show object
command showObjects pObject
   local tRow, tRows, tOwners, tOwnerRow, tVisibleRows, tVisibleRowNumber
   ### Highlight the parent trail
   put getOwners(pObject,tOwners) into tOwners
   set the cOwners of group "objectList" of me to tOwners
   
   lock screen
   repeat for each line tObject in tOwners      
      ## Expand if necessary
      put sDisplayArray["visible object keys"] into tVisibleRows
      put getRow(tObject) into tRow
      if sDisplayArray["objects"][tRow]["expanded"] is not true then
         put false into  sDisplayArray["objects"][tRow]["expanded"] 
         addChildren tObject, tRow
         put itemOffset(tRow, tVisibleRows) into tVisibleRowNumber
         dispatch "TreeToggleRow" to group "objectList" with sDisplayArray, tVisibleRowNumber, 0, true 
      end if
   end repeat
   
   updateActions
   unlock screen
end showObjects

on selectObjects pObjectList
   // AL-2015-12-17: Don't select objects anymore when they are selected
   // in the PB
   /*
   local tSelectedRows, tObjectList, tVisibleRows
   local tCards
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   if pObjectList is empty then
      put the dvHilitedRows["true"] of group "objectList" of this stack into tSelectedRows
      
      repeat for each item tRow in tSelectedRows
         put sDisplayArray["objects"][item tRow of tVisibleRows]["long id"] & return after tObjectList
      end repeat
      delete the last char of tObjectList
   else
      put pObjectList into tObjectList
   end if
   
   if the last char of tObjectList is return then delete the last char of tObjectList
   
   ## If a card or stack is selected we don't want to go to the card
   ## The user should be able to highlight or expand a card or stack without going to it
   if word 1 of tObjectList is "stack" or word 1 of tObjectList is "card" then
      exit selectObjects
   end if
   
   ## Don't go to card if it is part of the project browser
   If ideStackOfObject(line 1 of tObjectList) is the long id of me then
      exit selectObjects
   end if
   
   ## Go to correct card as required
   lock messages
   repeat for each line tObject in tObjectList      
      if revIDECardOfObject(tObject) is not among the lines of tCards then
         put revIDECardOfObject(tObject) & return after tCards
      end if
      if the last char of tCards is return then delete the last char of tCards
   end repeat
   
   if exists(tCards) then
      if tCards is not the long id of this card of the topStack then
         go tCards
      end if
   end if
   
   unlock messages
   
   ## Select objects
   revIDESelectObjects tObjectList  
   */ 
end selectObjects

on selectionChanged pHilitedRows, pPreviouslyHilitedRows
   lock screen
   local tObjectList, tAbsoluteRow, tStyle, tSelectedTypes
   local tContainer, tControl
   local tMostRecentRow
   
   repeat for each item tRow in pHilitedRows
      if tRow is not among the items of pPreviouslyHilitedRows then
         put tRow into tMostRecentRow
      end if      
   end repeat
   
   if the number of items of pHilitedRows <2 then
      ## If only one item is highlighted then no checks are needed
      put getAbsoluteRow(pHilitedRows) into tAbsoluteRow
      put sDisplayArray["objects"][tAbsoluteRow]["long id"] into tObjectList
   else
      put 0 into tContainer
      put 0 into tControl
      repeat for each item tRow in pHilitedRows
         put getAbsoluteRow(tRow) into tAbsoluteRow
         put getRowStyle(tAbsoluteRow) into tStyle
         
         if tStyle is "container" then add 1 to tContainer
         if tStyle is "control" or tStyle is "group" then 
            add 1 to tControl
            put getAbsoluteRow(tRow) into tAbsoluteRow
            put sDisplayArray["objects"][tAbsoluteRow]["long id"] & return after tObjectList
         end if
      end repeat
   end if
   
   ## If there is more that one stack or more than one card
   if tContainer > 1 then
      set the dvHilitedRows of group "objectList" of card 1 of this stack to tMostRecentRow
   else         
      if tObjectList is not empty then
         selectObjects tObjectList
      end if
   end if
   unlock screen
end selectionChanged

on goToObject pObjectID
   ## Don't go to object if it is part of the project browser
   If ideStackOfObject(pObjectID) is the long id of me then
      exit goToObject
   end if
   
   if word 1 of pObjectID is "stack"  then
      if not the visible of pObjectID then show pObjectID
      go pObjectID 
   else if word 1 of pObjectID is "card"  then
      if not the visible of the owner of pObjectID then show the owner of pObjectID
      go pObjectID
   else
      go ideStackOfObject(pObjectID)
      revIDESelectObjects pObjectID
   end if
end goToObject

########### Footer actions ############
####################################

command updateActions
   local tSelectedObjects
   put pbSelectedObjects() into tSelectedObjects
   
   lock screen
   if the number of lines in tSelectedObjects > 1 then
      enableFrameItem "alignLeft"
      enableFrameItem "alignTop"
      enableFrameItem "alignRight"
      enableFrameItem "alignBottom"
      
      enableFrameItem "centerX"
      enableFrameItem "centerY"
      
      enableFrameItem "equalizeWidth"
      enableFrameItem "equalizeHeight"
      enableFrameItem "equalizeRect"
      
      enableFrameItem "distributeHorizontally"
      enableFrameItem "distributeVertically"
      
      enableFrameItem "newControl"
      enableFrameItem "groupControl"
      enableFrameItem "cloneControl"
      enableFrameItem "deleteControl"
   else if the number of lines in tSelectedObjects = 1 then
      disableFrameItem "alignLeft"
      disableFrameItem "alignTop"
      disableFrameItem "alignRight"
      disableFrameItem "alignBottom"
      
      disableFrameItem "centerX"
      disableFrameItem "centerY"
      
      disableFrameItem "equalizeWidth"
      disableFrameItem "equalizeHeight"
      disableFrameItem "equalizeRect"
      
      disableFrameItem "distributeHorizontally"
      disableFrameItem "distributeVertically"
      
      enableFrameItem "newControl"
      enableFrameItem "groupControl"
      enableFrameItem "cloneControl"
      enableFrameItem "deleteControl"
   else if tSelectedObjects is empty then
      
      disableFrameItem "alignLeft"
      disableFrameItem "alignTop"
      disableFrameItem "alignRight"
      disableFrameItem "alignBottom"
      
      disableFrameItem "centerX"
      disableFrameItem "centerY"
      
      disableFrameItem "equalizeWidth"
      disableFrameItem "equalizeHeight"
      disableFrameItem "equalizeRect"
      
      disableFrameItem "distributeHorizontally"
      disableFrameItem "distributeVertically"
      
      disableFrameItem "newControl"
      disableFrameItem "groupControl"
      disableFrameItem "cloneControl"
      disableFrameItem "deleteControl"
   end if
   unlock screen
end updateActions

on alignControls pPosition   
   local tSelectedObjects
   put pbSelectedObjects() into tSelectedObjects
   revIDEAlignControls tSelectedObjects, pPosition
end alignControls

on centerControls pPosition
   local tSelectedObjects
   put pbSelectedObjects() into tSelectedObjects
   revIDECenterControls tSelectedObjects,pPosition
end centerControls

on equalizeControls pPosition
   local tSelectedObjects
   put pbSelectedObjects() into tSelectedObjects
   revIDEEqualizeControls tSelectedObjects,pPosition
end equalizeControls

on distributeControls pPosition
   local tSelectedObjects
   put pbSelectedObjects() into tSelectedObjects
   revIDEDistributeControls tSelectedObjects,pPosition, "First To Last selected"
end distributeControls

on newControls
   local tControls
   put pbSelectedObjects() into tControls   
   
   lock screen
   repeat for each line tControlID in tControls
      revIDECloneObjectWithDefaults tControlID
   end repeat
   unlock screen
end newControls

on groupControls
   local tName, tLayer, tList, tGroupID, tControlList
   
   put pbSelectedObjects() into tControlList
   revIDEGroupObjects tControlList
   
   if the result is empty and exists(it) then
      select it
   else
      beep
   end if
   unlock screen
end groupControls

on cloneControls
   local tClonedIDs, tControlList
   put pbSelectedObjects() into tControlList
   
   lock screen
   local tOldDefaultStack
   put the defaultStack into tOldDefaultStack
   set the defaultStack to revIDEStackOfObject(line 1 of tControlList)
   repeat for each line tControlID in tControlList
      revIDECloneObject tControlID
      put the result & return after tClonedIDs
   end repeat
   
   selectObjects tClonedIDs
   set the defaultStack to tOldDefaultStack
   unlock screen
end cloneControls

on backspaceKey
   if the dvIsFieldEditor of the target then
      pass backspaceKey
   else
      deleteControls
   end if
end backspaceKey

on deleteControls
   local tControlID, tGroupID, tControlList
   put pbSelectedObjects() into tControlList
   
   local tAnswerString
   put "Are you sure you want to delete these objects?" into tAnswerString
   put return & tControlList after tAnswerString
   answer tAnswerString with "Cancel" and "OK"
   if it is "ok" then
       lock screen
       revIDEDeleteObjects tControlList
       unlock screen
   end if
   
end deleteControls

on lockControls
   local tControlList, tUnlocked
   put pbSelectedObjects() into tControlList
   lock screen
   
   put true into tUnlocked
   repeat for each line tControl in tControlList
      if the cantSelect of tControl then put false into tUnlocked
      exit repeat
   end repeat
   
   revIDESetPropertyOfObject tControlList, "cantSelect", not(tUnlocked)
   updateObjectRows tControlList, "cantSelect", not(tUnlocked)
   unlock screen
end lockControls

on showControls
   local tControlList, tVisible
   put pbSelectedObjects() into tControlList
   lock screen
   
   put true into tVisible
   repeat for each line tControl in tControlList
      if not the visible of tControl then put false into tVisible
      exit repeat
   end repeat
   
   revIDESetPropertyOfObject tControlList, "visible", not(tVisible)
   updateObjectRows tControlList, "visible", not(tVisible)
   unlock screen
end showControls

####### DataView handlers #######
##############################
function NumberOfRows
   # return the number of rows in the data view
   return the number of items in sDisplayArray["visible object keys"]
end NumberOfRows

command DataForRow pRow, @pDataA, @pTemplateStyle
   local theID
   # Fill in pDataA with the values for this pRow and specify the row style.
   put item pRow of sDisplayArray["visible object keys"] into theId
   put sDisplayArray["objects"][theId] into pDataA
   
   switch pDataA["style"]
      case "section"
         put "section" into pTemplateStyle
         break
      case "container"
         put "container" into pTemplateStyle
         break
      case "group"
         put "group" into pTemplateStyle
         break
      case "library"
         put "library" into pTemplateStyle
         break
      case "control"
         put "control" into pTemplateStyle
         break
      default
         put "control" into pTemplateStyle
   end switch 
end DataForRow

function CacheKeyForRow pRow 
   # [OPTIONAL unless data is a tree] Specify a unique key for pRow. 
   # Only define if you will be reordering rows in the dataview 
   # By default the row number is used to cache the control for a row. 
   # If you will be reordering rows in your dataview then you need to provide 
   # a unique value for the cache key by defining this function and returning a value. 
   # A database id can work nicely. 
   local theID
   put item pRow of sDisplayArray["visible object keys"] into theId 
   return (sDisplayArray["objects"][theId]["long id"] && sDisplayArray["objects"][theId]["type"])
end CacheKeyForRow

on toggleGroup pRow, pState
   lock screen
   local tLongID, tLevel, tData, tAbsoluteRow, tVisibleRows
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   put item pRow of tVisibleRows into tAbsoluteRow
   
   put sDisplayArray["objects"][tAbsoluteRow]["long id"] into tLongID
   
   if tLongID is among the items of "front_scripts_title,back_scripts_title,stacks_in_use_title" then
      ## Do nothing
   else
      if pState is true then
         addChildren tLongID, tAbsoluteRow
      end if
   end if      
   
   updateListeners
   dispatch "TreeToggleRow" to group "objectList" with sDisplayArray, pRow, 0, pState 
   ideSelectedObjectChanged
   unlock screen
end toggleGroup

command scrollToRow pRow
   dispatch "ScrollRowTo" to group "objectList" of me with pRow, "top"
end scrollToRow

command scrollToObject pObjectID
   scrollToRow getRow(pObjectID)
end scrollToObject

on DataViewUpdated
   ideSelectedObjectChanged
end DataViewUpdated

####### Project List Array management #######
#######################################

function getRow pLongID
   if sLongIDToRow[pLongID] is not empty or \
         there is not a pLongID then
      return sLongIDToRow[pLongID]
   end if
   
   -- if the stack was new or cloned the long id
   -- may have the stack name rather than file name
   -- so we try that before returning empty
   
   --!NOTE this should be considered a workaround until we have an
   -- immutable object reference to use instead of long id
   put quote & the short name of ideMainStackOfObject(pLongID) & quote into the last word of pLongID
   
   return sLongIDToRow[pLongID]
end getRow

function getAbsoluteRow pVisibleRow
   local tVisibleRows
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   return item pVisibleRow of tVisibleRows
end getAbsoluteRow

function getVisibleRow pLongID
   local tRow
   put getRow(pLongID) into tRow
   return itemOffset(tRow, sDisplayArray["visible object keys"])
end getVisibleRow

function getOwners pLongID, @pOwnerList
   local tOwner
   try
      put the long id of the owner of pLongID into tOwner
   catch tError
   end try
   
   if tOwner is not empty then 
      put tOwner & return before pOwnerList
      get getOwners(tOwner, pOwnerList)
   end if
   return pOwnerList
end getOwners

function getRowType pAbsoluteRow
   return sDisplayArray["objects"][pAbsoluteRow]["type"]
end getRowType

function getRowStyle pAbsoluteRow
   return sDisplayArray["objects"][pAbsoluteRow]["style"]
end getRowStyle

function getRowExpanded pAbsoluteRow
   return sDisplayArray["objects"][pAbsoluteRow]["expanded"]
end getRowExpanded

function getLastSibling pVisibleRows, pRowList
   local tLastPosition, tItemPos, tLastRow
   put 0 into tLastPosition
   repeat for each item tRow in pRowList
      put itemOffset(tRow, pVisibleRows) into tItemPos
      if tItemPos > tLastPosition then
         put tItemPos into tLastPosition
         put tRow into tLastRow
      end if
   end repeat
   return tLastRow
end getLastSibling

function nextIndex
   local tKeys
   put the keys of sDisplayArray["objects"] into tKeys
   replace return with comma in tKeys
   return max(tKeys) + 1
end nextIndex

function getNextVisibleRow pRow
   local tVisibleRows, tItemNumber, tAbsoluteRow
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   return item (pRow+1) of tVisibleRows
end getNextVisibleRow

function itemise pStacks, pFrontScripts, pBackScripts, pLibraryStacks, pInitialIndex, pInitialLevel
   local tIndex, tLevel, tVisibleRows, tItemisedArray, tFrontScriptsHeaderIndex, tBackScriptsHeaderIndex, tLibraryHeaderIndex
   
   if pInitialIndex is empty then put 0 into tIndex
   if pInitialLevel is empty then put 0 into tLevel
   
   put 0 into tIndex
   
   ## Front scripts
   local tFrontChildren, tBackChildren, tLibraryChildren
   
   if pFrontScripts is not empty then
      add 1 to tIndex   
      put tIndex & comma after tVisibleRows
      put tIndex into tFrontScriptsHeaderIndex 
      
      put "false" into tItemisedArray["objects"][tIndex]["expanded"]
      
      put "Front Scripts" into tItemisedArray["objects"][tIndex]["title"]
      put "section" into tItemisedArray["objects"][tIndex]["type"]
      put "section" into tItemisedArray["objects"][tIndex]["style"]
      put "1" into tItemisedArray["objects"][tIndex]["level"]
      put "front_scripts_title" into tItemisedArray["objects"][tIndex]["long id"]
      repeat for each element tFrontScript in pFrontScripts
         add 1 to tIndex
         put tIndex & comma after tFrontChildren
         
         put 1 into tItemisedArray["objects"][tIndex]["indent"]
         put tFrontScriptsHeaderIndex into tItemisedArray["objects"][tIndex]["parent"]
         put "false" into tItemisedArray["objects"][tIndex]["expanded"]
         
         put tFrontScript["short name"] into tItemisedArray["objects"][tIndex]["name"]
         put tFrontScript["long id"] into tItemisedArray["objects"][tIndex]["long id"]
         put tFrontScript["scriptlines"] into tItemisedArray["objects"][tIndex]["script lines"]
         put "Front script" into tItemisedArray["objects"][tIndex]["type"]
         put "library" into tItemisedArray["objects"][tIndex]["style"]
         put "2" into tItemisedArray["objects"][tIndex]["level"]
         put "branch" into tItemisedArray["objects"][tIndex]["levels"][1]
         put "horizontal" into tItemisedArray["objects"][tIndex]["levels"][2]
      end repeat
      put "corner" into tItemisedArray["objects"][tIndex]["levels"][1]
      put char 1 to -2 of tFrontChildren into tItemisedArray["objects"][tFrontScriptsHeaderIndex]["children"]
   end if
   
   ## Stack
   local tStackObjects, tKeys
   put pStacks into tStackObjects
   --put tItemisedArray["visible object keys"] into tVisibleRows
   
   put the keys of  tStackObjects into tKeys
   sort lines of tKeys ascending numeric
   repeat for each line tKey in tKeys
      put tKey & comma after tVisibleRows
      put tStackObjects[tKey] into tItemisedArray["objects"][tKey]
   end repeat
   put line -1 of tKeys into tIndex
   
   ## Back scripts
   if pBackScripts is not empty then
      add 1 to tIndex   
      put tIndex & comma after tVisibleRows
      put tIndex into tBackScriptsHeaderIndex 
      
      put "false" into tItemisedArray["objects"][tIndex]["expanded"]
      
      put "Back Scripts" into tItemisedArray["objects"][tIndex]["title"]
      put "section" into tItemisedArray["objects"][tIndex]["type"]
      put "section" into tItemisedArray["objects"][tIndex]["style"]
      put "1" into tItemisedArray["objects"][tIndex]["level"]
      put "back_scripts_title" into tItemisedArray["objects"][tIndex]["long id"]
      repeat for each element tBackScript in pBackScripts
         add 1 to tIndex
         put tIndex & comma after tBackChildren
         
         put 1 into tItemisedArray["objects"][tIndex]["indent"]
         put tBackScriptsHeaderIndex into tItemisedArray["objects"][tIndex]["parent"]
         put "false" into tItemisedArray["objects"][tIndex]["expanded"]
         
         put tBackScript["short name"] into tItemisedArray["objects"][tIndex]["name"]
         put tBackScript["long id"] into tItemisedArray["objects"][tIndex]["long id"]
         put tBackScript["scriptlines"] into tItemisedArray["objects"][tIndex]["script lines"]
         put "Back script" into tItemisedArray["objects"][tIndex]["type"]
         put "library" into tItemisedArray["objects"][tIndex]["style"]
         put "2" into tItemisedArray["objects"][tIndex]["level"]
         
         put "branch" into tItemisedArray["objects"][tIndex]["levels"][1]
         put "horizontal" into tItemisedArray["objects"][tIndex]["levels"][2]
      end repeat
      put "corner" into tItemisedArray["objects"][tIndex]["levels"][1]
      put char 1 to -2 of tBackChildren into tItemisedArray["objects"][tBackScriptsHeaderIndex]["children"]
   end if
   
   if pLibraryStacks is not empty then
      ## Stacks in use
      add 1 to tIndex   
      put tIndex & comma after tVisibleRows
      put tIndex into tLibraryHeaderIndex 
      
      put "false" into tItemisedArray["objects"][tIndex]["expanded"]
      
      put "Stacks in use" into tItemisedArray["objects"][tIndex]["title"]
      put "section" into tItemisedArray["objects"][tIndex]["type"]
      put "section" into tItemisedArray["objects"][tIndex]["style"]
      put "1" into tItemisedArray["objects"][tIndex]["level"]
      put "stacks_in_use_title" into tItemisedArray["objects"][tIndex]["long id"]
      repeat for each element tLibrary in pLibraryStacks
         add 1 to tIndex
         put tIndex & comma after tLibraryChildren
         
         put 1 into tItemisedArray["objects"][tIndex]["indent"]
         put tLibraryHeaderIndex into tItemisedArray["objects"][tIndex]["parent"]
         put "false" into tItemisedArray["objects"][tIndex]["expanded"]
         
         put tLibrary["short name"] into tItemisedArray["objects"][tIndex]["name"]
         put tLibrary["long id"] into tItemisedArray["objects"][tIndex]["long id"]
         put tLibrary["scriptlines"] into tItemisedArray["objects"][tIndex]["script lines"]
         put "Library stack" into tItemisedArray["objects"][tIndex]["type"]
         put "library" into tItemisedArray["objects"][tIndex]["style"]
         put "2" into tItemisedArray["objects"][tIndex]["level"]
         
         put "branch" into tItemisedArray["objects"][tIndex]["levels"][1]
         put "horizontal" into tItemisedArray["objects"][tIndex]["levels"][2]
      end repeat
      put "corner" into tItemisedArray["objects"][tIndex]["levels"][1]
      put char 1 to -2 of tLibraryChildren into tItemisedArray["objects"][tLibraryHeaderIndex]["children"]
   end if
   
   put char 1 to -2 of tVisibleRows into tItemisedArray["visible object keys"]
   return tItemisedArray
end itemise

## Refreshes all the children of a parents
## Updates the array and visible rows as appropriate
on refreshChildren pParentList, pNewControl, pExpanded
   local tCardRow, tDescendants, tVisibleRows, tItem
   local tExpandedChildren, tChildRow, tVisibleRowNumber
   
   lock screen   
   ## Remember open controls
   repeat for each line pCard in pParentList
      put getRow(pCard) into tCardRow
      
      dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tCardRow,false
      put the result into tDescendants
      
      if sDisplayArray["objects"][tCardRow]["expanded"] is true then
         put pCard & return after tExpandedChildren
         repeat for each item tDescendant in tDescendants
            --sDisplayArray["objects"][tCardRow]["children"]
            if sDisplayArray["objects"][tDescendant]["expanded"] is true then put sDisplayArray["objects"][tDescendant]["long id"] & return after tExpandedChildren
         end repeat
      end if
   end repeat
   
   ## Delete all descendants
   repeat for each line pCard in pParentList
      put getRow(pCard) into tCardRow
      dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tCardRow,false
      put the result into tDescendants
      put sDisplayArray["visible object keys"] into tVisibleRows
      
      ## From the array
      ## From visible rows
      put empty into sDisplayArray["objects"][tCardRow]["children"]
      repeat for each item tDescendant in tDescendants
         delete variable sDisplayArray["objects"][tDescendant]
         put itemOffset(tDescendant, tVisibleRows) into tItem
         if tItem is not 0 then delete item tItem of tVisibleRows
      end repeat  
      put tVisibleRows into sDisplayArray["visible object keys"]
   end repeat
   
   ## Check the number of children of parents
   repeat for each line tCard in pParentList
      put getRow(tCard) into tCardRow
      if word 1 of tCard is "card" then
         put the number of lines in the controlIDs of tCard into sDisplayArray["objects"][tCardRow]["childCount"] 
      else if word 1 of tCard is "stack" then
         put the number of lines in the cardIDs of tCard into sDisplayArray["objects"][tCardRow]["childCount"] 
      end if
      --      put the number of items in sDisplayArray["objects"][tCardRow]["children"] into sDisplayArray["objects"][tCardRow]["childCount"] 
   end repeat
   
   ## Add any expanded children
   repeat for each line tExpandedChild in tExpandedChildren
      put sDisplayArray["visible object keys"] into tVisibleRows
      if exists(tExpandedChild) then
         put getRow(tExpandedChild) into tChildRow
         put itemOffset(tChildRow, tVisibleRows) into tVisibleRowNumber
         addChildren tExpandedChild, tChildRow, false
         put the number of items in sDisplayArray["objects"][tChildRow]["children"] into sDisplayArray["objects"][tChildRow]["childCount"] 
         put "false" into sDisplayArray["objects"][tChildRow]["expanded"]
         dispatch "TreeToggleRow" to group "objectList" with sDisplayArray, tVisibleRowNumber, 0, true
      end if
   end repeat
   
   ## If the original card was expanded then expand the new card
   put sDisplayArray["visible object keys"] into tVisibleRows
   if pNewControl is not empty then
      if pExpanded is true and pNewControl is not among the lines of tExpandedChildren then
         put getRow(pNewControl) into tChildRow
         put itemOffset(tChildRow, tVisibleRows) into tVisibleRowNumber
         addChildren pNewControl, tChildRow, false
         put false into sDisplayArray["objects"][tChildRow]["expanded"]
         dispatch "TreeToggleRow" to group "objectList" with sDisplayArray, tVisibleRowNumber, 0, true
      end if
   end if
   
   unlock screen
end refreshChildren

on addChildren pParentID, pParentRow, pVisible
   local tCards, theIndex, theNewChildren, tChildArray, tKeys
   local tVisibleRows
   local tOnlyChild, tParentOnlyChild
   local tLevelConnectors, tParentLevelConnectors, tPosition
   local tAudioclipTitleRow, tVideoclipTitleRow
   
   # If children are already set then don't worry about it
   if sDisplayArray["objects"][pParentRow]["children"] is not empty then
      --exit addChildren
   end if
   
   if pVisible then
      put sDisplayArray["visible object keys"] into tVisibleRows
      put comma after tVisibleRows
   end if
   
   if word 1 of pParentID is "stack" then
      put cardsOfStack(pParentID, sDisplayArray["objects"][pParentRow]["level"]) into tChildArray
      if the number of elements in tChildArray is 1 then
         put true into tOnlyChild
      end if
      
      ## Audioclips
      if the number of audioclips of pParentID > 0 then
         ## Add the audioclip title to the array
         put the number of elements in tChildArray + 1 into tAudioclipTitleRow
         
         put "false" into tChildArray[tAudioclipTitleRow]["expanded"]
         put "Audioclips" into tChildArray[tAudioclipTitleRow]["title"]
         put "section" into tChildArray[tAudioclipTitleRow]["type"]
         put "section" into tChildArray[tAudioclipTitleRow]["style"]
         put "2" into tChildArray[tAudioclipTitleRow]["level"]
         put pParentID into tChildArray[tAudioclipTitleRow]["owner"]
         put "audioclips" && pParentID into tChildArray[tAudioclipTitleRow]["long id"]
         put "audioclips" && pParentID into tChildArray[tAudioclipTitleRow]["long id"]
         
         put false into tOnlyChild
         if the number of videoclips of pParentID is 0 then
            put "corner" into tChildArray[tAudioclipTitleRow]["levels"][1]
         else
            put "branch" into tChildArray[tAudioclipTitleRow]["levels"][1]
         end if
      end if
      
      ## Videoclips
      if the number of videoclips of pParentID > 0 then
         ## Add the videoclip title to the array
         put the number of elements in tChildArray + 1 into tVideoclipTitleRow
         if the number of audioclips of pParentID > 0 then add 1 to tVideoclipTitleRow
         
         put "false" into tChildArray[tVideoclipTitleRow]["expanded"]
         put "Videoclips" into tChildArray[tVideoclipTitleRow]["title"]
         put "section" into tChildArray[tVideoclipTitleRow]["type"]
         put "section" into tChildArray[tVideoclipTitleRow]["style"]
         put "2" into tChildArray[tVideoclipTitleRow]["level"]
         put pParentID into tChildArray[tVideoclipTitleRow]["owner"]
         put "Videoclips" && pParentID into tChildArray[tVideoclipTitleRow]["long id"]
         put "corner" into tChildArray[tVideoclipTitleRow]["levels"][1]
      end if
   else if word 1 of pParentID is "card" then
      put controlsOfCard(pParentID, sDisplayArray["objects"][pParentRow]["level"]) into tChildArray
   else if word 1 of pParentID is "group" then
      put controlsOfGroup(pParentID, sDisplayArray["objects"][pParentRow]["level"]) into tChildArray
   else if word 1 of pParentID is "audioclips" then
      put revIDEStackAudioClips(word 2 to -1 of pParentID) into tChildArray
   else if word 1 of pParentID is "videoclips" then
      put revIDEStackVideoClips(word 2 to -1 of pParentID) into tChildArray
   else if pParentID is empty then
      
   end if
   
   if sDisplayArray["objects"][pParentRow]["onlyChild"] is true then put true into tParentOnlyChild
   
   # Add controls to array
   if pParentID is not empty then
      put the keys of sDisplayArray["objects"] into tKeys
      replace return with comma in tKeys
      put max(tKeys) into theIndex
      
      put the keys of tChildArray into tKeys
      sort lines of tKeys ascending numeric
      repeat for each line tKey in tKeys
         put empty into tLevelConnectors
         add 1 to theIndex
         put tChildArray[tKey] into sDisplayArray["objects"][theIndex]
         
         ## Store the long id of the object to the row number
         put theIndex into sLongIDToRow[tChildArray[tKey]["long id"]]
         
         if pVisible then put theIndex & comma after tVisibleRows
         
         # Set parent property
         put pParentRow into sDisplayArray["objects"][theIndex]["parent"] 
         
         # Build up list of children
         put theIndex & "," after theNewChildren
         
         if tOnlyChild then 
            put "only" into tPosition
         else if tKey is line -1 of tKeys then
            // Last child
            put "last" into tPosition
         else
            put "mid" into tPosition
         end if
         
         put levelConnectors(tChildArray[tKey], pParentRow, tPosition) into tLevelConnectors
         put tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"] 
      end repeat
      
      ## Tell the last child it is last
      put "true" into sDisplayArray["objects"][theIndex]["lastChild"] 
      
      delete the last char of theNewChildren
      delete the last char of tVisibleRows
      
      # Set the "parent" key of the row that was clicked on
      
      if pVisible then
         put tVisibleRows into sDisplayArray["visible object keys"] 
      end if
      
      put theNewChildren into sDisplayArray["objects"][pParentRow]["children"]
   else
      put sDisplayArray["objects"][pParentRow]["children"] after tVisibleRows
      put tVisibleRows into sDisplayArray["visible object keys"] 
   end if
end addChildren

function levelConnectors pObjectArray, pParentRow, pPosition
   local tLevelConnectors, tParentLevelConnectors
   
   //Level connectors
   if pObjectArray["type"] is "substack" then
      if pPosition is "only" then 
         put "corner" into tLevelConnectors[1]
      else if pPosition is "last" then
         // Last child
         put "corner" into tLevelConnectors[1]
      else
         put "branch"  into tLevelConnectors[1] 
      end if
   else if pObjectArray["type"] is "card" then
      if word 1 of pObjectArray["owner"] is "stack" AND pObjectArray["owner"] contains "of" then
         put sDisplayArray["objects"][pParentRow]["levels"] into tParentLevelConnectors
         if pPosition is "only" then 
            if tParentLevelConnectors[1] is "branch" then  put "vertical" into tLevelConnectors[1]
            else put empty into tLevelConnectors[1]
            put "corner" into tLevelConnectors[2]
         else if pPosition is "last" then
            // Last child
            if tParentLevelConnectors[1] is "branch" then  put "vertical" into tLevelConnectors[1]
            else put empty into tLevelConnectors[1]
            put "corner" into tLevelConnectors[2]
         else
            if tParentLevelConnectors[1] is "branch" then  put "vertical" into tLevelConnectors[1]
            else put empty into tLevelConnectors[1]
            put "branch"  into tLevelConnectors[2] 
         end if
      else
         if pPosition is "only" then 
            put "corner" into tLevelConnectors[1]
         else if pPosition is "last" then
            // Last child
            put "corner" into tLevelConnectors[1]
         else
            put "branch"  into tLevelConnectors[1] 
         end if
      end if
   else if pObjectArray["style"] is "group" then
      put sDisplayArray["objects"][pParentRow]["levels"] into tParentLevelConnectors
      
      repeat with l = 1 to pObjectArray["level"]-1
         if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "corner" then
            put empty into tLevelConnectors[l] 
         else if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "branch" then
            put "vertical" into tLevelConnectors[l] 
         else
            put tParentLevelConnectors[l]  into  tLevelConnectors[l] 
         end if
      end repeat
      
      // My connector
      if pPosition is "only" then 
         put "corner" into tLevelConnectors[pObjectArray["level"]-1]
      else if pPosition is "last" then
         // Last child
         put "corner" into tLevelConnectors[pObjectArray["level"]-1]
      else
         put "branch"  into tLevelConnectors[pObjectArray["level"]-1]
      end if            
   else
      //Control
      put sDisplayArray["objects"][pParentRow]["levels"] into tParentLevelConnectors
      
      repeat with l = 1 to pObjectArray["level"]-1
         if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "corner" then
            put empty into tLevelConnectors[l] 
         else if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "branch" then
            put "vertical" into tLevelConnectors[l] 
         else
            put tParentLevelConnectors[l]  into  tLevelConnectors[l] 
         end if
      end repeat
      
      // My connector
      if pPosition is "only" then 
         put "corner" into tLevelConnectors[pObjectArray["level"]-1]
      else if pPosition is "last" then
         // Last child
         put "corner" into tLevelConnectors[pObjectArray["level"]-1]
      else
         put "branch"  into tLevelConnectors[pObjectArray["level"]-1]
      end if         
      
      put "horizontal" into tLevelConnectors[pObjectArray["level"]] 
   end if
   
   return tLevelConnectors
end levelConnectors

####### Project Browser Update Events #######
#######################################

on addStackToProjectBrowser pTarget
   if not exists(pTarget) then
      exit addStackToProjectBrowser
   end if
   
   # If the target has already been added then don't do anything
   if getRow(pTarget) is not empty then
      exit addStackToProjectBrowser
   end if
   
   if word 3 of pTarget is "of" then
      addSubstackToProjectBrowser pTarget
      exit addStackToProjectBrowser
   end if
   
   local tVisibleRows, tRow, tChildren, tChildOffset, tKeys
   local tIndex
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   put nextIndex() into tIndex
   
   put tIndex into sLongIDToRow[pTarget]
   put revIDEStackProperties(pTarget, 1) into sDisplayArray["objects"][tIndex]
   
   if tVisibleRows is empty then
      put tIndex into tVisibleRows
   else
      put comma & tIndex after tVisibleRows
   end if
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   buildProjectView true
end addStackToProjectBrowser

on addSubstackToProjectBrowser pTarget
   local tParentID, tParentRow, tIndex, tParentExpanded, tVisibleRows, tVisibleRows2
   local tChildren, tSubStackInfo, tLevelConnectors
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   put ideMainStackOfObject(pTarget) into tParentID
   put getRow(tParentID) into tParentRow
   if tParentRow is empty then exit addSubstackToProjectBrowser
   put sDisplayArray["objects"][tParentRow]["expanded"] into tParentExpanded
   if tParentExpanded is false then exit addSubstackToProjectBrowser
   
   put nextIndex() into tIndex
   put tIndex into sLongIDToRow[pTarget]
   
   put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   put revIDEStackProperties(pTarget,2) into tSubStackInfo
   put tSubStackInfo into sDisplayArray["objects"][tIndex]
   
   ## Add the children
   local tPosition, tLastChild, tChilPos
   put "last" into tPosition
   put item -1 of tChildren into tLastChild
   put comma & tIndex after tChildren
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   put the number of items in tChildren into sDisplayArray["objects"][tParentRow]["childCount"]
   
   ## Add the levelconnectors
   put "substack" into sDisplayArray["objects"][tIndex]["type"]
   put levelConnectors(sDisplayArray["objects"][tIndex], tParentRow, tPosition) into tLevelConnectors
   put tLevelConnectors into sDisplayArray["objects"][tIndex]["levels"] 
   put "branch" into sDisplayArray["objects"][tLastChild]["levels"][1]
   
   local tLastChildOpen, tLastChildChild, tChildPos
   local tLastChildPos, tLastChildChildren
   put sDisplayArray["objects"][tLastChild]["expanded"] into tLastChildOpen
   
   if tParentExpanded then
      if tLastChildOpen then     
         ## Should go after the last child of the previous card
         ## Or - before the next card/stack would be easier to find
         
         dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray,itemOffset(tLastChild, tVisibleRows),false
         put the result into tLastChildChildren
         
         --put itemOffset(max(tLastChildChildren),tVisibleRows) into tLastChildPos
         put getLastSibling(tVisibleRows, tLastChildChildren) into tLastChildChild
         --put item tLastChildChild of tVisibleRows into tLastChildPos
         put itemOffset(tLastChildChild, tVisibleRows) into tLastChildPos
         put item 1 to tLastChildPos of tVisibleRows & comma & tIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
         
         ## Updated connectors for previos children
         repeat for each item tRow in tLastChildChildren
            put "vertical" into sDisplayArray["objects"][tRow]["levels"][1]
         end repeat
      else
         --put itemOffset(max(tChildren),tVisibleRows) into tLastChildPos
         put itemOffset(tLastChild,tVisibleRows) into tChildPos
         put item 1 to tChildPos of tVisibleRows & comma & tIndex & comma & item (tChildPos+1) to -1 of tVisibleRows into tVisibleRows2
      end if
   else
      put tVisibleRows into tVisibleRows2
   end if
   
   if the last char of tVisibleRows2 is comma then delete the last char of tVisibleRows2
   put tVisibleRows2 into sDisplayArray["visible object keys"]
   
   buildProjectView true
end addSubstackToProjectBrowser

on addCardToProjectBrowser pTarget
   local tParentID, tVisibleRows, tParentRow, theIndex, tChildren, tParentExpanded
   local tCardInfo, tLevelConnectors, tLastChildChild, tCardNumber, tLastCardNumber
   
   put word 5 to -1 of pTarget into tParentID   
   put the number of pTarget into tCardNumber
   put tCardNumber-1 into tLastCardNumber
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   put getRow(tParentID) into tParentRow
   if tParentRow is empty then exit addCardToProjectBrowser
   
   put nextIndex() into theIndex
   put theIndex into sLongIDToRow[pTarget]
   
   put sDisplayArray["objects"][tParentRow]["expanded"] into tParentExpanded
   --if tParentExpanded is false then exit addCardToProjectBrowser
   
   put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   put revIDECardProperties(pTarget,sDisplayArray["objects"][tParentRow]["level"]+1) into tCardInfo
   put tCardInfo into sDisplayArray["objects"][theIndex]
   
   ## Add the level connectors
   local tPosition, tLastChild
   if tChildren is empty then 
      put "only" into tPosition
   else 
      put "last" into tPosition
      put item -1 of tChildren into tLastChild
   end if
   
   # Work out the position of the new card
   local tLastChildOpen, tLastCard
   local tLastChildPos, tVisibleRows2, tLastChildChildren
   
   ## Should go after the last child of the last card
   put line tLastCardNumber of the cardIDs of tParentID into tLastCard
   put getRow(the long id of card id tLastCard of tParentID) into tLastChild
   if the long id of card id (line -1 of the cardIDs of  tParentID) of tParentID is pTarget then
      if the substacks of tParentID is empty then
         put "last" into tPosition
      else
         put "mid" into tPosition
      end if
   else
      put "mid" into tPosition
   end if
   
   put sDisplayArray["objects"][tLastChild]["expanded"] into tLastChildOpen
   dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray,tLastChild,false
   put the result into tLastChildChildren
   
   if tParentExpanded then
      if tLastChildOpen then     
         ## Should go after the last child of the previous card
         ## Or - before the next card/stack would be easier to find
         --put itemOffset(max(tLastChildChildren),tVisibleRows) into tLastChildPos
         put getLastSibling(tVisibleRows, tLastChildChildren) into tLastChildChild
         --put item tLastChildChild of tVisibleRows into tLastChildPos
         put itemOffset(tLastChildChild, tVisibleRows) into tLastChildPos
         put item 1 to tLastChildPos of tVisibleRows & comma & theIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
         
         ## Updated connectors for previous children
         repeat for each item tRow in tLastChildChildren
            put "vertical" into sDisplayArray["objects"][tRow]["levels"][1]
         end repeat
         
         put levelConnectors(sDisplayArray["objects"][theIndex], tParentRow, tPosition) into tLevelConnectors
         put tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"] 
         if tPosition is "last" then
            put "branch" into sDisplayArray["objects"][tLastChild]["levels"][the number of elements in tLevelConnectors]
         end if
      else
         --put itemOffset(max(tChildren),tVisibleRows) into tLastChildPos
         put itemOffset(tLastChild,tVisibleRows) into tLastChildPos
         put item 1 to tLastChildPos of tVisibleRows & comma & theIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
         
         repeat for each item tRow in tLastChildChildren
            put "vertical" into sDisplayArray["objects"][tRow]["levels"][1]
         end repeat
         
         if the substacks of tParentID is empty then
            put levelConnectors(sDisplayArray["objects"][theIndex], tParentRow, tPosition) into tLevelConnectors
            put  tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"] 
            if tPosition is "last" then 
               put "branch" into sDisplayArray["objects"][tLastChild]["levels"][the number of elements in tLevelConnectors]
            end if
         else            
            put levelConnectors(sDisplayArray["objects"][theIndex], tParentRow, tPosition) into tLevelConnectors
            put tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"] 
            put "branch" into sDisplayArray["objects"][tLastChild]["levels"][the number of elements in tLevelConnectors]
         end if
      end if
   else
      put tVisibleRows into tVisibleRows2
   end if
   
   if the last char of tVisibleRows2 is comma then delete the last char of tVisibleRows2
   put tVisibleRows2 into sDisplayArray["visible object keys"]
   
   put comma & theIndex after tChildren
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   put the number of items in tChildren into  sDisplayArray["objects"][tParentRow]["childCount"]
   
   refreshProjectView
end addCardToProjectBrowser

on addGroupToProjectBrowser pTarget
   local tParentRow, tChildren, pParentID
   local tCards, theIndex, theNewChildren, tChildArray, tKeys
   local tVisibleRows, tChildVisible, tParentExpanded
   local tChildOffset, tExpandedSiblings, tLastChild
   
   put word 5 to -1 of pTarget into pParentID   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   put getRow(pParentID) into tParentRow
   if tParentRow is empty then exit addGroupToProjectBrowser
   
   put nextIndex() into theIndex
   put theIndex into sLongIDToRow[pTarget]
   
   dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tParentRow,false
   put the result into tChildren
   put the last item of tChildren into tLastChild
   
   --   if tChildren is empty then
   --      put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   --   end if
   
   put sDisplayArray["objects"][tParentRow]["expanded"] into tParentExpanded
   if tParentExpanded is false then exit addGroupToProjectBrowser
   
   local tControlInfo
   put revIDEGroupProperties(pTarget,sDisplayArray["objects"][tParentRow]["level"]+1) into tControlInfo
   put tControlInfo into sDisplayArray["objects"][theIndex]
   
   ## Delete the children that now belong to the group from the parent
   ## Add the children to the new group
   local tGroupChildren, tGroupChildrenRows, tRowNumber, tItem, tOldID
   put revIDEControlPropertiesOfGroup(pTarget, 2) into tGroupChildren
   
   local tGroupChildrenCount
   put the number of elements in tGroupChildren into tGroupChildrenCount
   put tGroupChildrenCount into sDisplayArray["objects"][theIndex]["childCount"]
   repeat with x = 1 to tGroupChildrenCount
      put tGroupChildren[x]["long id"] into tOldID
      delete word 5 to 8 of tOldID
      put getRow(tOldID) into tRowNumber
      
      if tRowNumber is not empty then
         put itemOffset(tRowNumber,tChildren) into tItem
         delete item tItem of tChildren
         
         put itemOffset(tRowNumber,tVisibleRows) into tItem
         delete item tItem of tVisibleRows
      end if
   end repeat
   
   # Set the "parent" key of the row that was clicked on
   local tLastChildPos, tVisibleRows2
   if tParentExpanded then
      if tChildren is empty then
         --put tVisibleRows & comma & theIndex into tVisibleRows2
         ## Put it after the parent
         put itemOffset(tParentRow,tVisibleRows) into tLastChildPos
         put item 1 to tLastChildPos of tVisibleRows & comma & theIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
      else
         put itemOffset(the last item of tChildren,tVisibleRows) into tLastChildPos
         put item 1 to tLastChildPos of tVisibleRows & comma & theIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
      end if
   else
      put tVisibleRows into tVisibleRows2
   end if
   if the last char of tVisibleRows2 is comma then delete the last char of tVisibleRows2
   
   put tVisibleRows2 into sDisplayArray["visible object keys"]
   
   ## Add the connectors for the group
   local tLevelConnectors, tParentLevelConnectors
   put sDisplayArray["objects"][tParentRow]["levels"] into tParentLevelConnectors
   
   repeat with l = 1 to the number of elements in tParentLevelConnectors
      if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "corner" then
         put empty into tLevelConnectors[l] 
      else if tParentLevelConnectors[l] is empty or tParentLevelConnectors[l] is "branch" then
         put "vertical" into tLevelConnectors[l] 
      else
         put tParentLevelConnectors[l]  into  tLevelConnectors[l] 
      end if
   end repeat
   // Last child
   put "corner" into tLevelConnectors[l+1] 
   put tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"]
   
   local tDescendants, tParentChildren
   dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tParentRow,false
   put the result into tDescendants
   
   put sDisplayArray["objects"][tParentRow]["children"] into tParentChildren
   repeat for each item tDescendant in tDescendants
      if tDescendant is not among the items of tParentChildren then
         put "vertical" into sDisplayArray["objects"][tDescendant]["levels"][the number of elements in tLevelConnectors]
      end if
   end repeat
   put getLastSibling(tVisibleRows, tParentChildren) into tLastChild
   put "branch" into sDisplayArray["objects"][tLastChild]["levels"][the number of elements in tLevelConnectors]
   
   if the first char of tVisibleRows2 is comma then delete the first char of tVisibleRows2
   if the last char of tVisibleRows2 is comma then delete the last char of tVisibleRows2
   put tVisibleRows2 into sDisplayArray["visible object keys"]
   
   if tChildren is empty then
      put theIndex into tChildren
   else
      put comma & theIndex after tChildren
   end if
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   put the number of items in tChildren into  sDisplayArray["objects"][tParentRow]["childCount"]
   
   refreshProjectView
end addGroupToProjectBrowser  

on addControlToProjectBrowser pTarget
   local tParentRow, tChildren, pParentID
   local tCards, theIndex, theNewChildren, tChildArray, tKeys
   local tVisibleRows, tChildVisible, tParentExpanded
   local tChildOffset, tExpandedSiblings, tLevelConnectors, tDescendants
   
   put word 5 to -1 of pTarget into pParentID
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   put getRow(pParentID) into tParentRow
   if tParentRow is empty then exit addControlToProjectBrowser
   
   --   put the number of elements of sDisplayArray["objects"] into theIndex
   --   add 1 to theIndex
   put nextIndex() into theIndex
   
   put theIndex into sLongIDToRow[pTarget]
   
   dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tParentRow,false
   put the result into tDescendants
   
   --   if tChildren is empty then
   put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   --end if
   
   put sDisplayArray["objects"][tParentRow]["expanded"] into tParentExpanded
   
   local tControlInfo
   put revIDEControlProperties(pTarget,sDisplayArray["objects"][tParentRow]["level"]+1) into tControlInfo
   put tControlInfo into sDisplayArray["objects"][theIndex]
   
   ## Add the level connectors
   local tPosition, tLastChild
   if tChildren is empty then 
      put "only" into tPosition
   else 
      put "last" into tPosition
      put item -1 of tChildren into tLastChild
   end if
   
   put levelConnectors(sDisplayArray["objects"][theIndex], tParentRow, tPosition) into tLevelConnectors
   put tLevelConnectors into sDisplayArray["objects"][theIndex]["levels"] 
   put "branch" into sDisplayArray["objects"][tLastChild]["levels"][the number of elements in tLevelConnectors-1]
   
   repeat for each item tDescendant in tDescendants
      if tDescendant is not among the items of tChildren then
         put "vertical" into sDisplayArray["objects"][tDescendant]["levels"][the number of elements in tLevelConnectors-1]
      end if
   end repeat
   
   # Set the "parent" key of the row that was clicked on
   local tLastChildPos, tVisibleRows2
   if tParentExpanded then
      put itemOffset(the last item of tDescendants,tVisibleRows) into tLastChildPos
      put item 1 to tLastChildPos of tVisibleRows & comma & theIndex & comma & item (tLastChildPos+1) to -1 of tVisibleRows into tVisibleRows2
   else
      put tVisibleRows into tVisibleRows2
   end if
   
   if the last char of tVisibleRows2 is comma then delete the last char of tVisibleRows2
   put tVisibleRows2 into sDisplayArray["visible object keys"]
   
   put comma & theIndex after tChildren
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   put the number of items in tChildren into  sDisplayArray["objects"][tParentRow]["childCount"]
   
   refreshProjectView
end addControlToProjectBrowser   

on deleteStackFromProjectBrowser pTarget
   local tRow
   put getRow(pTarget) into tRow
   if tRow is empty then
      return false
   end if
   
   local tVisibleRows, tChildren, tChildOffset
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   delete variable sLongIDToRow[pTarget]
   
   dispatch function "TreeDescendantNodesOfNode" to group "objectList" with sDisplayArray, tRow,false
   put the result into tChildren
   
   if tChildren is empty then
      put sDisplayArray["objects"][tRow]["children"] into tChildren
   end if 
   
   ## Delete stack
   put itemOffset(tRow, tVisibleRows) into tChildOffset
   if tChildOffset is not 0 then
      delete item tChildOffset of tVisibleRows
   end if
   
   ## Update children
   repeat for each item tChild in tChildren
      delete variable sDisplayArray["objects"][tChild]
      put itemOffset(tChild, tVisibleRows) into tChildOffset
      if tChildOffset is not 0 then
         delete item tChildOffset of tVisibleRows
      end if
   end repeat
   put comma after tVisibleRows
   
   delete variable sDisplayArray["objects"][tRow]
   
   if the last char of tVisibleRows is comma then delete the last char of tVisibleRows
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   refreshProjectView
   return true
end deleteStackFromProjectBrowser

on deleteCardFromProjectBrowser pTarget
   local tParentID, tVisibleRows, tParentRow, theIndex, tChildren, tParentExpanded
   local tRow, tCardChildren
   
   put word 5 to -1 of pTarget into tParentID   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   put getRow(tParentID) into tParentRow
   if tParentRow is empty then exit deleteCardFromProjectBrowser
   
   put getRow(pTarget) into tRow
   delete variable sLongIDToRow[pTarget]
   
   put sDisplayArray["objects"][tParentRow]["expanded"] into tParentExpanded
   if tParentExpanded is false then exit deleteCardFromProjectBrowser
   
   put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   
   dispatch function "TreeDescendantNodesOfRow" to group "objectList" with sDisplayArray, tRow,false
   put the result into tCardChildren
   
   if tCardChildren is empty then
      put sDisplayArray["objects"][tRow]["children"] into tCardChildren
   end if
   
   local tItem, tChildChildren
   repeat for each item tCardChild in tCardChildren
      put itemOffset(tCardChild, tVisibleRows) into tItem
      delete item tItem of tVisibleRows
   end repeat
   
   ## Delete the row from visisble rows
   put itemOffset(tRow, tVisibleRows) into tItem
   delete item tItem of tVisibleRows
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   put itemOffset(tRow, tChildren) into tItem
   delete item tItem of tChildren
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   
   ## Delete the connectors of the previous children
   local tLevelCount
   put the number of elements in sDisplayArray["objects"][the last item of tChildren]["levels"] into tLevelCount
   put "corner" into sDisplayArray["objects"][the last item of tChildren]["levels"][tLevelCount]
   
   ## Update the children of the parent
   if the number of items in tChildren is 1 then
      dispatch function "TreeDescendantNodesOfRow" to group "objectList" with sDisplayArray, itemOffset(tChildren,tVisibleRows),false
      put the result into tChildChildren 
      
      repeat for each item tDescendant in tChildChildren 
         put empty into sDisplayArray["objects"][tDescendant]["levels"][1]
      end repeat
   end if
   refreshProjectView
end deleteCardFromProjectBrowser

on deleteControlFromProjectBrowser pTarget
   local tParentRow, tChildren, pParentID
   local tCards, theIndex, theNewChildren, tChildArray, tKeys
   local tVisibleRows, tChildVisible, tParentExpanded
   local tChildOffset, tExpandedSiblings
   local tRow, tLevelConnectors, tLevelCount
   
   put word 5 to -1 of pTarget into pParentID
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   ## Only update if expanded
   put getRow(pParentID) into tParentRow
   if tParentRow is empty then exit deleteControlFromProjectBrowser
   
   put getRow(pTarget) into tRow
   if tRow is empty then exit deleteControlFromProjectBrowser
   delete variable sLongIDToRow[pTarget]
   
   put sDisplayArray["objects"][tParentRow]["children"] into tChildren
   
   ## Delete the row from the children
   local tItem
   put itemOffset(tRow, tChildren) into tItem
   delete item tItem of tChildren
   put tChildren into sDisplayArray["objects"][tParentRow]["children"]
   
   ## Update the connector of the previous child if necessary
   ## Add the level connectors
   put the number of elements in sDisplayArray["objects"][the last item of tChildren]["levels"] into tLevelCount
   put "corner" into sDisplayArray["objects"][the last item of tChildren]["levels"][tLevelCount-1]
   
   if word 1 of pTarget is "group" then
      local tGroupChildren
      dispatch function "TreeDescendantNodesOfRow" to group "objectList" with sDisplayArray, tRow,false
      put the result into tGroupChildren
      
      if tGroupChildren is empty then
         put sDisplayArray["objects"][tRow]["children"] into tGroupChildren
      end if
      
      repeat for each item tGroupChild in tGroupChildren
         put itemOffset(tGroupChild, tVisibleRows) into tItem
         delete item tItem of tVisibleRows
      end repeat
   end if
   
   ## Delete the row from visisble rows
   put itemOffset(tRow, tVisibleRows) into tItem
   delete item tItem of tVisibleRows
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   refreshChildren pParentID
   
   refreshProjectView
end deleteControlFromProjectBrowser   

####### Dragging/Rearranging handlers #######
########################################
on reorderRows pDraggedRowList,pNewStartingRow, pDroppedAfterRow
   local tDraggedRowIndex, tNewRowIndex, tDroppedAfterRowIndex
   local tDraggedCard, tNewRowCard, tDroppedAfterCard
   local tDraggedStack, tNewRowStack, tDroppedAfterStack
   local tDraggedLayer, tNewRowLayer, tDroppedAfterLayer
   local tDraggedStyle, tNewRowStyle, tDroppedAfterStyle
   local tDraggedType, tNewRowType, tDroppedAfterType
   local tDraggedID, tNewRowID, tDroppedAfterID
   local tDraggedOwner, tNewRowOwner, tDroppedAfterOwner
   local tDirection, tVisibleRows
   local tUpdateParents
   local tNewRowNumber, tDroppedAfterNumber
   local tDraggedMainStack, tDroppedAfterMainStack
   local tExpanded, tNewID, tRowRect
   
   ####Testing
   
   if item 1 of pDraggedRowList > pNewStartingRow then
      put "before" into tDirection
   else 
      put "after" into tDirection
   end if
   
   put sDisplayArray["visible object keys"] into tVisibleRows
   
   put getAbsoluteRow(item 1 of pDraggedRowList) into tDraggedRowIndex
   put getAbsoluteRow(pNewStartingRow) into tNewRowIndex
   put getAbsoluteRow(pDroppedAfterRow) into tDroppedAfterRowIndex
   
   put sDisplayArray["objects"][tDraggedRowIndex]["layer"]into tDraggedLayer
   put sDisplayArray["objects"][tNewRowIndex]["layer"]into tNewRowLayer
   put sDisplayArray["objects"][tDroppedAfterRowIndex]["layer"]into tDroppedAfterLayer
   
   put sDisplayArray["objects"][tDraggedRowIndex]["style"]into tDraggedStyle
   put sDisplayArray["objects"][tNewRowIndex]["style"]into tNewRowStyle
   put sDisplayArray["objects"][tDroppedAfterRowIndex]["style"]into tDroppedAfterStyle
   
   put sDisplayArray["objects"][tDraggedRowIndex]["type"]into tDraggedType
   put sDisplayArray["objects"][tNewRowIndex]["type"]into tNewRowType
   put sDisplayArray["objects"][tDroppedAfterRowIndex]["type"]into tDroppedAfterType
   
   put sDisplayArray["objects"][tDraggedRowIndex]["long id"]into tDraggedID
   put sDisplayArray["objects"][tNewRowIndex]["long id"]into tNewRowID
   put sDisplayArray["objects"][tDroppedAfterRowIndex]["long id"]into tDroppedAfterID
   
   put sDisplayArray["objects"][tDraggedRowIndex]["owner"]into tDraggedOwner
   put sDisplayArray["objects"][tNewRowIndex]["owner"]into tNewRowOwner
   put sDisplayArray["objects"][tDroppedAfterRowIndex]["owner"]into tDroppedAfterOwner
   
   put revIDECardOfObject(tDraggedID) into tDraggedCard
   put revIDECardOfObject(tNewRowID) into tNewRowCard
   put revIDECardOfObject(tDroppedAfterID) into tDroppedAfterCard
   
   put revIDEStackOfObject(tDraggedID) into tDraggedStack
   put revIDEStackOfObject(tNewRowID) into tNewRowStack
   put revIDEStackOfObject(tDroppedAfterID) into tDroppedAfterStack
   
   local tAbs, tLongID, tRelayer
   switch tDraggedType
      case "stack"
         exit reorderRows
         break
      case "card"
         switch tDroppedAfterType
            case "card"
               put the number of tNewRowID into tNewRowNumber
               put the number of tDroppedAfterID+1 into tDroppedAfterNumber
               break
            case "stack"
               put 1 into tNewRowNumber
               put 1 into tDroppedAfterNumber
               break
            case "stack"
               ## A card has been dropped after a stack
               put 1 into tNewRowNumber
               put 1 into tDroppedAfterNumber
               break
            case "control"
            case "group"
               put the number of tDroppedAfterCard+1 into tDroppedAfterNumber
               put tDroppedAfterNumber into tNewRowNumber
               break
            default
               exit reorderRows
               break
         end switch
         if tDraggedStack is tDroppedAfterStack then
            ## Reorder cards
            revIDERenumberCard tDraggedID,tNewRowNumber
            refreshChildren tDraggedStack         
         else
            ## Move to another stack
            put sDisplayArray["objects"][tDraggedRowIndex]["expanded"] into tExpanded
            revIDEMoveCard tDraggedID, tDroppedAfterStack
            put the result into tNewID
            put tDraggedStack & return & tDroppedAfterStack into tUpdateParents
            revIDERenumberCard tNewID,tDroppedAfterNumber
            refreshChildren tUpdateParents, tNewID, tExpanded
         end if
         break
      case "substack"
         local tNewMainstack
         switch tDroppedAfterType
            case "substack"
            case "group"
            case "control"
               put the long name of stack (the mainstack of tDraggedStack) into tDraggedMainStack
               put  the long name of stack (the mainstack of tDroppedAfterStack) into tDroppedAfterMainStack
               put tDraggedMainStack & return & tDroppedAfterMainStack into tUpdateParents
               put tDroppedAfterMainStack into tNewMainstack
               break
            case "card"
            case "stack"
               put the long name of stack (the mainstack of tDraggedStack) & return & tDroppedAfterStack into tUpdateParents
               put tDroppedAfterStack into tNewMainstack
               break
            default
               exit reorderRows
               break
         end switch
         revIDEMoveSubstack tDraggedID, tNewMainstack
         put the long name of stack (line -1 of the substacks of tNewMainstack) into tNewID
         put sDisplayArray["objects"][tDraggedRowIndex]["expanded"] into tExpanded
         refreshChildren tUpdateParents,tNewID,tExpanded
         break
      default
         # Control
         put true into tRelayer
         switch tDroppedAfterType
            case "card"
               put "bottom" into tNewRowLayer
               break
            case "stack"
               ## if the stack is closed drop the control onto the current card of the stack
               if sDisplayArray["objects"][tDroppedAfterRowIndex]["expanded"] is not true then
                  put the long id of this card of tDroppedAfterStack into tDroppedAfterCard
               else
                  put the long id of card 1 of tDroppedAfterStack into tDroppedAfterCard
               end if
               put "bottom" into tNewRowLayer
               break
            case "group"
               ## Depending on "drop zone" of non-expanded group
               ## Drop after the group, not into it
               if sDisplayArray["objects"][tDroppedAfterRowIndex]["expanded"] is not true then
                  put the rect of the dvControlOfRow[pDroppedAfterRow] of the dvControl of group "objectList" of me into tRowRect
                  if (the mouseV <= item 2 of tRowRect+8) or (the mouseV  >=  item 4 of tRowRect-8) then
                     ## outside group
                     put false into tRelayer
                  end if  
               end if 
               break
            default
               if tDroppedAfterStyle is not "control" then
                  exit reorderRows
               end if
               break
         end switch
         lock messages
         if tRelayer then
            set the relayerGroupedControls to true
         end if
         repeat for each item tRow in pDraggedRowList
            put getAbsoluteRow(tRow) into tAbs
            put sDisplayArray["objects"][tAbs]["long id"] into tLongID
            if tDraggedCard is not tDroppedAfterCard then
               revIDEMoveControl tLongID, tDroppedAfterCard, tNewRowLayer
               put tDraggedCard & return & tDroppedAfterCard into tUpdateParents
            else
               revIDERelayerControl tLongID, tNewRowLayer, tDraggedCard
               put tDraggedCard into tUpdateParents
            end if
         end repeat
         set the relayerGroupedControls to false
         refreshChildren tUpdateParents            
         unlock messages
         break
   end switch
   refreshProjectView
end reorderRows

####### Property Management
on updateProperty pObjectID, pName, pValue
   revIDESetPropertyOfObject pObjectID, pName, pValue
   
   ## Also update the value in the array
   local tRowNumber
   put getRow(pObjectID) into tRowNumber
   put pValue into sDisplayArray["objects"][tRowNumber][pName]   
end updateProperty

command updateObjectRows pObjectIDs, pProperty, pValue
   local tRow, tHilited
   put the dvHilitedRows of  group "objectList" of me into tHilited
   repeat for each line tObject in pObjectIDs
      put getRow(tObject ) into tRow
      put pValue into sDisplayArray["objects"][tRow][pProperty]
   end repeat
   refreshProjectView
   set the dvHilitedRows of  group "objectList" of me to tHilited
end updateObjectRows

## Property Info
function cardsOfStack pStackID, pLevel
   local tCardArray
   
   put revIDECardPropertiesOfStack(pStackID, pLevel) into tCardArray
   return tCardArray
end cardsOfStack

function controlsOfCard pCardID, pLevel
   local tControlArray, tTime
   
   put revIDEControlPropertiesOfCard(pCardID, pLevel) into tControlArray
   return tControlArray
end controlsOfCard

function controlsOfGroup pGroupID, pLevel
   local tControlArray, tTime
   
   put revIDEControlPropertiesOfGroup(pGroupID, pLevel) into tControlArray
   return tControlArray
end controlsOfGroup

//on propertyChanged pObject   
   //local tHighlightedRows
   //lock messages
   //try
      //updateObjectRows pObject, "visible", the visible of pObject
      //updateObjectRows pObject, "cantSelect", the cantSelect of pObject
      //updateObjectRows pObject, "scriptlines", the number of lines in the script of pObject
   //catch pError
   //end try
   //unlock messages
//end propertyChanged

on loadImages
   local tImage, tFile
   
   lock screen
   lock messages
   repeat with x = 1 to the number of images of card "templates" of this stack
      put the short name of image x of card "templates" of this stack into tImage
      put revIDESpecialFolderPath("Toolset") & "/resources/supporting_files/images/" & tImage into tFile
      if there is a file tFile then
         set the filename of image  x of card "templates" of this stack to tFile
      else if there is a file (tFile & ".png") then
         set the filename of image  x of card "templates" of this stack to (tFile & ".png")
      end if
   end repeat
   unlock messages
   unlock screen
end loadImages

on revUpdatePalette
   ## Do nothing
end revUpdatePalette

on updateSelection pRows
   lock screen
   lock messages
   set the style of the templateGraphic to "rectangle"
   set the opaque of the templateGraphic to false
   set the dashes of the templateGraphic to 4
   set the foreColor of the templateGraphic to "black"
   
   local tNumSelected
   put the number of items in pRows into tNumSelected
   repeat with tCount = 1 to tNumSelected
      if there is not a graphic ("selection" && tCount) of group "selections" of me then
         create invisible graphic ("selection" && tCount) in group "selections" of me 
      end if
   end repeat
   reset the templateGraphic
   unlock messages
   
   put 1 into tCount
   local tControlOfRow
   repeat for each item tRow in pRows
      put the dvControlOfRow[tRow] of group "objectList" of me into tControlOfRow
      if tControlOfRow is not empty then
         set the rect of graphic ("selection" && tCount) of group "selections" of me to the rect of tControlOfRow
         show graphic ("selection" && tCount) of group "selections" of me
      else
         hide graphic ("selection" && tCount) of group "selections" of me
      end if
      add 1 to tCount
   end repeat
   
   repeat while there is a graphic ("selection" && tCount) of group "selections" of me
      hide graphic ("selection" && tCount) of group "selections" of me
      add 1 to tCount
   end repeat
   unlock screen
end updateSelection

on pbRightClick pObject
   local tVisibleRow, tHilited
   put getVisibleRow(pObject) into tVisibleRow
   put the dvHilitedRows of group "objectList" of me into tHilited
   if tVisibleRow is not among the items of tHilited then
      set the dvHilitedRows of group "objectList" of me to tVisibleRow
   end if
   
   -- ensure the target is the first in the list
   local tSelected
   put pbSelectedObjects() into tSelected
   filter tSelected without pObject
   if tSelected is not empty then
      put return before tSelected
   end if
   put pObject before tSelected
   
   revIDEPopupContextualMenu tSelected
end pbRightClick

## Connector creation for all row types
command setConnectorIcon pControl, pState
   local tLeft, tTop, tRight,tBottom, tHeight, tWidth, tPoints
   
   put the left of pControl into tLeft
   put the right of pControl into tRight
   put the top of pControl into tTop
   put the bottom of pControl into tBottom
   
   put the width of pControl into tWidth
   put the height of pControl into tHeight
   
   set the foregroundColor pControl to empty
   set the foregroundColor of graphic "line" of pControl to empty
   
   switch pState
      case empty
         hide widget "icon" of pControl
         hide graphic "line" of pControl
         break
      case "branch"
         hide widget "icon" of pControl
         show graphic "line" of pControl
         
         put tLeft + (tWidth/2), tTop & return into tPoints
         put tLeft + (tWidth/2), tTop + tHeight & return after tPoints
         put tLeft + (tWidth/2), tTop + (tHeight/2)  & return after tPoints
         put tLeft + tWidth, tTop + (tHeight/2)  & return after tPoints
         set the points of graphic "line" of pControl to tPoints
         
         break
      case "cantExpand"
         show graphic "line" of pControl
         show widget "icon" of pControl
         
         put tLeft,tTop + (tHeight/2)  & return into tPoints
         put tLeft + (tWidth/2) - (the width of widget "icon" of pControl /2),tTop + (tHeight/2)  & return after tPoints
         
         set the points of graphic "line" of pControl to tPoints
         set the iconPresetName of widget "icon" of pControl to "circle"
         break
      case "childContracted"
         show graphic "line" of pControl
         show widget "icon" of pControl
         
         put tLeft,tTop + (tHeight/2) & return into tPoints
         put tLeft + (tWidth/2) -  (the width of widget "icon" of pControl /2),tTop + (tHeight/2)  & return after tPoints
         
         set the points of graphic "line" of pControl to tPoints
         set the iconPresetName of widget "icon" of pControl to "plus sign"
         break
      case "childExpanded"
         show graphic "line" of pControl
         show widget "icon" of pControl
         
         put tLeft,tTop + (tHeight/2)  & return into tPoints
         put tLeft + (tWidth/2)  -  (the width of widget "icon" of pControl /2) ,tTop + (tHeight/2)  & return after tPoints
         put tLeft + (tWidth/2) ,tTop + (tHeight/2) + (the height of widget "icon" of pControl /2) & return after tPoints
         put tLeft + (tWidth/2),tTop + tHeight  & return after tPoints
         
         set the points of graphic "line" of pControl to tPoints
         set the iconPresetName of widget "icon" of pControl to "minus sign"
         
         break
      case "corner"
         hide widget "icon" of pControl
         show graphic "line" of pControl
         
         put tLeft + (tWidth/2),tTop & return into tPoints
         put  tLeft + (tWidth/2), tTop + (tHeight/2) & return after tPoints
         put  tLeft + tWidth, tTop + (tHeight/2) after tPoints
         set the points of graphic "line" of pControl to tPoints
         break
      case "horizontal"
         hide widget "icon" of pControl
         show graphic "line" of pControl
         
         put tLeft,tTop + (tHeight/2) & return into tPoints
         put tLeft + tWidth,tTop + (tHeight/2) after tPoints
         set the points of graphic "line" of pControl to tPoints
         break
      case "stackContracted"
         hide graphic "line" of pControl
         show widget "icon" of pControl
         set the iconPresetName of widget "icon" of pControl to "plus sign"
         break
      case "stackExpanded"
         show widget "icon" of pControl
         show graphic "line" of pControl
         
         put tLeft + (tWidth/2),tTop +(tHeight/2) +(the height of widget "icon" of pControl /2)  & return into tPoints
         put tLeft + (tWidth/2),tTop + tHeight after tPoints
         set the points of graphic "line" of pControl to  tPoints
         set the iconPresetName of widget "icon" of pControl to "minus sign"
         break
      case "vertical"
         hide widget "icon" of pControl
         show graphic "line" of pControl
         put tLeft + (tWidth/2),tTop & return into tPoints
         put tLeft + (tWidth/2),tBottom after tPoints
         set the points of graphic "line" of pControl to tPoints
         break
   end switch
end setConnectorIcon
