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
   local tBlendLevel
   put (item 4 of tValue / 2.55) into tBlendLevel
   if the number of items of tValue is 4 then
      set the thumbposition of scrollbar 1 of me to tBlendLevel
   else
      set the thumbposition of scrollbar 1 of me to 100
   end if
   set the blendlevel of graphic 1 of me to 100 - tBlendLevel
   
   set the enabled of graphic 1 of me to tEnabled
   if tEffective then
      set the backgroundcolor of graphic 1 of me to empty
   else
      set the backgroundcolor of graphic 1 of me to item 1 to 3 of tValue
   end if
   
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   local tRect
   put the rect of me into tRect
   set the rect of graphic 1 of me to item 1 of tRect, item 2 of tRect, item 1 of tRect + 21, item 2 of tRect + 21
   set the rect of scrollbar 1 of me to item 1 of tRect + 31, item 2 of tRect, item 3 of tRect, item 4 of tRect
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tValue, tBlendLevel
   put the backgroundcolor of graphic 1 of me into tValue
   put 100 - the thumbposition of scrollbar 1 of me into tBlendLevel
   set the blendlevel of graphic 1 of me to tBlendLevel
   put tBlendLevel * 2.55 into item 4 of tValue
   set the editorValue of me to tValue
   updateProperty
end valueChanged

on mouseUp pButton
   if pButton is not 1 then exit mouseUp 
   
   if the target begins with "graphic" then
      answer color with the backgroundcolor of graphic 1 of me
      if it is not empty then
         set the backgroundcolor of graphic 1 of me to it
         dispatch "valueChanged"
      end if
   end if
end mouseUp
