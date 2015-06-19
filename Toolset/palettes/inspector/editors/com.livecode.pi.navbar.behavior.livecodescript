script "com.livecode.pi.navbar.behavior"
on editorInitialize
   set the editMode of widget 1 of me to true
   set the editorMinWidth of me to 300
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the navData of widget 1 of me to tValue
   set the height of me to the desiredHeight of widget 1 of me
   set the height of widget 1 of me to the height of me
   unlock messages
   dispatch "inspectorLayout"
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the width of widget 1 of me to the width of me
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   set the height of widget 1 of me to the height of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the navData of widget 1 of me
   updateProperty
end valueChanged
