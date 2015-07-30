script "com.livecode.pi.gradientramp.behavior"
on editorInitialize
   set the editorMinWidth of me to 100
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
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the lockLoc of me to true
   
   if the height of me > 60 then
      set the rect of widget 1 of me to the rect of me
   else
      set the rect of widget 1 of me to the left of me, the top of me, the right of me, the top of me + 60
   end if
   
   set the lockloc of me to false
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the gradientstops of widget 1 of me
   updateProperty
end valueChanged

on gradientStopsChanged
   valueChanged
end gradientStopsChanged
