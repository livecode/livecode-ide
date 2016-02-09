script "com.livecode.pi.file.behavior"
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
   lock messages
   local tLeft,tTop,tRight,tBottom
   put item 1 of the rect of me into tLeft
   put item 2 of the rect of me into tTop
   put item 3 of the rect of me into tRight
   put item 4 of the rect of me into tBottom
   set the rect of button 1 of me to tRight-the width of button 1 of me, tTop, tRight,tBottom
   set the rect of field 1 of me to tLeft, tTop, tRight-the width of button 1 of me - sPadding, tBottom
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to field 1 of me
   updateProperty
end valueChanged

on mouseUp pButton
   local tOptions
   put the editorOptions of me into tOptions
   
   if the name of the target contains "button" and pButton is 1 then
      if tOptions is not empty then
         replace return with comma in tOptions
            end if
      local tResult
      revIDEAnswerFileWithTypes tOptions
      put the result into tResult
      
      if there is a file tResult then
         put tResult into field 1 of me
         valueChanged
      end if
   end if
end mouseUp
