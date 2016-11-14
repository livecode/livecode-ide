script "com.livecode.pi.dimension.behavior"
local sMax, sMin

constant kFieldWidth = 100
constant CONTROL_PADDING = 5
constant kEffectiveTextColor = "100,100,100"
constant kConflictedFieldColor = "193,201,215"

on editorInitialize
   lock screen
   lock messages
   local tStep
   put editorPropertyGet("max") into sMax
   put editorPropertyGet("min") into sMin
   put editorPropertyGet("step") into tStep
   
   set the lineinc of scrollbar "twiddle" of me to tStep
   set the visible of scrollbar "twiddle" of me to true

   unlock messages
   unlock screen
   set the editorMaxWidth of me to 0
end editorInitialize

getProp editorMinWidth
   local tWidth
   add kFieldWidth to tWidth
   add the width of scrollbar "twiddle" of me to tWidth
   add CONTROL_PADDING to tWidth
   return tWidth
end editorMinWidth

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tConflicted
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   put the editorConflicted of me into tConflicted
   
   if tValue is "fit" then
      exit editorUpdate
   end if
   
   lock messages
   set the thumbposition of scrollbar "twiddle" of me to tValue + 0
   set the enabled of field 1 of me to tEnabled
   if tEffective is true then
      if the focusedobject is not the long ID of field 1 of me then
         put tValue + 0 into field 1 of me
      end if
      set the textstyle["italic"] of field 1 of me to true
      set the textcolor of field 1 of me to kEffectiveTextColor
   else
      set the textstyle of field 1 of me to empty
      set the textcolor of field 1 of me to empty
      put tValue + 0 into field 1 of me
   end if
   if tConflicted then
      set the backcolor of field 1 of me to kConflictedFieldColor
      put empty into field 1 of me
   else
      set the backcolor of field 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   local tLeft, tTop, tBottom
   put the left of me into tLeft
   put the top of me into tTop
   put tTop + the formattedheight of field 1 of me into tBottom
   
   local tFieldWidth
   put max(the formattedWidth of field 1 of me, kFieldWidth) into tFieldWidth
   set the rect of field 1 of me to tLeft,tTop,tLeft+tFieldWidth,tBottom
   add tFieldWidth to tLeft
   
   add CONTROL_PADDING to tLeft
   # The twiddle control is visible
   set the rect of scrollbar "twiddle" of me to tLeft,tTop,tLeft + the width of scrollbar "twiddle" of me, tBottom
   add the width of scrollbar "twiddle" of me to tLeft
   
   add CONTROL_PADDING to tLeft
   set the topleft of button "fit" of me to tLeft, tTop
   unlock messages
   unlock screen
end editorResize

on openField
   if the editorEffective of me is true then
      lock messages
      put empty into field 1 of me
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
   if the visible of scrollbar "twiddle" of me is false then
      exit scrollbarLineInc
   end if
   scrollbarValueChanged field 1 of me - the lineInc of scrollbar "twiddle" of me
end scrollbarLineInc

on scrollbarLineDec
   if the visible of scrollbar "twiddle" of me is false then
      exit scrollbarLineDec
   end if
   scrollbarValueChanged field 1 of me + the lineInc of scrollbar "twiddle" of me
end scrollbarLineDec

on scrollbarValueChanged pValue
   if pValue is field 1 of me then
      exit scrollbarValueChanged
   end if
   
   if sMin is a number and pValue < sMin then
      put sMin into field 1 of me
   else if sMax is a number and pValue > sMax then
      put sMax into field 1 of me
   else
      put pValue into field 1 of me
   end if
   valueChanged
end scrollbarValueChanged

on mouseUp
   if the short name of the target is "fit" then
      set the editorValue of me to "fit"
      updateProperty
   end if
end mouseUp

on valueChanged   
   set the editorValue of me to field 1 of me
   updateProperty
end valueChanged
