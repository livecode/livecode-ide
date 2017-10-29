script "com.livecode.pi.folder.behavior"
local sPadding
on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   put the palettePadding of this stack into sPadding
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   if not tEnabled then
      set the opaque of field 1 of me to false
      set the showborder of field 1 of me to false
      set the locktext of field 1 of me to true
      set the autohilite of field 1 of me to false
      hide button 1 of me
   end if
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

on editorResize
   lock screen
   local tEnabled
   put the editorEnabled of me into tEnabled
   lock messages
   local tLeft,tTop,tRight,tBottom
   put item 1 of the rect of me into tLeft
   put item 2 of the rect of me into tTop
   put item 3 of the rect of me into tRight
   put item 4 of the rect of me into tBottom
   if tEnabled then
      set the rect of button 1 of me to tRight-the width of button 1 of me, tTop, tRight,tBottom
      set the rect of field 1 of me to tLeft, tTop, tRight-the width of button 1 of me - sPadding, tBottom
   else
      set the rect of field 1 of me to the rect of me
   end if
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to field 1 of me
   updateProperty
end valueChanged

on mouseUp pButton   
   if the name of the target contains "button" and pButton is 1 then
      local tResult
      answer folder "Please select a folder"
      put the result into tResult
      
      if there is a folder tResult then
         put tResult into field 1 of me
         valueChanged
      end if
   end if
end mouseUp
