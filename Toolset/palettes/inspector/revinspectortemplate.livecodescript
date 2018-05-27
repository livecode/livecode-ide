script "revInspectorTemplate"
local sSelectedObjects, sObjectTypes
local sInspectorLock
on preOpenStack
   put false into sInspectorLock
   put revIDESelectedObjects() into sSelectedObjects
   # Keep track of the object 'types' in case they are changed via PI
   put ideObjectTypesFromObjectList(sSelectedObjects) into sObjectTypes
   revIDESubscribe "idePropertyChanged",sSelectedObjects
   inspectorTitleUpdate
   inspectorSetLabelsPreference
   
   # Set the inspector behaviour
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of me
end preOpenStack

on openStack   
   lock screen
   
   # Register of IDE messages
   revIDESubscribe "idePreferenceChanged:idePropertyInspector_labels"
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEPropertiesInfo(sSelectedObjects)
   unlock screen
   
   set the visible of me to true
end openStack

on closeStack
   ## Unsubscribe from all messages
   revIDEUnsubscribe "idePreferenceChanged:idePropertyInspector_labels"
   
   set the cSelectedObjects of me to empty
   
   # Unlock
   put false into sInspectorLock
end closeStack

on resizeStack
   resizeInspector
end resizeStack

#####################
#### PI PROPERTIES #####
#####################
setProp cSelectedObjects pSelectedObjects
   if pSelectedObjects is sSelectedObjects then 
      exit cSelectedObjects
   end if
   
   if the cLocked of me then
      exit cSelectedObjects
   end if
   
   # Unsubscribe the the objects previously 
   revIDEUnsubscribe "idePropertyChanged","",sSelectedObjects
   
   lock screen
   
   inspectorClear
   
   put pSelectedObjects into sSelectedObjects
   
   # Keep track of the object 'types' in case they are changed via PI
   put ideObjectTypesFromObjectList(pSelectedObjects) into sObjectTypes
   
   if pSelectedObjects is empty then 
      inspectorTitleUpdate
      set the inspectorData of me to empty
      exit cSelectedObjects
   end if
   
   revIDESubscribe "idePropertyChanged", pSelectedObjects
   
   # Get a list of the properties and groups we'll be displaying
   set the inspectorData of me to revIDEPropertiesInfo(pSelectedObjects)
   
   inspectorTitleUpdate
   
   get pSelectedObjects is not revIDESelectedObjects()
   put it into sInspectorLock
   toggleFrameItem "inspectorLock", it
   
   unlock screen
   
   set the visible of me to true
end cSelectedObjects

getProp cSelectedObjects
   return sSelectedObjects
end cSelectedObjects

setProp cLocked pState
   if pState is false then
      put false into sInspectorLock
      send "ideSelectedObjectChanged" to stack "revInspector" in 0 millisecs
   else
      put true into sInspectorLock
   end if
   toggleFrameItem "inspectorLock", pState is true
end cLocked

getProp cLocked
   return sInspectorLock
end cLocked

#####################
#### PI FUNCTIONS #####
#####################

on inspectorLock pState
   put pState into sInspectorLock
   if pState is false then
      send "ideSelectedObjectChanged" to stack "revInspector" in 0 millisecs
   end if
end inspectorLock

on lockInspector
   if the cLocked of me is false then
      dispatch "actionSelected" to me with "inspectorLock"
   end if
end lockInspector

local sPropertyChangedMsg

on idePropertyChanged
   cancel sPropertyChangedMsg
   send "__IdePropertyChanged" to me in 200 milliseconds
   put the result into sPropertyChangedMsg
end idePropertyChanged

on __IdePropertyChanged
   lock screen
   # Check if the object 'types' have been changed via PI
   local tNewTypes
   put ideObjectTypesFromObjectList(sSelectedObjects) into tNewTypes
   if sObjectTypes is not tNewTypes then
      set the inspectorData of me to revIDEPropertiesInfo(sSelectedObjects)
      put tNewTypes into sObjectTypes
   else
      inspectorFill
      inspectorTitleUpdate
   end if
   unlock screen
end __IdePropertyChanged

on inspectorTreeMenuDisplay
   local tObjects, tStack, tDefaultStack
   local tHandlers, tSendMessageList, tLockInspector, tFocusedObject
   put sSelectedObjects into tObjects
   
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
   
   local tInspect
   put "Inspect" & cr into tInspect
   
   put revIDEObjectSelectionMenu(tObjects, "") after tInspect
   
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
   
   set the text of button "inspectMenu" of this stack to tInspect & return & "-" \
         & return & tSendMessageList
   
   popup button "inspectMenu" of this stack at the mouseloc
   
   set the defaultStack to tDefaultStack
end inspectorTreeMenuDisplay

on menuPick pWhich
   local tFocusedObject, tObjects, tStack
   put the long id of the focusedObject into tFocusedObject
   if word 1 of tFocusedObject is "field" \
         and revIDEStackOfObject(tFocusedObject) is the short name of this stack
   then send "closeField" to tFocusedObject
   
   put sSelectedObjects into tObjects
   set the itemDel to "|"
   switch item 1 of pWhich
      case "Inspect"
         revIDEInspectObjects the last item of pWhich
         break
      case "Send Message"
         revIDESendMessageToObject item 2 of pWhich, tObjects
         break
   end switch
end menuPick

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

on inspectorEditScript
   revIDEEditScriptOfObjects sSelectedObjects
end inspectorEditScript

#####################
##### MESSAGES #####
#####################

# Sent by an editor when a property value is being changed
on editorValueChanged pProperty, pValue, pLockUpdates
   revIDEPropertySet sSelectedObjects, pProperty, pValue
end editorValueChanged

function editorStoredValue pProperty
   return revIDEPropertyRetrieveStored(sSelectedObjects, pProperty)
end editorStoredValue

on editorStoreValue pProperty, pValue
   revIDEPropertyStore sSelectedObjects, pProperty, pValue
end editorStoreValue

on idePreferenceChanged pPreference
   switch pPreference
      case "idePropertyInspector_labels"
         inspectorSetLabelsPreference
         inspectorChanged
         break
   end switch
end idePreferenceChanged
   
command inspectorSetLabelsPreference
   local tValue
   put revIDEGetPreference("idePropertyInspector_labels") into tValue
   global gRevLanguageNames
   put tValue into gRevLanguageNames
   set the cLanguageNames of cd 1 of stack "revPreferences" to tValue
end inspectorSetLabelsPreference

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
   if sSelectedObjects is not empty then
      addFrameItem "inspectorEditScript","header", "action", "Edit script", "lc-edit-script", "lc-edit-script","inspectorEditScript", the long id of me
   end if
   addFrameItem "inspectorLock","header", "toggle", "Lock inspector", "unlock", "lock","inspectorLock", the long id of me
   addFrameItem "idePropertyInspector_labels", "header", "preference", "Property Labels", "enum","false:Description of option,true:Name of LiveCode property", "inspectorPropLabelsPrefChanged", the long id of me
end inspectorAddActions

on inspectorPropLabelsPrefChanged pPref, pValue
   revIDESetPreference pPref, pValue
end inspectorPropLabelsPrefChanged

getProp showMultiPropLabels
   return false
end showMultiPropLabels

on rawKeyDown pKeyNum
   switch pKeyNum
      case "65360"
         ## home
         if the target contains "field" then pass rawKeyDown
         set the vScroll of group "inspector" of me to 0
         break
      case "65367"
         ## end
         if the target contains "field" then pass rawKeyDown
         set the vScroll of group "inspector" of me to \
               the formattedHeight of group "inspector" of me - the height of group "inspector" of me 
         break
      case "65365"
         set the vScroll of group "inspector" of me to \
               max(0, the vScroll of group "inspector" of me - 50)
         break
      case "65366"
         set the vScroll of group "inspector" of me to \
               min(the formattedHeight of group "inspector" of me - the height of group "inspector" of me, \
               the vScroll of group "inspector" of me + 50)
         break
      case "65309"
         set the vScroll of group "inspector" of me to \
               max(0, the vScroll of group "inspector" of me - 5)
         break
      case "65308"
         set the vScroll of group "inspector" of me to \
               min(the formattedHeight of group "inspector" of me - the height of group "inspector" of me, \
               the vScroll of group "inspector" of me + 5)
         break
      default
         pass rawKeyDown
   end switch
end rawKeyDown

