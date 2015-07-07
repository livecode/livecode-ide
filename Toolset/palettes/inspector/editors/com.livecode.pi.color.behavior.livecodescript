script "com.livecode.pi.color.behavior"
on editorInitialize
   set the editorMinWidth of me to 24
   set the editorMaxWidth of me to 24
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the enabled of control 1 of me to tEnabled
   if tEffective then
      set the swatchcolor of control 1 of me to empty
   else
      set the swatchcolor of control 1 of me to item 1 to 3 of tValue
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of control 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to item 1 to 3 of the swatchcolor of control 1 of me
   updateProperty
end valueChanged

on mouseUp pButton
   if pButton is empty then put 1 into pButton
   if pButton is not 1 then 
      pass mouseUp
      exit mouseUp 
   end if
   
   answer color with the swatchcolor of control 1 of me
   if it is not empty then
      set the swatchcolor of control 1 of me to it
      dispatch "valueChanged"
   end if
end mouseUp
