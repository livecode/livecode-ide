script "propertyinspectorben"
# sPropertyInfo stores all the data about the properties to be inpspected
local sPropertyInfo
local sSelectedObjects
local sInspectorLock

on preOpenStack
   put false into sInspectorLock
   put empty into sSelectedObjects
   put empty into sSelectedObjects
   
   # Set the palette frame behaviour
   set the behavior of me to revIDEFrameBehavior()
   
   # Open all the editors
   local tEditorsFolder, tStackFiles
   set the itemdel to "/"
   put item 1 to -2 of the filename of me & "/editors/" into tEditorsFolder
   set the defaultfolder to tEditorsFolder
   set the itemdel to "."
   repeat for each line tFile in the files
      if char 1 of tFile is "." then next repeat
      
      if tStackfiles is empty then
         put item 1 to -2 of tFile &comma&tEditorsFolder&tFile into tStackFiles
      else
         put return & item 1 to -2 of tFile &comma& tEditorsFolder&tFile after tStackFiles
      end if
   end repeat
   set the stackfiles of me to tStackFiles
   
   # Register of IDE messages
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "idePreferenceChanged:idePropertyInspector_labels"
   inspectorMessagesRegister
   
   //addFrameItem "inspect","header", "action", "Inspect Menu", "f0e8", "f0e8","inspectorTreeMenuDisplay", the long id of me
   addFrameItem "lock","header", "toggle", "Lock Inspector", "f13e", "f023","inspectorLock", the long id of me
   
   # Render the inspector for the given selected object
   ideSelectedObjectChanged
   set the visible of me to true
end preOpenStack

on resizeStack
   inspectorLayout
end resizeStack

on closeStack
   ## Unsubscribe from all messges
   inspectorMessagesDeRegister
   revIDEUnsubscribe "idePreferenceChanged:idePropertyInspector_labels"
   revIDEUnsubscribe "ideNameChanged"
end closeStack

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

on inpectorOpenEditor pEditor
   # Check if the stack is already open
   if there is a stack pEditor then exit inpectorOpenEditor
   
   # Find the file for the editor
   local tEditorStackPath
   put revIDEPaletteResourcePath("editors/" & pEditor & ".livecode") into tEditorStackPath
   
   # open editor stack if it exists
   if there is a file tEditorStackPath then 
      go invisible stack tEditorStackPath
   end if
end inpectorOpenEditor

on inspectorLock pState
   if pState is false then
      put false into sInspectorLock
      ideSelectedObjectChanged
   else
      put true into sInspectorLock
   end if
end inspectorLock

# Generate inspector
private on inspectorGenerate
   lock screen
   
   local tSelectedSection
   put inspectorSectionGet() into tSelectedSection
   
   local tPropertyData
   put sPropertyInfo[tSelectedSection] into tPropertyData
   
   set the margins of the templategroup to 0
   set the visible of the templategroup to false
   
   set the behavior of the templategroup to the long ID of stack revIDEPaletteResourcePath("behaviors/rowbehavior.livecodescript")
   
   set the traversalon of the templatefield to false
   set the threed of the templatefield to false
   set the showborder of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the textalign of the templatefield to right
   set the opaque of the templatefield to false
   set the height of the templatefield to 21
   set the locktext of the templatefield to true
   set the width of the templatefield to 1000
   
   lock messages
   if there is not a group "template" then
      create group "template"
      create field "label" in group "template"
   end if
   unlock messages
   
   local tElement
   repeat with x = 1 to the number of elements in tPropertyData["grouplist"]
      put tPropertyData["grouplist"][x] into tElement
      if tElement["label"] is empty then next repeat
      lock messages
      copy group "template" to me
      set the name of it to tElement["label"]
      show group tElement["label"] of me
      unlock messages
      
      local tName
      put the short name of group tElement["label"] of me into tName
      if exists(group tElement["label"] of me) then
         set the rowLabel of group tElement["label"] of me to tElement["label"]
         
         local tPropList, tProperty
         repeat with y = 1 to the number of elements in tElement["proplist"]
            put tElement["proplist"][y] into tProperty
            dispatch "propertyRegister" to group tElement["label"] of me with tProperty
            
            # Build the list of properties to display in the tooltip for the row
            if tPropList is empty then
               put tProperty["property_name"] into tPropList
            else
               put return & tProperty["property_name"] after tPropList
            end if
         end repeat
         
         # Set the tooltip for the row
         set the rowTooltip of group tElement["label"] of me to tPropList
      end if
      put empty into tPropList
   end repeat
   reset the templatefield
   reset the templategroup
   
   unlock screen
end inspectorGenerate

private on inpsectorNavigationGenerate
   lock screen
   # Clear the current frame data
   clearFrameNavigationData
   
   # Add all the navigation elements
   repeat for each element tSection in sPropertyInfo
      addFrameItem tSection["label"],"header", "navigation", tSection["label"], revIDEFontawesomeNameToCodepoint(tSection["label"]), revIDEFontawesomeNameToCodepoint(tSection["label"]),"inspectorSectionChanged", the long id of me, tSection["label"]
   end repeat
   
   # Highlight the selected section
   hiliteFrameItem inspectorSectionGetName()
   unlock screen
end inpsectorNavigationGenerate

# Layout inspector
private on inspectorLayout
   local tTop, tLeft, tWidth, tContentRect, tMargin, tPadding, tEditorPadding
   put the contentRect of me into tContentRect
   put the palettePadding of me into tMargin
   put the palettePadding of me into tPadding
   put tPadding / 2 into tEditorPadding
   
   put item 1 of tContentRect + tMargin into tLeft
   put item 2 of tContentRect + (tMargin * 2) into tTop
   put (item 3 of tContentRect - item 1 of tContentRect) - (2* tMargin) into tWidth
   
   local tSelectedGroup
   put inspectorSectionGet() into tSelectedGroup
   
   put empty into msg
   lock screen
   repeat for each element tElement in sPropertyInfo[tSelectedGroup]["grouplist"]
      put tTop & return after msg
      if there is a group tElement["label"] of me then
         lock messages
         set the lockloc of  group tElement["label"] of me to true
         set the width of group tElement["label"] of me to tWidth
         set the topleft of group tElement["label"] of me to tLeft,tTop
         unlock messages
         dispatch "rowResize" to group tElement["label"] of me
         
         local tHeight
         put the editorHeight of group tElement["label"] of me into tHeight
         if tHeight > 0 then
            add tHeight + tEditorPadding to tTop
         else
            lock messages
            set the height of group tElement["label"] of me to the formattedheight of group tElement["label"] of me
            set the topleft of group tElement["label"] of me to tLeft,tTop
            unlock messages
            add the height of group tElement["label"] of me + tEditorPadding to tTop
         end if
      end if
   end repeat
   
   lock messages
   local tStackTop
   put the top of me into tStackTop
   set the minheight of me to tTop + (tMargin * 2)
   set the maxheight of me to tTop + (tMargin * 2)
   set the height of me to tTop + (tMargin * 2)
   set the top of me to tStackTop
   unlock messages
   unlock screen
end inspectorLayout

# Sent when the user changes the section
on inspectorSectionChanged pSection
   # Timing log
   local tStartTime
   put the milliseconds into tStartTime
   
   # Check if the section is different
   if inspectorSectionGetName() is pSection then exit inspectorSectionChanged
   
   lock screen
   # Set the section
   inspectorSectionSet pSection
   
   # Clear the current inspector
   inspectorClear
   
   # Generate the controls for group
   inspectorGenerate
   
   # Set values for all editors
   inspectorFill
   
   # Layout again as values will not doubt have effected teh size of some elements
   inspectorLayout
   
   # Layout
   dispatch "resizeStack" to me
   unlock screen
   
   //put "Last inspector update took" && the milliseconds - tStartTime && "milliseconds" & return after msg
end inspectorSectionChanged

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
   revSetGeometryObject revIDESelectedObjects()
   
   put revIDESelectedObjects() into tObjects
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
      
      # TH 14/12/07 - This line causes names containing dashes to be incorrectly displayed in the property
      # inspector, haven't found any adverse efffects of removing it.
      --replace "-" with empty in tControls
      
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
   
   # TH 14/12/07 - This line causes names containing dashes to be incorrectly displayed in the property
   # inspector, haven't found any adverse efffects of removing it.
   --replace "-" with empty in tControls
   
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
            & cr & tProfiles2 & cr & "-" & cr & "Edit Script" & cr & tSendMessageList \
            & cr & "-" & cr & tLockInspector
   else
      set the text of button "inspectMenu" of this stack to tControls & cr & tab & "-" & cr & tCards \
            & cr & tab & "-" & cr & tStacks & cr & "-" \
            & cr & tProfiles2 & cr & "-" & cr & "Edit Script" & cr & tSendMessageList \
            & cr & "-" & cr & tLockInspector
   end if
   
   popup button "inspectMenu" of this stack at the loc of field "inspect" of group "background" of this stack
end inspectorTreeMenuDisplay

on menuPick pPick
   set the itemdel to "|"
   switch item 1 of pPick
      case "inspect"
         local tObject
         put the last item of pPick into tObject
         set the itemdel to "["
         put word 1 to -1 of item 1 of tObject into tObject
         set the defaultstack to this stack
         do "select" && tObject && "of this stack"
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

private on inspectorFill
   # store the selected object and position
   lock screen
   local tProperties
   put revIDEPropertiesOfSection(sSelectedObjects, inspectorSectionGetName()) into tProperties
   
   repeat for each key tRow in tProperties
      if there is a group tRow of me then
         set the rowData of group tRow of me to tProperties[tRow]
      end if
   end repeat
   unlock screen
end inspectorFill

private on inspectorClear
   lock screen
   lock messages
   repeat while the number of groups of card 1 me is not 0
      delete group 1 of card 1 of me
   end repeat
   
   rowLabelWidthSet 0
   unlock messages
   unlock screen
end inspectorClear

local sSelectedSection
private on inspectorSectionSet pSection
   put pSection into sSelectedSection
end inspectorSectionSet

private function inspectorSectionGet
   repeat for each key tIndex in sPropertyInfo
      if sPropertyInfo[tIndex]["label"] is sSelectedSection then
         return tIndex
      end if
   end repeat
   return 1
end inspectorSectionGet

private function inspectorSectionGetName
   if sSelectedSection is not empty then 
      return sSelectedSection
   else
      return sPropertyInfo[1]["label"]
   end if
end inspectorSectionGetName

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
   # If the inspector is locked and a selected object changed message comes through
   # ignore it
   if sInspectorLock is true and exists(line 1 of sSelectedObjects) then 
      exit ideSelectedObjectChanged
   else
      put false into sInspectorLock
   end if
   
   # Timing the performance of the inspector
   local tStartTime
   put the milliseconds into tStartTime
   
   # Get the selected objects
   local tSelectedObjects
   put revIDESelectedObjects() into tSelectedObjects
   if tSelectedObjects is sSelectedObjects then exit ideSelectedObjectChanged
   if tSelectedObjects is empty then
      inspectorClear
      exit ideSelectedObjectChanged
   end if
   
   # Unsubscribe the the objects previously 
   revIDEUnsubscribe "idePropertyChanged","",sSelectedObjects
   revIDESubscribe "idePropertyChanged",tSelectedObjects
   
   put tSelectedObjects into sSelectedObjects
   
   lock screen
   
   # Get a list of the properties and groups we'll be displaying
   put revIDEPropertiesInfo(sSelectedObjects) into sPropertyInfo
   
   # Clear the current inspector
   inspectorClear
   
   # Setup the header
   inpsectorNavigationGenerate
   
   # Generate the controls for group
   inspectorGenerate
   
   # Set values for all editors
   inspectorFill
   
   # Set the title of the inspector
   inspectorTitleUpdate
   
   # Layout
   send "resizeStack" to me
   
   unlock screen
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

#####################
#### PROPERTIES #####
#####################

# Whether or not we display labels or 
on inspectorLabelTypeSet pType
   # Check if the value has changed
   
   # Repeat through the rows and set the label to the right value
   
   # Layout to adjust the width of the labels
end inspectorLabelTypeSet

function inspectorLabelTypeGet
   # Return the label type
end inspectorLabelTypeGet

local sRowLabelWidth
function rowlabelWidth
   if sRowLabelWidth <= 0 then
      put rowLabelWidthCalculate() into sRowLabelWidth
      if sRowLabelWidth is not a number then
         rowLabelWidthSet 100
      end if
   end if
   return sRowLabelWidth
end rowlabelWidth

on rowLabelWidthSet pValue
   put pValue into sRowLabelWidth
end rowLabelWidthSet

private function rowLabelWidthCalculate
   local tMaxWidth, tLabelWidth
   repeat with x = 1 to the number of groups of me
      put the rowLabelWidth of group x of me into tLabelWidth
      if tLabelWidth > tMaxWidth then
         put tLabelWidth into tMaxWidth
      end if
   end repeat
   return tMaxWidth
end rowLabelWidthCalculate


