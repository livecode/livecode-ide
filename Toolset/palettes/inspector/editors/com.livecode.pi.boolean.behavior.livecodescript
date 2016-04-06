script "com.livecode.pi.boolean.behavior"
on editorInitialize
   set the label of button "checkbox" of me to the editorLabel of me
   set the editorMinWidth of me to the formattedWidth of button "checkbox" of me
   set the rowShowLabel of me to false
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   if tValue is true then
      set the hilite of button "checkbox" of me to true
   else
      set the hilite of button "checkbox" of me to false
   end if
   set the enabled of button "checkbox" of me to tEnabled
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the width of button "checkbox" of me to the width of me
   set the width of button "checkbox" of me to the formattedwidth of button "checkbox" of me
   set the height of button "checkbox" of me to the formattedheight of button "checkbox" of me
   set the top of button "checkbox" of me to the top of me
   set the left of button "checkbox" of me to the left of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the hilite of button "checkbox" of me
   updateProperty
end valueChanged

on mouseup
   valueChanged
end mouseup




