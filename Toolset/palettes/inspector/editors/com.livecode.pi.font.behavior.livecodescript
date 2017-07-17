script "com.livecode.pi.font.behavior"
constant kEffectiveTextColor = "100,100,100"
constant kFontMenuLines = 20

on editorInitialize
   set the editorMinWidth of me to 40
   set the editorMaxWidth of me to 0
   
   local tFontNames
   put the fontNames into tFontNames
   sort tFontNames
   set the text of button 1 of me to tFontNames
   set the menuLines of button 1 of me to kFontMenuLines
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   set the label of button 1 of me to tValue
   
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of button 1 of me to kEffectiveTextColor
      set the textstyle["italic"] of button 1 of me to true
   else
      set the textcolor of button 1 of me to empty
      set the textstyle of button 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of button 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the label of button 1 of me
   updateProperty
end valueChanged

on closeField
   valueChanged
end closeField
