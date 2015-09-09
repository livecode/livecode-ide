script "com.livecode.pi.point.behavior"
local sFieldWidth, sMax, sMin

constant SLIDER_MAX_WIDTH = 130
constant SLIDER_MIN_WIDTH = 80
constant CONTROL_PADDING = 5

on editorInitialize
   lock screen
   lock messages
   local tStep
   put editorPropertyGet("max") into sMax
   put editorPropertyGet("min") into sMin
   put editorPropertyGet("step") into tStep
   
   if tStep is not a number then
      put 1 into tStep
   end if
   
   set the lineinc of scrollbar "twiddleX" of me to tStep
   set the lineinc of scrollbar "twiddleY" of me to tStep
   
   local tMinWidth
   put 25 into tMinWidth
   
   unlock messages
   unlock screen
   
   set the editorMinWidth of me to tMinWidth
   set the editorMaxWidth of me to 0
end editorInitialize

getProp editorMinWidth
   local tWidth
   add sFieldWidth to tWidth
   add the width of scrollbar "twiddleX" of me to tWidth
   add CONTROL_PADDING to tWidth
   return tWidth
end editorMinWidth

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   set the thumbposition of scrollbar "twiddleX" of me to item 1 of tValue + 0
   set the thumbposition of scrollbar "twiddleY" of me to item 2 of tValue + 0
   set the enabled of field 1 of me to tEnabled
   if tEffective is true then
      if the focusedobject is not the long ID of field 1 of me then
         put item 1 of tValue + 0 into field "x" of me
         put item 2 of tValue + 0 into field "y" of me
      end if
      set the textcolor of field "x" of me to "150,150,150"
      set the textcolor of field "y" of me to "150,150,150"
   else
      set the textcolor of field "x" of me to empty
      set the textcolor of field "y" of me to empty
      put item 1 of tValue + 0 into field "x" of me
      put item 2 of tValue + 0 into field "y" of me
   end if
   unlock messages
   
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   local tLeft, tXTop, tYTop
   put the left of me into tLeft
   put the top of me into tXTop
   put tXTop +  the height of field "x" of me + CONTROL_PADDING into tYTop
   
   # The field is full width but there is a twiddle controller at the end
   set the rect of field "x" of me to tLeft,tXTop,the right of me - the width of scrollbar "twiddleX" - CONTROL_PADDING,tXTop +  the height of field "x" of me
   set the rect of field "y" of me to tLeft,tYTop,the right of me - the width of scrollbar "twiddleY" - CONTROL_PADDING,tYTop +  the height of field "y" of me
   add the width of field "x" of me to tLeft
   
   set the topleft of scrollbar "twiddleX" of me to tLeft,tXTop
   set the topleft of scrollbar "twiddleY" of me to tLeft,tYTop
   
   unlock messages
   unlock screen
end editorResize

on openField
   if the editorEffective of me is true then
      lock messages
      put empty into field "x" of me
      put empty into field "y" of me
      # Ensure that when the user types the text is the default color rather than the effective grey
      set the textcolor of field 1 of me to empty
      unlock messages
   end if
end openField

on exitField
   editorUpdate
end exitField

on returnInField
   valueChanged
end returnInField

on enterInField
   valueChanged
end enterInField

on closeField
   valueChanged
end closeField

on scrollbarLineInc
   if the short name of the target is "twiddleX" then
      scrollbarValueChanged "x", field "x" of me - 1
   else
      scrollbarValueChanged "y", field "y" of me - 1
   end if
end scrollbarLineInc

on scrollbarLineDec
   if the short name of the target is "twiddleX" then
      scrollbarValueChanged "x", field "x" of me + 1
   else
      scrollbarValueChanged "y", field "y" of me + 1
   end if
end scrollbarLineDec

on scrollbarValueChanged pWhich, pValue
   if pValue is field pWhich of me then
      exit scrollbarValueChanged
   end if
   
   if sMin is a number and pValue < sMin then
      put sMin into field pWhich of me
   else if sMax is a number and pValue > sMax then
      put sMax into field pWhich of me
   else
      put pValue into field pWhich of me
   end if
   valueChanged
end scrollbarValueChanged

on valueChanged
   set the editorValue of me to (field "x" of me & comma & field "y" of me)
   updateProperty
end valueChanged
