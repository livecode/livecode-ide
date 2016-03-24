script "com.livecode.pi.datagrid.behavior"
on editorInitialize
   set the editorMinWidth of me to 200
   set the editorMaxWidth of me to 0
end editorInitialize

local sValue
on editorUpdate

end editorUpdate

on editorResize
   lock screen
   set the lockloc of me to true
   
   local tTop, tLeft,tRight,tWidth
   put the top of me into tTop
   put the left of me into tLeft
   put the width of me into tWidth
   
   repeat with x = 1 to the number of groups of me
      set the lockloc of group x of me to true 
      set the width of group x of me to tWidth
      set the topleft of  group x of me to tLeft,tTop
      send "subEditorResize" to group x of me
      add the formattedheight of group x of me + the palettePadding of stack "revInspector" to tTop
   end repeat
   
   set the lockloc of me to false
   unlock screen
end editorResize

on valueChanged
   updateProperty
end valueChanged

on dataGridRefresh
   dispatch "valueChanged"
end dataGridRefresh

on dataGridTemplateLoad
   local tValue
   put the editorValue of me into tValue
   
   local tCard
   set the itemdel to "card"
   put "card" && item 2 to -1 of tValue into tCard
   
   if exists(tCard) then
      go tCard
   end if
end dataGridTemplateLoad
