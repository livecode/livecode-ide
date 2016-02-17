script "com.livecode.pi.colorwithalpha.behavior"
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
   local tRect
   set the topleft of widget 1 of me to the topleft of me
   put the rect of me into tRect
   set the rect of scrollbar 1 of me to item 1 of tRect + the width of widget 1 of me + 10, item 2 of tRect, item 3 of tRect, item 4 of tRect
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
