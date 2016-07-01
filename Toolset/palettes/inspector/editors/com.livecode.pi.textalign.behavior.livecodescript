script "com.livecode.pi.textalign.behavior"
on editorInitialize
   set the editorMinWidth of me to 90
   set the editorMaxWidth of me to 90
end editorInitialize

local sConflictLock
on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tConflicted
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   put the editorConflicted of me into sConflictLock
   lock messages
   if sConflictLock then
      set the hilitedItemNames of widget 1 of me to empty
      wait 0 millisecs with messages
      put false into sConflictLock
   else
      set the hilitedItemNames of widget 1 of me to tValue
   end if
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

on hiliteChanged
   if not sConflictLock then
      valueChanged
   end if
end hiliteChanged

on valueChanged
   local tNames
   put the hilitedItemNames of widget 1 of me into tNames
   set the editorValue of me to tNames
   updateProperty
end valueChanged
