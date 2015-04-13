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
   set the behavior of me to revIDEInspectorBehavior()
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
end editorValueChanged

on ideNameChanged
   ideSelectedObjectChanged
end ideNameChanged

on ideInspectObjects
   ideSelectedObjectChanged
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
   
   put tSelectedStack into sSelectedStack
   
   if the cRevStandaloneSettings of sSelectedStack is empty then
      dispatch "revDefaultStandaloneSettings" to stack "revSBLibrary" with sSelectedStack
   end if
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEStandaloneSettingsInfo()
   inspectorTitleUpdate
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
   return revIDEStandaloneSettings(sSelectedStack, inspectorSectionGetName())
end displayData

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
