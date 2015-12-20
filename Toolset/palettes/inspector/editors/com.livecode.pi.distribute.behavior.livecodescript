script "com.livecode.pi.distribute.behavior"
on editorInitialize
   set the editorMinWidth of me to 0
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate

end editorUpdate

on editorResize
   lock screen
   lock messages
   set the topleft of group "controls" of me to the topleft of me
   unlock messages
   unlock screen
end editorResize

on menuPick pWhich
   local tValue
   put pWhich into tValue["type"]
   put the short name of the target is "horizontal" into tValue["isHorizontal"]
   set the editorValue of me to tValue
   updateProperty
end menuPick
