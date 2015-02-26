script "revIDEInspectorBehaviorRow"
# Adds the editor to the row
local sProperties, sOrder
on propertyRegister pPropertyInfo
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
      copy group "template" of stack tEditor to me
      put it into tGroupLongID
      set the name of it to tPropName
      set the behavior of button "behavior" of stack tEditor to the long id of stack revIDEPaletteResourcePath("behaviors/editorsharedbehavior.livecodescript")
      set the behavior of tGroupLongID to the long ID of button "behavior" of stack tEditor
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
   put pLabel into field "label" of me
end rowLabel

getProp rowLabel
   return field "label" of me
end rowLabel

getprop rowLabelWidth
   return the formattedwidth of field "label" of me
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
   set the tooltip of me to pTooltipText
end rowTooltip

on rowResize
   lock screen
   set the lockloc of me to true
   
   local tLeft, tTop, tRight, tWidth, tLabelWidth
   put the left of me into tLeft
   put the top of me into tTop
   put the right of me into tRight
   put the width of me into tWidth
   put rowlabelWidth() into tLabelWidth 
   
   # Position the label
   lock messages
   set the rect of field "label" of me to tLeft,tTop,tLeft+tLabelWidth,tTop+21
   unlock messages
   
   # Position the controllers
   local tEditorSpace, tEditorCount
   put the number of elements of sProperties into tEditorCount
   put tWidth - tLabelWidth into tEditorSpace
   
   local tEditorWidth, x, tMinWidth, tMaxWidth
   put 0 into x
   put tLabelWidth into tLeft
   local tElement
   repeat for each line tProperty in sOrder
      put sProperties[tProperty] into tElement
      put tEditorSpace /  (tEditorCount - x) into tEditorWidth
      put the editorMinWidth of group tElement["property"] of me into tMinWidth
      put the editorMaxWidth of group tElement["property"] of me into tMaxWidth
      if tMinWidth > 0 and tMinWidth > tEditorWidth then
         put tMinWidth into tEditorWidth
      else if tMaxWidth > 0 and tMaxWidth < tEditorWidth then
         put tMaxWidth into tEditorWidth
      end if
      
      lock messages
      set the width of group tElement["property"] of me to tEditorWidth
      --set the loc of group tElement["property"] of me to the loc of field "label" of me
      --set the left of group tElement["property"] of me to tLeft
      set the topleft of group tElement["property"] of me to tLeft,tTop
      unlock messages
      dispatch "editorResize" to group tElement["property"] of me
      add tEditorWidth to tLeft
      subtract tEditorWidth from tEditorSpace
      add 1 to x
   end repeat
   
   set the lockloc of me to false
   unlock screen
end rowResize
