script "com.livecode.pi.color.behavior"
local sNamedColor
constant kColorEditorSize = 24

on editorInitialize
   set the editorMinWidth of me to kColorEditorSize
   set the editorMaxWidth of me to kColorEditorSize
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   if tValue is not empty and \
         the number of items in tValue < 3 then
      put true into sNamedColor
      put revIDENamedColorToRGB(tValue) into tValue
   else
      put false into sNamedColor
   end if 
   
   set the enabled of control 1 of me to tEnabled
   if tEffective then
      set the swatchcolor of control 1 of me to empty
   else
      set the swatchcolor of control 1 of me to item 1 to 3 of tValue
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of control 1 of me to 0,0,kColorEditorSize,kColorEditorSize
   set the topleft of control 1 of me to the topleft of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tColor, tNamedColor
   put item 1 to 3 of the swatchcolor of control 1 of me into tColor
   if sNamedColor then
      put revIDERGBToNamedColor(tColor) into tNamedColor
   end if
   
   if tNamedColor is not empty then
      set the editorValue of me to tNamedColor
   else
      set the editorValue of me to tColor
      put false into sNamedColor
   end if
   
   updateProperty
end valueChanged

on mouseUp pButton
   if pButton is not 1 then 
      pass mouseUp
      exit mouseUp 
   end if
   
   answer color with item 1 to 3 of the swatchcolor of control 1 of me
   if it is not empty then
      set the swatchcolor of control 1 of me to it
      dispatch "valueChanged"
   end if
end mouseUp
