script "com.livecode.pi.textstyle.behavior"
on editorInitialize
   set the editorMinWidth of me to 210
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   local tSelected, tIndex
   repeat for each item tItem in tValue
      put itemOffset(tItem, the itemNames of widget 1 of me) into tIndex
      if tIndex is 0 then
         next repeat
      end if
      if tSelected is empty then 
         put tIndex into tSelected
      else
         put comma & tIndex after tSelected
      end if
   end repeat
   set the hilitedItems of widget 1 of me to tSelected
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the height of widget 1 of me to 21
   set the width of widget 1 of me to 210
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   unlock messages
   unlock screen
end editorResize

on hiliteChanged
   valueChanged
end hiliteChanged

on valueChanged
   local tNames
   put the hilitedItemNames of widget 1 of me into tNames
   if tNames is empty then
      set the editorValue of me to empty
   else
      local tValue
      repeat for each item tItem in tNames
         if tValue is empty then 
            put tItem into tValue
         else
            put comma & tItem after tValue
         end if
      end repeat
      set the editorValue of me to tValue
   end if
   updateProperty
end valueChanged
