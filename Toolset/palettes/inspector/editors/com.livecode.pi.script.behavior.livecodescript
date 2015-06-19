script "com.livecode.pi.script.behavior"
on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   disable button 1 of me
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field 1 of me
   if exists(tValue) then
      enable button 1 of me
   end if
   set the enabled of field 1 of me to tEnabled
   if tEffective is true then
      set the textcolor of field 1 of me to "150,150,150"
   else
      set the textcolor of field 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

getProp editorMinWidth
   return 140
end editorMinWidth

on editorResize
   lock screen
   lock messages
   
   set the right of button 1 of me to the right of me 
   set the width of field 1 of me to the width of me - 5 - the width of button 1 of me
   set the left of field 1 of me to the left of me
   
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tBehaviorScript
   put field 1 of me into tBehaviorScript
   set the editorValue of me to tBehaviorScript
   if exists(tBehaviorScript) then
      enable button 1 of me
   else
      disable button 1 of me
   end if
   updateProperty
end valueChanged

on editorEditScript
   local tObj
   put field 1 of me into tObj
   try
      edit the script of tObj
   catch tError
      answer "Object" && tObj && "not found"
   end try
end editorEditScript
