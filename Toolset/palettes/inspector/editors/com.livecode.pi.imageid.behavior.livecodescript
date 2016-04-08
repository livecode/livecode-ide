script "com.livecode.pi.imageid.behavior"
constant kFieldWidth = 65
constant kControlGap = 5
on editorInitialize
   local tMinWidth
   put the width of button "icon" of me  + kControlGap +kFieldWidth into tMinWidth
   set the editorMinWidth of me to tMinWidth
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   
   if tValue is not a number then
      put 0 into tValue
   end if
   
   lock messages
   put tValue into field "value" of me
   set the icon of button "icon" of me to tValue
   unlock messages
   
   unlock screen
end editorUpdate

on mouseUp pWhich
   if pWhich is 1 and word 1 of the target is "button" then
      set the cCurrentIcon of stack "revIconChooser" to field "value" of me
      sheet "revIconChooser"
      local tValue
      put the cReturnValue of stack "revIconChooser" into tValue 
      if tValue is not empty then
         put tValue into field "value" of me
         set the icon of button "icon" of me to tValue
         valueChanged
      end if
   end if
end mouseUp

on returnInField
   valueChanged
end returnInField

on enterInField
   valueChanged
end enterInField

on closeField 
   valueChanged
end closeField

on editorResize
   lock screen
   lock messages
   set the loc of button "icon" of me to the loc of me
   set the left of button "icon" of me to the left of me
   set the loc of field "value" of me to the loc of me
   set the width of field "value" of me to kFieldWidth
   set the height of field "value" of me to the formattedheight of field "value" of me
   set the left of field "value" of me to the right of button "icon" of me + kControlGap
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorvalue of me to field "value" of me
   updateProperty
end valueChanged
