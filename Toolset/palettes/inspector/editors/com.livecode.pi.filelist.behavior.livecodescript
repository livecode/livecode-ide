script "com.livecode.pi.filelist.behavior"
constant kButtonWidth = 120
constant kControlGap = 15
on editorInitialize
   set the editorMinWidth of me to 600
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field "files" of me
   set the enabled of field "files" of me to tEnabled
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of field "files" of me to the rect of me
   set the width of field "files" of me to the width of me - (kButtonWidth + kControlGap)
   set the topleft of field "files" of me to the topleft of me
   
   set the width of button "add file" of me to kButtonWidth
   set the height of button "add file" of me to 21
   set the top of button "add file" of me to the top of me
   set the left of button "add file" of me to the right of field "files" of me + kControlGap
   
   set the width of button "add folder" of me to kButtonWidth
   set the height of button "add folder" of me to 21
   set the top of button "add folder" of me to the bottom of button "add file" of me + kControlGap
   set the left of button "add folder" of me to the right of field "files" of me + kControlGap
   
   set the width of button "remove" of me to kButtonWidth
   set the height of button "remove" of me to 21
   set the top of button "remove" of me to the bottom of button "add folder" of me + kControlGap
   set the left of button "remove" of me to the right of field "files" of me + kControlGap
   
   unlock messages
   unlock screen
end editorResize

on addEntry pEntry
   local tValue
   put the editorValue of me into tValue
   if tValue is empty then
      put pEntry into tValue
   else
      put return & pEntry after tValue
   end if
   set the editorValue of me to tValue
   updateProperty
end addEntry

on removeLines pLines
   if pLines is not empty then
      repeat with X=the number of items in pLines down to 1
         delete line (item X of pLines) of fld "files" of me
      end repeat
   end if
   set the editorValue of me to field "files" of me
   updateProperty
end removeLines






