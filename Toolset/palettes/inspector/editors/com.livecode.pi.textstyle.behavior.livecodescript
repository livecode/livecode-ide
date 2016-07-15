script "com.livecode.pi.textstyle.behavior"
on editorInitialize
   set the editorMinWidth of me to 210
   set the editorMaxWidth of me to 0
end editorInitialize

private function commonSettings pConflicts
   local tCommon, tKeys
   put the keys of pConflicts into tKeys
   repeat for each item tItem in pConflicts[line 1 of tKeys]
      put true into tCommon[tItem]
   end repeat
   delete line 1 of tKeys
   
   local tCurrent
   repeat for each line tKey in tKeys
      repeat for each key tItem in tCommon
         if tItem is among the items of pConflicts[tKey] then
            put true into tCurrent[tItem]
         else
            delete variable tCurrent[tItem]
         end if
      end repeat
      put tCurrent into tCommon
   end repeat
   
   put the keys of tCommon into tCommon
   replace return with comma in tCommon
   return tCommon
end commonSettings

local sConflictLock
on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tConflicts
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   put the editorConflicted of me into sConflictLock
   put the editorConflicts of me into tConflicts
   lock messages
   if sConflictLock then
      put commonSettings(tConflicts) into tValue
   end if
   
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
   
   if sConflictLock then
      set the hilitedItems of widget 1 of me to tSelected
      wait 0 millisecs with messages
      put false into sConflictLock
   else
      set the hilitedItems of widget 1 of me to tSelected
   end if
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
   if not sConflictLock then
      valueChanged
   end if
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
