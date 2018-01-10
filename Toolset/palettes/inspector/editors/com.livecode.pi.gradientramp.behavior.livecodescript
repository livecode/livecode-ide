script "com.livecode.pi.gradientramp.behavior"
local sPopupDefaults

on editorInitialize
   set the editorMinWidth of group "editors" of me to 250
   set the editorMaxWidth of group "editors" of me to 0
   /*
   local tPopupData, tDefaultStore
   put editorPropertyGet("popup") into tPopupData
   repeat for each element tGroup in tPopupData
      repeat for each element tProp in tGroup["proplist"]
         put tProp["default"] into sPopupDefaults[tProp["property_name"]]
         put tProp["default"] into tDefaultStore[char 9 to -1 of tProp["property_name"]]
      end repeat
   end repeat
   
   if the storedValue of group "editors" of me is empty then
      set the editorValue of group "editors" of me to tDefaultStore
      storeProperty
      set the editorValue of group "editors" of me to empty
   end if
   */
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tProperty
   put the editorValue of group "editors" of me into tValue
   put the editorEnabled of group "editors" of me into tEnabled
   put the editorEffective of group "editors" of me into tEffective
   /*
   if tValue is empty then
      put the storedValue of group "editors" of me into tValue
   end if
   */
   local tPopupData
   if tValue["type"] is empty then
      set the label of button "type" of group "editors" of me to "No gradient"
   else
      set the label of button "type" of group "editors" of me to tValue["type"]
   end if
   put tValue["repeat"] into field "repeat" of group "editors" of me
   set the hilite of button "mirror" of group "editors" of me to tValue["mirror"] is true
   set the hilite of button "wrap" of group "editors" of me to tValue["wrap"] is true
   set the gradientRamp of widget "ramp" of group "editors" of me to tValue["ramp"]
   set the label of button "quality" of group "editors" of me to tValue["quality"]
   unlock screen
end editorUpdate

private command updateDisplay pValue
   local tFillData
   if pValue["type"] is not empty then
      put pValue["type"] into tFillData["type"]
      if pValue["type"] is not "linear" then
         put the loc of graphic 1 of group "editors" of me into tFillData["from"]
         put the right of graphic 1 of group "editors" of me,item 2 of the loc of graphic 1 of group "editors" of me into tFillData["to"]
         put item 1 of the loc of graphic 1 of group "editors" of me,the bottom of graphic 1 of group "editors" of me into tFillData["via"]
      else
         put the topleft of graphic 1 of group "editors" of me into tFillData["from"]
         put the topright of graphic 1 of group "editors" of me into tFillData["to"]
         put the bottomleft of graphic 1 of group "editors" of me into tFillData["via"]
      end if
      put pValue["repeat"] into tFillData["repeat"]
      put pValue["mirror"] into tFillData["mirror"]
      put pValue["wrap"] into tFillData["wrap"]
      put pValue["ramp"] into tFillData["ramp"]
      put pValue["quality"] into tFillData["quality"]
   end if
end updateDisplay

private command expandToRight pControl, pRight
   local tLeft
   put the left of pControl into tLeft
   set the width of pControl to pRight - tLeft
   set the left of pControl to tLeft
end expandToRight

on editorResize
   lock screen
   lock messages
   set the topleft of group "editors" of me to the topleft of me
   local tRight
   put the right of me into tRight
   expandToRight the long id of button "type" of group "editors" of me, tRight
   expandToRight the long id of widget "ramp" of group "editors" of me, tRight
   expandToRight the long id of button "quality" of group "editors" of me, tRight
   
   set the right of field "value" of group "editors" of me to tRight
   put the left of field "value" of group "editors" of me into tRight
   expandToRight the long id of scrollbar "alpha" of group "editors" of me, tRight
   
   set the right of scrollbar "twiddle" of group "editors" of me to tRight
   put the left of scrollbar "twiddle" of group "editors" of me into tRight
   expandToRight the long id of field "repeat" of group "editors" of me, tRight
   unlock messages
   set the editorHeight of me to the bottom of button "wrap" \
         of group "editors" of me - the top of me
   editorUpdate
   unlock screen
end editorResize

on valueChanged pProperty, pValue
   local tValue
   put the editorValue of group "editors" of me into tValue
   if tValue is empty then
      put the storedValue of group "editors" of me into tValue
   end if
   
   if pProperty is "gradientType" and pValue is "No gradient" then
      put empty into tValue
   else
      # A gradient must have a ramp
      if tValue["ramp"] is "" then
         put defaultramp() into tValue["ramp"]
      end if
      put pValue into tValue[char 9 to -1 of pProperty]
   end if
   set the editorValue of group "editors" of me to tValue
   
   updateDisplay tValue
   
   updateProperty
   dispatch "editorValueChanged" with "editmode", the editorProperty["property_name"] of group "editors" of me, false
end valueChanged

private function defaultramp
   return "0,255,255,255" & return & "1,0,0,0"
end defaultramp


on editorInitialize
   set the editorMinWidth of group "editors" of me to 260
   set the editorMaxWidth of group "editors" of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of group "editors" of me into tValue
   put the editorEnabled of group "editors" of me into tEnabled
   put the editorEffective of group "editors" of me into tEffective
   
   lock messages
   updateSubeditorValue tValue
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the lockLoc of group "editors" of me to true
   
   local tColorRect, tWidgetRect
   put the rect of group "editors" of me into tColorRect
   put tColorRect into tWidgetRect
   
   if the height of group "editors" of me <= 90 then
      put the top of group "editors" of me + 60 into item 4 of tWidgetRect
   else
      put the bottom of group "editors" of me - 30 into item 4 of tWidgetRect
   end if
   put the bottom of group "editors" of me - 30 into item 2 of tColorRect
   
   set the rect of group "color" of group "editors" of me to tColorRect
   set the rect of widget 1 of group "editors" of me to tWidgetRect
   
   unlock messages
   dispatch "resizeControl" to group "color" of group "editors" of me
   
   set the lockloc of group "editors" of me to false
   unlock screen
end editorResize

local sOpacity, sColor
on valueChanged
   if the long id of the target is the long id of widget 1 of group "editors" of me then
      set the editorValue of group "editors" of me to the gradientstops of widget 1 of group "editors" of me
   else
      local tSelected
      put the selectedStop of widget 1 of group "editors" of me into tSelected
      if tSelected is 0 then 
         exit valueChanged
      end if
      
      local tValue
      put the editorValue of group "editors" of me into tValue
      put the thumbposition of scrollbar "alpha" of group "editors" of me into sOpacity
      put currentValue() into item 2 to 5 of line tSelected of tValue 
      set the editorValue of group "editors" of me to tValue
      updateSubeditorValue tValue
   end if
   updateProperty
end valueChanged

on gradientStopsChanged
   valueChanged
end gradientStopsChanged

on selectedStopChanged
   local tValue
   put rampValue() into tValue
   updateColorDisplay item 2 to 5 of tValue
   updateOpacityDisplay item 5 of tValue
end selectedStopChanged

on updateRampValue tValue
   lock screen
   lock messages
   set the gradientStops of widget 1 of group "editors" of me to tValue
   unlock messages
   unlock screen
end updateRampValue

on updateOpacityValue pAlpha
   lock screen
   lock messages
   if pAlpha is not a number then
      put 0 into pAlpha
   end if
   set the thumbposition of scrollbar "alpha" of group "editors" of me to pAlpha
   put pAlpha into sOpacity
   unlock messages
   unlock screen
end updateOpacityValue

function rampValue
   lock messages
   local tValue
   put the gradientStops of widget 1 of group "editors" of me into tValue
   local tSelected
   put the selectedStop of widget 1 of group "editors" of me into tSelected
   local tColorValue
   if tSelected is 0 then
      put empty into tColorValue
   else
      put line tSelected of tValue into tColorValue
   end if
   unlock messages
   return tColorValue
end rampValue

on updateColorDisplay pColor
   lock screen
   lock messages
   put item 1 to 3 of pColor into sColor
   set the swatchcolor of widget "color" of group "editors" of me to pColor
   put pColor into field "value" of group "editors" of me
   unlock messages
   unlock screen
end updateColorDisplay

on updateOpacityDisplay pAlpha
   lock screen
   lock messages
   if pAlpha is not a number then
      put 0 into pAlpha
   end if
   set the thumbposition of scrollbar "alpha" of group "editors" of me to pAlpha
   put pAlpha into sOpacity
   unlock messages
   unlock screen
end updateOpacityDisplay

function currentValue
   if sColor is empty then
      return empty
   else
      return sColor & comma & sOpacity
   end if
end currentValue

local sUpdateRamp, sUpdateOpacity
on updateSubeditorValue pValue
   local tMDown
   if the mouse is "down" then
      put the mousecontrol into tMDown
   end if
   if tMDown is not empty then
      put the long id of the mousecontrol into tMDown
   end if
   
   if tMDown is not the long id of widget "ramp" of group "editors" of me then 
      updateRampValue pValue
   end if
   
   local tSelectedValue
   put rampValue() into tSelectedValue
   if tMDown is not the long id of scrollbar "alpha" of group "editors" of me then
      updateOpacityValue item 5 of tSelectedValue
   end if
   
   updateColorDisplay item 2 to 5 of tSelectedValue
end updateSubeditorValue

on mouseUp
   switch the short name of the target 
      case "color"
         local tSelectedStop
         put the selectedStop of widget "ramp" of group "editors" of me into tSelectedStop
         if tSelectedStop is 0 then
            exit mouseUp
         end if
         local tGradientStops, tColorValue
         put the gradientStops of widget "ramp" of group "editors" of me into tGradientStops
         put item 2 to 4 of line tSelectedStop of tGradientStops into tColorValue
         answer color with tColorValue
         if the result is "cancel" then
            exit mouseUp
         end if
         put it into sColor
         valueChanged
         break
      case "alpha"
         put the thumbposition of scrollbar "alpha" of group "editors" of me into sOpacity
         valueChanged
         break
      default
         pass mouseUp
   end switch
end mouseUp
