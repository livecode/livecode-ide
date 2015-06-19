script "revInspector"
local sSelectedObjects
local sInspectorLock
on preOpenStack
   put false into sInspectorLock
   put revIDESelectedObjects() into sSelectedObjects
   revIDESubscribe "idePropertyChanged",sSelectedObjects
   inspectorTitleUpdate
    
   # Set the inspector behaviour
   set the behavior of me to revIDEInspectorBehavior()
end preOpenStack

on openStack   
   lock screen
   # Register of IDE messages
   revIDESubscribe "idePreferenceChanged:idePropertyInspector_labels"
   inspectorMessagesRegister
   
   //addFrameItem "inspect","header", "action", "Inspect Menu", "f0e8", "f0e8","inspectorTreeMenuDisplay", the long id of me
   addFrameItem "lock","header", "toggle", "Lock Inspector", "unlock", "lock","inspectorLock", the long id of me
   set the navigationDisplayStyle of me to "icons"
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEPropertiesInfo(sSelectedObjects)
   
   set the visible of me to true
   unlock screen
end openStack

on closeStack
   ## Unsubscribe from all messges
   inspectorMessagesDeRegister
   revIDEUnsubscribe "idePreferenceChanged:idePropertyInspector_labels"
   revIDEUnsubscribe "ideNameChanged"
   
   revIDEStopInspecting
end closeStack

on resizeStack
   resizeInspector
end resizeStack

#####################
#### PI FUNCTIONS #####
#####################

on inspectorMessagesRegister
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "ideResumeStack"
   revIDESubscribe "ideNewStack"
   revIDESubscribe "ideInspectObjects"
   revIDESubscribe "ideCloseStack"
   revIDESubscribe "ideNameChanged"
end inspectorMessagesRegister

on inspectorMessagesDeRegister
   revIDEUnsubscribe "ideSelectedObjectChanged"
   revIDEUnsubscribe "ideResumeStack"
   revIDEUnsubscribe "ideInspectObjects"
   revIDEUnsubscribe "ideNewStack"
   revIDEUnsubscribe "ideCloseStack"
   revIDEUnsubscribe "ideNameChanged"
end inspectorMessagesDeRegister 

on inspectorLock pState
   if pState is false then
      put false into sInspectorLock
      ideSelectedObjectChanged
   else
      put true into sInspectorLock
   end if
end inspectorLock

on idePropertyChanged
   lock screen
   inspectorFill
   inspectorTitleUpdate
   unlock screen
end idePropertyChanged

on inspectorTreeMenuDisplay
   local tObjects, tStack, tDefaultStack, tControls, tNumControls, tCheck
   local tControlsArray, tList, tControlsList, tCards, tNumCards, tOpenStacks, tStacks, tProfiles1
   local tCurrentProfile, tProfiles2, tHandlers, tSendMessageList, tLockInspector, tFocusedObject
   
   global gREVShowStacks
   revSetGeometryObject sSelectedObjects
   
   put sSelectedObjects into tObjects
   put revTargetStack(line 1 of tObjects) into tStack
   put the defaultStack into tDefaultStack
   
   # Create the button that we're going to popup on this stack
   set the defaultstack to me
   lock messages
   if there is a button "inspectMenu" of me then delete button "inspectMenu" of me
   create button "inspectMenu"
   set the style of button "inspectMenu" of me to "menu"
   set the menumode of button "inspectMenu" of me to "popup"
   set the visible of button "inspectMenu" of me to false
   set the script of button "inspectMenu" of me to "on menuPick pItem;send" && quote & "menuPick pItem" & quote && "to this stack; end menuPick"
   unlock messages
   
   # Generate the inspect 
   set the defaultStack to tStack
   put "Inspect" & cr into tControls
   put the num of controls into tNumControls
   if tNumControls > 1000 then 
      put tab & "(Too many controls to display" && "[" & tNumControls & "]" after tControls
   else
      repeat with i = 1 to tNumControls
         if the long id control i is among the lines of tObjects 
         then put "!c" into tCheck
         else put "!n" into tCheck
         put tCheck & tab & menuitemEscape(the name of control i, false) && "[" & i & "]" & cr after tControls
      end repeat
      delete last char of tControls
      set the itemDel to tab
      sort lines of tControls numeric by item 2 of each
      
      if the number of lines in tControls > 20 then
         repeat for each line l in tControls -- sort into individual object types
            put tab & tab & l & cr after tControlsArray[word 2 of l]
         end repeat
         put keys(tControlsArray) into tList
         sort lines of tList
         repeat for each line l in tList
            delete last char of tControlsArray[l] -- trailing return in each element
            put tab & l & "s" & cr & tControlsArray[l] & cr after tControlsList
         end repeat
         delete char 1 to 5 of tControlsList
      end if
   end if
   
   put empty into tCards
   put the num of cards in this stack into tNumCards
   repeat with i = 1 to tNumCards
      if the long id of cd i is among the lines of tObjects
      then put "!c" into tCheck
      else put "!n" into tCheck
      put tCheck & tab & tab & menuitemEscape(the short name of card i, false) && "[" & i & "]" & cr after tCards
   end repeat
   delete last char of tCards
   sort lines of tCards by item 2 of each

   put tab & "Card" & cr before tCards
   
   set the defaultStack to tDefaultStack
   
   if gREVShowStacks then put the openStacks into tOpenStacks
   else put revFilterStacksList(the openStacks) into tOpenStacks
   put empty into tStacks
   repeat for each line l in tOpenStacks
      if the long id of stack l is among the lines of tObjects
      then put "!c" into tCheck
      else put "!n" into tCheck
      put tCheck & tab & tab & menuitemEscape(l, false) & cr after tStacks
   end repeat
   delete last char of tStacks
   sort lines of tStacks by item 2 of each
   if tStacks is empty then put "(" & tab & "Stack" into tStacks
   else put tab & "Stack" & cr before tStacks
   
   if the num of lines in tObjects = 1 then
      put the cREVGeneral["handlerList"] of tObjects into tHandlers
      if the cSort of stack "revPreferences" then sort lines of tHandlers
      if the num of words in line 1 of tHandlers is 0 then
         put "(Send Message" into tSendMessageList
      else
         put "Send Message" & cr into tSendMessageList
         repeat for each line l in tHandlers
            put tab & l & cr after tSendMessageList
         end repeat
         delete last char of tSendMessageList
      end if
   else put "(Send Message" into tSendMessageList
   
   if the cREVLinked of this stack is not empty
   then put "!cLock Inspector" into tLockInspector
   else put "!nLock Inspector" into tLockInspector
   
   if the number of lines in tControls > 20 then 
      replace cr with cr & tab & tab in tCards
      replace cr with cr & tab & tab in tStacks
      set the text of button "inspectMenu" of this stack to tControlsList & tab & "-" & cr & tCards \
            & cr & tab & "-" & cr & tStacks & cr & "-" \
            & cr & "-" & cr & "Edit Script" & cr & tSendMessageList
   else
      set the text of button "inspectMenu" of this stack to tControls & cr & tab & "-" & cr & tCards \
            & cr & tab & "-" & cr & tStacks & cr & "-" \
            & cr & "-" & cr & "Edit Script" & cr & tSendMessageList
   end if
   
   popup button "inspectMenu" of this stack at the mouseloc
end inspectorTreeMenuDisplay

on menuPick pWhich
   local tFocusedObject, tObjects, tStack
   put the long id of the focusedObject into tFocusedObject
   if word 1 of tFocusedObject is "field" \
         and revIDEStackOfObject(tFocusedObject) is the short name of this stack
   then send "closeField" to tFocusedObject
   
   put sSelectedObjects into tObjects
   put revIDEStackOfObject(line 1 of tObjects) into tStack
   set the itemDel to "|"
   switch item 1 of pWhich
      case "Inspect"
         switch item 2 of pWhich
            case "Card"
               local tNum
               put char 2 to -2 of word -1 of item -1 of pWhich into tNum
               try
                  if the mode of stack tStack is 0 \
                        or the num of this cd of stack tStack is not tNum
                  then go cd tNum of stack tStack
                  revIDEInspectObjects the long id of cd tNum of stack tStack
               catch tError
                  answer error "There was an error selecting" && the name of cd tNum of stack tStack
               end try
               break
            case "Stack"
               local tNewStack
               put word 1 to -1 of item -1 of pWhich into tNewStack
               try
                  revIDEInspectObjects the long id of stack tNewStack
               catch tError
                  answer error "There was an error selecting stack" && tNewStack
               end try
               break
            default
               put char 2 to -2 of word -1 of item -1 of pWhich into tNum
               try
                  if the mode of stack tStack is 0
                  then go stack tStack        
                  revIDEInspectObjects the long id of control tNum of this cd of stack tStack
               catch tError
                  answer error "There was an error selecting" \
                        && the name of control tNum of this cd of stack tStack
               end try
               break
         end switch
         break
      case "Send Message"
         revIDESendMessageToObject item 2 of pWhich, tObjects
         break
      case "Edit Script"
         revIDEEditScriptOfObjects tObjects 
         break
   end switch
end menuPick

private function menuitemEscape pItem, pFirst
   -- MW-2011-04-08: [[ Bug 9496 ]] Make sure we escape '!!' properly.
   replace "!" with "!!" in pItem
   replace "&" with "&&" in pItem
   replace "(" with "((" in pItem
   return pItem
end menuitemEscape

private on inspectorTitleUpdate
   if sSelectedObjects is empty then 
      set the title of me to "No object selected"
   else if the number of lines of sSelectedObjects is 1 then
      if exists(sSelectedObjects) then
         set the title of me to the name of sSelectedObjects && "(id"&& the id of sSelectedObjects&")"
      end if
   else
      set the title of me to "Multiple objects"
   end if
end inspectorTitleUpdate

#####################
##### MESSAGES #####
#####################

# Sent by an editor when a property value is being changed
on editorValueChanged pProperty, pValue, pLockUpdates
   revIDEPropertySet sSelectedObjects, pProperty, pValue
end editorValueChanged

on ideNameChanged
   ideInspectObjects
end ideNameChanged

on ideInspectObjects pObjects
   # If the inspector is locked and a selected object changed message comes through
   # ignore it
   if sInspectorLock is true and exists(line 1 of sSelectedObjects) then 
      exit ideInspectObjects
   else
      put false into sInspectorLock
   end if
   
   # Timing the performance of the inspector
   local tStartTime
   put the milliseconds into tStartTime
   
   # Get the selected objects
   local tSelectedObjects
   if pObjects is not empty then
      put pObjects into tSelectedObjects
   else
      put revIDESelectedObjects() into tSelectedObjects
   end if
   if tSelectedObjects is sSelectedObjects then exit ideInspectObjects
   if tSelectedObjects is empty then
      inspectorClear
      exit ideInspectObjects
   end if
   
   lock screen
   # Unsubscribe the the objects previously 
   revIDEUnsubscribe "idePropertyChanged","",sSelectedObjects
   revIDESubscribe "idePropertyChanged",tSelectedObjects
   
   put tSelectedObjects into sSelectedObjects
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEPropertiesInfo(sSelectedObjects)
   inspectorTitleUpdate
   unlock screen
end ideInspectObjects

on ideResumeStack
   ideSelectedObjectChanged
end ideResumeStack

on ideNewStack
   ideSelectedObjectChanged
end ideNewStack

on ideCloseStack
   ideSelectedObjectChanged
end ideCloseStack

# Sent by the IDE when the selection changed
on ideSelectedObjectChanged
   ideInspectObjects revIDESelectedObjects()
end ideSelectedObjectChanged

on idePreferenceChanged pPreference, pValue
   switch pPreference
      case "idePropertyInspector_labels"
         
         break
   end switch
end idePreferenceChanged
   

# Sent by the IDE when a property has changed
on revIDEPropertyChanged
   # Get values for properties in given group
   
   # Set values for all editors
   
   # Layout
end revIDEPropertyChanged

getProp displayData
   return revIDEPropertiesOfSection(sSelectedObjects, inspectorSectionGetName())
end displayData

getProp viewColumns [pSection]
   return 1
end viewColumns

getProp showSubSections [pSection]
   return false
end showSubSections

function inspectorSectionIcon pSection
   return revIDEPropertySectionNameToIconName(pSection)
end inspectorSectionIcon

# Add to header actions/preferences
on inspectorAddActions
   addFrameItem "inspectorTarget", "header", "action", "Select object to inspect", "bullseye", "bullseye", "inspectorTreeMenuDisplay", the long id of me 
end inspectorAddActions

getProp showMultiPropLabels
   return false
end showMultiPropLabels
