script "revInspectorBehavior"
constant kMaxLabelSize = 200

# The inspector data
local sDataA

on chainBehavior
   set the behavior of this me to revIDEFrameBehavior()
end chainBehavior

setProp inspectorData pDataA
   put pDataA into sDataA
   inspectorChanged
end inspectorData

getProp inspectorData
   return sDataA
end inspectorData

before openStack
   # Make sure the stack has inspector behavior and frame behavior
   chainBehavior
   
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
end openStack

on resizeInspector
   inspectorNavigationGenerate
   inspectorLayout
end resizeInspector

on inspectorOpenEditor pEditor
   # Check if the stack is already open
   if there is a stack pEditor then exit inspectorOpenEditor
   
   # Find the file for the editor
   local tEditorStackPath
   put revIDEPaletteResourcePath("editors/" & pEditor & ".livecode") into tEditorStackPath
   
   # open editor stack if it exists
   if there is a file tEditorStackPath then 
      go invisible stack tEditorStackPath
   end if
end inspectorOpenEditor

# Layout inspector
on inspectorLayout
   lock screen
   local tTop, tLeft, tWidth, tHeight, tContentRect, tMargin, tPadding, tEditorPadding
   put the contentRect of me into tContentRect
   put the palettePadding of me into tMargin
   put the palettePadding of me into tPadding
   put tPadding / 2 into tEditorPadding
   
   put item 1 of tContentRect + tMargin into tLeft
   put item 2 of tContentRect + (tMargin * 2) into tTop
   put (item 3 of tContentRect - item 1 of tContentRect) - (2* tMargin)  into tWidth
   put (item 4 of tContentRect - item 2 of tContentRect) - (3* tMargin) into tHeight
   
   local tSelectedGroup
   put inspectorSectionGet() into tSelectedGroup
   
   local tSubsections, tCurSection, tNewSubsection
   # Check if this inspector wants to show subsections
   put the showSubSections of me into tSubsections
   
   local tInspectorWidth, tInspectorHeight, tColumnNumber, tColumnTop
   put 1 into tColumnNumber
   repeat for each element tElement in sDataA[tSelectedGroup]["grouplist"]
      if tSubsections and tElement["subsection"] is not empty then
         # If we have a new subsection, create the subsection header
         if tElement["subsection"] is not tCurSection then
            set the width of group ("Subsection_" & tElement["subsection"]) of me to the formattedwidth of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me
            set the width of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me to the formattedwidth of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me
            set the topleft of group ("Subsection_" & tElement["subsection"]) of me to tLeft,tTop
            add (the formattedheight of field tElement["subsection"] of group ("Subsection_" & tElement["subsection"]) of me) to tTop
            put tElement["subsection"] into tCurSection
         end if
      end if
      
      if there is a group tElement["label"] of me then
         lock messages
         set the topleft of group tElement["label"] of me to tLeft,tTop
         set the lockloc of  group tElement["label"] of me to true
         set the width of group tElement["label"] of me to tWidth
         set the height of group tElement["label"] of me to tHeight
         unlock messages
         dispatch "rowResize" to group tElement["label"] of me
         
         local tRowWidth, tEditorHeight
         # If the editor does not report its own height, use the formatted height
         # This tends to report slightly strange values, otherwise we could just use it
         # all the time.
         put the editorHeight of group tElement["label"] of me into tEditorHeight
         if not tEditorHeight > 0 then
            put the formattedheight of group tElement["label"] of me into tEditorHeight
         end if
         put rowLabelWidth() + the rowMinWidth of group tElement["label"] of me into tRowWidth
         
         lock messages
         add tEditorHeight + tEditorPadding to tTop
         
         if tRowWidth > tInspectorWidth then
            put tRowWidth into tInspectorWidth
         end if
         if tTop > tInspectorHeight then
            put tTop into tInspectorHeight
         end if
         
         unlock messages
      end if
   end repeat
   
   local tStackTop, tStackLeft
   put the top of me into tStackTop
   put the left of me into tStackLeft
   
   lock messages
   set the minWidth of me to (tInspectorWidth + tMargin * 2)
   set the width of me to tWidth +  tMargin * 2
   set the left of me to tStackLeft
   
   set the minheight of me to tInspectorHeight + (tMargin * 2)
   set the maxheight of me to tInspectorHeight + (tMargin * 2)
   set the height of me to tInspectorHeight + (tMargin * 2)
   set the top of me to tStackTop
   unlock messages
   unlock screen
end inspectorLayout

local sSelectedSection
private on inspectorSectionSet pSection
   put pSection into sSelectedSection
end inspectorSectionSet

private function inspectorSectionGet
   repeat for each key tIndex in sDataA
      if sDataA[tIndex]["label"] is sSelectedSection then
         return tIndex
      end if
   end repeat
   return 1
end inspectorSectionGet

function inspectorSectionGetName
   if sSelectedSection is not empty then 
      return sSelectedSection
   else
      return sDataA[1]["label"]
   end if
end inspectorSectionGetName

private function inspectorDontShowGroup pGroup
   repeat for each element tProperty in pGroup["proplist"]
      if tProperty["user_visible"] is true then
         return false
      end if
   end repeat
   return true
end inspectorDontShowGroup

# Generate inspector
private on inspectorGenerate
   lock screen
   
   local tSelectedSection
   put inspectorSectionGet() into tSelectedSection
   
   local tPropertyData
   put sDataA[tSelectedSection] into tPropertyData
   
   set the margins of the templategroup to 0
   set the visible of the templategroup to false
   
   set the behavior of the templategroup to the long ID of stack revIDEPaletteResourcePath("behaviors/revinspectorgroupbehavior.livecodescript")
   
   set the traversalon of the templatefield to false
   set the threed of the templatefield to false
   set the showborder of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the textalign of the templatefield to right
   set the opaque of the templatefield to false
   set the height of the templatefield to 21
   set the locktext of the templatefield to true
   set the width of the templatefield to kMaxLabelSize
   
   lock messages
   if there is not a group "template" then
      create group "template"
      create field "rowlabel" in group "template"
      set the topleft of field "rowlabel" of group "template" to the topleft of group "template"
   end if
   unlock messages
   
   local tSubsections
   put the showSubSections of me into tSubsections
   
   local tElement
   repeat with x = 1 to the number of elements in tPropertyData["grouplist"]
      put tPropertyData["grouplist"][x] into tElement
      if tElement["label"] is empty then next repeat
      
      # If none of the properties is user visible then skip the group
      if inspectorDontShowGroup(tElement) then
         next repeat
      end if
      
      if tSubsections and tElement["subsection"] is not empty then
         if there is not a group ("Subsection_" & tElement["subsection"]) of me then
            create group "Subsection_" & tElement["subsection"]
            show it
            create field tElement["subsection"] in it
            set the text of it to tElement["subsection"]
            set the textstyle["bold"] of it to true
            set the textstyle["underline"] of it to true
         end if
      end if
      
      lock messages
      copy group "template" to me
      set the name of it to tElement["label"]
      show group tElement["label"] of me
      unlock messages
      
      local tName
      put the short name of group tElement["label"] of me into tName
      if exists(group tElement["label"] of me) then
         if tElement["label"] is not tElement["subsection"] then
            set the rowLabel of group tElement["label"] of me to tElement["label"]
         end if
         local tPropList, tProperty
         repeat with y = 1 to the number of elements in tElement["proplist"]
            put tElement["proplist"][y] into tProperty
            if tProperty["user_visible"] is false then next repeat
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

private on inspectorNavigationGenerate
   lock screen
   # Clear the current frame data
   clearFrameNavigationData
   
   # Add all the navigation elements
   repeat for each element tSection in sDataA
      local tIcon
      dispatch function "inspectorSectionIcon" to me with tSection["label"]
      put the result into tIcon
      addFrameItem tSection["label"],"header", "navigation", tSection["label"], tIcon, tIcon, "inspectorSectionChanged", the long id of me, tSection["label"]
   end repeat
   
   dispatch "inspectorAddActions" to me
   
   unlock screen
end inspectorNavigationGenerate

on inspectorChanged
   lock screen
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
end inspectorChanged

# Sent when the user changes the section
on inspectorSectionChanged pSection
   # Timing log
   local tStartTime
   put the milliseconds into tStartTime
   
   # Check if the section is different
   if inspectorSectionGetName() is pSection then exit inspectorSectionChanged
   
   # Set the section
   inspectorSectionSet pSection
   
   inspectorChanged
   
   //put "Last inspector update took" && the milliseconds - tStartTime && "milliseconds" & return after msg
end inspectorSectionChanged

on inspectorFill
   # store the selected object and position
   lock screen
   local tProperties
   put the displayData of me into tProperties
   
   local tRow
   repeat for each key tRow in tProperties
      if there is a group tRow of me then
         set the rowData of group tRow of me to tProperties[tRow]
      end if
   end repeat
   unlock screen
end inspectorFill

private on inspectorClear
   if the number of groups of card 1 of me is 0 then
      exit inspectorClear
   end if
   
   lock screen
   lock messages
   repeat while the number of groups of card 1 of me is not 1
      if the short name of group 2 of me is "background" then
         delete group 1 of card 1 of me
      else
         delete group 2 of card 1 of me
      end if
   end repeat
   
   rowLabelWidthSet 0
   unlock messages
   unlock screen
end inspectorClear

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
   local tMaxWidth, tLabelWidth, tChildren
   put the childControlNames of this card of me into tChildren
   repeat for each line tControl in tChildren
      if there is a field "rowlabel" of group tControl of me then
         put the rowLabelWidth of group tControl of me into tLabelWidth
      end if
      if tLabelWidth > tMaxWidth then
         put tLabelWidth into tMaxWidth
      end if
   end repeat
   return tMaxWidth
end rowLabelWidthCalculate

function absoluteRectOfObject pObject
   local tRect
   put the rect of group pObject of me into tRect
   # Work around the fact that groups are too large
   put item 2 of tRect + 21 into item 4 of tRect
   
   return revIDERelativeRectToAbsolute(tRect, me)
end absoluteRectOfObject

on highlightObject pObjectData
   dispatch "hiliteFrameItem" to me with pObjectData["section"]
   dispatch "navSelected" to me with pObjectData["section"]
end highlightObject

function inspectorPropertyOfInspectedObject pProp
   local tValue
   try
      put revIDEPropertiesOfObjects(the inspectedObjects of me, pProp) into tValue
   catch tError
      return empty
   end try

   # Work around the fact that property may be returned as a list
   if the number of lines of tValue[pProp] is 1 then
      replace comma with return in tValue[pProp]
   end if
   return tValue[pProp]
end inspectorPropertyOfInspectedObject
