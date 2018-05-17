script "com.livecode.pi.svgicon.behavior" with behavior "revInspectorEditorBehavior"
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
   set the iconPresetName of widget 1 of me to tValue
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
   local tValue
   put the editorValue of me into tValue
   set the dialogData to tValue

   set the behavior of stack "com.livecode.pi.svgiconfilter" to the long id of stack "com.livecode.pi.svgiconfilter.behavior"
   modal stack "com.livecode.pi.svgiconfilter" at the clickLoc

   if the dialogData is not tValue then
      set the iconPresetName of widget 1 of me to the dialogData
   end if
   valueChanged
end mouseUp

on valueChanged
   set the editorValue of me to the iconPresetName of widget 1 of me
   updateProperty
end valueChanged
