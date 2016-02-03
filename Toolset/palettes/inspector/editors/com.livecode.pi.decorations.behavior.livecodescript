script "com.livecode.pi.decorations.behavior"
on editorInitialize
   set the editorMinWidth of me to 0
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   
   -- Remove noshadow and metal from the display decorations - shouldn't be required.
   local tItemNumber
   put itemOffset("metal", tValue) into tItemNumber
   if tItemNumber <> 0 then
      delete item tItemNumber of tValue
   end if
   
   put itemOffset("noshadow", tValue) into tItemNumber
   if tItemNumber <> 0 then
      delete item tItemNumber of tValue
   end if
   lock messages
   put tValue into field "value" of me
   unlock messages
   
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the loc of button "choose" of me to the loc of me
   set the right of button "choose" of me to the right of me
   set the width of field "value" of me to the width of me - the width of button "choose" of me
   set the height of field "value" of me to the formattedheight of field "value" of me
   set the loc of field "value" of me to the loc of me
   set the right of field "value" of me to the left of button "choose" of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   if the short name of the target is "choose" then
      local tDecorations
      put field "value" of me into tDecorations
      
      set the cDecorations of stack "revTitleBarSelector" of stack "com.livecode.pi.decorations" to tDecorations
      
      local tReturnValue
      sheet stack "revTitleBarSelector" of stack "com.livecode.pi.decorations"
      put the cReturnValue of stack "revTitleBarSelector" of stack "com.livecode.pi.decorations" into tReturnValue
      if tReturnValue is not empty then
         if tReturnValue is "empty" then
            put empty into tReturnValue
         end if
         updateValue tReturnValue
      end if
   end if
end mouseUp

on updateValue pValue
   set the editorValue of me to pValue
   updateProperty
end updateValue
