script "com.livecode.pi.svgicon.behavior"
on editorInitialize
   set the editorMinWidth of me to 0
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the iconPathPreset of widget 1 of me to tValue
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the height of widget 1 of me to 40
   set the width of widget 1 of me to 40
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   popup widget "com.livecode.widget.iconpicker" at the clickLoc
   if the result is empty then
      set the iconPathPreset of widget 1 of me to it
   end if
   valueChanged
end mouseUp

on valueChanged
   set the editorValue of me to the iconPathPreset of widget 1 of me
   updateProperty
end valueChanged
