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
   unlock messages
   dispatch "setColor" to group "color" of me with tColorValue
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
      dispatch function "currentValue" to group "color" of me
      put the result into item 2 to 5 of line tSelected of tValue 
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
