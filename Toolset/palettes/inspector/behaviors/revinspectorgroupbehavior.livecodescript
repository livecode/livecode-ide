script "revInspectorGroupBehavior"
constant kOverflowSize = 500
constant kMaxPropsPerLine = 4
# Adds the editor to the row
local sProperties, sOrder
on propertyRegister pPropertyInfo
   lock screen
   local tPropName, tEditor
   put pPropertyInfo["property_name"] into tPropName
   put pPropertyInfo["editor"] into tEditor
   
   # Check that the property has not already been registered
   if tPropName is among the keys of sProperties then exit propertyRegister
   
   # Create the editor (need to decide if it's a classic editor (clone a group) 
   # or a new widget editor, in which case it's create control.
   if there is not a stack tEditor then
      put "com.livecode.pi.string" into tEditor
   end if
   
   local tGroupLongID
   if there is a group "template" of stack tEditor and there is a button "behavior" of stack tEditor then
      lock messages
      copy group "template" of stack tEditor to me
      put it into tGroupLongID
      set the name of it to tPropName
      set the behavior of button "behavior" of stack tEditor to the long id of stack revIDEPaletteResourcePath("behaviors/revinspectoreditorbehavior.livecodescript")
      set the behavior of tGroupLongID to the long ID of button "behavior" of stack tEditor
      
      if pPropertyInfo["label"] is not empty then
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
   repeat for each key tProperty in pData
      if there is a group tProperty of me then
         set the editorValue of group tProperty of me to pData[tProperty]["value"]
         set the editorEffective of group tProperty of me to pData[tProperty]["effective"]
         dispatch "editorUpdate" to group tProperty of me
      end if
   end repeat
   unlock screen
end rowData

on propertyDeregistor pProperty
   # Delete the editor for the property
   if there is a group pProperty of me then
      delete group pProperty of me
   end if
   
   # Remove the property from the list
   delete variable sProperties[pProperty]
   delete line lineOffset(pProperty, sOrder) of sOrder
end propertyDeregistor

# Sets the text for the row label
setprop rowLabel pLabel
   local tTopLeft
   put the topleft of field "rowlabel" of me into tTopLeft
   put pLabel into field "rowlabel" of me
   set the width of field "rowlabel" of me to the formattedwidth of field "rowlabel" of me
   set the topleft of field "rowlabel" of me to tTopLeft
end rowLabel

getProp rowLabel
   return field "rowlabel" of me
end rowLabel

getprop rowLabelWidth
   if field "rowlabel" of me is not empty then
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
   set the tooltip of field "rowlabel" of me to pTooltipText
end rowTooltip

on rowResize
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
   set the top of field "rowlabel" of me to tTop
   set the right of field "rowlabel" of me to tGroupLeft+tLabelWidth
   unlock messages
   	
   # Position the controllers
   local tEditorSpace, tEditorCount
   put the number of elements of sProperties into tEditorCount
   put tWidth - tLabelWidth into tEditorSpace
   
   local tEditorWidth, x, tMinWidth, tMaxWidth
   put 0 into x
   put tGroupLeft + tLabelWidth into tLeft
   local tElement
   
   local tPropCount, tPropDivisor
   put the number of lines in sOrder into tPropCount
   put kMaxPropsPerLine into tPropDivisor
   
   local tPropLabelWidth
   put propLabelWidth() into tPropLabelWidth
   
   repeat forever
      if tPropDivisor is 1 then
         exit repeat
      end if
      if tPropCount mod tPropDivisor is 0 and tEditorSpace / tPropDivisor > tPropLabelWidth + 50 then
         exit repeat
      end if
      subtract 1 from tPropDivisor
   end repeat
   
   divide tEditorSpace by tPropDivisor 
   
   local tSubsections
   put the showSubSections of this stack into tSubsections
   
   local tGroupLongID, tLastGroupLongID, tHeightOfRow, tLabelPrecede, tCount
   repeat for each line tProperty in sOrder
      add 1 to x
      put sProperties[tProperty] into tElement
      put the long id of group tElement["property"] of me into tGroupLongID
      put tEditorSpace into tEditorWidth
      
      if tPropCount > 1 and there is a field tElement["property"] of me then
         show field tElement["property"] of me
         set the width of field tElement["property"] of me to tPropLabelWidth
         subtract tPropLabelWidth from tEditorWidth
      end if
      
      put the editorMinWidth of tGroupLongID into tMinWidth
      put the editorMaxWidth of tGroupLongID into tMaxWidth
      if tMinWidth > 0 and tMinWidth > tEditorWidth then
         put tMinWidth into tEditorWidth
         if tWidth - tLabelWidth - tPropLabelWidth < tMinWidth then
            put true into tLabelPrecede
         end if
      else if tMaxWidth > 0 and tMaxWidth < tEditorWidth then
         put tMaxWidth into tEditorWidth
      end if
      
      if tPropCount > 1 and there is a field tElement["property"] of me then
         if tSubsections then
            set the topleft of field tElement["property"] of me to tLeft,tTop
            add tPropLabelWidth to tLeft
         end if
      end if
      
      set the lockloc of tGroupLongID to true
      set the width of tGroupLongID to tEditorWidth
      unlock messages
      dispatch "editorResize" to tGroupLongID
      
      lock messages
      # If the editor does not fit where we tried to put it, put it on the next line
      set the topleft of tGroupLongID to tLeft,tTop
      
      if tLabelPrecede or (tPropCount > 1 and tLeft + tEditorWidth > tRight) then
         if tLastGroupLongID is not empty then
            put tGroupLeft + tLabelWidth into tLeft
            add the formattedHeight of tLastGroupLongID to tTop
            if there is a field tElement["property"] of me then
               set the topleft of field tElement["property"] of me to tLeft,tTop
               add tPropLabelWidth to tLeft
            end if
            set the topLeft of tGroupLongID to tLeft,tTop
            put 0 into x
         end if
      end if
      unlock messages
      
      local tEditorHeight
      put the editorHeight of tGroupLongID into tEditorHeight
      put the editorWidth of tGroupLongID into tEditorWidth
      
      lock messages
      if not tSubsections and not tLabelPrecede and tPropCount > 1 and there is a field tElement["property"] of me then
         set the topleft of field tElement["property"] of me to tLeft + tEditorWidth,tTop
         put tGroupLeft + tLabelWidth + x * tEditorSpace into tLeft
      else
         
      end if
      
      if tEditorHeight is 0 then
         put the formattedheight of tGroupLongID into tEditorHeight
      else
         set the height of tGroupLongID to tEditorHeight
         set the top of tGroupLongID to tTop
      end if
      
      if tEditorHeight > tHeightOfRow then
         put tEditorHeight into tHeightOfRow
      end if
      
      if tPropCount is 1 or x mod tPropDivisor is 0 then
         put  tGroupLeft + tLabelWidth into tLeft
         add tHeightOfRow to tTop
         put 0 into tHeightOfRow
         put 0 into x
      else
         put tGroupLeft + tLabelWidth + x * tEditorSpace into tLeft
      end if
      put tGroupLongID into tLastGroupLongID
      unlock messages
   end repeat
   
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
   return tMinWidth + the width of field "rowlabel"
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
