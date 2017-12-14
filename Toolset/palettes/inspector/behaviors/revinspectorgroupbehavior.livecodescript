script "revInspectorGroupBehavior"
constant kOverflowSize = 500
constant kMaxPropsPerLine = 4
# Adds the editor to the row
local sProperties, sOrder
on propertyRegister pPropertyInfo
   lock screen
   local tPropName, tEditor
   put pPropertyInfo["property_name"] into tPropName
   
   # Check that the property has not already been registered
   if tPropName is among the keys of sProperties then exit propertyRegister
   
   // Some editors are only slight variants of each other. In this case 
   // we allow the editor behavior itself to configure the options
   switch pPropertyInfo["editor"]
      case "com.livecode.pi.integer"
         put "com.livecode.pi.number" into tEditor
         break
      case "com.livecode.pi.nowraptext"
         put "com.livecode.pi.text" into tEditor
         break
      case "com.livecode.pi.styledtext"
         put "com.livecode.pi.textcontents" into tEditor
         break
      default
         put pPropertyInfo["editor"] into tEditor
         break
   end switch
   
   inspectorOpenEditor tEditor
   
   # Create the editor (need to decide if it's a classic editor (clone a group) 
   # or a new widget editor, in which case it's create control.
   if there is not a stack tEditor then
      put "com.livecode.pi.string" into tEditor
      inspectorOpenEditor tEditor
   end if
   
   local tEditorBehavior
   put tEditor & ".behavior" into tEditorBehavior
   
   local tGroupLongID
   if there is a group "template" of stack tEditor and there is a stack tEditorBehavior then
      lock messages
      copy group "template" of stack tEditor to me
      put it into tGroupLongID
      set the name of it to tPropName
      set the behavior of stack tEditorBehavior to the long id of stack revIDEPaletteResourcePath("behaviors/revinspectoreditorbehavior.livecodescript", the long ID of stack "revInspector")
      set the behavior of tGroupLongID to the long ID of stack tEditorBehavior
      
      if pPropertyInfo["label"] is not empty and the showMultiPropLabels of this stack then
         create invisible field tPropName in me
         set the topleft of field tPropName of me to the topleft of me
         put pPropertyInfo["label"] into field tPropName of me
      end if
      
      unlock messages
      set the editorPropertyInfo of tGroupLongId to pPropertyInfo
      dispatch "editorInitialize" to tGroupLongID
   else
      return "No editor template editor found"
   end if
   
   # Store the property name
   put tPropName into sProperties[tPropName]["property"]
   if sOrder is empty then
      put tPropName into sOrder
   else
      put return & tPropName after sOrder
   end if
   unlock screen
end propertyRegister

on rowReset
   lock screen
   lock messages
   repeat while the number of groups of me is not 0
      delete group 1 of me
   end repeat
   
   put empty into sProperties
   
   unlock messages
   unlock screen
end rowReset

setProp rowData pData
   lock screen
   local tConflict, tValue
   repeat for each key tProperty in pData
      put false into tConflict
      put empty into tValue
      if there is a group tProperty of me then
         local tKeys
         put the keys of pData[tProperty]["value"] into tKeys
         repeat for each line tLine in tKeys
            if tValue is empty then
               put pData[tProperty]["value"][tLine] into tValue
               next repeat
            end if
            if tValue is not pData[tProperty]["value"][tLine] then
               put true into tConflict
               exit repeat
            end if
         end repeat
         if tConflict then
            set the editorConflicted of group tProperty of me to true
            set the editorConflicts of group tProperty of me to pData[tProperty]["value"]
         else
            set the editorConflicted of group tProperty of me to false
            set the editorConflicts of group tProperty of me to empty
            set the editorValue of group tProperty of me to tValue
            set the editorEffective of group tProperty of me to pData[tProperty]["effective"][line 1 of tKeys]
         end if
         dispatch "editorUpdate" to group tProperty of me
      end if
   end repeat
   unlock screen
end rowData

on rowFinalize
   repeat for each line tProperty in sOrder
      dispatch "editorFinalize" to group tProperty of me
   end repeat
end rowFinalize

# Sets the text for the row label
constant kLabelHeight = 21
local sShowLabel
setprop rowLabel pLabel
   put pLabel into field "rowlabel" of me
   if sShowLabel is true then
      local tTopLeft
      put the topleft of field "rowlabel" of me into tTopLeft
      set the width of field "rowlabel" of me to the formattedwidth of field "rowlabel" of me
      set the height of field "rowlabel" of me to the number of lines in pLabel * kLabelHeight
      set the topleft of field "rowlabel" of me to tTopLeft
   end if
end rowLabel

getProp rowLabel
   return field "rowlabel" of me
end rowLabel

setProp rowShowLabel pValue
   put pValue into sShowLabel
   if pValue then
      show field "rowlabel" of me
   else
      hide field "rowlabel" of me
   end if
end rowShowLabel

getprop rowLabelWidth
   if sShowLabel is true then
      return the formattedwidth of field "rowlabel" of me
   else
      return 0
   end if
end rowLabelWidth

# Dictates whether the editors act indipendently or overwrite each
# others behaviour. For example, if you created a group called "background"
# you might set the backgroundcolor, fillgradient or backgroundPattern properties
# all of which overwrite each other
local sMutuallyExclusive
setProp mutuallyExclusive pValue
   if pValue is true then
      put true into sMutuallyExclusive
   else
      put false into sMutuallyExclusive
   end if
end mutuallyExclusive

getProp mutuallyExclusive
   if sMutuallyExclusive is true then 
      return true
   else
      return false
   end if
end mutuallyExclusive

# Sets the row tooltip text
setProp rowTooltip pTooltipText
   local tEditor
   put the long name of group 1 of me into tEditor
   
   ## Set the tooltip of the row label
   set the tooltip of field "rowlabel" of me to pTooltipText
   
   ## Set the tooltip on each control in the editor group
   repeat with x = 1 to the number of controls of tEditor
      if the tooltip of control x of tEditor is empty then
         set the tooltip of control x of tEditor to pTooltipText
      end if
   end repeat
end rowTooltip

# Takes a list of properties and returns an array describing how to lay out the editors
function calculateLayout pProps
   local tWidth, tLabelWidth
   put the width of me into tWidth
   put rowLabelWidth() into tLabelWidth
   
   local tAvailableSpace
   put tWidth - tLabelWidth into tAvailableSpace
   
   local tPropLabelWidth
   put propLabelWidth() into tPropLabelWidth
   
   local tMultiPropLabels
   put the showMultiPropLabels of this stack into tMultiPropLabels
   
   local tLayoutA
   local tMinMaxA, tElement, tGroupLongID, tIndex, tMinTotal
   repeat for each line tProperty in pProps
      add 1 to tIndex
      put sProperties[tProperty] into tElement
      put the long id of group tElement["property"] of me into tGroupLongID
      put the editorMinWidth of tGroupLongID into tMinMaxA[tIndex]["min"]
      put the editorMaxWidth of tGroupLongID into tMinMaxA[tIndex]["max"]
      
      add tMinMaxA[tIndex]["min"] to tMinTotal
      # If we are showing labels, add this to the amount of space taken up by editors
      if tMultiPropLabels then
         add tPropLabelWidth to tMinTotal
      end if
      
      # Work out how much each editor can expand by
      if tMinMaxA[tIndex]["max"] is not 0 then
         put tMinMaxA[tIndex]["max"] - tMinMaxA[tIndex]["min"] into tMinMaxA[tIndex]["difference"]
      else
         put tAvailableSpace into tMinMaxA[tIndex]["difference"]
      end if
      
      # If the min total > the available space, we need to go on to multiple lines
      # So try and work out where the split should occur and recursively calculate layout
      if tMinTotal > tAvailableSpace and the number of lines in pProps > 1 then
         local tOver, tNumOver
         put calculateLayout(line 1 to tIndex - 1 of pProps) into tLayoutA
         put the number of elements in tLayoutA into tNumOver
         put calculateLayout(line 1 to tIndex - 1 of pProps) into tOver
         repeat with x = 1 to the number of elements in tOver
            put tOver[x] into tLayoutA[x + tNumOver]
         end repeat
         return tLayoutA
      end if
   end repeat
   
   # Calculate the amount of extra space beyond the min widths of all the editors
   subtract tMinTotal from tAvailableSpace
   subtract (the palettePadding of this stack * (the number of elements in tMinMaxA - 1)) from tAvailableSpace
   put expandedToFit(tMinMaxA, tAvailableSpace) into tLayoutA[1]
   return tLayoutA
end calculateLayout

function expandedToFit pMinMaxA, pSpace
   local tKeys
   put the keys of pMinMaxA into tKeys
   
   # Order the keys by how much each editor can expand by
   sort lines of tKeys numeric ascending by pMinMaxA[each]["difference"]
   
   local tWidthsA, tDifferencesA
   repeat for each key tKey in pMinMaxA
      put pMinMaxA[tKey]["min"] into tWidthsA[tKey]
      put pMinMaxA[tKey]["difference"] into tDifferencesA[tKey]
   end repeat
   
   local tFixedA, tCopy
   put false into tCopy
   
   local tMaxIncrement
   local tSpaceLeft
   put pSpace into tSpaceLeft
   repeat for each line tLine in tKeys
      # Update the maximum possible increment for all the remaining editors
      put tSpaceLeft / (the number of elements in tDifferencesA) into tMaxIncrement
      
      if not tCopy then
         if tLine is among the keys of tDifferencesA and pMinMaxA[tLine]["max"] is not 0 and tDifferencesA[tLine] < tMaxIncrement then
            # If this editor has a max width and there is space to expand all the remaining editors by this amount, then do so
            add tDifferencesA[tLine] to tWidthsA
            # Adjust the remaining differences
            subtract tDifferencesA[tLine] from tDifferencesA
            # Adjust the space left
            subtract tDifferencesA[tLine] * the number of elements in tWidthsA from tSpaceLeft
            # Remove this editor from the list of things to adjust (as it has reached its max width)
            delete variable tDifferencesA[tLine]
            # Copy the calculated with to the final array
            put tWidthsA[tLine] into tFixedA[tLine]
         else
            # Otherwise, just expand all remaining editors by the maximum increment
            # And copy all the values across to the final array
            add tMaxIncrement to tWidthsA
            put true into tCopy
         end if
      end if
      if tCopy then
         put tWidthsA[tLine] into tFixedA[tLine]
      end if
   end repeat
   
   return tFixedA
end expandedToFit

on rowResize pExpandableExtra
   lock screen
   set the lockloc of me to true
   
   local tLeft, tTop, tRight, tWidth, tLabelWidth, tGroupLeft
   put the left of me into tGroupLeft
   put the top of me into tTop
   put the right of me into tRight
   put the width of me into tWidth
   put rowLabelWidth() into tLabelWidth

   # Position the label
   lock messages
   # AL-2015-04-24: [[ Bug 15285 ]] Trim label fields so that editor fields can be unfocused
   set the width of field "rowlabel" of me to the formattedwidth of field "rowlabel" of me
   set the height of field "rowlabel" of me to the formattedHeight of field "rowlabel" of me
   set the top of field "rowlabel" of me to tTop
   set the right of field "rowlabel" of me to tGroupLeft+tLabelWidth
   unlock messages

   # Calculate layout
   local tWidthsA
   put calculateLayout(sOrder) into tWidthsA
   
   # Fetch the palette padding outside of lock messages
   local tPadding
   put the palettePadding of this stack into tPadding
   
   # Position the controllers
   local tEditorSpace, tEditorCount
   put the number of elements of sProperties into tEditorCount
   
   put tGroupLeft + tLabelWidth into tLeft
   
   local tPropLabelWidth
   put propLabelWidth() into tPropLabelWidth
   
   local tSubsections
   put the showSubSections of this stack into tSubsections
   
   local tGroupLongID, tLastGroupLongID, tHeightOfRow, tCount, tGroupHeight
   local tElement, tPropNumber, tLineNumber, tCanExpand
   put 1 into tLineNumber
   put 0 into tCanExpand
   repeat for each line tProperty in sOrder
      add 1 to tPropNumber
      put sProperties[tProperty] into tElement
      put the long id of group tElement["property"] of me into tGroupLongID
      
      # If there is no width specified for this line, then the editors didn't all fit,
      # So start positioning editors on the next line
      if tWidthsA[tLineNumber][tPropNumber] is empty then
         add 1 to tLineNumber
         put 1 into tPropNumber
         add tHeightOfRow to tTop
         add tHeightOfRow to tGroupHeight
         put 0 into tHeightOfRow
      end if
      
      if tEditorCount > 1 and there is a field tElement["property"] of me then
         show field tElement["property"] of me
         set the width of field tElement["property"] of me to tPropLabelWidth
         if tSubsections then
            set the topleft of field tElement["property"] of me to tLeft,tTop
            add tPropLabelWidth to tLeft
         end if
      end if
      
      set the lockloc of tGroupLongID to true
      set the width of tGroupLongID to tWidthsA[tLineNumber][tPropNumber]
      unlock messages
      dispatch "editorResize" to tGroupLongID
      
      lock messages
      # If the editor does not fit where we tried to put it, put it on the next line
      set the topleft of tGroupLongID to tLeft,tTop
      unlock messages
      
      local tEditorHeight
      put the editorHeight of tGroupLongID into tEditorHeight
      
      lock messages
      if not tSubsections and there is a field tElement["property"] of me then
         set the topleft of field tElement["property"] of me to tLeft + tWidthsA[tLineNumber][tPropNumber],tTop
         put tGroupLeft + tLabelWidth + tWidthsA[tLineNumber][tPropNumber] into tLeft
      end if
      
      if tEditorHeight is 0 then
         put the formattedheight of tGroupLongID into tEditorHeight
      end if
      
      set the height of tGroupLongID to tEditorHeight
      set the top of tGroupLongID to tTop
      
      if tEditorHeight > tHeightOfRow then
         put tEditorHeight into tHeightOfRow
      end if
      unlock messages
      
      local tThisCanExpand
      put the editorExpandVertical of tGroupLongID into tThisCanExpand
      if tThisCanExpand then
         add 1 to tCanExpand
         if pExpandableExtra > 0 then
            lock messages
            set the height of tGroupLongID to tEditorHeight + pExpandableExtra
            unlock messages
            dispatch "editorResize" to tGroupLongID
         end if
      end if
      
      add tWidthsA[tLineNumber][tPropNumber] + tPadding to tLeft
      add tHeightOfRow to tGroupHeight
      put tGroupLongID into tLastGroupLongID
   end repeat
   
   local tHeightDiff
   put the height of me - tGroupHeight into tHeightDiff
   if pExpandableExtra is empty and tCanExpand > 0 and tHeightDiff > 0 then
      local tExpandableExtra, tDummy
      put tHeightDiff / tCanExpand into tExpandableExtra
      rowResize tExpandableExtra
   end if
   
   set the height of me to tGroupHeight
   set the lockloc of me to false
   unlock screen
end rowResize

function propLabelWidth
   local tWidth, tElement
   repeat for each line tProperty in sOrder
      put sProperties[tProperty] into tElement
      if there is a field tElement["property"] of me then
         set the width of field tElement["property"] of me to the width of me
         if the formattedwidth of field tElement["property"] of me > tWidth then
            put the formattedwidth of field tElement["property"] of me into tWidth
         end if
      end if
   end repeat
   return tWidth
end propLabelWidth

getProp rowMinWidth
   local tMinWidth, tElement
   repeat for each line tProperty in sOrder
      put sProperties[tProperty] into tElement
      add the editorMinWidth of group tElement["property"] of me to tMinWidth
   end repeat
   return tMinWidth
end rowMinWidth

setProp rowEnabled pValue
   local tElement
   repeat for each line tProperty in sOrder
      put sProperties[tProperty] into tElement
      if there is a field tElement["property"] of me then
         set the enabled of field tElement["property"]  of me to pValue
      end if
      set the editorEnabled of group tElement["property"] of me to pValue
   end repeat
   set the enabled of field "rowlabel" of me to pValue
end rowEnabled

// The group can expand vertically if any of the editors can
function canExpandVertically
   local tElement
   repeat for each line tProperty in sOrder
      put sProperties[tProperty] into tElement
      if the editorExpandVertical of group tElement["property"] of me then
         return true
      end if
   end repeat
   return false
end canExpandVertically
