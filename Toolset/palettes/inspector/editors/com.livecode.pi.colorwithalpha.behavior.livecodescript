script "com.livecode.pi.colorwithalpha.behavior"
constant kColorEditorSize = 24
constant kControlGap = 5

on editorInitialize
   set the editorMinWidth of me to 60
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   local tAlpha
   put item 4 of tValue into tAlpha
   if tAlpha is a number then
      set the thumbposition of scrollbar 1 of me to tAlpha
   else
      set the thumbposition of scrollbar 1 of me to 255
   end if
   
   set the swatchcolor of widget 1 of me to tValue
   
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of widget 1 of me to 0,0,kColorEditorSize,kColorEditorSize
   set the topleft of widget 1 of me to the topleft of me
   
   local tScrollbarWidth
   put the width of me  - kColorEditorSize - kControlGap into tScrollbarWidth
   set the rect of scrollbar 1 of me to 0, 0, tScrollbarWidth, kColorEditorSize
   set the top of scrollbar 1 of me to the top of me
   set the left of scrollbar 1 of me to the right of widget 1 of me + kControlGap
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tValue
   put item 1 to 3 of the swatchcolor of widget 1 of me & comma & the thumbposition of scrollbar 1 of me into tValue
   set the swatchcolor of widget 1 of me to tValue
   set the editorValue of me to tValue
   updateProperty
end valueChanged

on mouseUp pButton
   if pButton is not 1 then exit mouseUp 
   
   if the target begins with "widget" then
      answer color with item 1 to 3 of the swatchcolor of widget 1 of me
      if it is not empty then
         set the swatchcolor of widget 1 of me to it
         dispatch "valueChanged"
      end if
   end if
end mouseUp
