script "revInspector"
constant kPropertyInspectorPrefix = "revPropertyInspector"
on preOpenStack
   inspectorMessagesRegister
end preOpenStack

on inspectorMessagesRegister
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "ideResumeStack"
   revIDESubscribe "ideNewStack"
   revIDESubscribe "ideInspectObjects"
   revIDESubscribe "ideCloseStack"
   revIDESubscribe "ideNameChanged"
   revIDESubscribe "ideMainstackChanged"
end inspectorMessagesRegister

on inspectorMessagesDeRegister
   revIDEUnsubscribe "ideSelectedObjectChanged"
   revIDEUnsubscribe "ideResumeStack"
   revIDEUnsubscribe "ideInspectObjects"
   revIDEUnsubscribe "ideNewStack"
   revIDEUnsubscribe "ideCloseStack"
   revIDEUnsubscribe "ideNameChanged"
   revIDEUnsubscribe "ideMainstackChanged"
end inspectorMessagesDeRegister 

on inspectorCloseAll
   ## Unsubscribe from all messges
   inspectorMessagesDeRegister
end inspectorCloseAll

#####################
#### PI FUNCTIONS #####
#####################
local sInspectorsA, sInspectorMax
private function inspectorList
   return sInspectorsA
end inspectorList

private on addInspectorToList pInspectorNumber
   put pInspectorNumber into sInspectorsA[pInspectorNumber]
   put max(pInspectorNumber, sInspectorMax) into sInspectorMax
end addInspectorToList

private on removeInspectorFromList pInspectorNumber
   delete variable sInspectorsA[pInspectorNumber]
   if pInspectorNumber is sInspectorMax then
      put max(sInspectorsA) into sInspectorMax
   end if
end removeInspectorFromList

private on deleteInspector pInspectorNumber
   delete stack (kPropertyInspectorPrefix && pInspectorNumber)
   removeInspectorFromList pInspectorNumber
end deleteInspector

local sInspectedObjectsA
on ideInspectObjects pObjects
   # Get the selected objects
   local tSelectedObjects
   if pObjects is not empty then
      put pObjects into tSelectedObjects
   else
      put revIDESelectedObjects() into tSelectedObjects
   end if
   
   local tStackName, tIndex, tTargetInspector, tKeys
   put the keys of inspectorList() into tKeys
   sort tKeys ascending numeric
   repeat for each line tKey in tKeys
      put kPropertyInspectorPrefix && tKey into tStackName
      if the cLocked of stack tStackName is true then next repeat
      
      if tTargetInspector is empty then
         put tStackName into tTargetInspector
         put tKey into tIndex
      else
         # Delete any unlocked inspectors other than the target
         deleteInspector tKey
      end if
   end repeat
   
   lock screen 
   lock messages
   # If all the inspectors are locked, or there aren't any, create a new one.
   if tTargetInspector is empty then
      local tNewInspectorName
      put sInspectorMax + 1 into tIndex
      put inspectorStackName(tIndex) into tNewInspectorName
      inspectorCloneTemplate tNewInspectorName
      put tNewInspectorName into tTargetInspector
      addInspectorToList tIndex
   end if
   -- Only reposition if we are opening a new editor
   if the mode of stack tTargetInspector is 0 then
      inspectorPositionPalette tIndex, tSelectedObjects
   end if
   palette stack tTargetInspector
   unlock messages
   set the cSelectedObjects of stack tTargetInspector to tSelectedObjects
  
   unlock screen
end ideInspectObjects

private command inspectorCloneTemplate pNewName
   set the _ideoverride of stack "revInspectorTemplate" to true
   clone invisible stack "revInspectorTemplate"
   set the cIDETransient of it to true
   set the name of it to pNewName
end inspectorCloneTemplate

function inspectorStackName pIndex
   return kPropertyInspectorPrefix && pIndex
end inspectorStackName

constant kNewInspectorOffset = 20
on inspectorPositionPalette pIndex, pSelObj
   local tStackName
   put inspectorStackName(pIndex) into tStackName
   local tRect
   put revIDEGetPreference("palette_rect_" & tStackName) into tRect
   
   if __isRect(tRect) then
      set the topleft of stack tStackName to item 1 to 2 of tRect
      exit inspectorPositionPalette
   end if
   
   local tPrevInspector
   put inspectorStackName(pIndex - 1) into tPrevInspector
   -- if we have an open inspector, just offset the new one by 10 pixels
   if there is a stack tPrevInspector and the mode of stack tPrevInspector is not 0 then
      set the topleft of stack tStackName to \
            the left of stack tPrevInspector + kNewInspectorOffset, the top of stack tPrevInspector + kNewInspectorOffset
   else
      local tScreenWidth, tScreenRect
      put revIDEStackScreenRect(tStackName, true) into tScreenRect
      put item 3 of tScreenRect - item 1 of tScreenRect into tScreenWidth
      set the top of stack tStackName to the top of the topstack            
      # AL-2015-09-09: [[ Bug 15745 ]] Try and place PI to left of stack if it doesn't fit on the right
      if the right of the topstack + kNewInspectorOffset + the width of stack tStackName < tScreenWidth then
         set the left of stack tStackName to the right of the topstack + kNewInspectorOffset
      else if the left of the topstack - kNewInspectorOffset - the width of stack tStackName > 0 then
         set the right of stack tStackName to the left of the topstack - kNewInspectorOffset
      else
         set the left of stack tStackName to the right of the topstack + kNewInspectorOffset
      end if
      
      if intersect(the long id of stack tStackName, revIDEStackOfObject(line 1 of pSelObj)) then
         revIDEPositionPaletteDefault tStackName
      end if
   end if
end inspectorPositionPalette


on ideResumeStack
   ideSelectedObjectChanged
end ideResumeStack

on ideNewStack
   ideSelectedObjectChanged
end ideNewStack

on ideCloseStack
   ideSelectedObjectChanged
end ideCloseStack

on stackNameChanged pOldName, pNewLongID
   lock screen
   local tStackName
   repeat for each key tKey in inspectorList()
      put kPropertyInspectorPrefix && tKey into tStackName
      if the cLocked of stack tStackName is true and the mode of stack tStackName is not 0 then
         local tCurObj
         put the cSelectedObjects of stack tStackName into tCurObj
         if tCurObj contains ("stack" && quote & pOldName & quote) then
            replace ("stack" && quote & pOldName & quote) with pNewLongID in tCurObj
            set the cLocked of stack tStackName to false
            set the cSelectedObjects of stack tStackName to tCurObj
            set the cLocked of stack tStackName to true
         end if
      end if
   end repeat
   unlock screen
end stackNameChanged

on ideNameChanged pOldName, pNewName, pNewLongID
   # If a stack name changed, we need to check locked inspectors for
   # long id changes
   if word 1 of pNewLongID is "stack" then
      stackNameChanged pOldName, pNewLongID
   end if
   
   ideSelectedObjectChanged
end ideNameChanged

on ideMainstackChanged
   ideSelectedObjectChanged
end ideMainstackChanged

# Sent by the IDE when the selection changed
on ideSelectedObjectChanged
   local tObjects
   put revIDESelectedObjects() into tObjects
   
   local tStack
   put revIDEStackOfObject(line 1 of tObjects) into tStack
   
   if exists(tStack) then
      # If the object is on an inspector stack, lock it
      if the short name of tStack begins with kPropertyInspectorPrefix then
         if the cLocked of tStack is not true then
            dispatch "lockInspector" to tStack
         end if
      end if
   else
      put empty into tObjects
   end if
   
   repeat with x = the number of lines in tObjects down to 1
      if there is not a (line x of tObjects) then
         delete line x of tObjects
      end if
   end repeat
   
   local tStackName
   repeat for each key tKey in inspectorList()
      put kPropertyInspectorPrefix && tKey into tStackName
      if the cLocked of stack tStackName is false and the mode of stack tStackName is not 0 then
         ideInspectObjects tObjects
         exit repeat
      end if
   end repeat
end ideSelectedObjectChanged

function inspectorForObject pObject
   local tStackName
   repeat for each key tKey in inspectorList()
      put kPropertyInspectorPrefix && tKey into tStackName
      if the mode of stack tStackName is not 0 \ 
            and pObject is among the lines of the cSelectedObjects of stack tStackName then
         return tStackName
      end if
   end repeat
   return empty
end inspectorForObject

function absoluteRectOfObject pObjectData
   local tInspector
   put inspectorForObject(pObjectData["object"]) into tInspector
   local tRect
   put the rect of group pObjectData["group"] of stack tInspector into tRect

   # Make sure left of group is left of stack
   put 0 into item 1 of tRect
   
   return revIDERelativeRectToAbsolute(tRect, the long id of stack tInspector)
end absoluteRectOfObject

on highlightObject pObjectData
   lock screen
   local tTargetInspector
   put the long id of stack inspectorForObject(pObjectData["object"]) into tTargetInspector
   dispatch "hiliteFrameItem" to tTargetInspector with pObjectData["section"]
   dispatch "navSelected" to tTargetInspector with pObjectData["section"]
   unlock screen
end highlightObject
