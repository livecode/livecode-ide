script "com.livecode.pi.gradientramp.behavior"
on editorInitialize
   set the editorMinWidth of me to 260
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   set the gradientstops of widget 1 of me to tValue
   unlock messages
   subeditorUpdate
   unlock screen
end editorUpdate

on subeditorUpdate
   lock screen
   local tValue
   put the gradientStops of widget 1 of me into tValue
   
   lock messages
   local tSelected
   put the selectedStop of widget 1 of me into tSelected
   local tColorValue
   if tSelected is 0 then
      put empty into tColorValue
   else
      put item 2 to 5 of line tSelected of tValue into tColorValue
   end if
   setColor tColorValue
   unlock messages
   unlock screen
end subeditorUpdate

on editorResize
   lock screen
   lock messages
   set the lockLoc of me to true
   
   local tColorRect, tWidgetRect
   put the rect of me into tColorRect
   put tColorRect into tWidgetRect
   
   if the height of me <= 90 then
      put the top of me + 60 into item 4 of tWidgetRect
   else
      put the bottom of me - 30 into item 4 of tWidgetRect
   end if
   put the bottom of me - 30 into item 2 of tColorRect
   
   set the rect of group "color" of me to tColorRect
   set the rect of widget 1 of me to tWidgetRect
   
   unlock messages
   dispatch "resizeControl" to group "color" of me
   
   set the lockloc of me to false
   unlock screen
end editorResize

on valueChanged
   if the long id of the target is the long id of widget 1 of me then
      set the editorValue of me to the gradientstops of widget 1 of me
   else
      local tValue, tSelected
      put the selectedStop of widget 1 of me into tSelected
      put the gradientStops of widget 1 of me into tValue
      if tSelected is 0 then
         exit valueChanged
      end if
      put currentValue() into item 2 to 5 of line tSelected of tValue 
      set the editorValue of me to tValue
   end if
   updateProperty
end valueChanged

on gradientStopsChanged
   valueChanged
end gradientStopsChanged

on selectedStopChanged
   subeditorUpdate
end selectedStopChanged

local sColor, sOpacity
on setColor pValue
   lock screen
   lock messages
   local tAlpha
   put item 4 of pValue into tAlpha
   if tAlpha is not a number then
      put 0 into tAlpha
   end if
   set the thumbposition of scrollbar "alpha" of me to tAlpha
   
   put tAlpha into sOpacity
   put item 1 to 3 of pValue into sColor
   
   set the swatchcolor of widget "color" of me to pValue
   put pValue into field "value" of me
   unlock messages
   unlock screen
end setColor

function currentValue
   if sColor is empty then
      return empty
   else
      return sColor & comma & sOpacity
   end if
end currentValue

on mouseUp
   switch the short name of the target 
      case "color"
         local tSelectedStop
         put the selectedStop of widget "ramp" of me into tSelectedStop
         if tSelectedStop is empty then
            exit mouseUp
         end if
         local tGradientStops, tColorValue
         put the gradientStops of widget "ramp" of me into tGradientStops
         put item 2 to 4 of line tSelectedStop of tGradientStops into tColorValue
         answer color with tColorValue
         if the result is "cancel" then
            exit mouseUp
         end if
         put it into sColor
         valueChanged
         break
      case "alpha"
         put the thumbposition of scrollbar "alpha" of me into sOpacity
         valueChanged
         break
      default
         pass mouseUp
   end switch
end mouseUp
