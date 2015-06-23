script "com.livecode.pi.textalign.behavior"
on editorInitialize
   set the editorMinWidth of me to 90
   set the editorMaxWidth of me to 90
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   get itemOffset(tValue, the segmentNames of widget 1 of me)
   set the selectedSegment of widget 1 of me to it
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the height of widget 1 of me to 21
   set the width of widget 1 of me to 90
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   if the selectedSegment of widget 1 of me is empty then
      set the editorValue of me to empty
   else
      get item (the selectedSegment of widget 1 of me) of the segmentNames of widget 1 of me
      set the editorValue of me to it
   end if
   updateProperty
end valueChanged
