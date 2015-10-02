script "revStandaloneSettingsNew"
local sSelectedStack

on preOpenStack
   local tSelected
   put revIDESelectedObjects() into tSelected
   if tSelected is empty then
      exit preOpenStack
   end if
   
   put revIDEStackOfObject(line 1 of tSelected) into sSelectedStack
   
   if the cRevStandaloneSettings of sSelectedStack is empty then
      dispatch "revDefaultStandaloneSettings" to stack "revSBLibrary" with sSelectedStack
   end if
   
   inspectorTitleUpdate
   
   # Set the inspector behaviour
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of me
end preOpenStack

on openStack   
   lock screen
   # Register of IDE messages
   revIDESubscribe "ideSelectedObjectChanged"
   inspectorMessagesRegister
   
   set the navigationDisplayStyle of me to "names"
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEStandaloneSettingsInfo()
   
   set the visible of me to true
   unlock screen
end openStack

on closeStack
   ## Unsubscribe from all messges
   inspectorMessagesDeRegister
   revIDEUnsubscribe "ideNameChanged"
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

private on inspectorTitleUpdate
   if sSelectedStack is empty or not exists(sSelectedStack) then 
      set the title of me to "No stack selected"
   else
      set the title of me to the name of sSelectedStack
   end if
end inspectorTitleUpdate

#####################
##### MESSAGES #####
#####################

# Sent by an editor when a property value is being changed
on editorValueChanged pProperty, pValue, pLockUpdates
   revIDEStandaloneSettingsSet sSelectedStack, pProperty, pValue
   inspectorFill
end editorValueChanged

on ideNameChanged
   ideSelectedObjectChanged
end ideNameChanged

on ideInspectObjects pStack
   put pStack into sSelectedStack
   
   if the cRevStandaloneSettings of sSelectedStack is empty then
      dispatch "revDefaultStandaloneSettings" to stack "revSBLibrary" with sSelectedStack
   end if
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEStandaloneSettingsInfo()
   inspectorTitleUpdate
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
   # Timing the performance of the inspector
   local tStartTime
   put the milliseconds into tStartTime
   
   # Get the selected objects
   local tSelectedStack
   put revIDEStackOfObject(line 1 of revIDESelectedObjects()) into tSelectedStack
   if tSelectedStack is sSelectedStack then exit ideSelectedObjectChanged
   if tSelectedStack is empty then
      inspectorClear
      exit ideSelectedObjectChanged
   end if
   
   ideInspectObjects tSelectedStack
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
   local tSettingsA, tSectionName
   put inspectorSectionGetName() into tSectionName
   put revIDEStandaloneSettings(sSelectedStack, tSectionName) into tSettingsA
   
   # Handle the disabled / enabled state of editors
   local tBuildFor
   switch tSectionName
      case "General"
         local tInclusions
         put tSettingsA["Inclusions"]["inclusions"]["value"] is "select" into tInclusions
         set the rowEnabled of group "Inclusion Options" of me to tInclusions
         set the rowEnabled of group "Script Libraries" of me to tInclusions
         set the rowEnabled of group "Database Drivers" of me to tInclusions
         
         // TODO : Property profiles
         break
      case "Stacks"
         local tSubstacks
         put tSettingsA["For the selected stack file"]["moveSubstacks"]["value"] is true into tSubstacks
         break
      case "Mac"
         put tSettingsA["Build for Mac OS X (Intel)"]["MacOSX x86-32"]["value"] is true into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Windows"
         put tSettingsA["Build for Windows"]["Windows"]["value"] is true into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Linux"
         break
      case "iOS"
         put tSettingsA["Build for iOS"]["iOS"]["value"]  is true into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Android"
         put tSettingsA["Build for Android"]["android"]["value"] is true into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      default
   end switch
   return tSettingsA
end displayData

on setEnabledOfSection pDataA, pValue
   repeat for each key tKey in pDataA
      if tKey begins with "Build for" then
         next repeat
      end if
      set the rowEnabled of group tKey of me to pValue
   end repeat
end setEnabledOfSection

getProp viewColumns [pSection]
   switch pSection
      case "iOS"
         return 3
      case "Android"
         return 2
      default
         return 1
   end switch
end viewColumns

getProp showSubSections [pSection]
   return true
end showSubSections

function inspectorSectionIcon pSection
   return revIDEStandaloneSectionNameToIconName(pSection)
end inspectorSectionIcon

function revStandaloneSettingsStackFiles
   
end revStandaloneSettingsStackFiles

function revStandaloneSettingsRelativePath pPath
   return revIDERelativeStackPath(sSelectedStack, pPath)
end revStandaloneSettingsRelativePath

on inspectorAddActions
   addFrameItem "inspectorTarget", "header", "action", "Select stack to inspect", "bullseye", "bullseye", "inspectorTreeMenuDisplay", the long id of me 
end inspectorAddActions

on inspectorTreeMenuDisplay
   local tDefaultStack
   local tOpenStacks, tStacks
   
   global gREVShowStacks
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
   
   set the defaultStack to tDefaultStack
   
   if gREVShowStacks then put the openStacks into tOpenStacks
   else put revFilterStacksList(the openStacks) into tOpenStacks
   put empty into tStacks
   local tCheck
   repeat for each line l in tOpenStacks
      if the long id of stack l is sSelectedStack
      then put "!c" into tCheck
      else put "!n" into tCheck
      put tCheck & menuitemEscape(l, false) & cr after tStacks
   end repeat
   delete last char of tStacks
   sort lines of tStacks by item 2 of each
   
   set the text of button "inspectMenu" of this stack to tStacks
   
   popup button "inspectMenu" of this stack at the mouseloc
end inspectorTreeMenuDisplay

on menuPick pWhich
   global gREVTemplateMasterName, gREVStacksList
   local tNewStack
   put word 1 to -1 of item -1 of pWhich into tNewStack
   try
      ideInspectObjects the long id of stack tNewStack
   catch tError
      answer error "There was an error selecting stack" && tNewStack
   end try
   break
end menuPick

private function menuitemEscape pItem, pFirst
   -- MW-2011-04-08: [[ Bug 9496 ]] Make sure we escape '!!' properly.
   replace "!" with "!!" in pItem
   replace "&" with "&&" in pItem
   replace "(" with "((" in pItem
   return pItem
end menuitemEscape

getProp showMultiPropLabels
   return true
end showMultiPropLabels
