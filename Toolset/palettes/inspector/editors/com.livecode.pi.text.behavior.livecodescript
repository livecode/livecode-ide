script "com.livecode.pi.text.behavior"
local sTextType
on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   
   set the itemdelimiter to "."
   put item -1 of the editorProperty["editor"] of me into sTextType
   
   local tText, tOptions
   put the editorOptions of me into tOptions
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      local tProperty,tValue
      put item 1 of tLine into tProperty
      put item 2 of tLine into tValue
      set the tProperty of field 1 of me to tValue
   end repeat
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tProp
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   if sTextType is "styledText" then
      set the styledText of field 1 of me to tValue
   else
      put tValue into field 1 of me
   end if
   
   if sTextType is "noWrapText" then
      set the dontWrap of field 1 of me to true
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

on editorResize
   lock screen
   lock messages
   set the lockLoc of me to true
   local tHeight
   put the formattedheight of field 1 of me into tHeight
   if tHeight < 21 then 
      put 21 into tHeight
   else if tHeight > 150 then
      put 150 into tHeight
   end if
   
   local tLeft, tTop, tRight
   put the left of me into tLeft
   put the top of me into tTop
   put the right of me into tRight
   set the rect of field 1 of me to tLeft, tTop, tRight, tTop + tHeight
   set the height of me to the height of field 1 of me
   set the lockloc of me to false
   unlock messages
   unlock screen
end editorResize

on valueChanged
   if sTextType is "styledText" then
      set the editorValue of me to the styledText of field 1 of me
   else
      set the editorValue of me to field 1 of me
   end if
   updateProperty
end valueChanged

on enterInField
   valueChanged
end enterInField

on returnInField
   if (the controlKey is down) then 
      enterInField
   else
      pass returnInField
   end if
end returnInField

on closeField
   valueChanged
end closeField
