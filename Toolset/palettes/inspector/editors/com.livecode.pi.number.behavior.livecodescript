script "com.livecode.pi.number.behavior"
local sMax, sMin, sScrollbarFactor

constant kFieldWidth = 100
constant SLIDER_MAX_WIDTH = 130
constant SLIDER_MIN_WIDTH = 80
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
   put 1 into sScrollbarFactor
   if tStep is a number then
      set the lineinc of scrollbar "twiddle" of me to tStep
      set the visible of scrollbar "twiddle" of me to true
   else
      set the visible of scrollbar "twiddle" of me to false
   end if
   
   if sMax is a number and sMin is a number and sMax > sMin then
      if tStep is a number then
         repeat while the floor of tStep is not tStep
            multiply tStep by 10
            multiply sScrollbarFactor by 10
         end repeat
      end if
      
      put sScrollbarFactor * sMax into field 1 of me
      set the visible of scrollbar "slider" of me to true
      set the endvalue of scrollbar "slider"of me to sScrollbarFactor * sMax
      set the startvalue of scrollbar "slider" of me to sScrollbarFactor * sMin
   else
      set the visible of scrollbar "slider" of me to false
   end if
   unlock messages
   unlock screen
   set the editorMaxWidth of me to 0
end editorInitialize

getProp editorMinWidth
   local tWidth
   add kFieldWidth to tWidth
   if the visible of scrollbar "slider" of me is true then
      add SLIDER_MIN_WIDTH to tWidth
      add CONTROL_PADDING to tWidth
   end if
   if the visible of scrollbar "twiddle" of me is true then
      add the width of scrollbar "twiddle" of me to tWidth
      add CONTROL_PADDING to tWidth
   end if
   return tWidth
end editorMinWidth

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tConflicted
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   put the editorConflicted of me into tConflicted
   
   lock messages
   set the thumbposition of scrollbar "slider" of me to sScrollbarFactor * tValue
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
   
   if the visible of scrollbar "twiddle" of me is true then
      add CONTROL_PADDING to tLeft
      # The twiddle control is visible
      set the rect of scrollbar "twiddle" of me to tLeft,tTop,tLeft + the width of scrollbar "twiddle" of me, tBottom
      add the width of scrollbar "twiddle" of me to tLeft
   end if
   
   if the visible of scrollbar "slider" of me is true then
      add CONTROL_PADDING to tLeft
      # The slider is visible
      local tRemainingWidth
      put the right of me - tLeft into tRemainingWidth
      if tRemainingWidth > SLIDER_MAX_WIDTH then
         put SLIDER_MAX_WIDTH into tRemainingWidth
      end if
      set the width of scrollbar "slider" of me to tRemainingWidth
      set the topleft of scrollbar "slider" of me to tLeft,tTop
   end if
   
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

on scrollbarDrag pValue
   if the visible of scrollbar "slider" of me is false then
      exit scrollbarDrag
   end if
   scrollbarValueChanged pValue / sScrollbarFactor
end scrollbarDrag

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

on valueChanged
   if field 1 of me is a number  then
      lock messages
      set the thumbposition of scrollbar "slider" of me to sScrollbarFactor * field 1 of me
      unlock messages
   end if
   
   set the editorValue of me to field 1 of me
   updateProperty
end valueChanged
