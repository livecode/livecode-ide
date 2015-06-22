script "com.livecode.pi.string.behavior"
on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field 1 of me
   set the enabled of field 1 of me to tEnabled
   if tEffective is true then
      set the textcolor of field 1 of me to "150,150,150"
   else
      set the textcolor of field 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on openField
   if the editorEffective of me is true then
      put empty into field 1 of me
   end if
end openField

on closeField
   editorUpdate
end closeField

on returnInField
   dispatch "valueChanged"
end returnInField

on enterInField
   dispatch "valueChanged"
end enterInField

on closeField
   dispatch "valueChanged"
end closeField

on editorResize
   lock screen
   lock messages
   set the rect of field 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to field 1 of me
   set the editorEffective of me to false
   updateProperty
end valueChanged
