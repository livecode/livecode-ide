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
   inspectorFill
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
         put tSettingsA["For the selected stack file"]["moveSubstacks"]["value"] is "true" into tSubstacks
         break
      case "Mac"
         put tSettingsA["Build for Mac OS X (Intel)"]["MacOSX x86-32"]["value"] into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Windows"
         put tSettingsA["Build for Windows"]["Windows"]["value"] into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Linux"
         break
      case "iOS"
         put tSettingsA["Build for iOS"]["iOS"]["value"] into tBuildFor
         setEnabledOfSection tSettingsA, tBuildFor
         break
      case "Android"
         put tSettingsA["Build for Android"]["android"]["value"] into tBuildFor
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
